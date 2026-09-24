# Verification record

The port was exercised against its built static site, including the production
Docker image. The checks below distinguish native game rules, browser wiring
and visual inspection. No upstream deployment was changed.

## Reproduce

```sh
docker compose run --build --rm test
docker compose --profile browser run --build --rm browser-test
docker compose run --rm build
docker compose --profile browser run --rm browser-ui
docker compose --profile browser down
```

On Linux, set `BUFO_UID=$(id -u) BUFO_GID=$(id -g)` before the browser command
when your user differs from the default UID/GID 1000. The bind-mounted
`artifacts/` directory must be writable. CI sets these values automatically.

The browser runner uses Perl's core HTTP and JSON modules to drive an isolated
Selenium Chromium container. It visits both `/` and `/BufoClicker/`, writes
screenshots, and records runtime download measurements. It does not need Node
or access to a personal browser profile. Fixture injection calls the same Perl
game API used by the app; normal actions use browser controls.

## Executed checks

| Layer | Result and scope |
| --- | --- |
| Native Perl | 763 assertions passed across 17 files, including original-source comparisons, Explorer/combat, service APIs, managers, saves, and game rules. |
| Production Chromium 138.0.7204.183 | 96 assertions passed through `scripts/browser-test.pl` and its fault helper. |
| Development Chromium 138.0.7204.183 | 88 assertions passed through `scripts/browser-ui.pl` on both hosting paths, with no browser errors. |
| WebPerl utility adapters | Six independent checks passed for shared services, Unicode saves, dates and URLs, timers, asynchronous loading, and uncaught errors. [Report](verification-data/utilities.json). |
| Firefox 146.0.1 | Both routes loaded; clicking, purchase, reload and Stats passed with no page errors. [Report](verification-data/firefox.json). |
| Responsive layout | Chromium and Firefox controls fit widths 375, 390, 412 and 768 px; Firefox inspected controls met the 44 px target. |
| Build and workflows | Production Docker build, Compose configuration and actionlint 1.7.7 passed. |

The repeatable Chromium suite covers clicks, unaffordable purchases, generators,
upgrades, Stats, export/import, bosses and result guards, Golden Bufo collection,
prestige, large arithmetic, late-game purchase/reload and pagehide persistence.
It also checks legacy migration without altering the source, current-key
precedence, corrupt-save recovery, explicit reset and storage-failure atomicity
for import, reset and prestige.

Fault injection blocks a required catalog download and verifies that startup
stops without touching either save key. A simulated 24-hour hidden interval
credits exactly 12 hours of permanent production and preserves boss fight health,
fight time, and Explorer state. This is a controlled lifecycle check, not an actual 24-hour browser
suspension test. Separate local checks exercised missing, malformed and
semantically invalid catalogs before the committed fault runner was assembled.

The [source operation map](source-map.md) accounts for all 64 original modules.
It maps 640 parsed declarations plus default exports, initialization, and nested
developer commands to 684 implementation entries. A mapping is not an assertion
that each operation has an independent test. The native comparisons execute
captured outputs from the original TypeScript, including 57 Explorer/combat
cases, 78 utility cases, and 16 model comparisons. Fixture provenance records
the original commit and source hashes.

## Failures that drove fixes

| Reproduced failure | Fix and passing evidence |
| --- | --- |
| Full conversion saturated Firefox's frame loop: a simulation step took 113 ms and a 60-step catch-up frame took 6.8 seconds. | Lazy event snapshots and batched browser state notifications remove redundant work. The same 60-step frame fell to 357 ms in Firefox and 57 ms in Chromium, with no runtime errors. [Measurements](verification-data/frame-cost.json). Normal live-loop clicks then completed in 195 ms Firefox and 52 ms Chromium. [Click samples](verification-data/click-latency.json). |
| Cancelling a browser timer retained its callback and captured objects. | A weak-reference browser check failed on both routes before cleanup. Both routes now pass the object-release check in the 88-assertion component suite. |
| Replacing a state snapshot could double a permanent bonus or retain the previous state's factor. | Thirteen assertions failed before the fix. All 15 state-replacement checks now pass, including custom multipliers and repeated updates. |
| A backward wall-clock change could leave the game paused after tab return. | Fifteen assertions failed before the fix. All 37 clock regression assertions now pass; valid game times clamp to the last accepted time without inventing offline income. |
| Achievement notifications intercepted a visible boss button. | Informational achievement toasts allow pointer events to reach the underlying controls. The production runner exercises the formerly blocked click. |
| The first Perl draft dropped Explorer during save migration and omitted its manager. | Two scope checks failed on that draft and pass after the complete conversion. Explorer, enemies, combat, and durable progress now have native and browser checks. |
| Manager replacement, custom upgrades, event payloads, and combined effects broke original API contracts. | Seven contract assertions failed before fixes. All nine assertions in `t/manager-contract.t` now pass, including save round trips and overflow rejection. |
| Destroyed components left JavaScript listeners attached after their Perl callbacks were unregistered. | Retain the exact bridge function for listener removal, with shared-callback ownership. The repeated component suite passes all 88 checks with no browser errors. |
| Native-only imports and JSON scalar encoding failed under WebPerl. | Browser adapters avoid unavailable eager imports, and scalar encoding explicitly permits non-reference values. Actual WebPerl utility and component runs verify these paths. |
| Unmodified WebPerl trapped on `15000000000 * (1.6 ** 0)`. | Pinned Binaryen compatibility pass; native/browser multiplication vectors through `1e100` agreed. The committed browser suite checks the original expression and purchase/reload with a `1e20` balance. |
| WebPerl ended the interpreter before pagehide, producing unload errors. | Remove the pinned bridge's eager shutdown hook. A click survives refresh without manual Save, and normal flows report no browser errors. |
| Replacing `dist/` invalidated the running preview's directory bind mount and returned HTTP 404. | Keep the output directory and replace its children. Rebuilding the mounted preview returned HTTP 200. |
| A number-format comparison disagreed with original comma grouping below one million. | Match the original threshold and requested decimals; native formatting tests and UI comparison passed. |
| The boss invitation intercepted a bottom-aligned Reset control in short windows. | Reserve scroll space while the invitation is visible. Direct pointer clicks opened Reset in both tested browsers and sizes. |
| Opening `/BufoClicker` without a slash dropped the local preview port during redirect. | Use a relative redirect. HTTP checks retain ports 9000 and 8080; the browser runner checks the redirect header. |

## Independent review

The native/domain review approved the fixes after two completed rounds. Its
first request timed out; the permitted retry returned the findings below.
The follow-up reviewed code but could not execute tests. Test results in this
record come from the separate local executions.

| Finding | Disposition |
| --- | --- |
| N1: backward clocks could leave gameplay paused | Fixed. The 37 clock regression checks pass. |
| N2: replacement state reused old permanent multiplier caches | Reproduced and fixed. The 15 state-replacement checks pass. |
| U1: cancelled browser timers retained closures | Fixed after UI review. The browser weak-reference check verifies object release. |
| U2: a rejected click can still display zero-gain feedback | Non-blocking cosmetic behavior retained. Gameplay guards still reject the action. |

The browser/build review approved its scoped code in one round. It checked
components, callbacks, application wiring, static packaging, browser runners,
Compose, CI, and CSS. Subsequent timer cleanup and notification pointer changes
were verified by execution but were not resubmitted for independent review.
The generated inventory, oracle fixtures, screenshots, and prose were outside
these code-review scopes. All requested code paths were included; none were
skipped by the review tool.

The native follow-up also noted that Explorer start writes the supplied clock
directly, rollback windows can extend a bounded click combo, and a hypothetical
replacement missing multiplier fields would need validation. These were
non-blocking observations. Current replacement callers supply those fields.

## Runtime cost

The [recorded browser measurements](verification-data/runtime-metrics.json)
come from local Docker networking with nginx gzip enabled. The four runtime
files total **16,073,455 bytes decoded** and **4,593,280 bytes compressed**.
Artwork, catalogs, styles and the Perl application add to those totals.

The final run records readiness observations for both hosting paths in the linked JSON. These are
single local samples and upper bounds observed by the polling runner. They are
not public-network, cold-device, mobile or comparative performance benchmarks.
The prefix run may benefit from browser runtime caches. The release archive
and build cache are separate from browser download costs.

## Screenshots

Screenshots show the implemented client with deterministic seeded progress.
They preserve the original game artwork and layout with the dark palette.

![Desktop game with generators and upgrades](screenshots/desktop.png)

| Mobile game | Mobile achievements |
| --- | --- |
| ![Mobile game](screenshots/mobile.png) | ![Mobile achievements](screenshots/achievements-mobile.png) |

![Boss fight](screenshots/boss.png)

## Remaining coverage

Safari, iOS, Android devices, touch hardware, prolonged play, memory growth,
real background suspension and poor-network startup were not validated.
Firefox received the smoke and responsive checks above, not the full Chromium
fault matrix. GitHub Pages path behavior was tested locally; the proposed
workflow has not deployed this branch upstream.

The pinned WebPerl beta and its documented compatibility adjustments remain
maintenance risks. The [ADR](adr/0001-port-client-to-perl-and-webassembly.md)
records them explicitly. Screenshot quality does not resolve those runtime
or browser coverage limits.
