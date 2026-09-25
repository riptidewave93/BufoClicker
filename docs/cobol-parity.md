# COBOL parity reference

The comparison baseline is TypeScript commit `fe02bde429b650d32591f22a824f7dad8a0d4dd9`. Tests execute the COBOL implementation and compare source-derived values or observable scenarios. Passing these checks establishes the covered behavior, not identity for every possible JavaScript input.

## Coverage

| Surface | COBOL implementation | Contract and evidence |
| --- | --- | --- |
| Clicks, production, 14 generators, 91 upgrades, 50 achievements, prestige, Golden Bufo, seven bosses | `game`, `generators`, `upgrades`, `achievements`, `prestige`, `golden`, `bosses` | [Domain operations](../tests/domain/OPERATIONS.md), [domain evidence](../tests/domain/EVIDENCE.md) |
| Explorer, enemies, rewards, equipment, manual and automatic combat | `explorer`, `explorer-models`, `enemies`, `combat` | [Explorer operations](../tests/explorer/OPERATIONS.md), [Explorer evidence](../tests/explorer/EVIDENCE.md) |
| Number, math, validation, state, events, timers, logging, data loading | `services` and service modules | [Service operations](../tests/services/OPERATIONS.md) |
| Components, containers, templates, DOM, animation, tooltips, styles | `components`, `component-render`, `templates`, `dom`, `animation`, `tooltip` | [Component operations](../tests/components/OPERATIONS.md) |
| Game facade, managers, developer tools, storage and UI APIs | `api` modules | [Public API operations](../tests/api/OPERATIONS.md) |
| Save migration, import, reset, offline credit, write failures | `save`, `save-validation` | [Transaction checks](../tests/integration/transactions.py), [persistence evidence](../tests/integration/EVIDENCE.md) |
| Browser coordinator and player interface | `app`, `actions`, `presentation`, `ui` | [Browser checks](../tests/browser/check.cjs) |

The shipped generator, upgrade, and achievement catalogs and image assets are retained. Boss and enemy definitions move from TypeScript constants into JSON catalogs. Explorer remains implemented even though the original player interface does not expose it.

## Preserved behavior

The checks cover click reward ordering, rapid clicks, rounded bulk prices and Max purchases, unlock prerequisites, manager-versus-facade spending, disabled-owned generator production, achievement bonuses, prestige carryover, boss timing and results, Golden Bufo probabilities and frenzy expiry, and Explorer encounter and combat formulas.

Persistence checks cover the legacy codec, corrupt-current-key precedence, atomic import and reset, permanent derived values, failed writes, one-time offline credit, reload and resume thresholds, and the 12-hour cap. Component and browser checks cover live DOM identity, listener cleanup, timer continuation, tooltips, dialogs, and responsive layout.

## Intentional differences

- The interface uses dark backgrounds and white primary text, with visible save import and export controls.
- Current saves use a separate COBOL schema and key. Invalid current data pauses progress instead of silently loading an older snapshot.
- Restoring achievements does not replay one-time currency bonuses. Permanent multiplier restoration retains the fix already present in the baseline.
- Saves and elapsed production rebuild permanent caches. Stopping a frenzy removes its cached production effect.
- Rounded Max purchases must fit the actual charged price. Public purchase facades enforce prerequisites.
- State crosses the browser boundary as owned values. Mutating a previously returned object does not mutate retained state. Arbitrary cycles, inherited properties, and object identity are not transported.
- Callback, DOM element, component, promise, and manager references have explicit transport tokens. Native DOM tests use supplied query fixtures; real browser tests exercise the DOM adapter.
- Removed listeners release their callback closures after the last owner disappears. Reusable throttle and debounce records remain allocated until the runtime resets, even if the JavaScript wrapper is discarded.
- Achievement counters and custom-event flags live in canonical state. A direct developer setter can therefore appear in a state snapshot earlier than the original private manager cache did.
- Native date formatting uses UTC and en-US. Browser date formatting uses platform locale operations.

## Runtime evidence

A native test exposed leaking generated COBOL function-result allocations. Generic C bindings now reuse caller-owned result fields, with nested string and loop checks under sanitizers. A separate round-trip check caught cJSON losing one binary unit when printing large numbers; its existing 17-digit fallback now uses an exact comparison.

WebAssembly service vectors exposed a libcob cross-configuration error that truncated large integer constants. The corrected target configuration passes the same vectors as native execution. Firefox also exposed expensive scans of padded 32 KiB string results. Compact function-result fields retain COBOL assignment semantics and avoid those scans. Compiler versions, target widths, ownership rules, and configuration changes are recorded in [the ABI reference](../vendor/ABI.md).

Browser screenshots and the final execution report are produced by the committed browser check. The PR includes selected screenshots from the tested build. WebKit on Linux is a browser-engine check, not a claim that physical iPhone Safari was tested.
