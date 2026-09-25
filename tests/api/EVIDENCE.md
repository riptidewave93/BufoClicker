# API execution evidence

The acceptance runner drives the actual BUFO-APP dispatcher through 123 public facade calls. A second runner exercises all 89 manager method signatures, comparing each positional facade result and resulting state against its named module operation (539 calls). Native, AddressSanitizer/LeakSanitizer and WebAssembly runs pass. Domain behavior is independently checked by the original TypeScript model oracle and the domain acceptance suite; the route comparison alone does not establish source equivalence.

Run from the repository using `bufoclicker-cobol-tools`:

```sh
./tests/api/run.sh
./tests/api/run-asan.sh
./tests/api/run-wasm.sh
./tests/catalog/run.sh
```

The original application dispatcher rejected `game.getState` before the facade existed. Later failures caught the exact 0.1 time-scale boundary and repeated initialization rejecting loader-normalized upgrade prerequisites. The retained tests now pass. Catalog validation covers 24 valid/invalid inputs, including both raw and normalized prerequisite representations, reference IDs, number types, fractional counts, invalid boosts, duplicate IDs, boss threshold ordering, and enemy distributions/drop references.

`browser.cjs` starts its own static server for the existing development `dist/` build, runs Chromium against it, and writes `build/browser-evidence/api-browser.png`. CI runs it after building the development site:

```sh
docker run --rm -v "$PWD:/app" -w /app bufoclicker-browser-tests node tests/api/browser.cjs
```

For isolated testing, `build-browser.sh` creates `build/api-browser`; set `API_BROWSER_ROOT=build/api-browser` in the browser container. `API_BROWSER_URL` selects an already running server instead; `API_SCREENSHOT` overrides the artifact path. The browser check covers a rendered nonblank page, manager and DOM identity, notification timing, loading overlays and missing-container behavior, successful and throwing modal callbacks, delayed close events, initialization progress, callback reentry, logger configuration, and cancel/accept reset confirmation. It asserts no console or page errors. Visible game play and responsive layout have separate application/browser evidence.

Callback ownership has a separate actual-browser regression, `tests/api/callbacks.cjs`. Before collection, registering and removing 100 event closures left all 100 closures in the host registry. Retained-context callback roots, unsettled dispatcher frames, and DOM listener/timer roots now determine which closures remain. The check covers last-owner removal, sharing across event/state/DOM owners, re-registration with an existing token, nested callbacks, animation completion/cancellation, and timer reuse. The native JSON root collector also runs under AddressSanitizer/UndefinedBehaviorSanitizer in `scripts/test-runtime.sh`. Cleanup preserves the original returned Promise identity, which the animation cancellation API requires.
