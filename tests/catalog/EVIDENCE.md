# Startup catalog validation

`run.sh` compiles the validator with the generic JSON runtime and tests 24 valid/invalid catalogs. The normalized prerequisite fixture first failed with `Invalid catalog: upgrades catalog-item ribbit_resonance field id`; the validator now accepts both the shipped `id` representation and the loader's normalized `target` representation, while validating their references. Repeated public initialization also passes this same case through BUFO-APP.

The validator is read-only. BUFO-APP calls it after reading all five catalogs and before domain initialization or writes. Other cases reject malformed types, duplicate IDs, nonpositive costs/boosts, fractional ownership, bad prerequisite targets, unknown achievement requirements, invalid boss order/health, and invalid enemy area/drop/distribution definitions. The suite does not claim exhaustive acceptance of unsupported custom catalogs.
