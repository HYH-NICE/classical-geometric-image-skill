---
name: generate-classical-geometric-images
description: Use when transforming architectural design drafts, sketches, plans, elevations, sections, axonometrics, renderings, photos, portraits, interiors, exteriors, geometric patterns, or classical manuscripts into a unified architectural poster, culturally coherent classical geometry, architectural painting, illustration, or high-end architectural photography.
---

# Generate Classical Geometric Images

Load references/normative-contracts.json before routing period typography, period palette, historical dissolution, or cross-source leakage safeguards, and obey every contract assigned to the selected files.

Treat this manifest as a mandatory integrity bootstrap for every execution, not as an optional progressive reference. Load it before classifying or routing the request; load the larger period and dissolution references progressively only when their conditions apply.

Create or edit images through a controlled classical-geometric workflow. Preserve evidence from supplied images before applying cultural lineage, geometry, or photographic style.

For ordinary image requests, directly analyze the supplied source, compile the prompt, call built-in ImageGen, perform concise visual QA, and return the image; do not create specifications or implementation plans, run TDD or Git workflows, or dispatch subagents unless the user explicitly asks to modify, test, package, or publish the Skill itself.

## Workflow

Follow this order without skipping steps:

1. Inspect every supplied image. Do not infer content, role, or intent from an unreadable input. Stop and ask for a readable replacement if any unreadable image is required for the target, identity, style, or composition. Optional unreadable references may be ignored only after clearly disclosing the limitation. Determine necessity from the user request at this stage; assign formal roles in step 3.
2. Route the request as **generate** or **edit**, then select exactly one primary mode:
   - portrait restyling or person-into-space
   - ordinary-photo atmosphere/style matching
   - architectural, interior, or exterior generation/editing
   - architectural painting or illustration from a design draft
   - architectural poster design from an original source
   - geometric pattern design
   - classical manuscript or diagram
3. Assign every input one or more roles: **edit target**, **identity/subject reference**, **style reference**, **composition reference**, or **auxiliary reference**. A single source portrait in an edit is commonly both edit target and identity/subject reference. Never infer that every image is an edit target.
4. Classify every readable input as person or group; object, product, vehicle, or prop; architecture, interior, exterior, or landscape; drawing, pattern, or manuscript; or mixed source before selecting anchors, copy, period, or effects. Build a Source Feature Map for every class, recording visible identity anchors, protected contacts or joints, geometry, exact characters, Expendable detail, and source-specific forbidden carryover. Build a Source Fidelity Card before styling any photo, architecture, or person edit. Use only visible, task-relevant, non-inferential identity anchors explicitly needed for preservation; never infer sensitive traits. Classify Source Fidelity Card findings as Hard locks, Soft preferences, or Expendable detail. Never remove user-requested items or safety/functional features. Use the full definition and architecture-specific **Architectural Source Card** block in `references/style-dna.md`.
   - For a photo, architecture, or person scene, select one primary composition strategy from the Source Fidelity Card. Compatible subordinate descriptors may clarify view direction, spatial archetype, or crop scale but must not compete with its hierarchy; preserve source perspective when hard-locked.
   - For patterns use `N/A — flat orthographic tile`; for manuscripts use `N/A — drawing-sheet projection`.
   - In poster mode, also build the **Poster Feature Card** in `references/poster-design.md`, separating observed evidence from explicit user associations and selecting no more than three subject anchors.
   - Rebuild every Source Feature Map and Poster Feature Card from the current source; never reuse anchors, associations, copy, period, palette, typography, or effects from a prior source.
5. After the mandatory manifest bootstrap, load only the larger references needed for the routed task, following [Progressive reference loading](#progressive-reference-loading).
6. Choose one cultural lineage—Islamic, Chinese, or Western—only from the user request, explicit style references, or architectural or ornamental evidence, unless the user explicitly requests fusion. Never infer cultural lineage from a person's perceived ethnicity, nationality, religion, facial features, name, clothing alone, or skin tone. When evidence supports a broad Islamic, Chinese, or Western lineage, use that corresponding broad-lineage system; only insufficient lineage evidence falls back to shared classical geometry and shared style DNA. For any period-, regional-, typography-, or palette-sensitive output, build the Period Evidence Card in `references/period-style-systems.md` and record its specific, broad, or insufficient confidence and fallback; this routing applies beyond poster mode.
7. For a routed poster, collage, editorial, zine-like, or stylized architectural-image transformation, load `references/historical-surreal-collage.md` after period and lineage selection and before prompt compilation. Use its historical-surreal grammar and Visual Thesis Card by default for normal historical-poster intent. If the user explicitly requests no surrealism or a restrained conventional poster or editorial, apply its conventional override: disable the impossible spatial gesture and monumental-fragment formula while preserving source-shape linkage, anti-cutout composition, integrated typography, period evidence, and source fidelity. Use source-derived mechanisms without named-artist imitation or copying. Generate one unified artifact directly from the original source; do not add a separate background-generation or cutout-compositing stage.

Load references/historical-surreal-collage.md before routing an Islamic, Chinese classical, or Western classical historical-surreal collage.

8. If the source is an architectural design draft or the user requests painting/illustration, classify its artifact type, route a matching architectural painting technique, and choose style strength from `references/painting-techniques.md`. Apply one unified medium to the complete frame; never preserve a photorealistic subject as a pasted layer inside a painted scene.
   - When an original source is supplied for a designed transformation, default to poster mode unless the user explicitly requests plain photography, painting without typography, a production pattern, or a manuscript. Treat poster mode as one end-to-end route from the original source to one final artifact, not as a second deliverable appended after a painting draft.
   - In poster mode, extract subject anchors, choose one painting/rendering route, one primary crop/mask geometry, exact short English copy, typography, and palette before generation. Compile them into the same tool-facing prompt.
9. Match the space and lens or drawing projection to the source: preserve believable camera height, field of view, subject scale, vanishing structure, orthographic/axonometric relationships, occlusion, and depth as applicable. Add historical dissolution only when requested or appropriate for time erosion, sand, dust, fading, or disappearance. Declare one safe expendable edge and every protected zone through `references/historical-dissolution.md`; omit the effect when no safe edge exists, and do not require it in plain photography, painting, pattern, or manuscript modes.
   - When a person, object, vehicle, prop, or held object is present, use this visual layer order inside the one unified artwork: substrate; optional background effects and material accents; incomplete architecture and integrated type; complete protected subject and held objects; grounding/contact shadow. Optional effects may appear through genuine negative openings but never cross protected subject pixels.
10. Compile the internal 13-field worksheet into the four-section generation prompt before calling ImageGen. The worksheet and input-role bookkeeping remain internal; only the compact four-section prompt is tool-facing. Use `references/prompt-recipes.md` for the mapping.
11. Preflight identity, perspective/projection, light or painted shadow, material/medium, geometry, lineage, anchor retention, crop safety, exact copy, typography, and palette. Resolve contradictions before generation.
12. **REQUIRED SUB-SKILL:** Use imagegen and follow its instructions before invoking the built-in imagegen tool for generation or editing. If built-in ImageGen is unavailable, stop and ask the user for direction; do not silently switch to another provider.
13. Review the result against all six gates in `references/quality-gates.md`. Perform thumbnail inspection and full-size inspection before assigning artifact outcomes.
14. Recompile a revised four-section generation prompt for the one targeted repair round. Repair the single highest-impact failure, restate all invariants, and change no other section beyond what that repair requires. Review again. If the result still fails, report the failed gates and ask the user for direction; do not loop or incur further generation cost automatically.
15. Deliver one final image, the exact visible copy, final prompt, concise QA result, and saved path when a local output path applies. Internal drafts are not separate deliverables.

## Hard defaults

- Treat identity and source invariants as constraints, not stylistic suggestions.
- Never carry a subject noun, association, palette, period, typography route, or effect from one source into an unrelated source.
- Do not mix dougong, Corinthian columns, and muqarnas unless the user explicitly requests fusion.
- Create grandeur through scale, axial depth, hierarchy, and material. Do not manufacture it with fog, teal-orange grading, god rays, or HDR excess.
- Hide construction lines in portraits, ordinary photos, and architectural photography. Geometric patterns and classical manuscripts/diagrams may show construction lines when they clarify the geometry or match the requested artifact.
- Prefer natural light behavior, tactile materials, controlled dynamic range, and high-end architectural photography over spectacle effects.
- For architectural painting, use one unified medium across architecture, people, props, ground, sky, light, and shadow. A filtered background plus a photorealistic cutout is a failure.
- Treat architectural painting as a geometry-preserving redesign of marks and pigment, not as a texture overlay.
- Poster mode is integrated composition, not text added after image generation. Geometric cuts may remove Expendable detail, but must preserve selected anchors and must not stretch anatomy, architecture, or lettering.
- Subject protection is an occlusion rule inside one unified drawing or painting medium, never permission for a photographic cutout. Keep coating, dissolution, abrasion, particles, enamel, glaze, and gemstone-like accents behind the complete protected subject and held objects.

## Progressive reference loading

The normative manifest has already been loaded for every execution. Load only the other needed reference files, and read every selected reference file completely.

- Keep `references/normative-contracts.json` loaded as the mandatory integrity bootstrap; never defer it until a safeguarded feature is selected.
- Load `references/style-dna.md` for the full Source Fidelity Card, composition routing, or when the request requires lineage, space, material, or geometric selection beyond this main contract; use only the relevant sections.
- Load `references/prompt-recipes.md` only to construct or adapt a prompt, including a targeted repair prompt.
- Load `references/painting-techniques.md` whenever the source is an architectural design draft, the user requests painting/illustration/collage/ink/watercolor/gouache/etching, or a prior result looks like background replacement; use it to select one medium and style strength.
- Load `references/poster-design.md` whenever the user requests a poster, visible copy, typography, graphic layout, subject-feature extraction, geometric cuts, or a final designed transformation from an original source.
- Load `references/period-style-systems.md` for any period-, regional-, typography-, or palette-sensitive output, independently of poster mode.
- Load `references/historical-surreal-collage.md` only for routed poster, collage, editorial, zine-like, stylized architectural-image, or historical-surreal transformations. After period/lineage selection and before loading prompt recipes, select its default historical-surreal path or its explicit conventional override.
- Load `references/historical-dissolution.md` when the user requests time erosion, sand, dust, fading, disappearance, or an appropriate historical dissolution effect; omission is valid when no safe expendable edge exists.
- Load `references/quality-gates.md` only immediately before generation for preflight and immediately after generation for QA; apply all six gates.
- Consult `assets/style-atlas.jpg` only when visual examples materially help; the atlas is optional and never required to proceed.
- Treat any user-supplied local reference directory as optional and read-only; never require a fixed drive, username, or machine-specific path, and never mutate, reorganize, rename, or delete its contents.
