## Deferred Work

- [ ] Directional collision RG blending after a concrete collision-confidence rule is designed.
  - Future rule must gate on both support-map signal and decoded collision-vector length.
  - It must never blend useful curve flow toward neutral when collision data is empty, flat, or low-confidence.

- [ ] Broad inspector UI for generation modes.
  - Current recommendation is serialized/script-accessible behavior first, visible inspector controls only after validation.

- [ ] Curve-only/no-collider procedural foam and pressure support.
  - Current first-pass behavior intentionally writes blank support maps for no-collider/curve-only bakes. Any foam, pressure, bank-distance, or edge-support generation without bake helpers needs a separate design and validation plan.

- [ ] Transparency/material-control validation in the canonical scene.
  - User-visible transparency controls appeared ineffective on curved validation rivers. Treat this as a shader/material/scene-depth follow-up, not as evidence that curve-derived bake generation regressed.

- [ ] Targeted material force-control checks.
  - `flow_pressure` is expected to have no visible effect on blank-support fixtures. `flow_max` should be validated with a high-force setup before treating it as a product regression.

- [ ] Per-point velocity, slope-derived speed, reverse-flow authoring, confluences, waterfalls, terrain simulation, and imported DCC/simulation generation modes.