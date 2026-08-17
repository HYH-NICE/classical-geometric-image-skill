from __future__ import annotations

import argparse
import contextlib
import importlib.util
import io
import pathlib
import sys
import tempfile
import unittest
import warnings
from unittest import mock

from PIL import Image, ImageDraw


SCRIPT = pathlib.Path(__file__).parents[1] / "scripts" / "build_style_atlas.py"
SPEC = importlib.util.spec_from_file_location("build_style_atlas", SCRIPT)
assert SPEC and SPEC.loader
atlas = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = atlas
SPEC.loader.exec_module(atlas)


def split_image(top: str, bottom: str, size: tuple[int, int] = (160, 120)) -> Image.Image:
    image = Image.new("RGB", size, top)
    ImageDraw.Draw(image).rectangle(
        (0, size[1] // 2, size[0] - 1, size[1] - 1), fill=bottom
    )
    return image


def candidate(
    name: str,
    image: Image.Image,
    score: float = 1.0,
    digest: str | None = None,
) -> atlas.Candidate:
    return atlas.Candidate(
        path=pathlib.Path(name),
        digest=digest or name,
        visual_score=score,
        perceptual_signatures=atlas.perceptual_signatures(image),
        aspect_ratio=image.width / image.height,
        width=image.width,
        height=image.height,
    )


class SizeTests(unittest.TestCase):
    def test_accepts_derived_minimum_999_and_default(self) -> None:
        self.assertEqual(atlas.parse_size("480x288"), (480, 288))
        self.assertEqual(atlas.parse_size("999x600"), (999, 600))
        self.assertEqual(atlas.parse_size("1800x1200"), (1800, 1200))

    def test_rejects_below_labeled_grid_and_malformed_values(self) -> None:
        for value in ("1x1", "479x288", "480x287"):
            with self.subTest(value=value), self.assertRaisesRegex(
                argparse.ArgumentTypeError, "5x4 labeled grid"
            ):
                atlas.parse_size(value)
        for value in ("0x288", "480x0", "bad", "1x2x3"):
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                atlas.parse_size(value)


class SimilarityTests(unittest.TestCase):
    def test_numbered_series_survive_but_reencoded_copy_merges(self) -> None:
        originals = (
            candidate("IMG_1.jpg", split_image("red", "cyan"), 1),
            candidate("IMG_2.jpg", split_image("green", "magenta"), 1),
            candidate("Iran-iWeb-1.jpg", split_image("blue", "yellow"), 1),
            candidate("Iran-iWeb-2.jpg", split_image("black", "white"), 1),
        )
        buffer = io.BytesIO()
        split_image("red", "cyan").save(buffer, format="JPEG", quality=70)
        buffer.seek(0)
        reencoded = Image.open(buffer).convert("RGB")
        copy = candidate("IMG_1_copy.jpg", reencoded, 5, digest="different bytes")

        collapsed = atlas.collapse_perceptual_variants(originals + (copy,))

        self.assertEqual(len(collapsed), 4)
        names = {item.path.name for item in collapsed}
        self.assertIn("IMG_1_copy.jpg", names)
        self.assertNotIn("IMG_1.jpg", names)
        self.assertTrue({"IMG_2.jpg", "Iran-iWeb-1.jpg", "Iran-iWeb-2.jpg"} <= names)

    def test_complementary_horizontal_halves_do_not_false_merge(self) -> None:
        pairs = (
            ("red", "cyan"),
            ("green", "magenta"),
            ("blue", "yellow"),
            ("black", "white"),
        )
        items = tuple(
            candidate(f"halves-{index}.png", split_image(*colors))
            for index, colors in enumerate(pairs)
        )
        self.assertEqual(len(atlas.collapse_perceptual_variants(items)), 4)

    def test_reencode_and_crop_merge_but_distinct_image_survives(self) -> None:
        base = Image.new("RGB", (320, 240), "white")
        draw = ImageDraw.Draw(base)
        draw.rectangle((30, 20, 290, 220), fill="navy")
        draw.ellipse((90, 50, 230, 190), fill="gold")
        buffer = io.BytesIO()
        base.save(buffer, format="JPEG", quality=66)
        buffer.seek(0)
        reencoded = Image.open(buffer).convert("RGB")
        cropped = base.crop((12, 9, 308, 231))
        distinct = split_image("lime", "purple", (320, 240))
        items = (
            candidate("base.png", base, 1),
            candidate("jpeg.jpg", reencoded, 2),
            candidate("crop.png", cropped, 3),
            candidate("distinct.png", distinct, 1),
        )
        collapsed = atlas.collapse_perceptual_variants(items)
        self.assertEqual([item.path.name for item in collapsed], ["crop.png", "distinct.png"])

    def test_similarity_components_are_transitive_and_deterministic(self) -> None:
        spatial = (100,) * 48
        signature = atlas.PerceptualSignature
        items = (
            atlas.Candidate(pathlib.Path("a"), "a", 3, (signature(0, 0, spatial),), 1, 500, 500),
            atlas.Candidate(pathlib.Path("b"), "b", 2, (signature(31, 0, spatial),), 1, 500, 500),
            atlas.Candidate(pathlib.Path("c"), "c", 1, (signature(1023, 0, spatial),), 1, 500, 500),
        )
        self.assertEqual(atlas.collapse_perceptual_variants(items), (items[0],))
        self.assertEqual(atlas.collapse_perceptual_variants(tuple(reversed(items))), (items[0],))
        tied = tuple(
            atlas.Candidate(item.path, item.digest, 1, item.perceptual_signatures, 1, 500, 500)
            for item in items
        )
        self.assertEqual(atlas.collapse_perceptual_variants(tuple(reversed(tied))), (tied[0],))


class SafetyTests(unittest.TestCase):
    def test_decompression_warning_is_promoted_and_counted_as_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            for category in atlas.CATEGORIES:
                (root / category).mkdir()
            image_path = root / atlas.CATEGORIES[0] / "oversized.jpg"
            image_path.write_bytes(b"metadata only")
            warning = Image.DecompressionBombWarning("synthetic oversized metadata")
            with mock.patch.object(atlas, "sha256_file", return_value="digest"), mock.patch.object(
                atlas, "measure_readable_image", side_effect=warning
            ), contextlib.redirect_stderr(io.StringIO()) as stderr:
                results = atlas.collect_images(root)
            self.assertEqual(results[atlas.CATEGORIES[0]].skipped, 1)
            self.assertIn("skipped unreadable image", stderr.getvalue())

    def test_measurement_promotes_pillow_bomb_warning_without_large_allocation(self) -> None:
        def warning_open(*_args: object, **_kwargs: object) -> Image.Image:
            warnings.warn("synthetic oversized metadata", Image.DecompressionBombWarning)
            raise AssertionError("warning should have become an exception")

        with mock.patch.object(atlas.Image, "open", side_effect=warning_open), self.assertRaises(
            Image.DecompressionBombWarning
        ):
            atlas.measure_readable_image(pathlib.Path("oversized.jpg"))

    def test_output_below_source_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            source = pathlib.Path(temporary).resolve()
            with self.assertRaisesRegex(ValueError, "read-only source"):
                atlas.validate_output_path(source, source / "category" / "atlas.jpg")
            atlas.validate_output_path(source, source.parent / "outside-atlas.jpg")


class SelectionTests(unittest.TestCase):
    def test_semantic_matches_displace_neutral_files_when_enough_exist(self) -> None:
        positive = tuple(
            candidate(f"Temple_{index}.jpg", split_image(color, "white", (640, 480)))
            for index, color in enumerate(("red", "green", "blue", "purple"))
        )
        neutral = candidate("unrelated_book.jpg", split_image("black", "white", (640, 480)))
        self.assertEqual(
            atlas.prefer_relevant("Chinese_Classical", positive + (neutral,)), positive
        )

    def test_low_information_images_are_omitted_when_four_detailed_exist(self) -> None:
        detailed = tuple(
            atlas.Candidate(
                path=pathlib.Path(f"detail-{index}.jpg"),
                digest=str(index),
                visual_score=10,
                perceptual_signatures=atlas.perceptual_signatures(
                    split_image(color, "white", (640, 480))
                ),
                aspect_ratio=4 / 3,
                width=640,
                height=480,
                information_score=8,
            )
            for index, color in enumerate(("red", "green", "blue", "purple"))
        )
        blank = atlas.Candidate(
            pathlib.Path("blank.jpg"),
            "blank",
            99,
            atlas.perceptual_signatures(Image.new("RGB", (640, 480), "black")),
            4 / 3,
            640,
            480,
            0,
        )
        self.assertEqual(atlas.prefer_informative(detailed + (blank,)), detailed)

    def test_low_resolution_is_omitted_when_four_adequate_images_exist(self) -> None:
        high = tuple(
            candidate(f"high-{index}.jpg", split_image(color, "white", (640, 480)), index)
            for index, color in enumerate(("red", "green", "blue", "purple"), 1)
        )
        low = candidate("thumbnail-100x100.jpg", split_image("black", "white", (100, 100)), 99)
        self.assertEqual(atlas.prefer_adequate(high + (low,)), high)

    def test_low_resolution_falls_back_when_needed(self) -> None:
        high = tuple(
            candidate(f"high-{index}.jpg", split_image(color, "white", (640, 480)), index)
            for index, color in enumerate(("red", "green", "blue"), 1)
        )
        low = candidate("thumbnail-100x100.jpg", split_image("black", "white", (100, 100)), 1)
        self.assertEqual(atlas.prefer_adequate(high + (low,)), high + (low,))

    def test_diversity_selection_has_stable_tie_breaking(self) -> None:
        items = tuple(
            candidate(name, split_image(top, bottom, (640, 480)), 1)
            for name, top, bottom in (
                ("b.jpg", "red", "cyan"),
                ("A.jpg", "green", "magenta"),
                ("a.jpg", "blue", "yellow"),
                ("c.jpg", "black", "white"),
            )
        )
        forward = atlas.select_diverse(items, limit=3)
        reverse = atlas.select_diverse(tuple(reversed(items)), limit=3)
        self.assertEqual(forward, reverse)
        self.assertEqual(forward[0].path.name, "A.jpg")


if __name__ == "__main__":
    unittest.main()
