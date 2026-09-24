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
- `web/app.pl` owns the DOM, browser events, fetch, storage and notifications.
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
Temporary frenzies, fights and click combos do not survive reloads. Rebuilding
an achievement effect must not award its one-time currency reward again.

## Behavior and scope

Preserve the existing content, prices, unlock conditions, click combo,
achievements, prestige, boss ladder, Golden Bufo rewards and offline limits.
Keep the existing artwork and responsive layout. Apply the requested dark
palette with white primary text. Keep rapid-click targets responsive and use
bounded effects rather than continuously repainting decoration.

As in PR #2, omit the retired Explorer/RPG subsystem, which has no player UI.
Accept its legacy save field without restoring its simulation. Export/import
and explicit save recovery become visible through the save tools.

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
