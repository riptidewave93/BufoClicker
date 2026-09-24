---
status: proposed
---

# Port the browser client to Perl and WebAssembly

## Context

BufoClicker is a static browser game. Its TypeScript client owns the economy,
DOM, timers and local saves. GitHub Pages hosts the built files under
`/BufoClicker/`. A server would change that deployment model.

This change proposes Perl as the application's implementation language. It
follows [the Rust/WASM proposal in PR #2](https://github.com/riptidewave93/BufoClicker/pull/2):
separate browser-independent rules from browser adapters, preserve the game and
its assets, and replace the application toolchain. The choice is about the
implementation language. It does not promise faster execution or smaller files.

## Decision

Run authored Perl game and UI code in [WebPerl](https://webperl.zero-g.net/), a
Perl interpreter compiled to WebAssembly. Use its supplied DOM bridge rather
than implementing a new binding layer or maintaining a Perl compiler fork.

- `lib/Bufo/Catalog.pm` validates game content and defines the boss ladder.
- `lib/Bufo/Game.pm` owns progression, economy and transient game state.
- `lib/Bufo/Save.pm` validates and migrates durable progress.
- `lib/Bufo/Model/` and `lib/Bufo/Managers/` retain the original reusable domain APIs.
- `ExplorerModel`, `Explorer`, `Enemies`, and `Combat` implement the complete Explorer subsystem.
- `lib/Bufo/Core/` and `lib/Bufo/Util/` provide events, state subscriptions, logging and utilities.
- `lib/Bufo/Browser/` provides components, DOM helpers, animations, UI management and developer tools.
- `web/app.pl` connects these services to browser events, fetching, storage and rendering.
- `scripts/build.pl` packages those modules with the static assets and runtime.

Game modules run under native Perl for tests and under Perl 5.28.1 in WebPerl.
They therefore use core modules and syntax supported by Perl 5.28. The browser
entry uses WebPerl's object wrappers for DOM methods and properties. Short
expressions obtain browser globals; game rules and UI callbacks remain Perl.

The production tree contains Perl, HTML, CSS, JSON, images, WASM and supplied
JavaScript runtime files. The two JavaScript files are WebPerl's bridge and its
Emscripten-generated loader. They are runtime dependencies, not an application
written in JavaScript and hidden in Perl strings.

Pin WebPerl to `v0.09-beta` and verify the release archive before extracting it:

```text
5f441249217e90ab378c666f473d4206ab4f44907f6bb0aa8d70834bc38c40dc
```

Apply Binaryen 108's `wasm-opt --trap-mode-clamp` to the extracted WASM binary.
The original runtime traps on `15000000000 * (1.6 ** 0)`: Perl probes an integer
conversion before falling back to floating point, and the old WASM conversion
traps outside its 32-bit range. The standard pass replaces trapping arithmetic
with guarded compatibility operations. It changes out-of-range conversions and
integer division/remainder trap behavior, so it is a semantic compatibility
step, not an optimization. Valid game inputs exclude division by zero.

The build also removes WebPerl's eager `beforeunload` shutdown hook, which ends
the interpreter before the app's `pagehide` and visibility handlers can save.
The removal checks for exactly one match in the verified source. Browser page
teardown reclaims the interpreter after those handlers finish. The Emscripten
loader remains unchanged. Browser checks cover large arithmetic and late-game
purchases; separate multiplication vectors were compared with native Perl.
The [Binaryen implementation](https://github.com/WebAssembly/binaryen/blob/version_108/src/passes/TrapMode.cpp)
defines the transform; the build pins Debian's `binaryen=108-1` package.

Ship WebPerl's Artistic and GPL license texts with the runtime. The build downloads
only this pinned archive and copies the required files. Runtime downloads and
`dist/` remain build artifacts.

## Persistence

Write the new schema to `bufo_idle_save_perl_v1`. This key differs from both the
legacy client's `bufo_idle_save` and the Rust proposal's `bufo_idle_save_v2`, so
independent ports cannot interpret each other's schema accidentally.

Read the Perl key first. Migrate the legacy key only when the Perl key is
absent. Preserve the original legacy value. A malformed Perl save blocks
automatic writes and exposes recovery controls; it never silently falls back
to older progress. Validate imports before changing storage or active state.
Reset and import replace the active game only after their storage write succeeds.

Preserve the legacy export encoding, Base64 of URI-encoded JSON. Reconstruct
costs, production and multipliers from durable purchases and achievements.
Temporary Golden frenzies, clicker-boss fights and click combos do not survive reloads.
Explorer data, equipment and upgrades persist. Its encounter/combat context remains
transient, matching the original save format; a restored fighting state cannot
resume that lost encounter. Generator enable flags and custom boosts persist. Rebuilding
an achievement effect must not award its one-time currency reward again.

## Behavior and scope

Preserve the existing content, prices, unlock conditions, click combo,
achievements, prestige, boss ladder, Golden Bufo rewards and offline limits.
Keep the existing artwork and responsive layout. Apply the requested dark
palette with white primary text. Keep rapid-click targets responsive and use
bounded effects rather than continuously repainting decoration.

Convert the entire original application, including Explorer/combat, exported
helpers, component APIs, and development tools. Explorer has no player panel,
but the original game initializes, ticks, saves, and exposes it. Preserve those
operations and saved progression. Do not treat lack of a visible control as
permission to remove code.

Keep original pure-model and manager algorithms separate where they differ.
Explorer's pure helper completes at 600 seconds of simulated progress; its
manager uses a 50-second distance counter and random encounters. Both use wall
clock duration when calculating completion rewards. Hidden pages pause progress
and healing, but that duration still includes the hidden interval. This is a
preserved source behavior, not a correction.

Use one browser-owned EventBus and provider-bound facade/state manager. A Game
instance owns its Explorer manager and transient combat context. Import, reset,
and prestige construct a candidate without live event listeners. After its save
succeeds, attach the shared services and replace the current Game. Facade calls
resolve that current instance, so developer tools cannot keep changing an old
Explorer after an import.

The fixed-step loop retains the original time-scale and FPS controls, one-second
accumulation cap, and 100 ms UI event interval. Browser state notifications during
simulation are flushed at that UI interval. Direct actions still notify immediately.
Tick payloads are constructed only when a subscriber needs them. Resume resets accumulation and
credits at most 12 hours of bulk production. Backward wall-clock adjustments
clamp to the last accepted game time, so returning to the tab cannot leave the
game paused. Negative or nonfinite timestamps remain invalid. Custom active generator boosts
remain effective while away; temporary Golden frenzies do not. The original
`enabled` generator flag gates purchases, not production from owned units.

An explicit development build exposes `window.debugTools`. Production omits
that binding. All callbacks and developer operations execute Perl. Export/import
and explicit save recovery are also available through the save tools.

## Alternatives

| Alternative | Reason not selected |
| --- | --- |
| Perl application server | Adds hosting infrastructure and changes the interaction model. |
| Perl-to-JavaScript compilation | Makes the shipped game a JavaScript program rather than executing Perl. |
| New Perl/Emscripten build and custom bindings | Adds a runtime maintenance project before the game can be evaluated. |
| Partial Perl rules with TypeScript UI | Retains two application languages and the Node build toolchain. |

## Consequences

The pinned runtime is a beta release from 2019. The project repository has
later commits, but this port does not treat those commits as a newer runtime
release. Its four runtime files total about 16 MB uncompressed, before the game
and image assets. Static hosting should compress them; cold startup must be
measured rather than inferred from a warm browser cache.

WebPerl retains Perl anonymous callbacks until they are unregistered. The UI
uses stable callbacks and delegated events, and removes temporary callbacks
when their work ends. The runtime's object bridge requires care around
JavaScript object lifetimes and unload behavior.

This proposal does not deploy or merge the port. The [migration description](../perl-wasm-migration.md)
and [verification record](../verification.md) describe the implementation and
its evidence. Browser coverage gaps remain explicit release considerations.
