# Service dispatch contract

`BUFO-SERVICES(request, context, response)` takes pointers by value. `operation` uses the prefixes below; `args` is a positional array matching the original export. `now` is milliseconds. `random` is consumed through shared `BUFO-RANDOM`. Results use `result`; failures use `ok:false,error` and, for formatting range failures, `errorName`.

| Prefix | Operations |
| --- | --- |
| `number` | roundTo, clamp, calculateExponentialCost, formatNumber, formatNumberWithPrecision, getNumberFullName, formatDuration, calculatePercentage, formatPercentage, sum, average |
| `math` | randomInt, randomFloat, mapRange, inRange, lerp, inverseLerp, distance, angle, toDegrees, toRadians, pointFromAngle, smoothLerp, weightedRandom, factorial, chance, randomNormal |
| `time` | getCurrentTime, calculateElapsedTime, formatTimeAgo, calculateFPS, formatTimestamp, throttle, debounce; transport operations invoke, fire, cancel |
| `validation` | isValidNumber, isValidInteger, isPositiveNumber, isNonNegativeNumber, isInRange, isNonEmptyString, isValidArray, isNonEmptyArray, isValidDate, isValidObject, hasRequiredProperties, validateObject, isValidEmail, isValidUrl, createValidationResult, isOneOf, validateSaveData |
| `utils` | isDefined, isNullOrUndefined, defaultIfNullOrUndefined, generateId, deepClone, isPlainObject, safeJsonParse, safeJsonStringify, attempt, getRandomElement, shuffleArray, delay, cancellableDelay; transport operation attemptResult |
| `state` | createDefaultState, updateState, calculateDerivedState, validateState |
| `gameState` | DEFAULT_GAME_STATE, updateState, calculateDerivedState, validateState, getProductionStatistics, getResourceDisplay |
| `stateManager` | getState, setState, startBatch, endBatch, subscribe, unsubscribe, resetState, loadState; internal notify |
| `event` | on, off, emit, hasListeners, getListenerCount, clearEvent, clearAllEvents, getEventNames, setDebugMode, setExcludedEvents, addExcludedEvent, removeExcludedEvent; transport operation continue |
| `logger` | setLogLevel, getLogLevel, enableTimestamps, enableConsoleColors, enableGrouping, setContext, error, warn, log, info, debug, trace, group, groupCollapsed, groupEnd, table, styled, time, createLogger; transport operation timeResult |
| `data` | loadJsonData, loadMultipleJsonData, shouldLoadData, updateDataCacheVersion; transport operations complete, completeMultiple |

`context.runtime.defaultState` is the root's freshly initialized state template. Utility defaults clone it, update timestamps, and omit `resources.clickCount`. The static game-state default exposes the captured template. Source module-load timing that captured an empty catalog is replaced by explicit root initialization.

## Callbacks and continuations

Callbacks are `{ "$callback": "token" }`. Commands use `{kind:"callback",id:"token",args:[...]}`. The host executes commands and then dispatches the complete `continuation` request, preserving additional fields. The last callback supplies `callbackResult:{ok:true,value:...}` or `{ok:false,error:...}`. The final continuation result is the caller's return value.

Event emission returns one callback at a time. `event.continue` advances after the host runs that callback, so synchronous subscription changes affect the live array. Removing the current listener skips the next listener; adding a listener visits it in the same emission. Deleting an event detaches its list, and an emission already traversing that list completes it. Nested emissions have separate IDs. State subscriptions use the same mechanism with `serviceScope:"state"`; they remain separate from the public event bus and permit duplicate subscriptions. Callback exceptions do not stop notification traversal. Root mutations dispatch `stateManager.notify([oldState])` after replacing state; this notifies with the current state and captured old value, or defers notification during a batch.

`validation.validateObject` accepts callback tokens or named descriptors such as `"validation.isPositiveNumber"` and `{operation:"validation.isPositiveNumber"}`. Callback schemas use the same continuation protocol. Thrown validators fail the call. `utils.attempt` returns its fallback after a thrown callback. `logger.time` emits console timing commands around the callback and propagates callback failures.

## Timers and logger instances

`time.throttle` and `time.debounce` take `[callback,delay]` and return `{$callable:token}`. The host maps the returned function to `time.invoke([token,args,thisArg])`. Timer commands contain `kind:"timer"`, `token`, `generation`, and `delay`; expiration dispatches `time.fire([token,generation])`. Superseded generations cannot execute. The callback command carries `thisArg`, and the host uses it as the callback receiver. `timerCancel` commands clear the host timer.

`utils.delay([ms])` returns `{$promise:token}`. `utils.cancellableDelay([ms])` returns `{promise:{$promise:token},cancel:{$cancel:token}}`. The cancel function dispatches `time.cancel([token])`. Expiration emits `{kind:"resolve",id:token,value:{$oracle:"undefined"}}`. Cancellation leaves the promise unresolved, matching the source.

`logger.createLogger([context])` returns `{$logger:context}`. Its host proxy routes logger methods with `loggerContext` set to that context. A log command has `kind:"log"`, `method`, and `args` for the corresponding console method.

## Data loading

Fetch commands contain `kind:"fetch"`, `id`, `url`, and `timeout:10000`. The host forwards `commandResults:[{id,ok,status,statusText,text,error?}]` on the continuation. COBOL checks HTTP status, parses the response, and returns the value or the successful entries of a multiple-file request. Cache version operations use the original `<key>_version` storage keys.

## Value representation

JSON transport has no inherited prototypes, Date instances, functions, cycles, or shared object identity. Callback tokens represent callable functions. Public utility input `$oracle` tags are explicitly rejected with an unsupported-value error; the internal `time.invoke` transport retains encoded callback arguments and receivers, including undefined. Unsupported values are never interpreted as null. Return tags represent undefined and nonfinite numeric results: `{$oracle:"undefined"}` and `{$oracle:"number",value:"-0"|"Infinity"|"-Infinity"|"NaN"}`. State reads and loads use owned value copies, so mutating a prior request cannot mutate retained state. This deliberately changes `loadState` reference sharing.

The generic number formatter expands the shortest decimal that round-trips to the input double before decimal rounding. Native timestamps use UTC/en-US; browser timestamp and URL formatting use platform APIs. Native URL validation covers absolute scheme syntax and the source vectors; browser validation uses the complete URL constructor. DOM/animation/easing and storage utility operations are owned by the root application, outside this service module.

## Verification

`original-vectors.jsonl` preserves all 709 original-source records. `compare.py` executes 525 JSON utility/state calls. `scenarios.py` compares the original event, state-batch, throttle and debounce observations and checks promise, logger, callback validation and data commands. It also verifies explicit rejection of all 141 tagged input cases. The two formatting RangeError vectors are tested separately. Four default-construction records use the explicit initialized-template adaptation; 30 easing records belong to the UI implementation. The source's load-reference scenario is adapted to owned copies.

Run `tests/services/run.sh` for native tests, `tests/services/asan.sh` after the native build for memory checks, and `tests/services/wasm.sh` for the same checks through the WebAssembly ABI. All scripts run inside `bufoclicker-cobol-tools`.

Finite numeric boundary provenance and exact comparison coverage are documented in [EVIDENCE.md](EVIDENCE.md). The canonical native, sanitizer and WASM runners include all 110 source-generated cases.
