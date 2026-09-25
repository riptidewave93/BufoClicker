# Component execution evidence

Executed against baseline `fe02bde429b650d32591f22a824f7dad8a0d4dd9`, using the pinned COBOL toolchain and Playwright 1.58.2 Chromium. Node and npm ran inside Docker.

## Source comparisons

`bash tests/components/run.sh` compiles the actual COBOL modules and passes **75 original-source comparisons**: 16 template results, 36 easing values, six concrete render/tooltip results, nine UI constant exports and eight style dictionaries. `original.cjs` executes the TypeScript source through the compiler. Its boundary mocks supply state and an unattached base component; they do not reimplement the tested markup or formulas. `original-provenance.json` records source hashes.

HTML comparisons parse tags, attributes and text, allowing source indentation differences. Numeric comparisons use a 1e-12 tolerance. Constant dictionaries compare structurally. The dark default deliberately replaces the original light default.

## Real browser checks

`bash tests/components/build-browser.sh`, then `node tests/components/browser.cjs`, passes **43 checks** against the real compiled WASM and live Chromium DOM. This covers DOM versus component string-content semantics, query/child/button identity, event cleanup, selected-state changes (including adjacent large doubles), stylesheet resolve/reject/fallback, animation completion/cancellation/custom easing, tooltip placement/delay/movement/cancel, all six factory initialization results, concrete lists and production contributions, independent GoldenBufo/BossFight init/destroy, and the golden/boss/achievement/statistics/prestige presentation.

The fixture injects state and runtime records at the test boundary. It does not replace DOM measurements, COBOL decisions or the browser bridge. Full player flows and other browser engines are covered separately by `tests/browser/check.cjs`.

## Regressions with failing-before evidence

`node tests/components/callback-reentry.cjs` failed on the earlier full build with `function signature mismatch` when a state callback destroyed its own component. The next call could no longer use the runtime. After callbacks moved out of COBOL and selectors/easing gained explicit continuations, the same real-app check passes:

```json
{"reentered":false,"changed":1,"selectorChanges":0,"easingCalls":1,"alive":"number","retainedTooltips":0}
```

The check also covers a selector that destroys its subscription before returning, an easing callback that cancels its animation, a synchronous focus event, and release of tooltip-owned element handles. Subscription guards suppress queued callbacks after destruction. Native queries still require explicit fixture results; missing browser access is an error.

`node tests/components/click-effects.cjs` failed on the earlier full build with `each click needs a ripple: 0 !== 2`. It now passes with two ripples, two floating values and two independent art elements for two clicks. It verifies source durations (1000 ms, 1500 ms, and 800–1000 ms), one-decimal labels, measured viewport bounds, and cleanup of all effect nodes and squish animations. COBOL generates the easing/parabola keyframes; the host only measures bounds and runs the supplied Web Animations data.

The full development build compiles and links every COBOL module, including `ui-details.cob`. These checks establish the named behavior, not pixel identity or exhaustive equivalence for every private TypeScript helper and every JavaScript value.

## Runtime return-buffer check

The canonical `scripts/test-runtime.sh` also runs `json-strings.c` under ASAN and
UBSAN. The previous JSTR implementation failed its small-allocation assertion
(32768 bytes for a five-character result). The replacement passes exact initial
allocation, growth to the limit, shrink/reuse, empty and oversized results, with
no sanitizer findings. This reduces temporary allocation size; isolated Firefox
measurements did not establish a seeded-game frame-time improvement from this
change alone.

`profile-firefox.cjs` disables rAF and measures the real application before and
after adding one million bufos and purchasing ten generators. The isolated
comparison used the same generated COBOL with only the owned-generator transfer
changed. Fifteen samples per operation measured seeded recalculation at about
3.80 to 3.13 ms and complete tick dispatch at 15.6 to 14.0 ms. The 1557-call domain
suite passes native and ASAN after the transfer. These are diagnostic timings,
not a hardware-independent performance threshold or proof of sustained 60 fps.
