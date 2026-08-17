# Visual Quality Gates

Read this file completely whenever it is selected. Apply the same six gates at preflight and after every generated artifact, but use different status vocabularies for those two stages.

## Evidence rule

Planning and prompt evidence show only that a requirement was stated or that needed inputs exist; they do not prove the pixels satisfy it. Artifact evidence comes from inspecting the generated image at a useful size, including relevant crops or enlarged details. Never report a visual **PASS** from the prompt alone or without inspecting the image. Compare portrait identity directly with the source portrait when an identity reference exists. Check a repeat pattern in a tiled preview and inspect every seam and corner.

## Two-scale review

Perform thumbnail inspection and full-size inspection before assigning artifact outcomes.

- **thumbnail inspection:** Judge hierarchy, dominant axis, subject scale, and whether the result remains source-specific rather than template-like.
- **full-size inspection:** Judge identity and object continuity; verticals and vanishing structure; façade topology; repeated-element counts and spacing; ornament attachment, joints, and supports; material and light behavior; and invented structures or anatomy.

### Historical-collage aesthetic gates

For a historical collage, apply these stricter aesthetic checks in addition to the six technical gates:

- At thumbnail scale require one focal hierarchy, one governing movement, source recognition within three seconds, participatory but subordinate type, and an effect subordinate to source identity and meaning.
- At full size require deliberate crop edges, overlaps, material seams, and type occlusion; no cutout halo; correct contacts and projection; exact visible copy; and credible cultural construction.
- Fail a historical collage for a complete background behind a cutout, detached captions, repeated corner emblems, symmetric badge grids, border or frame stacks, wallpaper motifs, more than one surreal gesture, normalized source projection, a uniform medium filter, localized dissolution, or arbitrary decoration.
- Typography interaction passes only when alignment, passage, or occlusion is deliberate and legible; accidental collision, clipped letterforms, or readability damage fails.
- Run the structural-removal test independently on each applicable device: gesture, accent, type interaction, and monumental fragment or source-shape linkage; if removing one leaves hierarchy or meaning unchanged, that device is decorative and fails, while a conventional or no-text N/A must record the specific reason.
- Assign the aesthetic verdict ACCEPT, REPAIR, or BLOCKED; REPAIR permits only the single highest-impact repair rebuilt from the original source and a fully recompiled four-section prompt.
- Reject jewelry-ad, black-gold luxury, plastic-gloss, or material accents attached to the protected subject.
- Inspect the protected-subject boundary at thumbnail and 100% scale; fail any coating, dissolution, abrasion, particle, glaze, enamel, or gemstone effect that crosses onto a protected subject or held object.
- If one targeted repair is allowed, rebuild it from the original source with a fully recompiled four-section prompt and correct only the highest-impact protected-effect failure.

At thumbnail scale, verify that the complete subject reads first and that material accents remain subordinate structural punctuation. At 100% scale, trace the full helmet or headwear, face when visible, clothing, anatomy, hands, shoes, held-object, functional-joint, contact, and source-silhouette boundary. Optional effects must stop cleanly behind those boundaries without a cutout halo; the one unified substrate, edge, pigment, and shadow language must remain visible on both subject and architecture.

If a required gate fails, allow one targeted revision round only. Repair the single highest-impact gate; do not bundle secondary corrections into that round. Repeat both inspections afterward.

## Preflight: readiness and artifact outcome

Before generation, report two independent fields for every one of the six rows:

- **Readiness: READY | BLOCKED.** READY means the required prompt constraints, readable inputs, references, and user decisions exist. BLOCKED means a required input, constraint, reference, or decision is missing, unreadable, or contradictory; **BLOCKED stops generation** and requires a question to the user.
- **Artifact outcome: PENDING | N/A — reason.** PENDING means the gate applies and the generated pixels must later receive PASS or FAIL after inspection. N/A is permitted only when the gate is genuinely non-applicable under the mode/source rules, and must include the reason.

READY normally pairs with PENDING. It pairs with N/A only when the gate is genuinely inapplicable. BLOCKED may still pair with PENDING because the artifact would need visual judgment after the blocker is resolved; do not generate until readiness becomes READY. Do not use PASS or FAIL before generation.

| Gate | Readiness: READY when | Readiness: BLOCKED when | Artifact outcome before generation |
|---|---|---|---|
| Identity | A required identity reference is readable and invariants are explicit, or the task explicitly requires no identity reference. | A required identity reference is absent/unreadable or identity invariants conflict. | PENDING when an identity reference must be preserved; otherwise N/A — no identity reference to compare. |
| Spatial integration | Required subjects/scenes and contact, scale, occlusion, and light constraints are defined; flat work is identified. | A required compositing input or spatial role is missing/ambiguous. | PENDING for portraits, compositing, dimensional scenes, or generated architecture; otherwise N/A — flat pattern/manuscript has no compositing or dimensional scene. |
| Perspective | Source projection is readable, or the intended camera, orthographic field, or drawing projection is stated. | A required source viewpoint is unreadable or requested projections conflict. | PENDING because the intended projection must be verified in pixels. |
| Geometry | The Source Fidelity Card/Architectural Source Card captures identity-bearing source geometry when a source exists, and the axis, module, symmetry/boundary rules, or drawing relationships needed by the mode are explicit. | Identity-bearing source geometry or a task-defining repeat cell, construction relationship, or structural decision is missing. | PENDING when architecture, pattern, measured drawing, symmetry, module, or classical geometry is asserted; otherwise N/A — no geometric or structural system is asserted. |
| Cultural lineage | Each named lineage is evidenced, or the task explicitly uses shared geometry with no lineage claim. | A requested lineage or fusion role lacks adequate evidence or user direction. | PENDING when a lineage or fusion is claimed; otherwise N/A — shared geometry with no cultural-lineage claim. |
| Rendering coherence | Intended photographic or painting medium is specified, including substrate/line/pigment/edge/shadow behavior for painting, or the flat production mode is explicit. | Required rendering medium is absent, contradictory, or permits a photographic cutout inside a painted scene. | PENDING for photographic, painterly, dimensional-material, collage, or aged-sheet rendering; otherwise N/A — flat production artwork has no material or media rendering claim. |

After generation, keep the same six-row report but reserve **PASS / FAIL / N/A** for the inspected artifact. Use **N/A — reason** only where the gate is genuinely non-applicable under the mode rules below; never omit a row.

## The six gates

### 1. Identity

- **Applicability:** Compare to the source only when an identity reference exists. For generated people without an identity reference, judge anatomy, person consistency, grounding, and scale under Spatial integration; mark Identity **N/A — generated person has no identity reference**. For a no-person task, mark **N/A — no person or identity reference is part of this task**.
- **Pass condition:** When an identity reference exists, direct comparison with it confirms the same recognizable face, age, skin tone, body type and proportions, pose, expression, hair, primary clothing, and natural skin texture except for changes the user explicitly requested.
- **Observable failure signatures:** Face shape, eyes, nose, age, skin tone, body, pose, clothing, or expression drifts; beauty retouching erases natural texture; a limb or head is stretched to fit the architecture.
- **One targeted repair instruction:** “Restore the source person's identity and stated body/pose/clothing invariants exactly; change no architecture, crop, light, or unrelated aesthetic.”

### 2. Spatial integration

- **Applicability:** For portraits, compositing, dimensional scenes, and generated architecture, assess grounding, scale, occlusion, depth, and shared light wherever visible. Mark **N/A — flat pattern/manuscript has no compositing or dimensional scene** for a flat pattern or manuscript unless it contains compositing or a dimensional scene.
- **Pass condition:** Applicable subjects, architecture, and ground/material planes share credible scale, contact, occlusion, depth of field, edge sharpness, light direction, color spill, contact/cast shadows, and material boundaries.
- **Observable failure signatures:** A person looks pasted in, floats above the floor, has a halo, casts no contact shadow, is mis-scaled to steps or bays, or is lit from a different direction.
- **One targeted repair instruction:** “Integrate the applicable subject or architecture into the unchanged scene by correcting only ground contact, occlusion, scale, matched edge/light behavior, and contact/cast shadows.”

### 3. Perspective

- **Applicability:** Match a source camera when one exists; otherwise assess the intended camera/projection. Flat patterns require exact orthographic projection. Manuscripts require consistent drawing projection among plan, elevation, section, and any explicitly perspective view.
- **Pass condition:** The applicable source or intended camera height, horizon, field of view, verticals, floor/roof lines, orthographic field, or drawing projections form one coherent system without unintended distortion.
- **Observable failure signatures:** Bent or leaning verticals, inconsistent vanishing directions, warped facade planes, ballooned near edges, stretched people, or a camera height/viewpoint that no longer matches the source.
- **One targeted repair instruction:** “Reconstruct only the projection to the source camera when one exists, otherwise to the stated intended camera, orthographic field, or drawing projection; reconcile every major edge without changing unrelated content.”

### 4. Geometry

- **Applicability:** Apply whenever the artifact asserts architecture, pattern, measured drawing, symmetry, module, or classical geometry. When a source exists, compare directly with its Source Fidelity Card and **Architectural Source Card**. Mark **N/A — no geometric or structural system is asserted** only for an artifact genuinely outside those modes, with the reason recorded.
- **Pass condition:** With a source, topology, roofline, openings, bay/column/window count and spacing, main axes, and semantic minimum match all Hard locks; then verify the dominant axis/center, primary module, repetitions, boundaries, symmetry, construction hierarchy, and structural spans resolve consistently. For repeat patterns, a 3 x 3 preview confirms exact continuity across every left/right, top/bottom, and corner seam.
- **Observable failure signatures:** An internally coherent building that drifts from identity-bearing source geometry fails the Geometry gate. Other failures include altered topology/roofline/openings/counts/spacing/axes/semantic minimum, broken symmetry or tiling, clipped mismatched edges, drifting line weights, random ornament, unresolved corners, unsupported arches/roofs, or plan/elevation/section disagreement.
- **One targeted repair instruction:** “Restore only source fidelity from the Source Fidelity Card/Architectural Source Card—topology, roofline, openings, bay/column/window count and spacing, main axes, and semantic minimum—without changing already-correct camera, palette, light, material, or subject; for a source-free pattern, correct only the governing grid, symmetry, repeat boundaries, and support alignment, then verify every tile seam.”

### 5. Cultural lineage

- **Applicability:** Apply when the prompt or artifact claims a cultural lineage or fusion. Mark **N/A — shared geometry with no cultural-lineage claim** only when no culture-specific claim or vocabulary is present.
- **Pass condition:** Every visible culture-specific element belongs to the evidenced regional/period subtradition, compatible vocabulary is selected rather than stacked, and any user-requested fusion is explicitly acknowledged, role-based, and geometrically unified. For fusion, inspect visible support, bearing, junctions, drainage, flashing, weather exposure, and material transitions. Concealed fire separation, movement assemblies, waterproofing layers, or other hidden systems may be assessed only from a supplied detail drawing or separate technical note; never claim them from a photorealistic bitmap.
- **Observable failure signatures:** Generic cultural symbol collage, unsolicited fusion, mixed unrelated periods or orders, arbitrary zellij/muqarnas/dougong/pediment use, or lineage inferred from a person's traits.
- **One targeted repair instruction:** “Remove the unsupported cultural elements only; retain the evidenced subtradition and shared geometry, or restore the explicit role-based fusion without adding new symbols.”

### 6. Photography and rendering coherence

- **Applicability:** Apply to photographs, photorealistic renders, architectural paintings, illustrations, collage, dimensional material depictions, and photographed/aged-sheet presentations. Mark **N/A — flat production artwork has no material or media rendering claim** only for a genuinely flat pattern or diagram with uniform production color and no substrate, texture, or lighting claim.
- **Pass condition:** A photograph has natural or purpose-appropriate illumination, controlled dynamic range, tactile material response, restrained saturation/sharpening, and no unintended presentation effects. A painting has one coherent substrate, line system, pigment system, edge language, shadow method, and detail hierarchy across architecture, people, props, ground, sky, and atmosphere at the chosen style strength.
- **Observable failure signatures:** Cinematic poster effects, exaggerated HDR, crushed or flat tones, plastic materials, a texture overlay with unchanged photographic detail, inconsistent paper grain, photographic specular highlights inside watercolor or ink forms, or a subject that reads as a pasted cutout.
- **Artifact rule:** If the subject and architecture use different edge, grain, pigment, or shadow languages, the Rendering coherence check fails even when compositing is spatially plausible.
- **Poster artifact rule:** A poster fails Rendering coherence when typography, palette, geometric cuts, subject treatment, and architectural medium do not read as one designed system.
- **Period poster artifact rule:** A period poster fails when typography or palette belongs to the wrong evidenced period, when pseudo-cultural glyphs replace legible copy, or when historical dissolution looks digitally overlaid instead of native to the selected medium.
- **Dissolution artifact rule:** Dissolution fails when it exceeds the subtle default without authorization, attacks more than one unrelated edge, contradicts motion/wind/geometry, or damages a protected anchor, contact, structural relationship, measured line, repeat boundary, or visible character.
- **Full-height dissolution rule:** When selected, dissolution fails if it is a localized single patch near a butt or shirt hem, a dense horizontal scratch band, a set of inconsistent directions, uniform erosion, a continuous destructive cut, damage to a protected anchor, or an effect without sparse top-to-bottom distribution along one consistent trailing side. Inspect this distribution at both thumbnail and full size; protected segments must be skipped while the same direction continues through adjacent background or atmosphere. Safe omission passes when no protected-anchor-respecting distributed field exists.
- **Medium-first dissolution rule:** Rendering coherence fails when a lineage effect or source medium overrides the selected final/output photography, painting/substrate, dimensional-render, or drawing/sheet medium, or when dust, fragments, grain, abrasion, pigment loss, or edge breakup is not physically native to that final medium. Verify that the final output medium controls the effect and the source medium does not leak into it.
- **Landscape dissolution rule:** Dissolution fails when it damages a defining horizon, terrain or waterline, circulation or threshold, identity-bearing primary vegetation silhouette, or architectural structure; only non-defining atmosphere, edge foliage, or ground fringe may be expendable.
- **Period evidence rule:** Confirm the rendered typography and palette match the declared specific or broad evidence confidence and fallback; false specificity or an unstated fallback fails.
- **Dissolution visibility rule:** At full size the requested effect must be visible and medium-native; at thumbnail size it must remain subordinate to source identity, geometry, and copy. Cross-source particles, palette, typography, period, or subject associations fail. Safe omission passes when no expendable edge exists.
- **Poster copy rule:** Compare every visible character with the exact quoted title and optional microline. Any missing, substituted, duplicated, or extra character fails.
- **One targeted repair instruction:** “Normalize only the rendering medium: preserve geometry, composition, identity, and content while applying the selected substrate, line, pigment, edge, shadow, texture, and detail hierarchy consistently across the complete frame.”

## Repair policy

1. Record artifact evidence for all six gates, then rank failures by user impact: identity and requested invariants first, integration/perspective next, task-defining geometry/lineage next, rendering coherence last unless the rendering medium is the task.
2. Repair only the single highest-impact failure. Recompile the repair as a revised four-section generation prompt, repeat all non-negotiable invariants, embed the one targeted instruction from that failed gate in its appropriate section, and change no unrelated section. Never send a targeted repair instruction as a standalone tool-facing prompt.
3. Do not improve unrelated aesthetics, add detail, change composition, or repair a second issue in the same round.
4. Allow one automatic repair round maximum. Inspect the repaired artifact at a useful size and re-evaluate all six gates, including identity source comparison and pattern seam checks when applicable.
5. If any required gate still fails, stop. Deliver the limitation and failed gates with evidence, then ask the user whether to accept, revise constraints, or authorize another generation.

## Common failure map

| Failure | Gate | Repair reference |
|---|---|---|
| Identity drift | Identity | Use Identity's canonical “One targeted repair instruction.” |
| Pasted or floating subject | Spatial integration | Use Spatial integration's canonical “One targeted repair instruction.” |
| Bent verticals or inconsistent vanishing points | Perspective | Use Perspective's canonical “One targeted repair instruction.” |
| Broken symmetry or tiling | Geometry | Use Geometry's canonical “One targeted repair instruction,” including seam verification. |
| Cultural symbol collage | Cultural lineage | Use Cultural lineage's canonical “One targeted repair instruction.” |
| Cinematic poster look, plastic materials, or photographic cutout in a painting | Rendering coherence | Use Photography and rendering coherence's canonical “One targeted repair instruction.” |
| Caption pasted over an image, mismatched poster palette/type, or incorrect visible copy | Rendering coherence | Recompile the full four-section poster prompt and repair only the integrated poster system or exact copy. |
| Wrong-period typography/palette, pseudo-cultural glyphs, false period confidence, or prior-source leakage | Rendering coherence | Restore the evidenced period route or declared fallback and remove every unrelated-source carryover. |
| Dissolution is over 10% without authorization, becomes a localized butt/hem patch or dense horizontal scratch band, uses inconsistent directions or uniform erosion, lacks top-to-bottom distribution, obscures anchors, looks digitally overlaid, or dominates the thumbnail | Rendering coherence | Restore one sparse full-height trailing-side field at approximately 6–10% overall in the selected medium, bridge protected gaps through adjacent atmosphere, or omit dissolution when no safe distributed field exists. |

## Delivery contract

Deliver:

1. The final image.
2. The exact final four-section generation prompt used, including the revised four-section prompt if a targeted repair round occurred.
3. A compact six-row **PASS / FAIL / N/A** artifact report with observable evidence; use N/A only under the mode/source applicability rules and always state why. If preflight is delivered too, show its separate `Readiness: READY | BLOCKED` and `Artifact outcome: PENDING | N/A — reason` fields clearly.
4. The local saved path when a local output path applies.

If built-in ImageGen is unavailable, stop and ask the user for direction; do not silently switch to another provider. Do not silently use a third-party generator or the CLI/API path. Mention a fallback only in accordance with the imagegen skill, and proceed only after the user explicitly chooses it.
