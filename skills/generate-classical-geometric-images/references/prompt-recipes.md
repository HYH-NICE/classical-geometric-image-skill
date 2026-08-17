# Structured Prompt Recipes

Read this file completely whenever it is selected. Adapt a recipe only after every input image has been inspected and assigned one or more explicit roles.

## Ordered internal worksheet contract

The 13 ordered fields are an internal analysis worksheet, not a tool-facing prompt. Each recipe below is a 13-field internal recipe whose evidence and decisions must be resolved before compilation.

Write internal worksheets in this exact order:

1. **Task and mode:** State generate or edit, then the single primary mode and intended asset.
2. **Input image roles:** Label every image by index as edit target, identity/subject reference, style reference, composition reference, or auxiliary reference. One image may hold multiple roles. Do not describe unreadable content; ask for a readable replacement when it is required.
3. **Non-negotiable invariants:** State what must remain unchanged before any styling instruction.
4. **Cultural lineage:** Name the evidenced regional/period subtradition, or use shared classical geometry when evidence is insufficient. Never infer lineage from a person's perceived ethnicity, nationality, religion, facial features, name, clothing alone, skin tone, or other traits.
5. **Matched space and scale:** Match the source framing, subject scale, thresholds, human scale, and depth.
6. **Geometry and composition:** Define the dominant axis or center, primary module, repetition, hierarchy, boundaries, and depth sequence.
7. **Camera and perspective:** Give source viewpoint and field of view priority over defaults. Preserve source camera height and lens character; any lens is a full-frame-equivalent fallback only.
8. **Light and color:** Specify believable direction, exposure, white balance, dynamic range, and restrained palette.
9. **Materials and craft:** Name a limited, lineage-appropriate palette plus joints, wear, grain, seams, and light response.
10. **Integration requirements:** State contact, occlusion, scale, perspective, light, shadow, and material transitions that must agree.
11. **Visible construction logic:** Say whether guides are hidden or visible and require believable support, spans, joints, or geometric derivation.
12. **Avoid list:** Use mode-specific exclusions, including prohibited drift from the invariants.
13. **Output format/aspect ratio:** State bitmap intent, orientation or ratio, and text policy.

Keep every field, but a field may be concise or read `N/A — specific reason` when it genuinely does not apply. The non-negotiable invariants are the first constraint block and the highest-priority instructions in the prompt; keep them explicit and easy to scan rather than burying them in scene prose.

Unless poster mode or lettering is requested, specify **no text, labels, logos, or watermark**. Poster mode may change the aspect ratio and crop Expendable detail under `references/poster-design.md`; otherwise preserve a portrait or source image's aspect ratio unless the user asks to change it. Pattern masters default to a square repeat tile; manuscripts default to a suitable portrait or landscape sheet. When adapting ratios, recompose by crop, camera distance, masks, and added spatial breathing room—never by stretching a person, building, geometric cell, or letterform.

## Prompt compiler

The sole tool-facing prompt is the four-section generation prompt. It is also the final generation prompt recorded for delivery. Resolve all 13 ordered fields first, then compile only pixel-effective instructions—never hidden analysis, theory, file paths, input-role labels, or reference bookkeeping.

1. **Subject and architectural fidelity:** State identity/architecture plus **Hard locks**, including the semantic minimum.
2. **Composition and camera:** For a scene, name one primary composition strategy and state source spatial invariants, viewpoint, horizon, vanishing structure, topology, rhythm, counts, and scale; compatible subordinate descriptors may not compete. For patterns and manuscripts, N/A modifies only the scene-composition-strategy value; section 2 still includes geometry, scale, projection, and construction logic.
3. **Rendering and material finish:** Apply **Soft preferences** after every hard lock using the finish appropriate to the mode.
4. **Guardrails and omissions:** State prohibited drift and explicit **Expendable detail** omissions; omit nothing by implication.

Rendering and material finish is mode-aware: photographic modes specify high-end architectural or photographic light, material response, and color; pattern, diagram, and manuscript modes specify their applicable flat, orthographic, or drafting finish, including uniform production color for a tile and paper, ink, and line hierarchy for a manuscript, and may mark photographic lighting N/A.

For painting modes, section 3 must name substrate, line system, pigment system, edge behavior, shadow method, and style strength.

For an architectural painting, compile the selected route from `references/painting-techniques.md` into section 3 and repeat the unified-medium constraint in section 4. Translate every visible person, prop, reflective object, plant, sky, ground, and building surface into that medium; never preserve a photorealistic cutout inside a painted environment.

For poster mode, section 2 must declare the crop/mask geometry and retained anchors, section 3 must declare typography and palette, and section 4 must quote every visible string verbatim.

Use the following period-poster compiler sentence ONLY when historical dissolution is selected and a safe edge exists:

For period poster mode, section 1 states source class, anchors, protected relationships, lineage, period, evidence confidence, and forbidden carryover; section 2 states type zone, crop geometry, motion/wind axis, one full-height trailing-side dissolution field, its consistent direction, safe upper-to-lower segments, protected gaps, atmospheric bridges, and every protected zone; section 3 states period typography construction, material-derived palette, connector accent, unified medium, and intermittent low-density medium-native behavior at approximately 6–10% total perceived loss; section 4 quotes exact copy and prohibits extra glyphs, unsafe erosion, localized butt or shirt-hem patches, dense horizontal scratch bands, inconsistent directions, uniform erosion, generic particle effects, false period claims, and prior-source leakage.

In that canonical sentence, `medium-native particle behavior` is a legacy umbrella for the selected final medium's dissolution/material-loss behavior. It may be non-particle abrasion, fading, fiber, line loss, or opacity breakup; never force literal particles when they are not native to the final medium.

Rebuild the Source Feature Map and any Poster Feature Card from the current input before compiling the same single tool-facing prompt. Apply period typography and palette routing to every period-sensitive output, not only posters. When historical dissolution is selected and a safe distributed field exists, section 2 declares one full-height trailing side/system, one consistent direction, safe upper-to-lower segments, protected gaps, and the adjacent-background or atmospheric bridges that continue the direction across those gaps; section 3 declares intermittent low-density, final-medium-native loss at approximately 6–10% overall, with no chunks or continuous destructive cut. When the effect is not requested or selected, section 2 says `no dissolution — not selected`. When the effect is selected but unsafe, section 2 says `no dissolution — no safe expendable edge`. For either no-effect status, section 3 omits dissolution/material-loss behavior, section 4 prohibits unsolicited erosion, and the prompt records the correct reason. Never include both the effect compiler and a no-effect compiler.

Compile poster mode from the original source in one tool-facing prompt:

- Section 1 states the primary anchor, up to two secondary anchors, and protected pose/contact/occlusion relationships.
- Section 2 states the one primary crop or mask system, at most one subordinate geometry, type zones, crop permissions, architecture, projection, and retained anchors.
- Section 3 states the unified painting or rendering medium plus type category, case, weight, tracking, palette, and style strength. Lettering must share the artwork's pigment, edge, print, and aging behavior.
- Section 4 quotes the exact title and optional microline, prohibits every other glyph, and states safe-crop, no-stretch, and omission rules.

Do not first generate a plain painting and then overlay typography. Poster layout, subject treatment, architecture, lettering, geometric cuts, and color are one generation decision.

Keep hard locks ahead of soft preferences. Do not combine composition systems or retain instructions that have no visible effect.

| Four-section destination | Internal fields compiled into it |
|---|---|
| 1. Subject and architectural fidelity | 1 Task and mode; 2 Input image roles after stripping labels/bookkeeping and retaining only resolved fidelity evidence; 3 Non-negotiable invariants; 4 Cultural lineage. |
| 2. Composition and camera | 5 Matched space and scale; 6 Geometry and composition; 7 Camera and perspective; 10 Integration requirements; 11 Visible construction logic. |
| 3. Rendering and material finish | 8 Light and color; 9 Materials and craft. |
| 4. Guardrails and omissions | 12 Avoid list; 13 Output format/aspect ratio. |

This mapping is deterministic: each internal field has one destination, and field 2 contributes only visible fidelity constraints rather than image indices or role bookkeeping.

## A. Close portrait in an Islamic arcade

```text
Task and mode: Edit; portrait restyling/person-into-space; produce a natural close architectural portrait.
Input image roles: Image 1 is both the edit target and the identity/subject reference. Inspect it directly; do not invent obscured facial, clothing, or background details.
Non-negotiable invariants: Preserve the same identity, facial proportions, age, skin tone, hair, natural skin texture, body type, pose, expression, crop logic, and primary clothing; change only the surrounding space and its physically necessary light interaction.
Cultural lineage: Use the Islamic regional/period subtradition evidenced by the user's request or an explicit architectural/style reference; if none is evidenced, use restrained shared classical geometry and omit invented culture-specific ornament. Do not select lineage from the person's traits.
Matched space and scale: Place the close portrait in a shallow niche, window bay, or short arcade whose opening, sill, and springing height remain human-scaled; keep the face dominant and the background shallow.
Geometry and composition: Use one framed local symmetry or a clearly related offset axis; align the niche or nearest arch around the portrait; keep ornament density low and subordinate; allow only one or two readable depth layers.
Camera and perspective: Preserve Image 1's viewpoint, camera height, facial projection, and field of view first. Use 35–50 mm full-frame equivalent only as a fallback, with enough camera distance to avoid facial distortion; adjust crop or space rather than the face.
Light and color: Match the source key direction, softness, exposure, and color temperature; use neutral white balance, open natural shadows, restrained warm mineral tones, and no theatrical color grade.
Materials and craft: Use a limited evidenced palette such as matte lime plaster, local stone, carved wood, or selectively glazed tile; show fine seams, softened hand-contact edges, mineral variation, and non-plastic reflectance.
Integration requirements: Make shoulders and clothing occlude the arcade correctly; match edge light, ambient bounce, contact shadow, depth of field, atmospheric sharpness, and color spill; no halo or cutout edge.
Visible construction logic: Hide grids and compass lines. Arches must spring from credible supports and finish against a real substrate; ornament follows the opening geometry instead of floating behind the head.
Avoid list: Identity drift, beautification, changed age or body, stretched face, relit face that conflicts with the source, floating/pasted subject, deep monumental hall, dense generic arabesque, unsupported muqarnas, random zellij, fog, god rays, teal-orange grading, HDR, plastic skin or stone.
Output format/aspect ratio: Photorealistic bitmap; preserve Image 1's aspect ratio and close crop unless the user asks otherwise; no text, logo, labels, or watermark.
```

## B. Full-body portrait in an evidenced Chinese courtyard

```text
Task and mode: Edit; portrait restyling/person-into-space; produce a full-body environmental portrait in a Chinese courtyard.
Input image roles: Image 1 is the edit target and identity/body/pose/clothing reference. Any separate architectural image is a style and composition reference only unless explicitly labeled otherwise; one image may hold several roles.
Non-negotiable invariants: Preserve identity, face, age, skin tone, body proportions, full pose, limb placement, expression, hair, primary clothing, footwear, and clothing silhouette; do not alter them to fit the architecture.
Cultural lineage: Select the Chinese regional and period subtradition only from the user request or evidenced architecture/ornament. If the subtradition is unclear, retain shared axial timber-court geometry and avoid invented rank-specific decoration; never infer lineage from the person.
Matched space and scale: Use an axial court, colonnade, or measured steps suited to the source full-body framing; keep step risers, door bays, railings, plinths, and eaves credible relative to the person.
Geometry and composition: Establish one court axis and a readable ground paving module; relate columns, screens, steps, roof bays, and openings to a consistent bay rhythm; use nested gate-court-hall depth without competing centers.
Camera and perspective: Preserve the source viewpoint, camera height, pose projection, and field of view first; use 28–35 mm full-frame equivalent only as a fallback. Keep one dominant vanishing structure, control edge distortion, and keep verticals straight unless the source intentionally converges.
Light and color: Match source light direction and softness; use neutral white balance, restrained timber and tile colors, recoverable highlights beneath eaves, and natural courtyard bounce without cinematic grading.
Materials and craft: Use evidenced timber framing, roof tile, stone plinth, plaster, bronze, and paper selectively; show directional grain, mortise-and-tenon logic, tile overlap, paving joints, matte plaster variation, and restrained weathering.
Integration requirements: Plant both feet on the ground plane with contact and cast shadows; match subject scale to the bay and step module; make occlusions, ambient color, edge sharpness, and depth of field continuous across person and court.
Visible construction logic: Hide guide lines. Timber posts meet beams, roof loads bear through a coherent frame, and dougong appears only at a credible scale, hierarchy, and evidenced building type rather than as applied decoration.
Avoid list: Changed identity/body/pose/clothing, floating feet, pasted edges, oversized weightless roof, random bracket sets, decorative-only joints, incoherent bay spacing, mixed periods, saturated imperial-red fantasy, movie fog, god rays, HDR, plastic timber or tile.
Output format/aspect ratio: Photorealistic bitmap; preserve the source portrait aspect ratio and full-body clearance unless the user requests a new ratio; no text, logo, labels, or watermark.
```

## C. Existing building in an evidenced Western classical subtradition

```text
Task and mode: Edit; architectural/interior/exterior reconstruction; refine the existing building without changing its type.
Input image roles: Image 1 is the edit target and primary composition/camera reference. Additional images may be style or auxiliary references and must be labeled by index; do not treat them as replacement massing unless the user says so.
Non-negotiable invariants: Preserve building function, source viewpoint, field of view, camera height, principal massing, footprint cues, major openings, approach, and surrounding site relationships; retain recognizable identity of the building.
Cultural lineage: Select the Western regional/period subtradition supported by the request or visible architectural evidence. If evidence is insufficient, use rational bays, proportions, and shared classical geometry without inventing a named order, pediment, dome, or Gothic feature.
Matched space and scale: Retain the existing building type and human scale; strengthen the existing approach, threshold, stair, bay, and interior/exterior depth rather than replacing the structure with a palace or monument.
Geometry and composition: Establish coherent orders and bay spacing where evidenced; align facade divisions, openings, stairs, cornice, and interior volumes. Add a pediment or dome only when structurally, typologically, and historically plausible; never use both as prestige props.
Camera and perspective: Source viewpoint, lens character, camera height, horizon, and framing take priority. Use 24–35 mm full-frame equivalent only as an optional reconstruction fallback; maintain straight verticals, coherent vanishing points, and restrained tilt-shift correction without warping the facade.
Light and color: Use neutral white balance, broad controlled dynamic range, retained highlight detail, open but dimensional shadows, and restrained natural saturation; match the source time and direction unless the user requests a change.
Materials and craft: Use evidenced cut stone, plaster, marble, timber, bronze, and glass selectively; preserve masonry courses, voussoirs, joints, fasteners, edge wear, mineral weight, and differentiated reflectance.
Integration requirements: New or clarified elements must join existing walls, roofs, foundations, paving, drainage, and light consistently; match scale, occlusion, shadow, weather exposure, detail frequency, and image grain to the source.
Visible construction logic: Hide design grids. Columns bear entablatures, arches spring from piers, pediments terminate a real composition, domes have credible drums or supports, and openings align through the wall thickness.
Avoid list: Changed function/viewpoint/massing/camera height, invented palace scale, inconsistent orders or bays, columns bearing nothing, implausible pediment or dome, bent verticals, conflicting vanish points, extreme wide-angle bulging, warm/orange cast, fog, god rays, teal-orange grade, HDR, plastic stone.
Output format/aspect ratio: Photorealistic architectural bitmap; preserve the source aspect ratio unless the user requests another; no text, logo, labels, or watermark.
```

## D. Repeatable Islamic eight-point-star geometric master

```text
Task and mode: Generate; geometric pattern design; create a flat production master for a seamless eight-point-star repeat.
Input image roles: Any supplied pattern image is labeled explicitly as style, palette, composition, or auxiliary geometry reference; no image is an edit target unless the user requests editing. Do not infer unreadable motifs or lineage details.
Non-negotiable invariants: Preserve the requested eight-point-star family, exact repeat cell, symmetry class, line-weight hierarchy, palette, edge continuity, and orthographic flatness across all iterations.
Cultural lineage: Use only the Islamic regional/period subtradition evidenced by the request or references; otherwise describe the work as an eight-point geometric construction and avoid region-specific finish claims.
Matched space and scale: Treat one square repeat cell as the complete production unit; set motif and interstitial scale so all segments resolve at corners and opposite edges without a privileged pictorial center.
Geometry and composition: Primary scene composition strategy: N/A — flat orthographic tile. Construct the star field from a consistent square-and-octagonal regulating grid; maintain exact rotational/reflection symmetry as specified; use repeatable intersections, consistent offsets, closed polygons, and an explicit boundary rule.
Camera and perspective: Strict orthographic top view; zero lens perspective, foreshortening, depth blur, cast shadow, bevel, page curl, or oblique presentation.
Light and color: Flat production color with uniform fills; limited evidenced palette with sufficient value contrast; no gradients, glow, vignette, or lighting effects.
Materials and craft: Represent clean ink, cut tile, or vector-like color fields as requested; keep joints or outlines at consistent production scale and avoid simulated plastic relief.
Integration requirements: Opposite left/right and top/bottom edges must join exactly; corner fragments must complete across four adjacent tiles; intersections and line weights remain identical through the seam.
Visible construction logic: Final master may show a separate, subordinate regulating grid only if requested; otherwise hide guides while preserving exact derivation. Verify seamless tile edges by previewing at least a 3 x 3 repeat and inspecting every seam and corner.
Avoid list: Broken tiling, clipped nonmatching edges, random decoration, drifting line weights, near-symmetry, accidental gaps or overlaps, impossible interlaces, freehand wobble, perspective, relief, shadow, texture noise, extra symbols, text, logo, or watermark.
Output format/aspect ratio: Square bitmap repeat tile by default, production-flat and edge-to-edge; no text, labels, logo, or watermark unless explicitly requested.
```

## E. Classical construction manuscript

```text
Task and mode: Generate; classical manuscript/diagram; produce a measured architectural construction sheet.
Input image roles: Label any source by index as content, style, composition, or auxiliary reference; if a supplied drawing must be retained, label it edit target too. Do not decipher or reproduce unreadable marks.
Non-negotiable invariants: Preserve the requested subject, geometric construction sequence, measured relationships, sheet orientation, and any legible user-supplied diagram content; guides and finals must remain distinguishable.
Cultural lineage: Use the manuscript and architectural conventions of the evidenced regional/period subtradition; if none is evidenced, use a neutral historical measured-drawing language without invented script or cultural attribution.
Matched space and scale: Fit a coordinated plan, elevation, and section at readable scales on one sheet, with margins and registration relationships that allow dimensions and construction arcs to be followed.
Geometry and composition: Primary scene composition strategy: N/A — drawing-sheet projection. Organize the sheet on a visible proportion grid; align plan, elevation, and section; show centers, axes, compass radii, regulating squares/circles, projection lines, and measured subdivisions that genuinely produce the final forms.
Camera and perspective: Near-orthographic flat sheet reproduction viewed square-on; no oblique tabletop perspective unless explicitly requested, and no lens distortion or shallow depth of field that obscures marks.
Light and color: Even archival illumination, neutral-to-warm paper tone, high local contrast for legibility, restrained ink colors, and no dramatic shadows or vignette.
Materials and craft: Aged but legible fibrous paper, crisp dark final ink, lighter guide graphite/ink, subtle measured ticks, pinpricks, compass points, and restrained edge wear; aging must not erase information.
Integration requirements: Projection lines must connect corresponding plan/elevation/section features; dimensions, center marks, and compass arcs must terminate meaningfully; guide and final layers must never merge into visual noise.
Visible construction logic: Show compass lines, proportion grid, measured marks, axes, and projection guides deliberately. Use a clear hierarchy: palest construction grid, medium guide arcs/dimensions, darkest final architectural outlines.
Avoid list: Decorative pseudo-diagram, impossible geometry, mismatched plan/elevation/section, fake unreadable script, random numbers, equal-weight line soup, excessive stains, torn-away content, cinematic lighting, photoreal building render, watermark or logo.
Output format/aspect ratio: High-resolution bitmap manuscript sheet; choose a suitable portrait or landscape paper ratio for legibility; no prose text or labels unless requested, though measured ticks and nonverbal construction marks are allowed.
```

## F. Explicit controlled Islamic–Chinese fusion through octagonal geometry

```text
Task and mode: Generate or edit as requested; architectural/interior/exterior controlled fusion. Explicitly acknowledge that the user requested an Islamic–Chinese fusion rather than presenting it as a historical pure style.
Input image roles: Label every image by index and allow multiple roles; identify edit target, architectural/lineage evidence, composition reference, and auxiliary material reference separately. Do not infer unreadable content or culture from people.
Non-negotiable invariants: Preserve any edit target's function, viewpoint, camera height, massing, and user-named program; preserve every person according to the portrait invariants. Keep the shared octagonal organizing geometry and the assigned structural/spatial roles unchanged.
Cultural lineage: Select one evidenced Islamic regional/period subtradition and one evidenced Chinese regional/period subtradition from the request or references. State both. If either explicitly requested lineage lacks adequate evidence, pause and ask the user for a reference or direction. Produce a shared-geometry-led abstraction only after the user accepts that alternative, and relabel it as an octagonal cross-tradition abstraction rather than claiming a two-lineage fusion.
Matched space and scale: Form an octagonally regulated dome or central court whose span, bay width, eave height, thresholds, and human circulation share a declared module; keep dome space and timber eaves at compatible real-world scales.
Geometry and composition: Use one octagonal grid, center, axis set, and base module to govern the dome transition, court paving, timber bay spacing, screens, and eave rhythm; create layered thresholds without competing centers.
Camera and perspective: Preserve a source view first when editing; otherwise use a believable eye-level architectural view with a restrained 24–35 mm full-frame-equivalent fallback. Keep verticals straight and all octagonal edges, roof lines, and bays in one coherent vanishing system.
Light and color: Use neutral white balance and one physically continuous daylight system across dome, court, and eaves; limited mineral, plaster, timber, tile, and bronze colors; controlled highlights and open dimensional shadows.
Materials and craft: Limit the palette to structurally assigned materials: masonry/plaster or tile for the dome-space enclosure, timber/roof tile for the frame and eaves, stone at plinths and wet edges, and restrained bronze at resolved connections; show real grain, courses, overlaps, fasteners, and weathering.
Integration requirements: Assign the evidenced Islamic subtradition the dome-space and geometric-screen role and the evidenced Chinese subtradition the timber-frame and eave role, unless the user specifies otherwise. Resolve visible octagon-to-bay dimensions, dome thrust and support, timber bearing, fastening, drainage paths, flashing, weathering exposure, and material transitions at every visible junction.
Visible construction logic: Hide guides in the final architectural image, but make the shared octagonal system legible through paving, supports, screen divisions, dome springing, and eave bays. Every span has visible bearing and every visible junction has a plausible assembly. If concealed fire separation, movement accommodation, waterproofing layers, or other hidden systems are requested, provide them in a separate detail drawing or technical note; do not claim that a photorealistic bitmap proves them.
Avoid list: Unacknowledged fusion, symbol collage, generic crescent-and-dragon motifs, surface-applied muqarnas or dougong, incompatible scales, unsupported dome, floating eaves, unresolved octagon-to-rectangle corners, mixed random palettes, conflicting shadows, bent verticals, movie fog, god rays, HDR, plastic materials.
Output format/aspect ratio: Photorealistic architectural bitmap; use or preserve the user-requested/source aspect ratio, otherwise choose a compositionally suitable landscape ratio; no text, labels, logo, or watermark.
```

## Historical-surreal route bindings

Use these bindings only after the request has been routed to a historical-surreal poster, collage, editorial, zine-like, or stylized architectural transformation. Compile the selected route into the same four-section prompt; do not generate a separate background or cutout layer.

When period evidence is broad and lineage is Islamic, Chinese, or Western, use the corresponding broad-lineage system; only insufficient lineage evidence uses shared classical geometry.

For a routed historical poster, collage, editorial, zine-like, or stylized architectural transformation, use the historical-surreal grammar by default; when the user explicitly requests no surrealism or a restrained conventional poster or editorial, disable the impossible spatial gesture and monumental-fragment formula while retaining source-shape linkage, anti-cutout composition, integrated typography, period evidence, and source fidelity.

The evidenced cultural route remains active for both historical-surreal and conventional composition; the override replaces only the route's impossible/monumental composition formula.

### Historical-surreal compiler section 1 — source fidelity

Historical-surreal section 1 must state each source role, the semantic minimum, no more than three hard anchors, protected projection, proportions, and contacts, plus lineage and period confidence.

### Historical-surreal compiler section 2 — poster direction

Historical-surreal section 2 must state the exact visual thesis; exactly one memorable impossible spatial gesture; exactly one monumental architectural fragment; at most two or three source-faithful planes linked to source shapes; typography that shares the source-derived shape linkage by aligning with, passing behind or through, or being occluded by the same contour, axis, or plane; active negative space, one governing axis, asymmetric crop with off-frame continuation; and, when selected, the exact dissolution side, direction, protected gaps, and atmospheric bridge behavior.

When the source includes a protected subject or held object, section 2 must state this layer order: substrate; optional background coating, dissolution, abrasion, particles, glaze, enamel, and gemstone accents; incomplete architecture and integrated typography; complete protected subject and held objects; grounding/contact shadow. It must name genuine negative openings through which a background effect may remain visible and must prohibit every optional effect from crossing protected pixels.

### Historical-surreal compiler section 3 — rendering, material, and type

Historical-surreal section 3 must use one unified medium across subject and architecture; it must always state evidenced period material behavior and must also state applicable period print or paint behavior, or an explicit applicable production or mark-making behavior when print and paint are N/A; one dominant field, one structural secondary color, at most one high-chroma source- and period-compatible accent; period-native typography construction and interaction; and selective completion with lost edges.

When material accents are selected, section 3 must name the lineage-routed enamel, glazed ceramic, or gemstone-like vocabulary, its architectural or typography-linked nodes behind the subject, and an approximate combined visual-area budget of 5–12%; it must keep the subject and architecture in one base medium and make the accents subordinate to that medium.

### Historical-surreal compiler section 4 — guardrails

Historical-surreal section 4 must quote exact visible copy and prohibit logos or extra glyphs, complete-background replacement, pasted cutout edges, detached top or bottom caption bars, repeated corner emblems, badges, borders, wallpaper motifs, arbitrary floating decoration, a second surreal gesture, normalized source projection or proportions, localized butt- or waist-only dissolution, and cultural leakage.

For a protected subject, section 4 must additionally prohibit coating or effect overlap on the complete subject and held object, jewelry-ad staging, black-gold luxury treatment, plastic gloss, subject-attached material accents, and any repair that uses a generated draft instead of the original source.

### Historical-surreal conventional override

Select the evidenced Islamic, Chinese, or Western cultural route before applying either historical-surreal or conventional composition; the conventional override changes only Section 2's impossible gesture and monumental fragment while retaining that route's materials, typography, palette, source fidelity, exact copy, and foreign-route rejections.

Under an explicit conventional or no-surreal override, Section 2 must omit the impossible gesture and monumental fragment; preserve the semantic minimum and hard anchors; use one source-derived, culturally appropriate organizing structure that is neither impossible nor monumental; use at most one or two coherent planes or fields, active negative space, and a governing axis; use asymmetric crop or off-frame continuation only when compatible; and retain integrated type and anti-cutout composition.

## Islamic historical-surreal route

Apply the Islamic-fragment contract only when the Period Evidence Card selects Islamic lineage at specific or broad confidence; never apply it to Chinese, Western, shared-geometric, or insufficient-evidence routes.

Render the source and one monumental Islamic architectural fragment as one unified historical-surreal collage; never place a complete background behind a cutout subject or add detached caption bars.

The Islamic route may build from an evidenced portal, inscription band, muqarnas, tile, manuscript, or measured geometry using mineral pigment, plaster, tile, paper, or ink; construct evidenced Latin lettering without fake Arabic, preserve source fidelity and exact copy, reject Chinese and Western mechanics, and do not default to a full tiled facade.

## Chinese classical historical-surreal route

Apply the Chinese-route contracts only when the Period Evidence Card selects Chinese lineage at specific or broad confidence; never apply them to Islamic, Western, shared-geometric, or insufficient-evidence routes.

Express the shared collage grammar through evidenced bay rhythm, dougong, jiehua or ruled-line construction, stele or plaque proportion, woodblock, album-leaf, or mineral-pigment behavior without fake Chinese strokes.

Preserve the source topology, measured relationships, and semantic minimum while allowing at most two or three source-faithful planes.

The Chinese route may build from evidenced bay rhythm, dougong, jiehua, stele, plaque, woodblock, album-leaf, or mineral-pigment behavior; preserve source fidelity and exact copy, reject Islamic and Western mechanics, and do not invent Chinese strokes, default to generic red-gold festival styling, or replace the source with a complete courtyard background.

## Western classical historical-surreal route

Apply the Western-route contracts only when the Period Evidence Card selects Western lineage at specific or broad confidence; never apply them to Islamic, Chinese, shared-geometric, or insufficient-evidence routes.

Express the shared collage grammar through evidenced orders, entablature, vault, measured section, engraving plate, fresco, manuscript, or architectural-capriccio behavior without generic luxury-ad framing.

Make typography participate through alignment, partial occlusion, negative space, shared geometry, or the governing motion axis.

The Western route may build from evidenced orders, entablature, vault, measured section, engraving, fresco, manuscript, or capriccio behavior; preserve source fidelity and exact copy, reject Islamic and Chinese mechanics, and do not use generic luxury-serif or unrequested Art Deco styling or replace the source with a complete temple backdrop.

## Adaptation rules

- Keep all 13 fields and their order when adapting an internal recipe; replace evidence-dependent phrases with facts from the inspected inputs. Use a concise value or `N/A — reason` when a field genuinely does not apply. Compile every resolved 13-field internal recipe into the four-section generation prompt before the tool call.
- For a photo, architecture, or person scene, resolve exactly one primary composition strategy; subordinate view-direction, spatial-archetype, or crop-scale descriptors may refine but never compete with it. Use `N/A — flat orthographic tile` for patterns and `N/A — drawing-sheet projection` for manuscripts.
- A targeted repair call must use a revised four-section generation prompt, never a standalone repair instruction. Repeat every non-negotiable invariant, change only the section(s) required by the highest-impact failed gate, and treat the revision as the sole tool-facing/final prompt. Do not let style, ratio, or architectural instructions override identity, source viewpoint, or building function.
- Preserve the source viewpoint and lens character before using the full-frame-equivalent fallback ranges. A default focal length is never evidence.
- For a requested aspect-ratio change, protect subject/building geometry: extend or crop the environment, adjust camera distance, or redesign negative space. Never stretch the artifact.
- Default to no text unless the user explicitly requests exact text. If text is requested, quote it verbatim and keep it out of culturally sensitive or identity-bearing content unless supplied by the user.
- Default repeat patterns to a square tile and verify opposite edges plus a 3 x 3 seamless preview. Default manuscripts to a suitable portrait or landscape sheet. Preserve portrait and other source aspect ratios unless the user asks otherwise.
- For architectural design drafts and requested painterly results, classify the source artifact and select exactly one painting family plus one style-strength level from `references/painting-techniques.md`. Do not combine watercolor, ink wash, gouache, etching, collage, and photographic rendering as unrelated surface effects.
