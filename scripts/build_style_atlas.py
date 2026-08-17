#!/usr/bin/env python3
"""Build a deterministic five-column classical architecture style atlas."""

from __future__ import annotations

import argparse
import hashlib
import math
import sys
import warnings
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageStat, UnidentifiedImageError


CATEGORIES = (
    "Islamic_Architecture",
    "Chinese_Classical",
    "Western_Classical",
    "Geometric_Design",
    "Original_Manuscripts",
)
SUPPORTED_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".bmp",
    ".tif",
    ".tiff",
}
ROWS = 4
MIN_CELL_WIDTH = 96
MIN_CELL_HEIGHT = 72
DHASH_DISTANCE_THRESHOLD = 8
SPATIAL_RGB_RMSE_THRESHOLD = 32.0
ASPECT_RATIO_DELTA_THRESHOLD = 0.12
MIN_EFFECTIVE_PIXELS = 160_000
MIN_EFFECTIVE_SHORT_SIDE = 180
MIN_INFORMATION_SCORE = 3.0
RELEVANCE_TERMS = {
    "Islamic_Architecture": (
        "alhambra", "dome", "girih", "islamic", "mosque", "muqarnas", "samarkand", "zillij"
    ),
    "Chinese_Classical": (
        "dougong", "fogong", "foguang", "forbidden city", "nanchan", "pagoda", "palace",
        "temple", "天坛", "故宫", "斗拱",
    ),
    "Western_Classical": (
        "basilica", "column", "facade", "pantheon", "parthenon", "temple", "villa"
    ),
    "Geometric_Design": (
        "circle", "diamond", "euclidean", "geometr", "natural-form", "pattern", "serpinski",
        "triangular", "trigonometric", "villard",
    ),
    "Original_Manuscripts": (
        "alberti", "book", "frontispiece", "libri", "manuscript", "recto", "temple types",
        "title page", "vitruvius",
    ),
}
IRRELEVANCE_TERMS = {
    "Chinese_Classical": ("bolshevism", "housing complex", "restaurant", "station", "workout"),
    "Geometric_Design": ("bridge", "sausalito"),
    "Original_Manuscripts": ("buste", "pilgrim", "statue"),
    "Western_Classical": ("cathedral", "chartres", "gothic", "notre dame", "rosace"),
}


@dataclass(frozen=True)
class PerceptualSignature:
    horizontal_hash: int
    vertical_hash: int
    spatial_rgb: tuple[int, ...]


@dataclass(frozen=True)
class Candidate:
    path: Path
    digest: str
    visual_score: float
    perceptual_signatures: tuple[PerceptualSignature, ...] = ()
    aspect_ratio: float = 0.0
    width: int = 0
    height: int = 0
    information_score: float = 0.0


@dataclass
class CategoryResult:
    readable: int = 0
    skipped: int = 0
    duplicates: int = 0
    selected: tuple[Candidate, ...] = ()


def parse_size(value: str) -> tuple[int, int]:
    """Parse a positive WIDTHxHEIGHT command-line value."""
    parts = value.lower().split("x")
    if len(parts) != 2:
        raise argparse.ArgumentTypeError(
            f"invalid size {value!r}; expected WIDTHxHEIGHT, for example 1800x1200"
        )
    try:
        width, height = (int(part) for part in parts)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"invalid size {value!r}; width and height must be integers"
        ) from exc
    if width <= 0 or height <= 0:
        raise argparse.ArgumentTypeError(
            f"invalid size {value!r}; width and height must be positive"
        )
    minimum_width = len(CATEGORIES) * MIN_CELL_WIDTH
    minimum_height = ROWS * MIN_CELL_HEIGHT
    if width < minimum_width or height < minimum_height:
        raise argparse.ArgumentTypeError(
            f"invalid size {value!r}; need at least {minimum_width}x{minimum_height} "
            f"for a {len(CATEGORIES)}x{ROWS} labeled grid "
            f"({MIN_CELL_WIDTH}x{MIN_CELL_HEIGHT} pixels per cell)"
        )
    return width, height


def sha256_file(path: Path) -> str:
    """Return the SHA-256 digest of a file's bytes without modifying it."""
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def difference_hashes(image: Image.Image) -> tuple[int, int]:
    """Return deterministic horizontal and vertical 64-bit dHashes."""
    gray = image.convert("L")
    horizontal_sample = gray.resize((9, 8), Image.Resampling.LANCZOS)
    horizontal_pixels = list(horizontal_sample.tobytes())
    horizontal = 0
    for row in range(8):
        offset = row * 9
        for column in range(8):
            horizontal = (horizontal << 1) | (
                horizontal_pixels[offset + column]
                > horizontal_pixels[offset + column + 1]
            )

    vertical_sample = gray.resize((8, 9), Image.Resampling.LANCZOS)
    vertical_pixels = list(vertical_sample.tobytes())
    vertical = 0
    for row in range(8):
        for column in range(8):
            vertical = (vertical << 1) | (
                vertical_pixels[row * 8 + column]
                > vertical_pixels[(row + 1) * 8 + column]
            )
    return horizontal, vertical


def make_signature(image: Image.Image) -> PerceptualSignature:
    """Capture edge direction and coarse spatial RGB layout using Pillow only."""
    horizontal, vertical = difference_hashes(image)
    spatial = image.convert("RGB").resize((4, 4), Image.Resampling.BOX)
    spatial_rgb = tuple(spatial.tobytes())
    return PerceptualSignature(horizontal, vertical, spatial_rgb)


def perceptual_signatures(
    image: Image.Image,
) -> tuple[PerceptualSignature, PerceptualSignature]:
    """Describe the full image and a 4% center crop for crop tolerance."""
    width, height = image.size
    inset_x = max(1, round(width * 0.04))
    inset_y = max(1, round(height * 0.04))
    if width > 2 * inset_x and height > 2 * inset_y:
        cropped = image.crop((inset_x, inset_y, width - inset_x, height - inset_y))
    else:
        cropped = image
    return make_signature(image), make_signature(cropped)


def measure_readable_image(
    path: Path,
) -> tuple[float, tuple[PerceptualSignature, PerceptualSignature], float, int, int]:
    """Fully decode an image and return deterministic visual measurements."""
    with warnings.catch_warnings():
        warnings.simplefilter("error", Image.DecompressionBombWarning)
        with Image.open(path) as image:
            transposed = ImageOps.exif_transpose(image)
            transposed.load()
            preview = ImageOps.contain(transposed.convert("L"), (256, 256))
            contrast = ImageStat.Stat(preview).stddev[0]
            score = preview.entropy() + contrast / 32.0
            signatures = perceptual_signatures(transposed)
            aspect_ratio = transposed.width / transposed.height
            return score, signatures, aspect_ratio, transposed.width, transposed.height


def filename_relevance(category: str, path: Path) -> int:
    """Score category-specific filename signals without relying on randomness."""
    name = path.name.casefold().replace("_", " ").replace("-", " ")
    positive = sum(term.casefold() in name for term in RELEVANCE_TERMS[category])
    negative = sum(term.casefold() in name for term in IRRELEVANCE_TERMS.get(category, ()))
    return positive - 3 * negative


def prefer_relevant(
    category: str, candidates: Sequence[Candidate], minimum: int = ROWS
) -> tuple[Candidate, ...]:
    """Drop category-negative filenames when enough representative choices remain."""
    positive = tuple(
        candidate
        for candidate in candidates
        if filename_relevance(category, candidate.path) > 0
    )
    if len(positive) >= minimum:
        return positive
    nonnegative = tuple(
        candidate
        for candidate in candidates
        if filename_relevance(category, candidate.path) >= 0
    )
    return nonnegative if len(nonnegative) >= minimum else tuple(candidates)


def prefer_adequate(
    candidates: Sequence[Candidate], minimum: int = ROWS
) -> tuple[Candidate, ...]:
    """Exclude tiny sources only when enough higher-resolution choices exist."""
    adequate = tuple(
        candidate
        for candidate in candidates
        if candidate.width * candidate.height >= MIN_EFFECTIVE_PIXELS
        and min(candidate.width, candidate.height) >= MIN_EFFECTIVE_SHORT_SIDE
    )
    return adequate if len(adequate) >= minimum else tuple(candidates)


def prefer_informative(
    candidates: Sequence[Candidate], minimum: int = ROWS
) -> tuple[Candidate, ...]:
    """Exclude visually empty/flat sources only when detailed choices suffice."""
    informative = tuple(
        candidate
        for candidate in candidates
        if candidate.information_score >= MIN_INFORMATION_SCORE
    )
    return informative if len(informative) >= minimum else tuple(candidates)


def effective_information_score(
    raw_score: float, signature: PerceptualSignature
) -> float:
    """Penalize large flat color fields while retaining fine monochrome drawings."""
    edge_bits = signature.horizontal_hash.bit_count() + signature.vertical_hash.bit_count()
    mean = sum(signature.spatial_rgb) / len(signature.spatial_rgb)
    spatial_spread = (
        sum((channel - mean) ** 2 for channel in signature.spatial_rgb)
        / len(signature.spatial_rgb)
    ) ** 0.5
    if edge_bits < 50 and spatial_spread > 30:
        return raw_score * 0.25
    return raw_score


def are_perceptually_similar(
    first: Candidate,
    second: Candidate,
) -> bool:
    """Require directional edges, spatial RGB, and aspect ratio all to match."""
    if not first.perceptual_signatures or not second.perceptual_signatures:
        return False
    if first.aspect_ratio <= 0 or second.aspect_ratio <= 0:
        return False
    aspect_delta = abs(first.aspect_ratio - second.aspect_ratio) / max(
        first.aspect_ratio, second.aspect_ratio
    )
    if aspect_delta > ASPECT_RATIO_DELTA_THRESHOLD:
        return False
    for left in first.perceptual_signatures:
        for right in second.perceptual_signatures:
            horizontal_distance = (
                left.horizontal_hash ^ right.horizontal_hash
            ).bit_count()
            vertical_distance = (left.vertical_hash ^ right.vertical_hash).bit_count()
            spatial_rmse = (
                sum(
                    (left_channel - right_channel) ** 2
                    for left_channel, right_channel in zip(
                        left.spatial_rgb, right.spatial_rgb
                    )
                )
                / len(left.spatial_rgb)
            ) ** 0.5
            if (
                horizontal_distance <= DHASH_DISTANCE_THRESHOLD
                and vertical_distance <= DHASH_DISTANCE_THRESHOLD
                and spatial_rmse <= SPATIAL_RGB_RMSE_THRESHOLD
            ):
                return True
    return False


def collapse_perceptual_variants(candidates: Sequence[Candidate]) -> tuple[Candidate, ...]:
    """Cluster all similarity-connected variants and keep each component's best."""
    ordered = sorted(
        candidates,
        key=lambda candidate: (
            candidate.path.as_posix().casefold(),
            candidate.path.as_posix(),
        ),
    )
    count = len(ordered)
    parent = list(range(count))

    def find(index: int) -> int:
        while parent[index] != index:
            parent[index] = parent[parent[index]]
            index = parent[index]
        return index

    def union(left: int, right: int) -> None:
        left_root, right_root = find(left), find(right)
        if left_root == right_root:
            return
        lower, higher = sorted((left_root, right_root))
        parent[higher] = lower

    for left in range(count):
        for right in range(left + 1, count):
            if are_perceptually_similar(ordered[left], ordered[right]):
                union(left, right)

    components: dict[int, list[int]] = {}
    for index in range(count):
        components.setdefault(find(index), []).append(index)
    return tuple(
        ordered[max(indices, key=lambda index: ordered[index].visual_score)]
        for indices in components.values()
    )


def candidate_path_key(candidate: Candidate) -> tuple[str, str]:
    """Provide a deterministic case-insensitive then exact path ordering."""
    exact = candidate.path.as_posix()
    return exact.casefold(), exact


def descriptor_distance(first: Candidate, second: Candidate) -> float:
    """Measure visual diversity from directional edges, spatial RGB, and aspect."""
    if not first.perceptual_signatures or not second.perceptual_signatures:
        return 1.0
    left, right = first.perceptual_signatures[0], second.perceptual_signatures[0]
    edge_distance = (
        (left.horizontal_hash ^ right.horizontal_hash).bit_count()
        + (left.vertical_hash ^ right.vertical_hash).bit_count()
    ) / 128.0
    color_distance = (
        sum(
            (left_channel - right_channel) ** 2
            for left_channel, right_channel in zip(left.spatial_rgb, right.spatial_rgb)
        )
        / len(left.spatial_rgb)
    ) ** 0.5 / 255.0
    aspect_distance = min(1.0, abs(math.log(first.aspect_ratio / second.aspect_ratio)))
    return 0.45 * edge_distance + 0.50 * color_distance + 0.05 * aspect_distance


def candidate_quality(candidate: Candidate) -> float:
    """Rank semantic/visual quality first, with a small resolution preference."""
    resolution_bonus = math.log2(max(1, candidate.width * candidate.height)) / 20.0
    return candidate.visual_score + resolution_bonus


def select_diverse(
    candidates: Sequence[Candidate], limit: int = ROWS
) -> tuple[Candidate, ...]:
    """Select a quality seed, then deterministic farthest-point visual samples."""
    pool = sorted(candidates, key=candidate_path_key)
    if not pool or limit <= 0:
        return ()
    first = max(pool, key=candidate_quality)
    selected = [first]
    remaining = [candidate for candidate in pool if candidate is not first]
    while remaining and len(selected) < limit:
        chosen = max(
            remaining,
            key=lambda candidate: (
                min(descriptor_distance(candidate, prior) for prior in selected),
                candidate_quality(candidate),
            ),
        )
        selected.append(chosen)
        remaining.remove(chosen)
    return tuple(selected)


def collect_images(source: Path) -> dict[str, CategoryResult]:
    """Decode, globally deduplicate, and select each category's images."""
    seen_digests: set[str] = set()
    results: dict[str, CategoryResult] = {}

    for category in CATEGORIES:
        category_dir = source / category
        paths = sorted(
            (
                path
                for path in category_dir.rglob("*")
                if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS
            ),
            key=lambda path: (
                path.relative_to(category_dir).as_posix().casefold(),
                path.relative_to(category_dir).as_posix(),
            ),
        )
        result = CategoryResult()
        unique: list[Candidate] = []
        for path in paths:
            try:
                digest = sha256_file(path)
                raw_score, signatures, aspect_ratio, width, height = (
                    measure_readable_image(path)
                )
            except (
                OSError,
                ValueError,
                UnidentifiedImageError,
                Image.DecompressionBombWarning,
                Image.DecompressionBombError,
            ) as exc:
                result.skipped += 1
                print(f"WARNING: skipped unreadable image {path}: {exc}", file=sys.stderr)
                continue

            result.readable += 1
            if digest in seen_digests:
                result.duplicates += 1
                continue
            seen_digests.add(digest)
            relevance = filename_relevance(category, path)
            information_score = effective_information_score(raw_score, signatures[0])
            unique.append(
                Candidate(
                    path=path,
                    digest=digest,
                    visual_score=relevance * 100.0 + information_score,
                    perceptual_signatures=signatures,
                    aspect_ratio=aspect_ratio,
                    width=width,
                    height=height,
                    information_score=information_score,
                )
            )

        perceptual_unique = collapse_perceptual_variants(unique)
        representative = prefer_relevant(category, perceptual_unique)
        quality_pool = prefer_adequate(representative)
        informative_pool = prefer_informative(quality_pool)
        result.selected = select_diverse(informative_pool)
        results[category] = result

    return results


def load_font(size: int) -> ImageFont.ImageFont:
    """Use Pillow's bundled default font without machine font discovery."""
    try:
        return ImageFont.load_default(size=max(10, size))
    except TypeError:
        return ImageFont.load_default()


def truncate_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.ImageFont,
    max_width: int,
) -> str:
    """Fit text to a pixel width, or omit it when an ellipsis cannot fit."""
    if max_width <= 0:
        return ""
    if draw.textlength(text, font=font) <= max_width:
        return text
    ellipsis = "..."
    if draw.textlength(ellipsis, font=font) > max_width:
        return ""
    shortened = text
    while shortened and draw.textlength(shortened + ellipsis, font=font) > max_width:
        shortened = shortened[:-1]
    return shortened.rstrip() + ellipsis if shortened else ""


def contain_image(path: Path, bounds: tuple[int, int]) -> Image.Image:
    """Decode with EXIF orientation and fit without cropping or distortion."""
    with Image.open(path) as image:
        oriented = ImageOps.exif_transpose(image).convert("RGB")
        return ImageOps.contain(oriented, bounds, Image.Resampling.LANCZOS)


def render_atlas(
    results: dict[str, CategoryResult], output: Path, size: tuple[int, int]
) -> None:
    """Render an RGB JPEG in five category columns and four rows."""
    width, height = size
    background = (28, 29, 31)
    cell_background = (39, 40, 43)
    border = (91, 93, 98)
    label_color = (238, 238, 235)
    empty_color = (154, 156, 160)
    canvas = Image.new("RGB", size, background)
    draw = ImageDraw.Draw(canvas)

    x_edges = [round(index * width / len(CATEGORIES)) for index in range(len(CATEGORIES) + 1)]
    y_edges = [round(index * height / ROWS) for index in range(ROWS + 1)]
    font = load_font(min(width // 90, height // 45))

    for column, category in enumerate(CATEGORIES):
        selected = results[category].selected
        for row in range(ROWS):
            left, right = x_edges[column], x_edges[column + 1]
            top, bottom = y_edges[row], y_edges[row + 1]
            cell_width, cell_height = right - left, bottom - top
            if cell_width <= 0 or cell_height <= 0:
                continue
            draw.rectangle((left, top, right - 1, bottom - 1), fill=cell_background)
            draw.rectangle((left, top, right - 1, bottom - 1), outline=border, width=1)

            label = f"{category} {row + 1}"
            padding = min(12, min(cell_width, cell_height) // 32)
            label_y = top + padding
            fitted_label = ""
            label_height = 0
            if cell_width >= 20 and cell_height >= 20:
                fitted_label = truncate_text(
                    draw, label, font, max(0, cell_width - 2 * padding)
                )
                if fitted_label:
                    label_box = draw.textbbox((0, 0), fitted_label, font=font)
                    label_height = label_box[3] - label_box[1]
                    if label_height + 2 * padding >= cell_height:
                        fitted_label = ""
                        label_height = 0
            if fitted_label:
                draw.text(
                    (left + padding, label_y), fitted_label, fill=label_color, font=font
                )

            image_top = label_y + label_height + (padding if fitted_label else 0)
            image_width = cell_width - 2 * padding
            image_height = bottom - image_top - padding
            if image_width <= 0 or image_height <= 0:
                continue
            if row < len(selected):
                fitted = contain_image(selected[row].path, (image_width, image_height))
                image_x = left + (right - left - fitted.width) // 2
                image_y = image_top + (image_height - fitted.height) // 2
                canvas.paste(fitted, (image_x, image_y))
                draw.rectangle(
                    (image_x, image_y, image_x + fitted.width - 1, image_y + fitted.height - 1),
                    outline=(116, 118, 122),
                    width=1,
                )
            else:
                empty = "EMPTY - no unique readable image"
                empty = truncate_text(draw, empty, font, image_width)
                if not empty:
                    continue
                empty_box = draw.textbbox((0, 0), empty, font=font)
                empty_width = empty_box[2] - empty_box[0]
                empty_height = empty_box[3] - empty_box[1]
                draw.text(
                    (
                        left + max(padding, (right - left - empty_width) // 2),
                        image_top + max(0, (image_height - empty_height) // 2),
                    ),
                    empty,
                    fill=empty_color,
                    font=font,
                )

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, format="JPEG", quality=94, subsampling=0, optimize=True)


def validate_source(source: Path) -> None:
    """Raise an actionable error for an invalid source tree."""
    if not source.exists():
        raise ValueError(f"source directory does not exist: {source}")
    if not source.is_dir():
        raise ValueError(f"source path is not a directory: {source}")
    missing = [category for category in CATEGORIES if not (source / category).is_dir()]
    if missing:
        raise ValueError(
            "source is missing required category directories: " + ", ".join(missing)
        )


def validate_output_path(source: Path, output: Path) -> None:
    """Reject output aliases that could create or overwrite files in source."""
    resolved_source = source.resolve()
    resolved_output = output.resolve(strict=False)
    if resolved_output == resolved_source or resolved_source in resolved_output.parents:
        raise ValueError(
            f"output must be outside the read-only source directory: {resolved_output}"
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Build a deterministic 5-column x 4-row classical style atlas."
    )
    parser.add_argument("--source", required=True, type=Path, help="read-only image collection root")
    parser.add_argument("--output", required=True, type=Path, help="output JPEG path")
    parser.add_argument(
        "--size",
        default=parse_size("1800x1200"),
        type=parse_size,
        metavar="WIDTHxHEIGHT",
        help="atlas dimensions (default: 1800x1200)",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        validate_source(args.source)
        validate_output_path(args.source, args.output)
        results = collect_images(args.source)
        total_readable = sum(result.readable for result in results.values())
        if total_readable == 0:
            raise ValueError(
                f"source contains no readable supported images in the required categories: {args.source}"
            )
        render_atlas(results, args.output, args.size)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"ERROR: could not build atlas: {exc}", file=sys.stderr)
        return 2

    for category in CATEGORIES:
        result = results[category]
        print(
            f"{category}: selected={len(result.selected)} readable={result.readable} "
            f"skipped={result.skipped} duplicates={result.duplicates}"
        )
    print(f"Output: {args.output.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
