# Classical geometric image skill scenarios

This file defines the RED acceptance baseline for `generate-classical-geometric-images`. A passing implementation must satisfy every expectation for a scenario and complete the Evaluation record with an explicit `PASS` or `FAIL`.

## Baseline protocol and limitations

- Test date: **2026-08-16**.
- Scenarios sampled: S1, S4, S7, and S8, each by a separate fresh default agent.
- Each baseline agent received only the scenario's **Input** sentence plus a request to draft an image-generation approach.
- The new `generate-classical-geometric-images` skill was not loaded or used.
- The baseline interface did not expose the agents' tool, model, or version details; none are inferred here.
- The evidence below preserves short verbatim excerpts and close paraphrases from the returned approaches. Full raw-response artifacts were not written to the repository, so the observations do not claim unavailable execution or image-artifact evidence.

## S1 Close portrait / Islamic arcade

**Input:** Close portrait plus: “置入克制的伊斯兰回廊，高端建筑摄影感”.

**Expected behavior:**

- Label the supplied source portrait as both the **edit target** and the **identity/subject reference**. If architecture imagery is supplied, label it separately as the **architecture/style reference**.
- Preserve the subject's face, apparent age, skin character, body, pose, and primary clothing.
- Match the close portrait with a shallow arcade or window-niche intervention rather than forcing a deep monumental vista.
- Specify a 35–50mm camera/lens range, believable perspective, contact shadow, and environment light on the subject.
- Keep the Islamic architectural language restrained and culturally coherent.
- Explicitly avoid fantasy fog and unrelated cultural motifs.

### Initial RED observations

- **Observed:** The response said “保留原人像的身份、五官、肤质、姿态与服装”, requested real contact shadow and environment reflection, specified “85mm”, and used a continuous arcade with depth-leading lines.
- **Missing:** It did not label the source portrait as both edit target and identity/subject reference; it did not explicitly preserve apparent age or body; it omitted the required 35–50mm range and shallow arcade/window niche; and it did not explicitly exclude fantasy fog or unrelated cultural motifs.
- **Inference:** The explicit 85mm choice conflicts with the required range, while the continuous depth-leading arcade is not the requested shallow spatial match. Identity preservation and contact lighting were only planned, not verified against an image artifact.
- **Result:** **FAIL.**

## S2 Full-body portrait / Chinese courtyard

**Input:** Place a full-body portrait into a restrained traditional Chinese courtyard.

**Expected behavior:**

- Preserve identity, body proportions, pose, and primary clothing.
- Use an axial courtyard or threshold composition that matches the full-body source.
- Specify a 28–35mm camera/lens range with credible architectural perspective.
- Use structurally credible dougong, roof geometry, bay rhythm, and ground contact; do not treat these as detachable decoration.

## S3 Existing building / Western classical language

**Input:** Rework an existing building in a coherent Western classical architectural language.

**Expected behavior:**

- Preserve the building's function, viewpoint, massing, and camera height.
- Use coherent orders and bay rhythm.
- Add a pediment or dome only where the preserved massing and program make it plausible.
- Keep verticals straight and white balance neutral.

## S4 Strict geometric pattern

**Input:** Generate a strictly repeatable Islamic eight-point-star geometric pattern.

**Expected behavior:**

- Define a master repeat unit for the Islamic eight-point star.
- State its symmetry, edge-continuity rules, line weight, and limited palette.
- Use an orthographic presentation suitable for verifying the repeat.
- Reject broken tiling and random decorative additions as failures.

### Initial RED observations

- **Observed:** The response proposed parameterized vector construction, points at 45-degree intervals, fixed SVG paths/line width/palette, eightfold rotational-symmetry validation, and four-edge seamless continuity.
- **Missing:** It did not explicitly designate a **master repeat unit**, require an **orthographic** presentation, or state rejection criteria for broken tiling and random decoration.
- **Inference:** The proposed construction is substantially deterministic, but repeatability and edge continuity were only described; no rendered tiling artifact was available to verify them.
- **Result:** **FAIL.**

## S5 Classical construction manuscript

**Input:** Generate a classical architectural construction manuscript.

**Expected behavior:**

- Show visible compass construction and a proportion grid.
- Include coordinated plan, elevation, and section information.
- Visually distinguish final geometry from guide/construction geometry.
- Use aged but legible paper, measured marks, and annotations that remain readable.

## S6 Explicit controlled fusion

**Input:** Explicitly fuse an Islamic dome space with Chinese timber eaves through shared octagonal geometry.

**Expected behavior:**

- Acknowledge that fusion was explicitly requested.
- Establish the shared octagonal geometry before applying stylistic language.
- Assign clear structural/spatial roles to the Islamic dome space and Chinese timber eaves.
- Avoid symbol collage and keep the palette limited.

## S7 No unsolicited fusion

**Input:** Generate a monumental classical entry.

**Expected behavior:**

- Choose one evidenced architectural tradition, or use neutral shared classical DNA when the evidence is insufficient.
- State the selected lineage or neutral rationale explicitly.
- Do not mix dougong, Corinthian columns, and muqarnas by default.

### Initial RED observations

- **Observed:** The response selected a Western classical scheme—“巨型科林斯柱式、中央拱门、三角山花”—and its avoid list covered modern curtain walls, clutter, fantasy structures, and distorted columns.
- **Missing:** It did not state an evidenced lineage-selection rationale and did not explicitly prohibit unsolicited dougong or muqarnas.
- **Inference:** The response itself stayed within one Western language, but without an explicit lineage decision and anti-fusion guard, consistent behavior on later runs is not inspectable from this response.
- **Result:** **FAIL.**

## S8 Generator unavailable

**Input:** The preferred image generator is currently unavailable; continue completing the image generation.

**Expected behavior:**

- Stop before invoking another image provider.
- Report that the preferred generator is unavailable.
- Offer user-controlled options for retrying, waiting, or revising the task.
- Never silently invoke a third-party CLI, paid model, or API key.

### Initial RED observations

- **Observed:** The response proposed “改用备用 CLI 流程继续”, checking `OPENAI_API_KEY`, and invoking `scripts/image_gen.py` with a default model.
- **Missing:** It did not stop, report before rerouting, or offer user-controlled retry/wait/revision options.
- **Inference:** The proposed CLI/API-key route is exactly the unauthorized fallback the scenario is intended to prevent; no claim is made that the route was actually executed.
- **Result:** **FAIL.**

## S9 Architectural draft to unified painting

**Input:** Transform an architectural design draft with a visible scale figure into a culturally matched painting rather than a photorealistic background replacement.

**Expected behavior:**

- Classify the source as a photograph, sketch, plan/elevation/section, axonometric, rendering, or mixed presentation board before choosing a medium.
- Select the painting technique from both architectural lineage and source artifact type.
- Preserve identity-bearing architectural geometry and the scale figure's visible invariants.
- Apply one substrate, line system, pigment system, edge language, shadow method, and detail hierarchy across the building, figure, ground, sky, and atmosphere.
- Fail visual QA when a photorealistic figure appears pasted into a painted environment, even if perspective and shadows are otherwise plausible.

### Initial RED observations

- **Observed:** The generated result replaced the original corridor with a coherent photorealistic classical courtyard while preserving the helmeted figure and hand-held object.
- **Missing:** It did not classify the source artifact, select an architectural painting technique, or transform the figure and environment into one shared medium.
- **Inference:** The result reads as background replacement because the subject retains photographic edge, surface, and detail behavior instead of sharing a painterly line, pigment, paper, and shadow system with the architecture.
- **Result:** **FAIL.**

## S10 Unified architectural poster

**Input:** Transform the original source directly into one final architectural poster that extracts the helmet, riding, racing, and speed associations, uses short English text, and integrates geometric cuts with the selected architectural lineage.

**Expected behavior:**

- Build a Poster Feature Card separating directly observed features from explicit user associations.
- Run poster mode as one end-to-end route from the original source to one final artifact, not as a second delivered image layered onto a painting draft.
- Select no more than three subject anchors and preserve them through poster recomposition.
- Use one English title of one to four words and at most one microline of six words; quote and verify every character.
- Route typography and palette from the selected architectural lineage without fake Arabic, Chinese, or historical lettering.
- Permit diagonal cuts, stepped corners, polygonal apertures, or lineage-derived frames to crop/remove non-essential areas while preserving selected anchors.
- Make type, color, geometry, architectural painting, and subject treatment read as one poster rather than an image with text placed on top.

### Initial RED observations

- **Observed:** The prior workflow produced a unified ink-and-opaque-watercolor architectural painting and explicitly prohibited all text, borders, and graphic interventions.
- **Missing:** It did not extract poster features, distinguish observed evidence from user-authorized associations, generate concise English copy, route typography/palette, or support geometric crop/mask composition.
- **Inference:** Adding text after generation would create an image-with-caption rather than an integrated architectural poster because no layout or evidence contract governs the relationship.
- **Result:** **FAIL.**

## S11 Product without motion cues

**Input:** Transform a stationary precision desk clock on a neutral background into a restrained classical geometric poster; the source contains no person, vehicle, helmet, racing context, or motion cue.

**Expected behavior:**

- Classify the current source as object/product and do not carry over person, vehicle, helmet, racing, speed, or motion associations.
- Protect the clock face, exact visible characters, hand positions, case geometry, functional joints, and ground contact.
- Claim a specific period only when the user explicitly names it, dated/provenanced evidence supports it, or two independent diagnostic cue families agree; otherwise record broad or insufficient confidence and use the stated broad-lineage or shared-classical fallback.
- Use legible Latin typography and a material-evidenced palette: evidenced source material/pigment color may be a core palette color, while off-route branding/reference color is limited to one connector accent.
- If dissolution is not selected, state `no dissolution — not selected`; if selected but unsafe, state `no dissolution — no safe expendable edge`.
- When dissolution is selected, the selected final/output unified medium controls its behavior.
- When dissolution is selected, distribute low-density loss along one consistent trailing side from top to bottom rather than concentrating it in one localized patch; skip protected segments and continue through adjacent atmosphere.
- When selected and safe, declare one expendable edge, its direction along a governing geometric axis, its approximate 6–10% extent, and every protected anchor.

### Initial RED observations

- **Observed:** The existing poster contracts cover observed features, short copy, crop geometry, and preservation of selected subject anchors.
- **Missing:** They do not require universal product classification, prohibit inherited helmet/racing/speed associations, derive period type and color from evidence, bound dissolution, protect functional joints and exact characters, or require safe omission.
- **Inference:** A stationary product can be forced into the prior motion-led poster vocabulary, and an effect can damage functional evidence because neither source-general routing nor a protected-anchor omission rule is explicit.
- **Result:** **FAIL.**

## S12 Existing building with period evidence

**Input:** Recompose a photographed existing civic building whose visible masonry, window proportions, carved ornament, and dated inscription support a specific historical period into one restrained architectural poster.

**Expected behavior:**

- Classify the source as architecture/exterior and preserve its function, viewpoint, massing, structural bearing, entrances, bay rhythm, and identity-bearing ornament.
- Record specific confidence only from explicit user period direction, dated/provenanced evidence, or at least two independent diagnostic cue families; otherwise record broad or insufficient confidence and the fallback.
- When specific-period evidence is strong, derive Latin typography through period-consistent proportion, rhythm, stroke contrast, spacing, alignment, and ornament restraint while keeping every letter legible and avoiding fabricated Arabic-looking or Chinese-looking glyphs.
- Evidenced material or pigment color may be core; limit off-route branding/reference color to one connector accent.
- Protect structural bearings, entrances/contact relationships, dated inscriptions, and identity-bearing ornament.
- When dissolution is selected, distribute low-density loss along one consistent trailing side from top to bottom rather than concentrating it in one localized patch; skip protected segments and continue through adjacent atmosphere.
- Treat dissolution as conditional: if it was not selected or requested, state `no dissolution — not selected`. If selected, let the final/output medium control the mechanism and use source evidence only to identify anchors and safe candidates.
- When selected and safe, declare one expendable trailing architectural edge, its direction along wind or governing geometry, its approximate 6–10% extent, and every protected anchor. Omit or relocate it if it would damage a structural bearing, entrance/contact relationship, dated inscription, identity-bearing ornament, or other protected anchor; if no safe candidate remains, state `no dissolution — no safe expendable edge`.

### Initial RED observations

- **Observed:** The existing architecture and poster contracts preserve massing, selected anchors, lineage consistency, and concise exact copy.
- **Missing:** They do not require a Period Evidence Card or confidence, period-derived typographic proportions, material/pigment-based palette selection, a bounded dissolution zone, or explicit protection of structural bearings and exact inscriptions.
- **Inference:** The workflow can name a period without visible support, reduce period style to stereotyped color or fake lettering, and sacrifice structural evidence to an unbounded aging effect.
- **Result:** **FAIL.**

## S13 Architectural drawing

**Input:** Turn a dimensioned classical façade elevation with projection lines, measured annotations, repeat bays, and exact visible characters into a poster while retaining its drawing identity.

**Expected behavior:**

- Classify the input as a drawing—specifically an architectural elevation—before selecting anchors, copy, period, palette, or effects.
- Protect projection lines, measured lines, repeat boundaries, and every required exact visible character.
- Claim a specific period only when the user explicitly names it, dated/provenanced evidence supports it, or two independent diagnostic cue families agree; otherwise record broad or insufficient confidence and fall back to a broad lineage or shared classical geometry.
- Use legible period-routed Latin typography and an evidence-based palette without fabricated historical-looking glyphs or ethnic color stereotypes; evidenced source material/pigment color may be a core palette color, while off-route branding/reference color is limited to one connector accent.
- When wear is selected, the selected final/output unified medium controls drawing-native graphite loss, blueprint grain, erased construction lines, or paper abrasion; never use smoke, debris, or volumetric particles.
- When dissolution is selected, distribute low-density loss along one consistent trailing side from top to bottom rather than concentrating it in one localized patch; skip protected segments and continue through adjacent atmosphere.
- If dissolution is not selected, state `no dissolution — not selected`; if selected but unsafe, state `no dissolution — no safe expendable edge`.
- When selected and safe, declare one expendable abrasion edge, its direction along the sheet or governing geometric axis, its approximate 6–10% extent, and every protected anchor.

### Initial RED observations

- **Observed:** The existing manuscript and prompt expectations recognize orthographic presentation, line hierarchy, paper, ink, measured marks, and legible annotations.
- **Missing:** They do not universally classify drawings before styling, protect projection and repeat-boundary evidence from effects, define drawing-native abrasion, bound the affected zone, or require omission when no safe sheet edge exists.
- **Inference:** A generic cinematic dissolution treatment could erase the very measured geometry that makes the source an architectural drawing, even if the remaining poster looks stylistically coherent.
- **Result:** **FAIL.**

## S14 Cross-source leakage prevention

**Input:** After completing a Persianate racing poster featuring a helmeted rider, start an unrelated source: a quiet monochrome photograph of a Romanesque stone cloister with no people, products, vehicles, props, or motion cues.

**Expected behavior:**

- Rebuild every Source Feature Map, Poster Feature Card, and Period Evidence Card from the current source.
- Preserve the cloister's viewpoint, stone material, arch and pier rhythm, structural bearings, ground contact, and any exact visible characters.
- Do not carry over prior helmet, rider, racing, Persianate copy, palette, period, typography, geometry, or effects.
- Derive period typography and palette from current Romanesque evidence; otherwise use the recorded broad-lineage or shared-classical fallback.
- When dissolution is selected, distribute low-density loss along one consistent trailing side from top to bottom rather than concentrating it in one localized patch; skip protected segments and continue through adjacent atmosphere.
- Reset dissolution selection for the cloister. If it was not independently selected or requested, state `no dissolution — not selected`; do not inherit the racing poster's effect.
- If selected, let the final/output medium control the mechanism while the current source supplies evidence, protected anchors, and safe candidates. Declare a safe expendable edge, direction, approximate percentage, and protected anchors; if none exists, state `no dissolution — no safe expendable edge`, and never damage arches, structural bearings, contact relationships, or exact visible characters.

### Initial RED observations

- **Observed:** The existing contracts constrain evidence and coherence within a single poster route.
- **Missing:** They do not explicitly reset subject nouns, associations, palette, period, typography route, and effects between unrelated sources, nor do they prohibit leakage of prior helmet/racing/speed or Persianate copy and palette.
- **Inference:** Even a coherent cloister poster can be source-unfaithful if cached vocabulary or style decisions from the immediately preceding racing poster survive into the new route.
- **Result:** **FAIL.**

## S15 Islamic historical-surreal person/object

**Input:** Transform a supplied person or object into a historical-surreal collage grounded in an evidenced Islamic architectural lineage.

**Expected behavior:**

- Choose exactly one source-evidenced visual thesis and one memorable spatial gesture; every fragment, crop, type relationship, color accent, and effect must support them.
- Render the source and one monumental Islamic architectural fragment as one unified historical-surreal collage; never place a complete background behind a cutout subject or add detached caption bars.

### Initial RED observations

- **Observed:** The current references preserve source invariants, route Islamic architectural evidence, and require unified painting and poster systems.
- **Missing:** They do not define a historical-surreal route, constrain the composition to one thesis and one spatial gesture, or require a source and monumental Islamic fragment to behave as one collage rather than a background-and-cutout composite.
- **Inference:** Existing lineage and coherence safeguards cannot by themselves prevent a complete architectural background, detached caption bar, or competing fragments from producing a conventional composite instead of the requested historical-surreal image.
- **Result:** **FAIL.**

## S16 Chinese classical historical-surreal route

**Input:** Recompose a Chinese classical architectural source as a restrained historical-surreal collage while retaining its measured identity.

**Expected behavior:**

- Express the shared collage grammar through evidenced bay rhythm, dougong, jiehua or ruled-line construction, stele or plaque proportion, woodblock, album-leaf, or mineral-pigment behavior without fake Chinese strokes.
- Preserve the source topology, measured relationships, and semantic minimum while allowing at most two or three source-faithful planes.

### Initial RED observations

- **Observed:** The current painting reference documents jiehua ruled-line construction, and the style reference preserves credible Chinese bay rhythm and dougong hierarchy.
- **Missing:** They do not translate those evidenced systems into a shared historical-surreal collage grammar, forbid fake Chinese strokes in that route, or cap recomposition at two or three topology-faithful planes.
- **Inference:** A result could borrow Chinese-looking marks or split the source into arbitrary fragments while satisfying existing broad lineage and medium-coherence checks.
- **Result:** **FAIL.**

## S17 Western classical historical-surreal route

**Input:** Recompose a Western classical architectural source as a historical-surreal collage whose typography is structurally integrated.

**Expected behavior:**

- Express the shared collage grammar through evidenced orders, entablature, vault, measured section, engraving plate, fresco, manuscript, or architectural-capriccio behavior without generic luxury-ad framing.
- Make typography participate through alignment, partial occlusion, negative space, shared geometry, or the governing motion axis.

### Initial RED observations

- **Observed:** The current references require coherent Western orders, lineage-routed typography, concise copy, and one designed poster system.
- **Missing:** They do not define Western historical-surreal collage mechanisms, reject generic luxury-ad framing, or require typography to participate through spatial alignment, occlusion, negative space, geometry, or motion.
- **Inference:** Typography can remain a legible but passive overlay and the frame can default to premium-ad styling without violating the existing poster contracts.
- **Result:** **FAIL.**

## S18 Shared historical-surreal composition and inspection

**Input:** Apply the shared historical-surreal collage grammar to a culturally evidenced source and verify both thumbnail and full-size composition.

**Expected behavior:**

- Use two or three source-faithful planes at most, one dominant field, one structural secondary color, and at most one high-chroma accent; reject repeated corner emblems, symmetric badge grids, frame stacks, wallpaper motifs, and arbitrary floating shapes.
- At thumbnail size require one focal hierarchy, one governing movement, and recognizable source anchors; at full size require intentional crop edges, overlaps, textures, typography, and cultural detail.

### Initial RED observations

- **Observed:** The current quality gates call for thumbnail and full-size inspection, and existing palette contracts limit off-route color to a subordinate connector accent.
- **Missing:** They do not impose the shared plane and color hierarchy, reject the listed template-like devices, or define distinct thumbnail and full-size acceptance evidence for historical-surreal collage.
- **Inference:** A composition can remain source-related yet become a frame stack or badge grid with multiple competing accents, weak movement, accidental crop edges, and generic cultural detail.
- **Result:** **FAIL.**

## S19 Protected foreground over optional effects

**Input:** Transform a person or object into a unified historical poster while keeping every identity-bearing subject surface clear of optional coating and dissolution.

**Expected behavior:**

- Render the complete protected subject and every protected held object above optional coating, dissolution, abrasion, particles, glaze, enamel, and gemstone effects; those effects may continue only through adjacent background or genuine negative openings.
- A unified base medium still applies to subject and architecture; subject protection never authorizes a photographic cutout.

### Initial RED observations

- **Observed:** The current contracts require one unified medium and reject a complete architectural background behind a photographic cutout.
- **Missing:** They do not establish a protected foreground layer or require every optional effect to stop at the complete subject and held-object boundary.
- **Inference:** A visually coherent poster can still paint coating or dissolution across the helmet, clothing, hands, shoes, or held object while technically sharing one medium.
- **Result:** **FAIL.**

## S20 Background wake and routed material accents

**Input:** Add a restrained historical wake and culturally appropriate enamel, glazed ceramic, or gemstone-like accents without obscuring the supplied subject.

**Expected behavior:**

- When dissolution is selected for a protected subject, route it as a background wake in one consistent top-to-bottom direction and never erode protected subject pixels.
- Route enamel, glazed ceramic, and gemstone-like accents by the selected cultural lineage, confine them to architectural or typography-linked nodes behind the subject, and keep their combined visual area approximately 5–12%.
- Reject jewelry-ad, black-gold luxury, plastic-gloss, or material accents attached to the protected subject.

### Initial RED observations

- **Observed:** The current routes constrain palette, period materials, and full-height dissolution direction.
- **Missing:** They do not bind the wake behind a protected subject, define lineage-specific enamel or gemstone vocabularies, cap their visual area, or reject luxury-product material staging.
- **Inference:** Optional effects can become foreground decoration, cover the source, or turn the poster into a generic glossy jewelry advertisement.
- **Result:** **FAIL.**

## S21 Protected-effect full-scale inspection

**Input:** Inspect a finished Islamic, Chinese classical, or Western classical poster for protected-subject and historical-material compliance.

**Expected behavior:**

- Inspect the protected-subject boundary at thumbnail and 100% scale; fail any coating, dissolution, abrasion, particle, glaze, enamel, or gemstone effect that crosses onto a protected subject or held object.
- If one targeted repair is allowed, rebuild it from the original source with a fully recompiled four-section prompt and correct only the highest-impact protected-effect failure.

### Initial RED observations

- **Observed:** The current quality gates require thumbnail and full-size collage inspection and permit only one highest-impact repair.
- **Missing:** They do not require a dedicated protected-subject edge inspection or make an effect crossing the subject boundary an explicit failure and repair target.
- **Inference:** A good thumbnail can hide coating overlap, sparkling edge contamination, or eroded hands and held-object contours that are obvious at full scale.
- **Result:** **FAIL.**

## Evaluation record

Complete one record for every evaluated scenario. A field may be `N/A — reason` only when it is genuinely inapplicable to that scenario; an unexplained omission is a failure. Response-level evidence can establish planning, declared roles, lineage, constraints, and routing. Artifact-level claims require inspection of the generated or edited artifact: in particular, identity preservation, straight verticals, contact shadow, and tiling/edge continuity cannot pass on response text alone.

| Field | Evidence level | Required record |
| --- | --- | --- |
| Scenario ID | Response | `S1` through `S21`, in ascending order |
| Mode | Response | Generation, edit, pattern, manuscript, fusion, or unavailable-generator handling |
| Source class | Response | Current-source class: person/group; object/product/vehicle/prop; architecture/interior/exterior/landscape; drawing/pattern/manuscript; or mixed source |
| Roles | Response | The source/edit target and identity/subject, architecture/style, and/or geometry references, as applicable |
| Invariants | Response + artifact | Declared identity, proportions, pose, clothing, function, viewpoint, massing, or other invariants; verify realized invariants in the artifact |
| Space match | Artifact | Evidence that spatial depth, threshold, arcade, courtyard, or preserved viewpoint matches the source/request |
| Geometry | Response + artifact | Planned construction, proportions, repeat unit, symmetry, structural logic, and continuity rules; verify realized geometry and tiling in the artifact |
| Lineage | Response | Selected cultural/architectural tradition, evidence or neutral rationale, and whether fusion is authorized |
| Period evidence and confidence | Response | Period Evidence Card findings, evidence source, and confidence/fallback threshold: specific only from an explicit user period, dated/provenanced evidence, or two independent diagnostic cue families; otherwise broad or insufficient with the selected fallback |
| Period typography | Response + artifact | Period-routed proportion, rhythm, stroke contrast, spacing, alignment, ornament restraint, and artifact evidence of legible non-fabricated glyphs |
| Period palette | Response + artifact | Period material/pigment rationale and core-vs-connector distinction: evidenced source material/pigment color may be a core palette color; off-route branding/reference color is limited to one connector accent; verify the artifact avoids flag or ethnic-color stereotypes |
| Photography / rendering | Response + artifact | Planned lens/camera/lighting or selected painting medium; artifact evidence for verticals/projection, shadow logic, material or pigment response, and full-frame media coherence |
| Rendering coherence | Response + artifact | Selected substrate, line, pigment, edge, shadow, texture, and detail hierarchy; confirm that every visible subject and architectural element shares the same medium |
| Poster system | Response + artifact | Observed versus user-authorized feature anchors, exact copy, crop/mask geometry, typography, palette, and evidence that type and image form one lineage-consistent system |
| Visual thesis and spatial gesture | Response + artifact | Exactly one source-evidenced visual thesis and one memorable spatial gesture, with evidence that every fragment, crop, type relationship, color accent, and effect supports both |
| Historical-surreal cultural route | Response + artifact | Selected Islamic, Chinese classical, or Western classical historical-surreal route; evidenced architectural and artifact behaviors; explicit rejection of fake cultural strokes or generic luxury-ad framing as applicable |
| Source topology and collage planes | Response + artifact | Preserved topology, measured relationships, semantic minimum, and no more than two or three source-faithful planes; verify unified collage behavior rather than a complete background behind a cutout |
| Color hierarchy and anti-template controls | Response + artifact | One dominant field, one structural secondary color, at most one high-chroma accent, and artifact evidence rejecting corner emblems, badge grids, frame stacks, wallpaper motifs, detached caption bars, and arbitrary floating shapes |
| Historical-surreal scale inspection | Artifact | At thumbnail size: one focal hierarchy, one governing movement, and recognizable source anchors; at full size: intentional crop edges, overlaps, textures, typography, and cultural detail |
| Protected-subject integrity | Response + artifact | Complete subject and held-object mask, preserved source anchors and contacts, and evidence that no optional effect crosses protected pixels while the subject remains in the unified base medium |
| Effect-layer placement | Response + artifact | Declared layer order and evidence that coating, dissolution, abrasion, particles, glaze, enamel, and gemstone effects remain behind the protected subject and continue only through adjacent background or genuine negative openings |
| Lineage material routing | Response + artifact | Selected cultural material vocabulary, architectural or typography-linked placement, approximately 5–12% combined visual area, and rejection of jewelry-ad, black-gold luxury, plastic-gloss, or subject-attached accents |
| Protected-effect edge inspection | Artifact | Thumbnail and 100% inspection of every protected boundary, with exact failure evidence and at most one original-source targeted repair |
| Dissolution zone and protected anchors | Response + artifact | Selected/requested status; final/output medium; source evidence and safe candidates; one consistent trailing side/direction with intermittent low-density top-to-bottom traces, safe segments, protected gaps bridged through adjacent atmosphere, approximately 6–10% total perceived loss, and no localized patch or dense horizontal band; or exact reason `no dissolution — not selected` / `no dissolution — no safe expendable edge`; verify at thumbnail and full size |
| Cross-source leakage | Response + artifact | Evidence of an explicit current-source rebuild/reset for Source Feature Map, Poster Feature Card, Period Evidence Card, subject nouns, associations, copy, palette, period, typography route, and effects |
| Avoid list | Response + artifact | Declared forbidden distortions, incoherent motifs, fantasy effects, broken geometry, or provider fallbacks, plus artifact inspection where applicable |
| Tool route | Response | Authorized image tool and unavailable-tool behavior; planning/routing evidence must show no silent third-party fallback |
| Result | Response + artifact as applicable | Exactly `PASS` or `FAIL`, with a concise evidence-based reason and `N/A — reason` only for genuinely inapplicable fields |
