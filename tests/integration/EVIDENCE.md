# Persistence verification

Run these scripts inside `bufoclicker-cobol-tools`:

```sh
bash tests/integration/run.sh
bash tests/integration/asan.sh
```

The test executable links the real coordinator, persistence validator, game managers, Explorer, and presentation module. Browser UI, public facade, and generic service boundaries use explicit test stubs. Storage reads and writes use the runtime's actual storage abstraction and fault injection.

`verify.py` covers first save, clicks, import/export, atomic storage failures, corrupt-save recovery, and reload. `transactions.py` covers:

- Failed load retains both stored bytes and the validated uncredited snapshot. Retrying credits once.
- Offline load has a 60-second minimum and 12-hour cap. Resume has no minimum.
- Repeated retries and visibility changes preserve the pending source. Duplicate hidden transitions preserve the original interval; recovery while visible restarts simulation.
- Legacy records cannot fill missing required fields from defaults. Numeric consistency and integer checks use exact comparisons. Invalid achievement maps and duplicate boost IDs are rejected.
- Candidate bounds are checked after elapsed credit. Failed initial writes can recover by retry.
- Resume preserves an active Explorer encounter while the durable copy removes transient combat state.
- Saves strip frenzy from their copy, and repeated achievement reloads do not replay one-time currency rewards.
- Prestige updates storage before replacing live state and publishing prestige events.
- SaveManager supplied saves, reads, imports, exports, and clear operations preserve the running game state.
- Explicit save clearing removes both current and legacy records without clearing unrelated storage. The migrated-save check failed when legacy fallback revived cleared progress and passed after both records were removed.
- Failed autosaves wait 60 seconds before another automatic attempt. A fault-injection check failed when every frame retried the write and passed after the coordinator tracked the last attempt.

Before the persistence fixes, failed initial credit left a fresh zero-currency state instead of the saved uncredited state. Legacy partial validation accepted omitted currency after merging defaults. The focused transaction checks exposed these failures before the changes and passed afterward. The original coordinator checks also remain in the suite.

Native AddressSanitizer and LeakSanitizer run both suites. Generic services have their own source-oracle and WebAssembly checks documented in [the service contract](../services/OPERATIONS.md).
