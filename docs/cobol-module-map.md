# Original module map

Baseline: `fe02bde429b650d32591f22a824f7dad8a0d4dd9`. The inventory contains **64 modules: 63 under `src/` and `styles/styleLoader.ts`**. Each appears once below. Replacement filenames without a directory are under `cobol/`.

This is a code-and-test coverage map, not a claim of complete equivalence. A test link identifies the executable check and its scope. Source-derived oracle checks establish more than facade routing against another COBOL operation; browser checks establish more than native DOM fixtures. Pending rows identify uncovered public adapters or semantics at this audit point.

Proof references:

- **D**: [domain source-oracle and acceptance checks](../tests/domain/verify.py), [execution record](../tests/domain/EVIDENCE.md).
- **X**: [Explorer source-oracle comparison](../tests/explorer/compare.py), [validation](../tests/explorer/validation.py), [execution record](../tests/explorer/EVIDENCE.md).
- **S**: [525 source JSON vectors](../tests/services/compare.py), [event/state/timer and transport scenarios](../tests/services/scenarios.py), [contract and adaptations](../tests/services/OPERATIONS.md), [110 exact finite boundaries and provenance](../tests/services/EVIDENCE.md). Native and WASM checks pass; ASAN/LSAN clean.
- **I**: [coordinator checks](../tests/integration/verify.py), [persistence/lifecycle transactions](../tests/integration/transactions.py), [execution record](../tests/integration/EVIDENCE.md). Native and ASAN/LSAN pass with UI/API/service stubs.
- **A**: [public API acceptance](../tests/api/verify.py), [manager routing comparison](../tests/api/routing.py), [actual browser acceptance](../tests/api/browser.cjs), [execution record](../tests/api/EVIDENCE.md). Routing compares a facade call with its named COBOL operation, not independently with TypeScript.
- **C**: [75 source comparisons](../tests/components/compare.py), [43 live component/presentation checks](../tests/components/browser.cjs), [callback reentry regression](../tests/components/callback-reentry.cjs), [click composition regression](../tests/components/click-effects.cjs), [execution record](../tests/components/EVIDENCE.md). The record distinguishes source oracles from browser scenarios.
- **B**: [full application browser check](../tests/browser/check.cjs). Final full-build execution is the browser gate; this map does not substitute for its report.

| Original module | Replacement | Proof | Scope or remaining gap |
| --- | --- | --- | --- |
| `src/core/eventBus.ts` | event-services.cob; api.cob | S, A, B | Live listener mutation, callback isolation and token transport. Callback ownership browser regression verifies release after the last event/state/DOM owner. |
| `src/core/eventTypes.ts` | Event names in domain, Explorer, save, and API modules | D, X, I, A | Constants become event-name strings; tests cover emitted names, not a separate constants export. |
| `src/core/stateManager.ts` | state-services.cob; app.cob | S, B | Owned snapshots, batches, subscribers; root mutations use notify. |
| `src/core/types.ts` | JSON context contract; save-validation.cob | I, X | Type-only declarations become validated durable records. |
| `src/game/gameCore.ts` | game.cob; app.cob; api.cob; api-extra.cob | D, A, I, B | Tick ordering, managers, start/stop, facade purchases. |
| `src/game/gameLoader.ts` | app.cob; api-extra.cob; async-services.cob | A | Bundled/preloaded catalogs; separate status flags, counts and completeness. Startup rejects malformed catalogs before initialization; raw and normalized prerequisite fixtures covered. |
| `src/game/gameLoop.ts` | app.cob; api-extra.cob | A, I, B | Frame accumulator, FPS, timescale, start/stop. |
| `src/game/gameSave.ts` | save.cob; save-validation.cob | I, A, B | Atomic acceptance; offline thresholds; save/import events. |
| `src/game/gameState.ts` | state-services.cob | S | Derived values, merge/validation, display/statistics. |
| `src/game/index.ts` | api.cob; api-extra.cob | A, I, B | Game facade routes to domain, Explorer and saves. |
| `src/index.ts` | app.cob; web/host.js; web/index.html | B | Entrypoint and development-only facade; browser gate owns final acceptance. |
| `src/initialization.ts` | app.cob; api-initialization.cob; api-ui.cob | I, A, B | Nine progress callbacks, loading overlay update/removal, callback errors, logger/debug setup; root lifecycle owns global browser hooks. |
| `src/managers/UIManager.ts` | api-ui.cob; ui.cob; components.cob | A, C, B | Live modal/notification elements, callback close/throw behavior, delayed close events, notification removal and stable component/DOM identity tested in Chromium. |
| `src/managers/achievementManager.ts` | achievements.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/managers/bossManager.ts` | bosses.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/managers/explorerManager.ts` | explorer.cob; api.cob | X, A | Eight areas, encounters, leveling, manual and automatic combat. |
| `src/managers/generatorManager.ts` | generators.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/managers/goldenBufoManager.ts` | golden.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/managers/index.ts` | game.cob; explorer.cob; api-extra.cob | D, X, I, A | Source-order manager initialization/reset wrappers route to migrated operations. |
| `src/managers/prestigeManager.ts` | prestige.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/managers/upgradeManager.ts` | upgrades.cob; api.cob | D, A | Original manager operations; facade routing compares result and state. |
| `src/models/achievements.ts` | achievements.cob; assets/data catalogs | D | Pure model operations and catalog-backed initialization. |
| `src/models/boss.ts` | bosses.cob; assets/data catalogs | D | Pure model operations and catalog-backed initialization. |
| `src/models/combat.ts` | combat.cob; assets/data/enemies.json | X | Source oracle covers model results and deterministic random consumption. |
| `src/models/enemies.ts` | enemies.cob; assets/data/enemies.json | X | Source oracle covers model results and deterministic random consumption. |
| `src/models/explorer.ts` | explorer-models.cob; assets/data/enemies.json | X | Source oracle covers model results and deterministic random consumption. |
| `src/models/generators.ts` | generators.cob; assets/data catalogs | D | Pure model operations and catalog-backed initialization. |
| `src/models/prestige.ts` | prestige.cob; assets/data catalogs | D | Pure model operations and catalog-backed initialization. |
| `src/models/upgrades.ts` | upgrades.cob; assets/data catalogs | D | Pure model operations and catalog-backed initialization. |
| `src/ui/components/bossFight.ts` | components.cob; ui.cob; presentation.cob; actions.cob | C, B | Independent live init/destroy; health percentage, urgent timer and positioned projection; full fight flow in B. |
| `src/ui/components/clickArea.ts` | components.cob; component-render.cob; actions.cob | C, B | Game click route plus ripple/value/art composition, combo styling, finite squish, viewport bounds and cleanup. |
| `src/ui/components/generatorItem.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/generatorList.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/goldenBufo.ts` | components.cob; ui.cob; presentation.cob; actions.cob | C, B | Independent live init/destroy; spawn position/art/TTL, timed frenzies and reward presentation. |
| `src/ui/components/index.ts` | components.cob | C | Six named factories and initializeUI produce live initialized component references. |
| `src/ui/components/productionStats.ts` | components.cob; component-render.cob; state-services.cob | C, S | Browser contribution rendering and source statistics values. |
| `src/ui/components/resourceDisplay.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/shop.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/shopItem.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/upgradeItem.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/components/upgradeList.ts` | components.cob; component-render.cob | C, B | Generic component instance transport plus concrete render/update behavior; see proof limits below. |
| `src/ui/constants.ts` | ui-constants.cob; ui.cob; web/game.css | C, B | All nine exports compared with source; dark default deliberately replaces light. |
| `src/ui/core/Component.ts` | components.cob; web/dom-bridge.js; web/host.js | C | Live elements, exact state selectors, listener cleanup; self-destroy callbacks and selector continuations execute safely. |
| `src/ui/core/Container.ts` | components.cob | C | Add/remove/find children and DOM identity. |
| `src/ui/core/types.ts` | Component options and reference-token contract | C | Type-only declarations represented by component options and handles. |
| `src/ui/index.ts` | api-ui.cob; components.cob | A, C | UIManager/component exports and initUI/updateUI wrappers route to migrated UI and factory operations. |
| `src/ui/styles.ts` | ui-constants.cob; component-render.cob; templates.cob; web/game.css | C, B | All eight exported style dictionaries compared with source. |
| `src/ui/templates.ts` | templates.cob | C | Original-source structural markup comparisons. |
| `src/utils/animationUtils.ts` | animation.cob; web/host.js | C | Source easing vectors; live completion/cancellation/custom easing with safe result continuations. |
| `src/utils/dataLoader.ts` | async-services.cob | S | Fetch continuations, HTTP failures, partial results, cache versions. |
| `src/utils/debugTools.ts` | api.cob; api-extra.cob; web/host.js | A, B | Manager aliases, resources, time, boss/golden, reset, inspection, timing/help. |
| `src/utils/domUtils.ts` | dom.cob; web/dom-bridge.js | C | Live queries, element identity, classes/content/listeners and visibility. |
| `src/utils/index.ts` | services.cob; async-services.cob; random.cob | S | JSON utilities, IDs/random, delay/cancel/attempt; representation limits disclosed. |
| `src/utils/logger.ts` | async-services.cob; web/host.js | S | Levels/context, groups/styles/table, timing/callback continuations. |
| `src/utils/mathUtils.ts` | services.cob; random.cob; runtime/utility.c | S | COBOL formulas with generic IEEE math primitives. |
| `src/utils/numberUtils.ts` | services.cob; format.cob; format-number.cob; runtime/format.c | S | Formatting variants, precision/error boundaries, decimal rounding. |
| `src/utils/saveManager.ts` | save.cob; api-storage.cob | I, A | Supplied snapshots persist/read without activating live state. |
| `src/utils/saveManagerTypes.ts` | SaveManager request/result contract; save-validation.cob | I, A | Type-only interfaces; no executable module behavior. |
| `src/utils/stateUtils.ts` | state-services.cob | S | Default state, utility-specific merge/validation/derived rules. |
| `src/utils/storageUtils.ts` | api-storage.cob; runtime/storage.c | A | Storage defaults, keys, size/availability, Unicode codec and errors. |
| `src/utils/timeUtils.ts` | services.cob; async-services.cob | S, B | Time formulas, throttle/debounce, receiver transport; native UTC locale adaptation. |
| `src/utils/tooltipUtils.ts` | tooltip.cob; web/dom-bridge.js | C | Delayed display/cancel, viewport placement, movement cleanup and release of owned handles. |
| `src/utils/validationUtils.ts` | services.cob; validation-services.cob | S | Predicates, named/callback schemas, save validation; unsupported input tags explicit. |
| `styles/styleLoader.ts` | dom.cob; web/dom-bridge.js | C | Stylesheet resolve/reject, fallback stylesheet and cleanup. |

The service contract documents owned JSON copies, callback/promise tokens, initialized-default timing, and explicit rejection of 141 non-JSON oracle inputs. The parity reference documents economic and persistence corrections. These are deliberate differences, not excluded failures silently counted as equivalent.

Loader adaptation uses bundled catalogs instead of fetching them again. Manager and component object identity is cached and tested in the API browser suite. Component constants, style dictionaries and independent GoldenBufo/BossFight lifecycle now have dedicated execution checks. The module count is an inventory, not exhaustive proof of every possible input or private helper.
