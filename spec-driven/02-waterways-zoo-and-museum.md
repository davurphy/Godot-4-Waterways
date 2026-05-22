# Waterways Zoo And Museum

This document adapts the "Gyms, Zoos, and Museums" documentation pattern for the Godot 4 Waterways add-on.

For Waterways, the Gym pattern is usually less important than the Zoo and the Museum. Waterways is not primarily documenting player movement metrics. It is documenting authoring workflows, generated water data, shader behavior, validation scenes, runtime sampling, and known-good visual outcomes.

The core question for future features is:

> Does this feature deserve to be showcased in the Museum? Does it represent a new idea or feature that is worth showcasing?

Ask that question before a feature is marked complete.

## Why This Exists

Waterways knowledge is not only conceptual. It is visual, spatial, procedural, and state-dependent.

A user does not only need to know that `flow_foam_noise.rg` stores packed flow vectors. They need to see what healthy flow looks like, what a stale bake looks like, how Flow Arrows should behave, why data textures must not be imported as color art, and how a WaterSystem map should respond after child Rivers are regenerated.

Written docs are still useful, but they cannot carry the whole burden. Waterways behavior depends on Godot editor state, shader output, bake resources, texture channels, import settings, renderer behavior, and visible motion. If that knowledge lives only in Markdown, it can drift from the current add-on.

The better question is not "Do we have enough documentation?"

It is:

> Can someone open the project and see the truth?

For Waterways, in-project documentation should take two main forms:

- **The Zoo:** a browsable collection of working examples.
- **The Museum:** explanatory exhibits that teach systems beside live examples.

## The Waterways Zoo

Best used for:

- example Rivers
- validation scenes
- material presets
- bake outputs
- imported map examples
- WaterSystem setups
- wet material examples
- runtime and buoyancy samples

A Zoo is a browsable space of working examples. For Waterways, that means curated scenes that show the add-on's real authoring cases.

Instead of explaining every edge case in prose, the Zoo lets someone open a scene and inspect it directly:

- a straight River with default curve-derived flow
- a curved River with continuous downstream motion
- a no-collider River using blank support maps
- a bank-helper setup with foam and pressure support
- a WaterSystem combining multiple child Rivers
- a wet material target receiving generated system-map uniforms
- a buoyant runtime object sampling height and flow
- lava and debug shader variants
- imported data textures with correct import settings

The Waterways Zoo is not only a demo gallery. It is a living reference library. It answers:

> What should this look like when it is working?

That matters because Waterways has many failure modes that are hard to describe but easy to recognize: flat flow, stale resources, broken alpha/noise channels, over-strong pressure distortion, missing wet-target uniforms, or near-neutral vectors being mistaken for meaningful direction.

### Zoo Benefits

- **Visible source of truth:** Users and maintainers can inspect real River, WaterSystem, shader, and bake behavior without translating prose into a scene from scratch.
- **Regression-friendly examples:** Validation scenes become reusable evidence whenever shader, bake, editor, or runtime behavior changes.
- **Better onboarding:** A new user learns faster from working scenes than from abstract setting descriptions alone.
- **Packaging clarity:** The source project can keep rich validation and example scenes while the minimal add-on package stays focused on `addons/waterways`.

### What Makes A Good Waterways Zoo

Organize Zoo scenes by workflow, not only by file structure:

- **Authoring basics:** add a River, edit curve points, adjust width, generate flow and foam.
- **Bake cases:** no-collider, flat collider, bank helper, seam crossing, curve-only, legacy comparison.
- **Shader cases:** default river, debug views, lava, zero or near-zero settings, imported data maps.
- **WaterSystem cases:** multiple Rivers, generated system maps, wet material assignment, saved external bake resources.
- **Runtime cases:** buoyancy, flow force, fallback behavior outside coverage.

Each display should include enough in-scene context to be understood quickly: labels, expected debug views, reference objects, and obvious valid/invalid comparisons where useful.

## The Waterways Museum

Best used for:

- channel contracts
- shader behavior
- bake pipeline concepts
- import rules
- runtime sampling
- failure cases
- "do not do this" guidance

The Museum explains Waterways systems beside live examples of those systems.

Some Waterways knowledge is too technical to be discovered by looking at a finished river. For example:

- why neutral flow is `(0.5, 0.5)` in `R/G`
- why near-neutral vectors should not draw confident arrows
- what `flow_foam_noise.a` contributes to two-phase flow
- why generated River data uses a padded UV2 atlas
- why WaterSystem maps use alpha coverage instead of black RGB
- why imported data textures need lossless or uncompressed settings
- why unsaved scenes keep temporary bake data until saved and rebaked

These are Museum topics. They need explanation, but the explanation should sit next to an interactive or visible example.

A Waterways Museum exhibit might show the same River in several modes: Flow Map, Flow Pattern, Flow Arrows, Flow Strength, Foam Mix, and normal shaded view. The labels would explain what each view proves and what failure signs to look for. Another exhibit might compare a correctly imported flow texture against one damaged by color or compression settings.

The value is that maintainers and users learn the system through the actual Godot project, not through detached prose that can silently go stale.

### Museum Benefits

- **Live technical explanation:** Shader and bake behavior can be explained while the user sees the exact output.
- **Better debugging instincts:** Users learn to check generated data, import settings, stale resources, and debug views before assuming the shader is broken.
- **Guardrails for future work:** The Museum makes Waterways contracts visible: packed channels, editor/runtime boundaries, generated resources, and validation expectations.
- **Clear negative examples:** Bad imports, stale bakes, legacy collision-only behavior, and near-neutral flow can be shown directly instead of buried in warnings.

### What Makes A Good Waterways Museum

A good Museum should have small, purposeful exhibits:

- **Two-Phase Flow Exhibit:** shows `FlowUVW`, alpha/noise offset, Flow Pattern, and reset hiding.
- **Channel Contract Exhibit:** shows `flow_foam_noise` and `dist_pressure` channels with labels for each component.
- **Bake Resource Exhibit:** shows generated `.res` bake data, saved-scene behavior, and stale-resource warnings.
- **Import Rules Exhibit:** compares valid data-texture import settings against broken color or compressed settings.
- **WaterSystem Sampling Exhibit:** shows flow, height, alpha coverage, wet-target assignment, and runtime sampling.
- **Failure Case Exhibit:** shows flat or neutral flow, legacy collision-only output, missing collider support, and misleading near-zero arrows.

The Museum does not replace written docs. It is the front door to them: the place where someone first understands the behavior, then follows links to deeper technical notes when needed.

## Spatial Documentation

Waterways benefits from light spatial notes inside example and validation scenes.

Good spatial documentation may include:

- labels beside each validation River explaining what it proves
- small signs naming the debug view to inspect
- notes on expected Output markers after validation actions
- warnings beside intentionally broken examples
- links from scene labels to deeper docs like the user guide or import notes
- consistent node names used in validation, such as `StraightRiver`, `BankHelperRiver`, or `WaterSystem`

The goal is not to turn every scene into a wall of text. The goal is to make each scene self-orienting.

## Feature Completion Gate

Before marking a feature complete, answer this in `tasks.md` or `review.md`:

> Does this feature deserve to be showcased in the Museum? Does it represent a new idea or feature that is worth showcasing?

Use this decision rule:

- **Yes:** the feature is not complete until a Zoo or Museum path exists. Add or update a validation scene, demo scene, Museum exhibit, spatial labels, screenshots, or a clearly tracked follow-up that is accepted as part of the feature's visible proof.
- **No:** record why. Internal cleanup, tiny bug fixes, or invisible maintenance may not need a new exhibit, but they may still need validation coverage if they can break existing behavior.

When the answer is yes, the exhibit should explain at least one of these:

- what users can now do
- what maintainers must not accidentally break
- what a healthy result looks like
- what a broken result looks like
- which debug view, validation action, or runtime scene proves the behavior

## Putting It Together

For Waterways, the Zoo and Museum should work together.

The Zoo answers:

> What are the working examples?

The Museum answers:

> Why do they work, and how do I know when they are broken?

A validation scene like `curve_derived_river_flow_validation.tscn` can be both. As a Zoo scene, it displays important river cases: straight, curved, no-collider, bank-helper, legacy comparison, and seam-crossing behavior. As a Museum scene, it can explain the generated flow contract, debug views, support maps, and expected validation output.

That is the opportunity for Waterways. The project already has strong written docs and validation scenes. The next step is to make those scenes deliberately educational, so they serve three audiences at once:

- users learning how to author rivers
- maintainers checking regressions
- future contributors understanding the system before changing it

External docs still matter. The README, user guide, import notes, specs, plans, and validation files should stay. But Waterways' most important knowledge should also be visible inside the Godot project itself.

Build the Zoo. Build the Museum. Keep the examples live.
