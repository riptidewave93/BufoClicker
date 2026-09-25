# Explorer operations

All modules take borrowed request, context and response JSON pointers by value. Requests contain `operation`, `args`, `now` and a shared deterministic `random` sequence. Successful calls set `ok: true` and the source return value under `result`; void methods omit `result`. Errors set `ok: false, error`.

`BUFO-EXPLORER` owns `state.explorer` and `runtime.explorer`. It never spends or credits the main bank. Root charges the returned stat upgrade cost once for the game facade. `init` creates defaults with the current context time. `rebuild` clears transient state without events. `reset` clears transient state and emits `EXPLORER_UPDATED` without replacing durable Explorer data.

| Manager operation | Arguments | Result |
| --- | --- | --- |
| getExplorer | none | ExplorerData |
| getCurrentEnemy | none | Enemy or null |
| getCurrentCombat | none | CombatState or null |
| update | delta, seconds | ExplorationResult or null |
| startExploration | area | boolean |
| performCombatAction | action | boolean |
| autoResolveCombat | none | boolean |
| upgradeExplorerStat | statName, availableBufos | success, cost |
| getExplorerStats | none | powerRating, dps, survivalTime, healthPercent |
| getAvailableAreas | none | array of eight area names |

`model.*` operations use supplied values and do not write context state. `BUFO-EXPLORER-MODELS` implements them.

| Pure operation, prefixed model. | Arguments |
| --- | --- |
| DEFAULT_EXPLORER_DATA, ExplorerState | none |
| calculateDPS, calculateSurvivalTime, calculatePowerRating | explorer |
| recalculateExplorerStats, canLevelUp, levelUpExplorer, startCombat | explorer |
| calculateAreaEffectiveness | explorer, areaLevel |
| calculateStatUpgradeCost | statLevel, baseCost optional, default 50 |
| upgradeExplorerStat | explorer, statName, bufos |
| startExploration | explorer, area |
| calculateExplorationResult | explorer, elapsedSeconds |
| completeExploration | explorer, result |
| restExplorer | explorer, seconds |
| getAreaLevel | area |
| updateExplorer | explorer, deltaSeconds |

`BUFO-ENEMIES` provides `enemy.BASE_DROP_ITEMS`, `enemy.INITIAL_ENEMY_TEMPLATES`, `enemy.EnemyType`, `enemy.generateEnemy(area,distanceMultiplier,areaLevel)`, `enemy.calculateEnemyRewards(enemy)` and `enemy.calculateRelativeDifficulty(enemyStats,explorerStats)`. Catalog constants are exact extracted source values at `catalog.enemies`.

`BUFO-COMBAT` provides `combat.CombatStatus`, `combat.CombatActionType`, `combat.initializeCombat(explorer,enemy)`, `combat.executeCombatAction(state,action)`, and `combat.simulateCombat(explorer,enemy,simulationRounds=10)`.

Source interfaces map to JSON objects with their original field names. Source singleton getters map to the root's stable manager command facade. Equipment remains durable. Distance, current enemy and combat are transient. Combat results use deep value copies, including combatLog; the source shares and mutates the input log array. Returned values preserve its log content and ordering without reproducing reference aliasing.

Internal save operations: `validate {explorer}` returns a boolean without changing context. `normalize {explorer, strict}` returns a cloned record or an error. Strict mode requires every field. Legacy mode fills only missing fields, including missing stat/equipment members; present invalid values fail validation. Validation enforces number types, finite parser inputs, nonnegative values, integer levels/counters, health at most maximum, progress 0..100, valid states and equipment strings/null. Levels are 1..1000, counters/timestamps at most 9e15, ordinary amounts at most 1e100 and next-level experience at most 1e200.

A normalized saved `fighting` state has no restorable transient opponent. It uses the source combat-end thresholds: injured below 20% health, resting below 50%, exploring otherwise. Its state start time becomes the accepted current time. Equipment and all other valid durable data remain intact.

Numeric comparisons use the generic exact IEEE double comparison helper at funds, experience, health and random boundaries. Powers use the generic libm helper because the WASM GnuCOBOL decimal exponent implementation differed from native execution. Formulas and thresholds remain in COBOL.
