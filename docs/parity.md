# Gameplay and save compatibility

The Perl port preserves the clicker game, its content, and static hosting. It
follows the scope of [Rust proposal PR #2](https://github.com/riptidewave93/BufoClicker/pull/2),
including removal of the retired Explorer simulation. This matrix compares the
original TypeScript client with the Perl implementation. The
[verification record](verification.md) records completed executions, browser
coverage, measurements, and screenshots.

## Gameplay

| Behavior in the original client | Perl implementation | Evidence |
| --- | --- | --- |
| 14 generator tiers, 91 upgrades, and 50 achievements | Original JSON catalogs and IDs remain unchanged. Catalog validation rejects unknown conditions, effects, and references. | [`t/catalog.t`](../t/catalog.t) checks counts, boss definitions, numeric-leading IDs, and invalid catalogs. |
| Main clicks earn click power and count once | `Game::click` updates currency and the shared click counter. The first achievement affects subsequent clicks. | [`t/game.t`](../t/game.t) checks first-click rewards, counters, and reconstruction. [`scripts/browser-test.pl`](../scripts/browser-test.pl) drives the visible click target. |
| Clicks less than 500 ms apart build a combo | The combo adds 5% per step, up to 50%. A gap of 500 ms resets it. | Engine tests check the cap and exact reset boundary. |
| Generator prices increase geometrically | Next-unit cost is rounded up. Bulk cost starts with that rounded price. Purchases reduce current currency without reducing run-total currency. | Engine tests check single, bulk, and Max purchases, price rounding, locked tiers, and insufficient funds. |
| Upgrades require currency and their unlock conditions | Generator counts, total currency, and prerequisite upgrades remain enforced. Each purchase applies once. | Engine tests cover prerequisite rejection, unlock after purchase, and duplicate-purchase atomicity. |
| Production and click bonuses have separate effects | Click upgrades multiply clicks. Global production upgrades multiply generators. Generator upgrades affect their target tier. | Engine tests check each path separately. |
| Achievements grant permanent effects or one-time currency | Unlocks and custom-event flags persist. New unlocks emit notifications. Currency rewards apply only when the achievement is first earned. | Engine and save tests check retained effects, repeated loads, console rewards, and custom-event flags. |
| Prestige starts at 1 billion run-total bufos | Points equal `floor(sqrt(totalBufos / 1e9))`. Each lifetime point adds 10% to production and click power. | Engine tests check the curve, reset fields, retained clicks, and retained achievement effects. |
| Seven bosses form an ordered ladder | IDs, thresholds, baseline health, and artwork remain unchanged. Bosses must be defeated in order. | Catalog tests compare all seven health values. Engine tests exercise every boss at 0, 100, 700, and 5,000 prestige points. |
| Boss health scales with permanent player bonuses | Starting health includes prestige and boss multipliers. Hits use current click power without the click combo. Click Frenzy remains an advantage. | Engine tests verify passive-power normalization within health rounding and frenzy-assisted victories. |
| Boss fights last 30 seconds | Hits count as clicks but earn no ordinary click income. Timeout clears current currency. Retreat has no penalty. Hidden tabs preserve remaining fight time. | Engine tests cover damage, counters, retreat, loss, pause, and resume. Browser tests exercise the overlay and result modal. |
| Boss rewards survive prestige | Each defeat adds 25% to production and click power. Prestige banks current defeats and reopens the ladder. | Engine tests check lifetime defeats and the cleared current ladder. Browser tests perform prestige through the dialog. |
| Golden Bufo has three weighted outcomes | Production frenzy has a 50% chance, Lucky 30%, and click frenzy 20%. Production frenzy lasts 30 seconds at ×7. Click frenzy lasts 15 seconds at ×7. | Engine tests check probability boundaries, duration refresh, expiry, and separate multipliers. Browser tests collect the visible Golden Bufo. |
| Lucky grants immediate currency | The reward is `floor(min(bank × 0.15, productionPerSecond × 1200) + 13)`. | Engine tests cover a funded game and zero production. |
| Idle production continues across browser absences | Reload credit ignores gaps under one minute. Tab return includes shorter gaps. Both cap credited time at 12 hours and use permanent production. | Engine and save tests check the cap and restored rate. Browser fault checks simulate a 24-hour hidden period during a boss fight. |
| Number labels use fixed English grouping | Prices below one million use grouped whole numbers. Larger values use magnitude suffixes, with bounded extreme displays. | [`t/number.t`](../t/number.t) checks grouping, precision, rounding, and the display cap. |

## Saves and lifecycle

| Contract | Perl behavior | Evidence |
| --- | --- | --- |
| Existing browser progress remains recoverable | Legacy `bufo_idle_save` is read only when the Perl key is absent. Migration leaves the original value untouched. | [`t/save.t`](../t/save.t) and the browser migration checks use a captured legacy fixture. |
| The new save has an independent format | `bufo_idle_save_perl_v1` holds the versioned Perl schema. A valid Perl save takes precedence over the legacy key. | Native and browser tests exercise both keys together. |
| A corrupt save does not disappear | Invalid current data blocks gameplay and automatic writes until explicit recovery. It does not trigger a legacy fallback. | [`scripts/browser-faults.pl`](../scripts/browser-faults.pl) records reads and writes during recovery. |
| Import and reset preserve progress if storage fails | The browser validates a candidate game and writes its save before replacing the active game. Prestige uses the same replacement rule. | Browser fault checks inject storage quota failures and compare active state and both stored keys. |
| Export strings remain compatible | Export uses Base64 of URI-encoded JSON. Import also accepts raw JSON. Save tools now expose these operations in the UI. | Browser tests export, decode, import, and reject malformed input. |
| Durable state restores once | Currency, ownership, purchases, achievements, custom events, prestige, boss history, and settings persist. Derived prices and multipliers are rebuilt. | Native save round trips compare permanent production and click power. |
| Temporary state does not persist | Saves exclude active fights, click combos, Golden Bufo spawns, frenzy deadlines, and notification queues. | Save tests verify transient exclusion. Engine tests verify a fresh transient state after reconstruction. |
| Purchases and lifecycle transitions save progress | Manual Save, purchases, autosave, page hide, and tab hide use the Perl storage adapter. | Browser tests refresh after interaction and exercise lifecycle writes. |

## Deliberate changes

The retired Explorer subsystem had no player UI and was superseded by clicker
bosses. Its combat simulation, models, and public methods are removed, as in
PR #2. Legacy `explorer` fields are accepted and ignored. The port does not add
an Explorer interface or convert that saved progression into clicker rewards.

The port corrects three existing economy defects. Reloads no longer replay
one-time achievement currency rewards. Prestige retains the effects of the
achievements it retains. Max purchases verify the rounded actual price, so a
logarithmic estimate cannot authorize an unaffordable purchase. Catalog prices,
production, rewards, and unlock thresholds remain unchanged.

Export, import, and save recovery gain visible controls. The interface retains
the existing artwork and layout, with a dark palette and white primary text.

## Execution boundaries

[`lib/Bufo/Game.pm`](../lib/Bufo/Game.pm) owns game rules and receives time as an
argument. [`lib/Bufo/Catalog.pm`](../lib/Bufo/Catalog.pm) validates content.
[`lib/Bufo/Save.pm`](../lib/Bufo/Save.pm) validates durable state.
[`web/app.pl`](../web/app.pl) owns browser events, rendering, and storage.
The [migration description](perl-wasm-migration.md) and
[ADR](adr/0001-port-client-to-perl-and-webassembly.md) explain those boundaries
and the pinned WebPerl runtime.

Native tests run with `docker compose run --rm test`. The browser suite runs
with `docker compose --profile browser run --rm browser-test` against the built
site. Browser checks cover both `/` and `/BufoClicker/`; the verification record
identifies the browsers actually exercised.

The tests prove rules and browser interactions. They do not establish human
boss difficulty, touch ergonomics on physical phones, or long-term economy
balance. Screenshots document the rendered interface. They do not replace
those checks.
