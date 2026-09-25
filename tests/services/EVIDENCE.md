# Finite numeric boundary regression

`numeric-source.cjs` executes the original TypeScript number, math and validation modules. `numeric-edges.json` records their SHA-256 hashes and 110 finite-input results. [Source expectation instructions](../README.md#reproduce-source-expectations) restore the baseline and regenerate the fixture in Docker.

Before the fix, 46 cases failed. Adjacent representable numbers near 1, 1e12 and positive/negative 1e16 were treated as equal by COBOL comparisons. Clamp returned out-of-range values; range predicates accepted them; mapRange/inverseLerp returned the start of a nonempty range; lerp and weighted selection crossed boundaries incorrectly.

The affected comparisons now use the generic exact IEEE comparison primitive. Interpolation uses the original sequence of binary operations so subtracting adjacent endpoints preserves their representable difference. The check compares results exactly, without a relative-error allowance. It runs through the canonical native, WebAssembly and sanitizer scripts alongside the existing source vectors and service scenarios:

```sh
./tests/services/run.sh
./tests/services/asan.sh
./tests/services/wasm.sh
```

The existing 525 source vectors continue to pass. This regression covers the selected finite boundaries; it does not extend the transport contract to unsupported non-JSON values. Public game-loop time-scale checks also reject the adjacent value above 5 and below 0.1, while preserving the adjacent in-range value below 5 (`tests/api/verify.py`).
