# Explorer execution evidence

The source oracle executes the original Explorer model, enemies, combat and manager at `fe02bde`. The checked-in provenance records source and fixture hashes. Its StateManager stores cloned values, and its EventBus records events without listener delivery. Browser initialization and root state subscriptions need separate integration checks.

The current checks pass 177 original-source vectors and 78 durable-state validation checks natively. The same 177 vectors pass through compiled WebAssembly in Chromium at `/` and `/BufoClicker/`. Both paths also exercise save normalization and invalid-health rejection, with no page errors.

Observed failures drove these fixes:

- Manual combat victory exposed a shared `STRING` and `J-STR` runtime use-after-free. The runtime UDF no longer calls `STRING`; combat also reads strings before concatenation.
- GnuCOBOL's fuzzy floating comparison accepted purchases and level-ups with one unit missing at 61,923,852. Exact numeric comparisons fix six failing boundary vectors.
- GnuCOBOL's `MIN` healed 61,923,851 health to a 61,923,852 maximum with zero elapsed time. An exact clamp and IEEE arithmetic fix the two failing source vectors.
- Native stat cost at level 8 was 133, while the original WASM exponent path returned zero. Generic libm powers produce the source value on both targets.

`build.sh` builds the isolated native executable, runs both native checks and builds the browser test artifact. It uses `build/explorer-generated` and `build/explorer-wasm`, so it does not replace production output. Run it inside the repository's COBOL tools image. `browser.cjs` requires Playwright 1.58.2 and its Chromium image, and reads the repository path from `REPO_ROOT`, default `/source`.

The Browser plugin could not initialize because its runtime import of `node:process` was blocked. Browser evidence therefore uses Docker Playwright Chromium. The test starts an isolated HTTP server and verifies both hosting prefixes.

An initial LeakSanitizer run found 17,426,504 bytes in shared GnuCOBOL UDF result contexts. The runtime now reuses caller-owned result buffers through generic C ABI wrappers. The final ASan and LeakSanitizer run over all 177 vectors passes with no reported errors or leaks. This check does not establish physical-device or long-session performance.
