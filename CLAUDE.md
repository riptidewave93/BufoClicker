# Working on BufoClicker

Read README.md for commands. Read docs/adr/0001-port-client-to-perl-and-webassembly.md
before changing runtime or hosting, and docs/perl-wasm-migration.md before changing
save or lifecycle behavior.

## Toolchain

Use Docker for project builds and tests. Native tests run on Perl 5.40.2;
the browser runtime is Perl 5.28.1. Keep application syntax and core dependencies
compatible with Perl 5.28. Keep JSON, CSS and artwork as static assets.

scripts/build.pl bundles custom packages in dependency order and registers them
in %INC before compiling consumers. Use methods or qualified calls between
custom modules; compile-time Exporter lists need different packaging.

## State and persistence

Game owns all rules and derived values. UI reads state and invokes methods.
Save validates external data before Game consumes it. Preserve original catalog
IDs and use the same formulas in native tests and browser execution.

New saves use bufo_idle_save_perl_v1. A present new key takes precedence over
legacy progress. An invalid new key blocks automatic fallback and writes.
Imports and reset write successfully before replacing active state. Preserve
the legacy key for recovery. Reconstruct effects once; never replay one-time
achievement currency rewards while loading.

Pause hides no elapsed production: save and pause on tab hide, credit the capped
permanent production gap on resume, then restart. Reload has a 60-second floor;
tab resume has none. The cap is 12 hours. Fights pause and frenzies stop while
hidden. Active fights and frenzies are not durable state.

## Browser work

Use WebPerl wrappers for browser APIs and stable named/delegated callbacks.
Anonymous callbacks passed into JavaScript need unregistering after use.
Every browser callback returns explicitly. Avoid testing JSObject truthiness;
use definedness because wrapper overloads differ from native Perl references.

Keep shop targets stable while counters update. Unaffordable controls remain
clickable and show feedback. Boss overlays consume ordinary clicks. Boss result
controls stay locked for 800ms and do not dismiss through their backdrop.

mobile.css remains the last base CSS import. Native CSS @imports must precede
style rules. Check element bounds at phone widths; page scrollWidth alone can
hide clipped controls. Preserve touch-action: manipulation and pinch zoom.

## Verification

Run native tests and browser flows for changes to game/UI integration. Capture
screenshots from the running output, not mockups. docs/parity.md maps behavior
to tests. docs/verification.md records browser versions, actual evidence and gaps.

Changes to catalog schemas must update validation and tests. A malformed catalog
must stop startup before any save write. Keep runtime download SHA256 checks.
