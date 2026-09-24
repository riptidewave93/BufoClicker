# Original source to Perl map

This inventory maps all 64 original TypeScript modules at `fc7f61a` to concrete Perl owners. The original export/method inventory contains 640 declarations. Two default export objects, the application entry point, and 41 named debug-object operations are included separately. No original module is excluded because its functions were hidden from the visible interface.

[Machine-readable inventory](source-map.json) records each declaration, implementation file, callable or data contract, and related checks. Method names retain their original camelCase spelling unless the table names an adapter. `Package->method` identifies an owner instance method or class constructor; `Package::function` identifies a standalone function. Type-only declarations map to argument, state, result, and callback contracts; they do not require empty Perl classes.

A test-file reference identifies relevant execution evidence, not a claim that every declaration has a separate assertion. Native tests cover game rules and services. Browser checks cover DOM operations and the deployed WebPerl runtime. See [verification](verification.md) for executed commands and results.

Owner-bound `getInstance` and `get*Manager` adapters resolve the active game or shared browser service. Barrel exports resolve to the actual implementations listed here. They do not create a second game, save writer, event bus, or timer.

## `src/core/eventBus.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `EventCallback` | `on(event, coderef) and emit(event, payload) callback contract` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | data contract |
| `EventBus.getInstance` | `Bufo::Core::EventBus->getInstance` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.setDebugMode` | `Bufo::Core::EventBus->setDebugMode` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.on` | `Bufo::Core::EventBus->on` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.setExcludedEvents` | `Bufo::Core::EventBus->setExcludedEvents` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.addExcludedEvent` | `Bufo::Core::EventBus->addExcludedEvent` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.removeExcludedEvent` | `Bufo::Core::EventBus->removeExcludedEvent` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.off` | `Bufo::Core::EventBus->off` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.emit` | `Bufo::Core::EventBus->emit` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.hasListeners` | `Bufo::Core::EventBus->hasListeners` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.getListenerCount` | `Bufo::Core::EventBus->getListenerCount` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.clearEvent` | `Bufo::Core::EventBus->clearEvent` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.clearAllEvents` | `Bufo::Core::EventBus->clearAllEvents` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `EventBus.getEventNames` | `Bufo::Core::EventBus->getEventNames` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |
| `getEventBus` | `Bufo::Core::EventBus->getEventBus` in [lib/Bufo/Core/EventBus.pm](../lib/Bufo/Core/EventBus.pm) | callable |

Related checks: [t/core.t](../t/core.t), [t/core_services.t](../t/core_services.t).

## `src/core/eventTypes.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `RESOURCE_ADDED` | `Bufo::Core::Events::RESOURCE_ADDED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `RESOURCE_SPENT` | `Bufo::Core::Events::RESOURCE_SPENT()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GENERATOR_PURCHASED` | `Bufo::Core::Events::GENERATOR_PURCHASED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GENERATOR_UNLOCKED` | `Bufo::Core::Events::GENERATOR_UNLOCKED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GENERATOR_PRODUCTION_UPDATED` | `Bufo::Core::Events::GENERATOR_PRODUCTION_UPDATED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `EXPLORATION_STARTED` | `Bufo::Core::Events::EXPLORATION_STARTED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `EXPLORATION_COMPLETED` | `Bufo::Core::Events::EXPLORATION_COMPLETED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `EXPLORER_LEVEL_UP` | `Bufo::Core::Events::EXPLORER_LEVEL_UP()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `EXPLORER_STAT_UPGRADED` | `Bufo::Core::Events::EXPLORER_STAT_UPGRADED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `EXPLORER_STATE_CHANGED` | `Bufo::Core::Events::EXPLORER_STATE_CHANGED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UPGRADE_PURCHASED` | `Bufo::Core::Events::UPGRADE_PURCHASED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UPGRADES_AVAILABLE` | `Bufo::Core::Events::UPGRADES_AVAILABLE()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `PRESTIGE_TRANSCENDED` | `Bufo::Core::Events::PRESTIGE_TRANSCENDED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GOLDEN_BUFO_SPAWNED` | `Bufo::Core::Events::GOLDEN_BUFO_SPAWNED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GOLDEN_BUFO_EXPIRED` | `Bufo::Core::Events::GOLDEN_BUFO_EXPIRED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GOLDEN_BUFO_COLLECTED` | `Bufo::Core::Events::GOLDEN_BUFO_COLLECTED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_AVAILABLE` | `Bufo::Core::Events::BOSS_AVAILABLE()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_FIGHT_STARTED` | `Bufo::Core::Events::BOSS_FIGHT_STARTED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_DAMAGED` | `Bufo::Core::Events::BOSS_DAMAGED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_TICK` | `Bufo::Core::Events::BOSS_TICK()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_DEFEATED` | `Bufo::Core::Events::BOSS_DEFEATED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_FIGHT_LOST` | `Bufo::Core::Events::BOSS_FIGHT_LOST()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `BOSS_FIGHT_RETREATED` | `Bufo::Core::Events::BOSS_FIGHT_RETREATED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `ACHIEVEMENT_UNLOCKED` | `Bufo::Core::Events::ACHIEVEMENT_UNLOCKED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `ACHIEVEMENTS_UPDATED` | `Bufo::Core::Events::ACHIEVEMENTS_UPDATED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_TICK` | `Bufo::Core::Events::GAME_TICK()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_SAVED` | `Bufo::Core::Events::GAME_SAVED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_LOADED` | `Bufo::Core::Events::GAME_LOADED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_RESET` | `Bufo::Core::Events::GAME_RESET()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_STARTED` | `Bufo::Core::Events::GAME_STARTED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `GAME_PAUSED` | `Bufo::Core::Events::GAME_PAUSED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UI_TAB_CHANGED` | `Bufo::Core::Events::UI_TAB_CHANGED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UI_SETTINGS_TOGGLED` | `Bufo::Core::Events::UI_SETTINGS_TOGGLED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UI_MODAL_OPENED` | `Bufo::Core::Events::UI_MODAL_OPENED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `UI_MODAL_CLOSED` | `Bufo::Core::Events::UI_MODAL_CLOSED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |

Related checks: [t/core.t](../t/core.t), [t/core_services.t](../t/core_services.t).

## `src/core/stateManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `StateManager.getInstance` | `Bufo::Core::StateManager->getInstance` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.getState` | `Bufo::Core::StateManager->getState` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.setState` | `Bufo::Core::StateManager->setState` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.startBatch` | `Bufo::Core::StateManager->startBatch` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.endBatch` | `Bufo::Core::StateManager->endBatch` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.subscribe` | `Bufo::Core::StateManager->subscribe` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.unsubscribe` | `Bufo::Core::StateManager->unsubscribe` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.resetState` | `Bufo::Core::StateManager->resetState` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `StateManager.loadState` | `Bufo::Core::StateManager->loadState` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |
| `getStateManager` | `Bufo::Core::StateManager->getStateManager` in [lib/Bufo/Core/StateManager.pm](../lib/Bufo/Core/StateManager.pm) | callable |

Related checks: [t/core.t](../t/core.t), [t/core_services.t](../t/core_services.t).

## `src/core/types.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `Resources` | `Bufo::Save::_normalize resources; Bufo::Game->refresh derived values` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `PrestigeState` | `Bufo::Save::_normalize prestige; Bufo::Model::Prestige->default_state` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `BossState` | `Bufo::Save::_normalize bosses, ladder order, lifetimeDefeats` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `GameSettings` | `Bufo::Save::_normalize gameSettings timestamps, version, autoSave` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `UpgradeState` | `Bufo::Save::_normalize upgrades purchased/definitions; Game available reconstruction` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `AchievementState` | `Bufo::Save::_normalize achievements unlocked/progress/clickCount/customEvents` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `GameState` | `Bufo::Game->new/state; Bufo::Save::_normalize validates durable slices` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `StateChangeListener` | `Bufo::Core::StateManager->subscribe coderef receives current/prior snapshots` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |
| `PartialGameState` | `Bufo::Util::State::updateState; Bufo::Core::StateManager->setState` in [lib/Bufo/Save.pm](../lib/Bufo/Save.pm) | data contract |

Related checks: [t/core.t](../t/core.t), [t/core_services.t](../t/core_services.t).

## `src/game/gameCore.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GameCore.getInstance` | `Bufo::API->getGameCore (active owner-bound facade)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.init` | `Bufo::API->init` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.start` | `Bufo::API->start` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.stop` | `Bufo::API->stop` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.resetState` | `Bufo::API->resetState` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.toggleAutoSave` | `Bufo::API->toggleAutoSave` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.isAutoSaveEnabled` | `Bufo::API->isAutoSaveEnabled` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.registerClick` | `Bufo::API->registerClick` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.click` | `Bufo::API->click` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.checkUnlocks` | `Bufo::API->checkUnlocks` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.processTick` | `Bufo::API->processTick` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.destroy` | `Bufo::API->destroy` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getGeneratorManager` | `Bufo::API->getGeneratorManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getUpgradeManager` | `Bufo::API->getUpgradeManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getExplorerManager` | `Bufo::API->getExplorerManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getAchievementManager` | `Bufo::API->getAchievementManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getPrestigeManager` | `Bufo::API->getPrestigeManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getGoldenBufoManager` | `Bufo::API->getGoldenBufoManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameCore.getBossManager` | `Bufo::API->getBossManager` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `getGameCore` | `Bufo::API->getGameCore (active owner-bound facade)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/full-conversion.t](../t/full-conversion.t), [t/manager-contract.t](../t/manager-contract.t), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/game/gameLoader.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GameLoadingStatus` | `loadingStatus result: generators, upgrades, achievements, isComplete, optional error` in [lib/Bufo/Loader.pm](../lib/Bufo/Loader.pm) | data contract |
| `loadingStatus` | `Bufo::Loader->loadingStatus` in [lib/Bufo/Loader.pm](../lib/Bufo/Loader.pm) | callable |
| `isGameDataLoaded` | `Bufo::Loader->isGameDataLoaded` in [lib/Bufo/Loader.pm](../lib/Bufo/Loader.pm) | callable |
| `loadGameData` | `Bufo::Loader->loadGameData` in [lib/Bufo/Loader.pm](../lib/Bufo/Loader.pm) | callable |
| `verifyGameData` | `Bufo::Loader->verifyGameData` in [lib/Bufo/Loader.pm](../lib/Bufo/Loader.pm) | callable |

Related checks: [t/full-conversion.t](../t/full-conversion.t), [t/manager-contract.t](../t/manager-contract.t), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/game/gameLoop.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GameLoop.getInstance` | `Bufo::API->getGameLoop (browser-owned Bufo::Loop)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GameLoop.start` | `Bufo::Loop->start` in [lib/Bufo/Loop.pm](../lib/Bufo/Loop.pm) | callable |
| `GameLoop.stop` | `Bufo::Loop->stop` in [lib/Bufo/Loop.pm](../lib/Bufo/Loop.pm) | callable |
| `GameLoop.setTimeScale` | `Bufo::Loop->setTimeScale` in [lib/Bufo/Loop.pm](../lib/Bufo/Loop.pm) | callable |
| `GameLoop.getTimeScale` | `Bufo::Loop->getTimeScale` in [lib/Bufo/Loop.pm](../lib/Bufo/Loop.pm) | callable |
| `GameLoop.setTargetFPS` | `Bufo::Loop->setTargetFPS` in [lib/Bufo/Loop.pm](../lib/Bufo/Loop.pm) | callable |
| `getGameLoop` | `Bufo::API->getGameLoop (browser-owned Bufo::Loop)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/full-conversion.t](../t/full-conversion.t), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/game/gameSave.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `saveGame` | `Bufo::API->save; web/app.pl storage hooks` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `applyElapsedProduction` | `Bufo::Save->elapsed_seconds + Bufo::Game->credit_elapsed; web/app.pl load_game/on_visibility` in [lib/Bufo/Game.pm](../lib/Bufo/Game.pm) | callable |
| `loadGame` | `Bufo::API->load; web/app.pl storage hooks` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `exportSave` | `Bufo::API->exportSave; web/app.pl storage hooks` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `importSave` | `Bufo::API->importSave; web/app.pl storage hooks` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/save.t](../t/save.t), [t/util_services.t](../t/util_services.t), [scripts/browser-faults.pl](../scripts/browser-faults.pl).

## `src/game/gameState.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `DEFAULT_GAME_STATE` | `Bufo::Model::State->default_state` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |
| `calculateDerivedState` | `Bufo::Model::State->calculateDerivedState` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |
| `updateState` | `Bufo::Model::State->updateState` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |
| `validateState` | `Bufo::Model::State->validateState` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |
| `getProductionStatistics` | `Bufo::Model::State->getProductionStatistics` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |
| `getResourceDisplay` | `Bufo::Model::State->getResourceDisplay` in [lib/Bufo/Model/State.pm](../lib/Bufo/Model/State.pm) | callable |

Related checks: [t/full-conversion.t](../t/full-conversion.t), [t/manager-contract.t](../t/manager-contract.t), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/game/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `Game.init` | `Bufo::API->init` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.start` | `Bufo::API->start` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.stop` | `Bufo::API->stop` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.reset` | `Bufo::API->reset` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.save` | `Bufo::API->save` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.load` | `Bufo::API->load` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.exportSave` | `Bufo::API->exportSave` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.importSave` | `Bufo::API->importSave` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.toggleAutoSave` | `Bufo::API->toggleAutoSave` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.isAutoSaveEnabled` | `Bufo::API->isAutoSaveEnabled` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.click` | `Bufo::API->click` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getState` | `Bufo::API->getState` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getGenerators` | `Bufo::API->getGenerators` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.buyGenerator` | `Bufo::API->buyGenerator` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getMaxAffordable` | `Bufo::API->getMaxAffordable` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getAvailableUpgrades` | `Bufo::API->getAvailableUpgrades` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.buyUpgrade` | `Bufo::API->buyUpgrade` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getPurchasedUpgrades` | `Bufo::API->getPurchasedUpgrades` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getExplorer` | `Bufo::API->getExplorer` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.startExploration` | `Bufo::API->startExploration` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getAvailableAreas` | `Bufo::API->getAvailableAreas` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.upgradeExplorerStat` | `Bufo::API->upgradeExplorerStat` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getExplorerStats` | `Bufo::API->getExplorerStats` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.on` | `Bufo::API->on` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.off` | `Bufo::API->off` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `Game.getProductionStatistics` | `Bufo::API->getProductionStatistics` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `{ getGameCore, getGameLoop, saveGame, loadGame, exportSave, importSave, DEFAULT_GAME_STATE, updateState, calculateDerivedState, validateState }` | `getGameCore/getGameLoop: Bufo::API getters; saveGame/loadGame/exportSave/importSave: Bufo::API save/load/exportSave/importSave; DEFAULT_GAME_STATE/updateState/calculateDerivedState/validateState: Bufo::Model::State default_state/updateState/calculateDerivedState/validateState` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | forwarding |

Related checks: [t/full-conversion.t](../t/full-conversion.t), [t/manager-contract.t](../t/manager-contract.t), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `module startup` | `start; initialize_services; initialize_utility_adapters; startup loader callback` in [web/app.pl](../web/app.pl) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/initialization.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `InitializationStatus` | `initializeGame status callback: step, progress, optional error` in [lib/Bufo/Browser/Initialization.pm](../lib/Bufo/Browser/Initialization.pm) | data contract |
| `InitStatusCallback` | `initializeGame status callback: step, progress, optional error` in [lib/Bufo/Browser/Initialization.pm](../lib/Bufo/Browser/Initialization.pm) | data contract |
| `initializeGame` | `Bufo::Browser::Initialization::initializeGame` in [lib/Bufo/Browser/Initialization.pm](../lib/Bufo/Browser/Initialization.pm) | callable |
| `createLoadingUI` | `Bufo::Browser::Initialization::createLoadingUI` in [lib/Bufo/Browser/Initialization.pm](../lib/Bufo/Browser/Initialization.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/managers/UIManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ModalOptions` | `Bufo::Browser::UIManager->showModal id/title/content/buttons/closeOnBackdrop options` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | data contract |
| `UIManager.getInstance` | `Bufo::Browser::UIManager->getInstance` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.init` | `Bufo::Browser::UIManager->init` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.updateTabNotification` | `Bufo::Browser::UIManager->updateTabNotification` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.initializeMenu` | `Bufo::Browser::UIManager->initializeMenu` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.showAchievementNotification` | `Bufo::Browser::UIManager->showAchievementNotification` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.updateAutoSaveStatus` | `Bufo::Browser::UIManager->updateAutoSaveStatus` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.showModal` | `Bufo::Browser::UIManager->showModal` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.closeModal` | `Bufo::Browser::UIManager->closeModal` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.showNotification` | `Bufo::Browser::UIManager->showNotification` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.destroy` | `Bufo::Browser::UIManager->destroy` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `UIManager.getComponent` | `Bufo::Browser::UIManager->getComponent` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |
| `getUIManager` | `Bufo::Browser::UIManager->getUIManager` in [lib/Bufo/Browser/UIManager.pm](../lib/Bufo/Browser/UIManager.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/managers/achievementManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ACHIEVEMENT_UNLOCKED` | `Bufo::Core::Events::ACHIEVEMENT_UNLOCKED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `ACHIEVEMENTS_UPDATED` | `Bufo::Core::Events::ACHIEVEMENTS_UPDATED()` in [lib/Bufo/Core/Events.pm](../lib/Bufo/Core/Events.pm) | callable |
| `AchievementManager.getInstance` | `Bufo::API->getAchievementManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `AchievementManager.initialize` | `Bufo::Managers::Achievements->initialize` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.saveToState` | `Bufo::Managers::Achievements->saveToState` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.checkAllAchievements` | `Bufo::Managers::Achievements->checkAllAchievements` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.checkAchievementCategory` | `Bufo::Managers::Achievements->checkAchievementCategory` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.unlockAchievement` | `Bufo::Managers::Achievements->unlockAchievement` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.reapplyAllAchievementRewards` | `Bufo::Managers::Achievements->reapplyAllAchievementRewards` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.silentUnlockAchievement` | `Bufo::Managers::Achievements->silentUnlockAchievement` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getAllAchievements` | `Bufo::Managers::Achievements->getAllAchievements` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getUnlockedAchievements` | `Bufo::Managers::Achievements->getUnlockedAchievements` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getVisibleLockedAchievements` | `Bufo::Managers::Achievements->getVisibleLockedAchievements` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getAchievementProgress` | `Bufo::Managers::Achievements->getAchievementProgress` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.isAchievementUnlocked` | `Bufo::Managers::Achievements->isAchievementUnlocked` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getTotalAchievementCount` | `Bufo::Managers::Achievements->getTotalAchievementCount` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getUnlockedCount` | `Bufo::Managers::Achievements->getUnlockedCount` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getClickCount` | `Bufo::Managers::Achievements->getClickCount` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.setCustomEvents` | `Bufo::Managers::Achievements->setCustomEvents` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.setClickCount` | `Bufo::Managers::Achievements->setClickCount` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.triggerCustomEvent` | `Bufo::Managers::Achievements->triggerCustomEvent` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getCustomEvents` | `Bufo::Managers::Achievements->getCustomEvents` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getAchievementDetails` | `Bufo::Managers::Achievements->getAchievementDetails` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.getAllCustomEvents` | `Bufo::Managers::Achievements->getAllCustomEvents` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.hasCustomEventOccurred` | `Bufo::Managers::Achievements->hasCustomEventOccurred` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `AchievementManager.reset` | `Bufo::Managers::Achievements->reset` in [lib/Bufo/Managers/Achievements.pm](../lib/Bufo/Managers/Achievements.pm) | callable |
| `getAchievementManager` | `Bufo::API->getAchievementManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/bossManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ActiveBossFight` | `Bufo::Managers::Boss->getActiveFight boss/health/maxHealth/remainingMs snapshot` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | data contract |
| `BossManager.getInstance` | `Bufo::API->getBossManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `BossManager.getAvailableBoss` | `Bufo::Managers::Boss->getAvailableBoss` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.getActiveFight` | `Bufo::Managers::Boss->getActiveFight` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.getScaledHealth` | `Bufo::Managers::Boss->getScaledHealth` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.getMultiplier` | `Bufo::Managers::Boss->getMultiplier` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.getDefeatedCount` | `Bufo::Managers::Boss->getDefeatedCount` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.startFight` | `Bufo::Managers::Boss->startFight` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.hit` | `Bufo::Managers::Boss->hit` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.retreat` | `Bufo::Managers::Boss->retreat` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.pause` | `Bufo::Managers::Boss->pause` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.resume` | `Bufo::Managers::Boss->resume` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `BossManager.reset` | `Bufo::Managers::Boss->reset` in [lib/Bufo/Managers/Boss.pm](../lib/Bufo/Managers/Boss.pm) | callable |
| `getBossManager` | `Bufo::API->getBossManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/explorerManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ExplorerManager.getInstance` | `Bufo::API->getExplorerManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `ExplorerManager.getExplorer` | `Bufo::Explorer->getExplorer` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.getCurrentEnemy` | `Bufo::Explorer->getCurrentEnemy` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.getCurrentCombat` | `Bufo::Explorer->getCurrentCombat` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.update` | `Bufo::Explorer->update` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.startExploration` | `Bufo::Explorer->startExploration` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.performCombatAction` | `Bufo::Explorer->performCombatAction` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.autoResolveCombat` | `Bufo::Explorer->autoResolveCombat` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.upgradeExplorerStat` | `Bufo::Explorer->upgradeExplorerStat` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.getExplorerStats` | `Bufo::Explorer->getExplorerStats` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.getAvailableAreas` | `Bufo::Explorer->getAvailableAreas` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `ExplorerManager.reset` | `Bufo::Explorer->reset` in [lib/Bufo/Explorer.pm](../lib/Bufo/Explorer.pm) | callable |
| `getExplorerManager` | `Bufo::API->getExplorerManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/explorer-oracle.t](../t/explorer-oracle.t), [t/explorer-state.t](../t/explorer-state.t), [t/full-conversion.t](../t/full-conversion.t).

## `src/managers/generatorManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GeneratorContribution` | `Bufo::Managers::Generators->getProductionStats generatorContributions rows` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | data contract |
| `GeneratorManager.getInstance` | `Bufo::API->getGeneratorManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GeneratorManager.recalculateGenerator` | `Bufo::Managers::Generators->recalculateGenerator` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.recalculateAllGenerators` | `Bufo::Managers::Generators->recalculateAllGenerators` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.checkUnlocks` | `Bufo::Managers::Generators->checkUnlocks` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.purchaseGenerator` | `Bufo::Managers::Generators->purchaseGenerator` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.getMaxAffordable` | `Bufo::Managers::Generators->getMaxAffordable` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.calculateTotalProduction` | `Bufo::Managers::Generators->calculateTotalProduction` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.calculateProductionForTime` | `Bufo::Managers::Generators->calculateProductionForTime` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.getProductionStats` | `Bufo::Managers::Generators->getProductionStats` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.applyBoostToGenerator` | `Bufo::Managers::Generators->applyBoostToGenerator` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.toggleGeneratorBoost` | `Bufo::Managers::Generators->toggleGeneratorBoost` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.getAllGenerators` | `Bufo::Managers::Generators->getAllGenerators` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.getUnlockedGenerators` | `Bufo::Managers::Generators->getUnlockedGenerators` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `GeneratorManager.reset` | `Bufo::Managers::Generators->reset` in [lib/Bufo/Managers/Generators.pm](../lib/Bufo/Managers/Generators.pm) | callable |
| `getGeneratorManager` | `Bufo::API->getGeneratorManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/goldenBufoManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GoldenBufoRewardType` | `Bufo::Game->golden_outcome/collect_golden bufo_frenzy/lucky/click_frenzy domain` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | data contract |
| `GoldenBufoSpawn` | `Bufo::Managers::Golden spawn event id/rewardType/position/ttl payload` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | data contract |
| `GoldenBufoReward` | `Bufo::Managers::Golden->collect rewardType/label/detail result` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | data contract |
| `ActiveFrenzy` | `Bufo::Managers::Golden->getActiveFrenzies multiplier/endsAt result` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | data contract |
| `GoldenBufoManager.getInstance` | `Bufo::API->getGoldenBufoManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `GoldenBufoManager.start` | `Bufo::Managers::Golden->start` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.stop` | `Bufo::Managers::Golden->stop` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.isActive` | `Bufo::Managers::Golden->isActive` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.getActiveFrenzies` | `Bufo::Managers::Golden->getActiveFrenzies` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.collect` | `Bufo::Managers::Golden->collect` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.reset` | `Bufo::Managers::Golden->reset` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `GoldenBufoManager.forceSpawn` | `Bufo::Managers::Golden->forceSpawn` in [lib/Bufo/Managers/Golden.pm](../lib/Bufo/Managers/Golden.pm) | callable |
| `getGoldenBufoManager` | `Bufo::API->getGoldenBufoManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `initializeManagers` | `Bufo::Managers->initializeManagers` in [lib/Bufo/Managers.pm](../lib/Bufo/Managers.pm) | callable |
| `resetManagers` | `Bufo::Managers->resetManagers` in [lib/Bufo/Managers.pm](../lib/Bufo/Managers.pm) | callable |
| `{ getGeneratorManager, GeneratorManager, getExplorerManager, ExplorerManager, getUpgradeManager, UpgradeManager, getAchievementManager, AchievementManager, getPrestigeManager, PrestigeManager, getGoldenBufoManager, GoldenBufoManager, getBossManager, BossManager }` | `GeneratorManager/ExplorerManager/UpgradeManager/AchievementManager/PrestigeManager/GoldenBufoManager/BossManager: packages listed in manager sections; get*Manager: Bufo::API current-Game getters` in [lib/Bufo/Managers.pm](../lib/Bufo/Managers.pm) | forwarding |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/prestigeManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `PrestigeManager.getInstance` | `Bufo::API->getPrestigeManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `PrestigeManager.getPendingPoints` | `Bufo::Managers::Prestige->getPendingPoints` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.getMultiplier` | `Bufo::Managers::Prestige->getMultiplier` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.getState` | `Bufo::Managers::Prestige->getState` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.getBonusPerPoint` | `Bufo::Managers::Prestige->getBonusPerPoint` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.getMinTotalBufos` | `Bufo::Managers::Prestige->getMinTotalBufos` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.canTranscend` | `Bufo::Managers::Prestige->canTranscend` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.transcend` | `Bufo::Managers::Prestige->transcend` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `PrestigeManager.reset` | `Bufo::Managers::Prestige->reset` in [lib/Bufo/Managers/Prestige.pm](../lib/Bufo/Managers/Prestige.pm) | callable |
| `getPrestigeManager` | `Bufo::API->getPrestigeManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/managers/upgradeManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `UpgradeManager.getInstance` | `Bufo::API->getUpgradeManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |
| `UpgradeManager.initialize` | `Bufo::Managers::Upgrades->initialize` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.checkAvailableUpgrades` | `Bufo::Managers::Upgrades->checkAvailableUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.purchaseUpgrade` | `Bufo::Managers::Upgrades->purchaseUpgrade` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.applyUpgradeEffects` | `Bufo::Managers::Upgrades->applyUpgradeEffects` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.calculateTotalMultiplierForGenerator` | `Bufo::Managers::Upgrades->calculateTotalMultiplierForGenerator` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.calculateTotalClickMultiplier` | `Bufo::Managers::Upgrades->calculateTotalClickMultiplier` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.reapplyAllUpgrades` | `Bufo::Managers::Upgrades->reapplyAllUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.getUpgradeEffects` | `Bufo::Managers::Upgrades->getUpgradeEffects` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.findUpgradeById` | `Bufo::Managers::Upgrades->findUpgradeById` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.getAvailableUpgrades` | `Bufo::Managers::Upgrades->getAvailableUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.getPurchasedUpgrades` | `Bufo::Managers::Upgrades->getPurchasedUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.isUpgradePurchased` | `Bufo::Managers::Upgrades->isUpgradePurchased` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.setUpgrades` | `Bufo::Managers::Upgrades->setUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.getAllUpgrades` | `Bufo::Managers::Upgrades->getAllUpgrades` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `UpgradeManager.reset` | `Bufo::Managers::Upgrades->reset` in [lib/Bufo/Managers/Upgrades.pm](../lib/Bufo/Managers/Upgrades.pm) | callable |
| `getUpgradeManager` | `Bufo::API->getUpgradeManager (current Game-owned manager)` in [lib/Bufo/API.pm](../lib/Bufo/API.pm) | callable |

Related checks: [t/manager-contract.t](../t/manager-contract.t), [t/full-conversion.t](../t/full-conversion.t), [t/game.t](../t/game.t).

## `src/models/achievements.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `AchievementCategory` | `Bufo::Model::Achievements->AchievementCategory` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | constant |
| `Achievement` | `Bufo::Catalog->new achievement definitions and Bufo::Model::Achievements->initializeAchievements` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | data contract |
| `RequirementType` | `Bufo::Model::Achievements->RequirementType` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | constant |
| `AchievementRequirement` | `Bufo::Catalog->new requirement type/value/target; Model::Achievements->checkAchievementRequirement` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | data contract |
| `RewardType` | `Bufo::Model::Achievements->RewardType` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | constant |
| `AchievementReward` | `Bufo::Catalog->new reward type/value/target; Bufo::Game->refresh reward reconstruction` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | data contract |
| `INITIAL_ACHIEVEMENTS` | `Bufo::Catalog->achievements` in [lib/Bufo/Catalog.pm](../lib/Bufo/Catalog.pm) | callable |
| `initializeAchievements` | `Bufo::Model::Achievements->initializeAchievements` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | callable |
| `checkAchievementRequirement` | `Bufo::Model::Achievements->checkAchievementRequirement` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | callable |
| `getCategoryIcon` | `Bufo::Model::Achievements->getCategoryIcon` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | callable |
| `getAchievementIcon` | `Bufo::Model::Achievements->getAchievementIcon` in [lib/Bufo/Model/Achievements.pm](../lib/Bufo/Model/Achievements.pm) | callable |

Related checks: [t/models.t](../t/models.t), [t/game.t](../t/game.t).

## `src/models/boss.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `BossDefinition` | `Bufo::Catalog->bosses; Bufo::Model::Boss->findBoss result` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | data contract |
| `BOSS_FIGHT_DURATION_MS` | `Bufo::Model::Boss->BOSS_FIGHT_DURATION_MS` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |
| `BOSS_BONUS_PER_DEFEAT` | `Bufo::Model::Boss->BOSS_BONUS_PER_DEFEAT` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |
| `BOSSES` | `Bufo::Catalog->bosses` in [lib/Bufo/Catalog.pm](../lib/Bufo/Catalog.pm) | callable |
| `findBoss` | `Bufo::Model::Boss->findBoss` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |
| `getAvailableBoss` | `Bufo::Model::Boss->getAvailableBoss` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |
| `getBossMultiplier` | `Bufo::Model::Boss->getBossMultiplier` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |
| `getBossHealth` | `Bufo::Model::Boss->getBossHealth` in [lib/Bufo/Model/Boss.pm](../lib/Bufo/Model/Boss.pm) | callable |

Related checks: [t/models.t](../t/models.t), [t/game.t](../t/game.t).

## `src/models/combat.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `CombatStatus` | `Bufo::Combat->statuses` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | callable |
| `CombatActionType` | `Bufo::Combat->action_types` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | callable |
| `CombatState` | `Bufo::Combat->initializeCombat/executeCombatAction state: explorer, enemy, status, round, combatLog, startTime, lastActionTime` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | data contract |
| `CombatActionResult` | `Bufo::Combat->executeCombatAction newState/damageToEnemy/damageToExplorer/actionMessage/rewards result` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | data contract |
| `initializeCombat` | `Bufo::Combat->initializeCombat` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | callable |
| `executeCombatAction` | `Bufo::Combat->executeCombatAction` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | callable |
| `simulateCombat` | `Bufo::Combat->simulateCombat` in [lib/Bufo/Combat.pm](../lib/Bufo/Combat.pm) | callable |

Related checks: [t/explorer-oracle.t](../t/explorer-oracle.t), [t/explorer-state.t](../t/explorer-state.t), [t/full-conversion.t](../t/full-conversion.t).

## `src/models/enemies.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `EnemyType` | `Bufo::Enemies->types` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |
| `DropItem` | `Bufo::Enemies->base_drop_items item metadata` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | data contract |
| `DropTable` | `Bufo::Enemies->initial_enemy_templates/generateEnemy dropTable; calculateEnemyRewards drop results` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | data contract |
| `Enemy` | `Bufo::Enemies->generateEnemy complete enemy result hash` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | data contract |
| `EnemyTemplate` | `Bufo::Enemies->initial_enemy_templates six complete definitions` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | data contract |
| `BASE_DROP_ITEMS` | `Bufo::Enemies->base_drop_items` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |
| `INITIAL_ENEMY_TEMPLATES` | `Bufo::Enemies->initial_enemy_templates` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |
| `generateEnemy` | `Bufo::Enemies->generateEnemy` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |
| `calculateEnemyRewards` | `Bufo::Enemies->calculateEnemyRewards` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |
| `calculateRelativeDifficulty` | `Bufo::Enemies->calculateRelativeDifficulty` in [lib/Bufo/Enemies.pm](../lib/Bufo/Enemies.pm) | callable |

Related checks: [t/explorer-oracle.t](../t/explorer-oracle.t), [t/explorer-state.t](../t/explorer-state.t), [t/full-conversion.t](../t/full-conversion.t).

## `src/models/explorer.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ExplorerState` | `Bufo::ExplorerModel->states` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `ExplorerStat` | `Bufo::ExplorerModel->normalize attack/defense/speed/luck value/level/growthRate/upgradeCost/multiplier` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | data contract |
| `ExplorerEquipment` | `Bufo::ExplorerModel->normalize equipment weapon/armor/accessory` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | data contract |
| `ExplorationResult` | `Bufo::ExplorerModel->calculateExplorationResult and Bufo::Explorer->update result hash` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | data contract |
| `ExplorerData` | `Bufo::ExplorerModel->default_data/normalize complete persistent Explorer hash` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | data contract |
| `DEFAULT_EXPLORER_DATA` | `Bufo::ExplorerModel->default_data` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculateDPS` | `Bufo::ExplorerModel->calculateDPS` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculateSurvivalTime` | `Bufo::ExplorerModel->calculateSurvivalTime` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculatePowerRating` | `Bufo::ExplorerModel->calculatePowerRating` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculateAreaEffectiveness` | `Bufo::ExplorerModel->calculateAreaEffectiveness` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculateStatUpgradeCost` | `Bufo::ExplorerModel->calculateStatUpgradeCost` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `recalculateExplorerStats` | `Bufo::ExplorerModel->recalculateExplorerStats` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `canLevelUp` | `Bufo::ExplorerModel->canLevelUp` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `levelUpExplorer` | `Bufo::ExplorerModel->levelUpExplorer` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `upgradeExplorerStat` | `Bufo::ExplorerModel->upgradeExplorerStat` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `startExploration` | `Bufo::ExplorerModel->startExploration` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `startCombat` | `Bufo::ExplorerModel->startCombat` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `calculateExplorationResult` | `Bufo::ExplorerModel->calculateExplorationResult` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `completeExploration` | `Bufo::ExplorerModel->completeExploration` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `restExplorer` | `Bufo::ExplorerModel->restExplorer` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `getAreaLevel` | `Bufo::ExplorerModel->getAreaLevel` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |
| `updateExplorer` | `Bufo::ExplorerModel->updateExplorer` in [lib/Bufo/ExplorerModel.pm](../lib/Bufo/ExplorerModel.pm) | callable |

Related checks: [t/explorer-oracle.t](../t/explorer-oracle.t), [t/explorer-state.t](../t/explorer-state.t), [t/full-conversion.t](../t/full-conversion.t).

## `src/models/generators.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GeneratorType` | `Bufo::Model::Generators->GeneratorType` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | constant |
| `GeneratorCategory` | `Bufo::Model::Generators->GeneratorCategory` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | constant |
| `UnlockType` | `Bufo::Model::Generators->UnlockType` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | constant |
| `UnlockRequirement` | `Bufo::Catalog->new validates generator unlockRequirements; Model::Generators->checkGeneratorUnlock consumes them` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | data contract |
| `ProductionBoost` | `Bufo::Model::Generators->applyBoostToGenerator; Bufo::Save::_normalize id/multiplier/active/source` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | data contract |
| `GeneratorData` | `Bufo::Model::Generators->createGenerator/recalculateGenerator; Bufo::Catalog->new and Bufo::Save::_normalize validate data` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | data contract |
| `GeneratorUpdate` | `Bufo::Model::Generators->updateGenerator partial hash` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | data contract |
| `INITIAL_GENERATORS` | `Bufo::Catalog->generators` in [lib/Bufo/Catalog.pm](../lib/Bufo/Catalog.pm) | callable |
| `initializeGenerators` | `Bufo::Model::Generators->initializeGenerators` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `updateGenerator` | `Bufo::Model::Generators->updateGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `recalculateGenerator` | `Bufo::Model::Generators->recalculateGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `checkGeneratorUnlock` | `Bufo::Model::Generators->checkGeneratorUnlock` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `unlockGenerator` | `Bufo::Model::Generators->unlockGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `calculateTotalProduction` | `Bufo::Model::Generators->calculateTotalProduction` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `canAffordGenerator` | `Bufo::Model::Generators->canAffordGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `calculateBulkCost` | `Bufo::Model::Generators->calculateBulkCost` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `calculateMaxAffordable` | `Bufo::Model::Generators->calculateMaxAffordable` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `createGenerator` | `Bufo::Model::Generators->createGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `applyBoostToGenerator` | `Bufo::Model::Generators->applyBoostToGenerator` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |
| `toggleBoost` | `Bufo::Model::Generators->toggleBoost` in [lib/Bufo/Model/Generators.pm](../lib/Bufo/Model/Generators.pm) | callable |

Related checks: [t/models.t](../t/models.t), [t/game.t](../t/game.t).

## `src/models/prestige.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `PRESTIGE_BONUS_PER_POINT` | `Bufo::Model::Prestige->PRESTIGE_BONUS_PER_POINT` in [lib/Bufo/Model/Prestige.pm](../lib/Bufo/Model/Prestige.pm) | callable |
| `PRESTIGE_MIN_TOTAL_BUFOS` | `Bufo::Model::Prestige->PRESTIGE_MIN_TOTAL_BUFOS` in [lib/Bufo/Model/Prestige.pm](../lib/Bufo/Model/Prestige.pm) | callable |
| `DEFAULT_PRESTIGE_STATE` | `Bufo::Model::Prestige->default_state` in [lib/Bufo/Model/Prestige.pm](../lib/Bufo/Model/Prestige.pm) | callable |
| `prestigePointsFor` | `Bufo::Model::Prestige->prestigePointsFor` in [lib/Bufo/Model/Prestige.pm](../lib/Bufo/Model/Prestige.pm) | callable |
| `getPrestigeMultiplier` | `Bufo::Model::Prestige->getPrestigeMultiplier` in [lib/Bufo/Model/Prestige.pm](../lib/Bufo/Model/Prestige.pm) | callable |

Related checks: [t/models.t](../t/models.t), [t/game.t](../t/game.t).

## `src/models/upgrades.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `UpgradeCategory` | `Bufo::Model::Upgrades->UpgradeCategory` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | constant |
| `UpgradeEffectType` | `clickMultiplier/generatorProduction/globalMultiplier/unlockSpecial tags consumed by upgrade model/manager` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | data contract |
| `UnlockConditionType` | `Bufo::Model::Upgrades->UnlockConditionType` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | constant |
| `UnlockCondition` | `Bufo::Catalog->new conditions; Bufo::Model::Upgrades->meetsUnlockConditions` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | data contract |
| `UpgradeEffect` | `Bufo::Catalog->new effect type/target/multiplier; Managers::Upgrades->applyUpgradeEffects` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | data contract |
| `Upgrade` | `Bufo::Catalog->new and Bufo::Managers::Upgrades->setUpgrades definitions` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | data contract |
| `INITIAL_UPGRADES` | `Bufo::Catalog->upgrades` in [lib/Bufo/Catalog.pm](../lib/Bufo/Catalog.pm) | callable |
| `initializeUpgrades` | `Bufo::Model::Upgrades->initializeUpgrades` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |
| `findUpgradeById` | `Bufo::Model::Upgrades->findUpgradeById` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |
| `meetsUnlockConditions` | `Bufo::Model::Upgrades->meetsUnlockConditions` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |
| `calculateUpgradeEffectForGenerator` | `Bufo::Model::Upgrades->calculateUpgradeEffectForGenerator` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |
| `calculateClickMultiplier` | `Bufo::Model::Upgrades->calculateClickMultiplier` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |
| `calculateGlobalMultiplier` | `Bufo::Model::Upgrades->calculateGlobalMultiplier` in [lib/Bufo/Model/Upgrades.pm](../lib/Bufo/Model/Upgrades.pm) | callable |

Related checks: [t/models.t](../t/models.t), [t/game.t](../t/game.t).

## `src/ui/components/bossFight.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `BossFight.init` | `Bufo::Browser::BossFight->init` in [lib/Bufo/Browser/Special.pm](../lib/Bufo/Browser/Special.pm) | callable |
| `BossFight.destroy` | `Bufo::Browser::BossFight->destroy` in [lib/Bufo/Browser/Special.pm](../lib/Bufo/Browser/Special.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/clickArea.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ClickAreaOptions` | `Bufo::Browser::ClickArea->new imagePath/maxComboClicks/comboTimeout options` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | data contract |
| `ClickArea.constructor` | `Bufo::Browser::ClickArea->new` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ClickArea.render` | `Bufo::Browser::ClickArea->render` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ClickArea.destroy` | `Bufo::Browser::ClickArea->destroy` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/generatorItem.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GeneratorItem.constructor` | `Bufo::Browser::GeneratorItem->new` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `GeneratorItem.render` | `Bufo::Browser::GeneratorItem->render` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `GeneratorItem.update` | `Bufo::Browser::GeneratorItem->update` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/generatorList.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GeneratorList.constructor` | `Bufo::Browser::GeneratorList->new` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `GeneratorList.refreshGenerators` | `Bufo::Browser::GeneratorList->refreshGenerators` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/goldenBufo.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `GoldenBufo.init` | `Bufo::Browser::GoldenBufo->init` in [lib/Bufo/Browser/Special.pm](../lib/Bufo/Browser/Special.pm) | callable |
| `GoldenBufo.destroy` | `Bufo::Browser::GoldenBufo->destroy` in [lib/Bufo/Browser/Special.pm](../lib/Bufo/Browser/Special.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `{ ResourceDisplay, ClickArea, GeneratorList, GeneratorItem, Shop, ShopItem, UpgradeList, UpgradeItem, ProductionStats }` | `ResourceDisplay/ClickArea/GeneratorList/GeneratorItem/Shop/ShopItem/UpgradeList/UpgradeItem/ProductionStats: Bufo::Browser::<class>->new, methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `createResourceDisplay` | `Bufo::Browser::UI::createResourceDisplay` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `createClickArea` | `Bufo::Browser::UI::createClickArea` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `createGeneratorList` | `Bufo::Browser::UI::createGeneratorList` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `createShop` | `Bufo::Browser::UI::createShop` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `createUpgradeList` | `Bufo::Browser::UI::createUpgradeList` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `createProductionStats` | `Bufo::Browser::UI::createProductionStats` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `initializeUI` | `Bufo::Browser::UI::initializeUI` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/productionStats.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ProductionStats.constructor` | `Bufo::Browser::ProductionStats->new` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `ProductionStats.render` | `Bufo::Browser::ProductionStats->render` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `ProductionStats.refreshStats` | `Bufo::Browser::ProductionStats->refreshStats` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/resourceDisplay.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ResourceDisplayOptions` | `Bufo::Browser::ResourceDisplay->new showProductionRate options` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | data contract |
| `ResourceDisplay.constructor` | `Bufo::Browser::ResourceDisplay->new` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ResourceDisplay.render` | `Bufo::Browser::ResourceDisplay->render` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ResourceDisplay.update` | `Bufo::Browser::ResourceDisplay->update` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/shop.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `Shop.constructor` | `Bufo::Browser::Shop->new` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `Shop.refreshGenerators` | `Bufo::Browser::Shop->refreshGenerators` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `Shop.destroy` | `Bufo::Browser::Shop->destroy` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/shopItem.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ShopItem.constructor` | `Bufo::Browser::ShopItem->new` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ShopItem.render` | `Bufo::Browser::ShopItem->render` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `ShopItem.update` | `Bufo::Browser::ShopItem->update` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/upgradeItem.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `UpgradeItem.constructor` | `Bufo::Browser::UpgradeItem->new` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `UpgradeItem.render` | `Bufo::Browser::UpgradeItem->render` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `UpgradeItem.update` | `Bufo::Browser::UpgradeItem->update` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |
| `UpgradeItem.destroy` | `Bufo::Browser::UpgradeItem->destroy` in [lib/Bufo/Browser/Components.pm](../lib/Bufo/Browser/Components.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/components/upgradeList.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `UpgradeList.constructor` | `Bufo::Browser::UpgradeList->new` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `UpgradeList.refreshUpgrades` | `Bufo::Browser::UpgradeList->refreshUpgrades` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |
| `UpgradeList.destroy` | `Bufo::Browser::UpgradeList->destroy` in [lib/Bufo/Browser/Lists.pm](../lib/Bufo/Browser/Lists.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/constants.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `TabConfig` | `Bufo::Browser::Constants::get(TABS) id/label/icon records` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | data contract |
| `TABS` | `Bufo::Browser::Constants::get('TABS')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `DEFAULT_TAB` | `Bufo::Browser::Constants::get('DEFAULT_TAB')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `Z_INDEX` | `Bufo::Browser::Constants::get('Z_INDEX')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `ANIMATION` | `Bufo::Browser::Constants::get('ANIMATION')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `BREAKPOINTS` | `Bufo::Browser::Constants::get('BREAKPOINTS')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `DEFAULT_NOTIFICATION_DURATION` | `Bufo::Browser::Constants::get('DEFAULT_NOTIFICATION_DURATION')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `DEFAULT_THEME` | `Bufo::Browser::Constants::get('DEFAULT_THEME')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `THEMES` | `Bufo::Browser::Constants::get('THEMES')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |
| `TOOLTIP_DELAY` | `Bufo::Browser::Constants::get('TOOLTIP_DELAY')` in [lib/Bufo/Browser/Constants.pm](../lib/Bufo/Browser/Constants.pm) | constant |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/core/Component.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `Component.constructor` | `Bufo::Browser::Component->new` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.init` | `Bufo::Browser::Component->init` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.render` | `Bufo::Browser::Component->render` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.update` | `Bufo::Browser::Component->update` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.setContent` | `Bufo::Browser::Component->setContent` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.addClass` | `Bufo::Browser::Component->addClass` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.removeClass` | `Bufo::Browser::Component->removeClass` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.toggleClass` | `Bufo::Browser::Component->toggleClass` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.addEventListener` | `Bufo::Browser::Component->addEventListener` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.removeEventListener` | `Bufo::Browser::Component->removeEventListener` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.connectToState` | `Bufo::Browser::Component->connectToState` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.subscribeToEvent` | `Bufo::Browser::Component->subscribeToEvent` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.getElement` | `Bufo::Browser::Component->getElement` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.getId` | `Bufo::Browser::Component->getId` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |
| `Component.destroy` | `Bufo::Browser::Component->destroy` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/core/Container.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `Container.constructor` | `Bufo::Browser::Container->new` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.addChild` | `Bufo::Browser::Container->addChild` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.removeChild` | `Bufo::Browser::Container->removeChild` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.getChildren` | `Bufo::Browser::Container->getChildren` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.getChildById` | `Bufo::Browser::Container->getChildById` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.clearChildren` | `Bufo::Browser::Container->clearChildren` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.destroy` | `Bufo::Browser::Container->destroy` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |
| `Container.renderChildren` | `Bufo::Browser::Container->renderChildren` in [lib/Bufo/Browser/Container.pm](../lib/Bufo/Browser/Container.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/core/types.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ComponentOptions` | `Bufo::Browser::Component->new id/tagName/className/template/element options` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `RenderOptions` | `Bufo::Browser::Component->setContent replace/append options` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `StateSelector` | `Bufo::Browser::Component->connectToState selector coderef` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `ComponentEventHandler` | `Bufo::Browser::Component->addEventListener callback coderef` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `EventHandlerMap` | `Bufo::Browser::Component event-handler registry and destroy cleanup` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `ChildComponent` | `Bufo::Browser::Container->addChild/getChildren component/data records` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |
| `IComponent` | `Bufo::Browser::Component init/render/update/destroy/getElement interface` in [lib/Bufo/Browser/Component.pm](../lib/Bufo/Browser/Component.pm) | data contract |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `* from './components/resourceDisplay'` | `Bufo::Browser::ResourceDisplay->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/clickArea'` | `Bufo::Browser::ClickArea->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/generatorList'` | `Bufo::Browser::GeneratorList->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/generatorItem'` | `Bufo::Browser::GeneratorItem->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/shop'` | `Bufo::Browser::Shop->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/shopItem'` | `Bufo::Browser::ShopItem->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/upgradeList'` | `Bufo::Browser::UpgradeList->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './components/upgradeItem'` | `Bufo::Browser::UpgradeItem->new and public methods below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `{ UIManager, getUIManager, ModalOptions } from '../managers/UIManager'` | `Bufo::Browser::UIManager->getInstance/getUIManager; ModalOptions constructor/modal contract` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* as templates from './templates'` | `Bufo::Browser::Templates named helpers below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* as styles from './styles'` | `Bufo::Browser::Styles::get named maps below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `* from './constants'` | `Bufo::Browser::Constants::get named constants below` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | forwarding |
| `initUI` | `Bufo::Browser::UI::initUI` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |
| `updateUI` | `Bufo::Browser::UI::updateUI` in [lib/Bufo/Browser/UI.pm](../lib/Bufo/Browser/UI.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/styles.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `LAYOUT` | `Bufo::Browser::Styles::get('LAYOUT')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `COMPONENT` | `Bufo::Browser::Styles::get('COMPONENT')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `STATE` | `Bufo::Browser::Styles::get('STATE')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `MODAL` | `Bufo::Browser::Styles::get('MODAL')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `NOTIFICATION` | `Bufo::Browser::Styles::get('NOTIFICATION')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `TOOLTIP` | `Bufo::Browser::Styles::get('TOOLTIP')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `ANIMATION` | `Bufo::Browser::Styles::get('ANIMATION')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |
| `CATEGORY` | `Bufo::Browser::Styles::get('CATEGORY')` in [lib/Bufo/Browser/Styles.pm](../lib/Bufo/Browser/Styles.pm) | constant |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/ui/templates.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `sectionHeader` | `Bufo::Browser::Templates::sectionHeader` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `panel` | `Bufo::Browser::Templates::panel` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `button` | `Bufo::Browser::Templates::button` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `iconButton` | `Bufo::Browser::Templates::iconButton` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `progressBar` | `Bufo::Browser::Templates::progressBar` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `resourceDisplay` | `Bufo::Browser::Templates::resourceDisplay` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `tooltip` | `Bufo::Browser::Templates::tooltip` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `notification` | `Bufo::Browser::Templates::notification` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `modal` | `Bufo::Browser::Templates::modal` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |
| `tabContainer` | `Bufo::Browser::Templates::tabContainer` in [lib/Bufo/Browser/Templates.pm](../lib/Bufo/Browser/Templates.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/utils/animationUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `AnimationOptions` | `Bufo::Browser::Animation::animate delay/easing/onUpdate/onComplete options` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | data contract |
| `CSSAnimationOptions` | `Bufo::Browser::Animation::animateElement properties/duration/animation options` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | data contract |
| `Easing` | `%Bufo::Browser::Animation::Easing` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | constant |
| `animate` | `Bufo::Browser::Animation::animate` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |
| `animateElement` | `Bufo::Browser::Animation::animateElement` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |
| `fadeIn` | `Bufo::Browser::Animation::fadeIn` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |
| `fadeOut` | `Bufo::Browser::Animation::fadeOut` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |
| `pulse` | `Bufo::Browser::Animation::pulse` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |
| `shake` | `Bufo::Browser::Animation::shake` in [lib/Bufo/Browser/Animation.pm](../lib/Bufo/Browser/Animation.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/utils/dataLoader.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `loadJsonData` | `Bufo::Util::DataLoader->loadJsonData` in [lib/Bufo/Util/DataLoader.pm](../lib/Bufo/Util/DataLoader.pm) | callable |
| `loadMultipleJsonData` | `Bufo::Util::DataLoader->loadMultipleJsonData` in [lib/Bufo/Util/DataLoader.pm](../lib/Bufo/Util/DataLoader.pm) | callable |
| `shouldLoadData` | `Bufo::Util::DataLoader->shouldLoadData` in [lib/Bufo/Util/DataLoader.pm](../lib/Bufo/Util/DataLoader.pm) | callable |
| `updateDataCacheVersion` | `Bufo::Util::DataLoader->updateDataCacheVersion` in [lib/Bufo/Util/DataLoader.pm](../lib/Bufo/Util/DataLoader.pm) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/utils/debugTools.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `state` | `Bufo::Browser::Debug->expose / window.debugTools.state` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events` | `Bufo::Browser::Debug->expose / window.debugTools.events` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `gameCore` | `Bufo::Browser::Debug->expose / window.debugTools.gameCore` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `gameLoop` | `Bufo::Browser::Debug->expose / window.debugTools.gameLoop` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `ui` | `Bufo::Browser::Debug->expose / window.debugTools.ui` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `generators` | `Bufo::Browser::Debug->expose / window.debugTools.generators` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `upgrades` | `Bufo::Browser::Debug->expose / window.debugTools.upgrades` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `explorer` | `Bufo::Browser::Debug->expose / window.debugTools.explorer` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `prestige` | `Bufo::Browser::Debug->expose / window.debugTools.prestige` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `golden` | `Bufo::Browser::Debug->expose / window.debugTools.golden` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss` | `Bufo::Browser::Debug->expose / window.debugTools.boss` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `save` | `Bufo::Browser::Debug->expose / window.debugTools.save` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `time` | `Bufo::Browser::Debug->expose / window.debugTools.time` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `resources` | `Bufo::Browser::Debug->expose / window.debugTools.resources` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect` | `Bufo::Browser::Debug->expose / window.debugTools.inspect` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events_debug` | `Bufo::Browser::Debug->expose / window.debugTools.events_debug` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `logging` | `Bufo::Browser::Debug->expose / window.debugTools.logging` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `generator_debug` | `Bufo::Browser::Debug->expose / window.debugTools.generator_debug` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `upgrade_debug` | `Bufo::Browser::Debug->expose / window.debugTools.upgrade_debug` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `reset` | `Bufo::Browser::Debug->expose / window.debugTools.reset` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `performance` | `Bufo::Browser::Debug->expose / window.debugTools.performance` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `help` | `Bufo::Browser::Debug->expose / window.debugTools.help` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `default` | `expose: debugTools.default repeats all named debug groups` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | forwarding |
| `golden.spawn` | `Bufo::Browser::Debug->expose / window.debugTools.golden.spawn` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `golden.collect` | `Bufo::Browser::Debug->expose / window.debugTools.golden.collect` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.available` | `Bufo::Browser::Debug->expose / window.debugTools.boss.available` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.start` | `Bufo::Browser::Debug->expose / window.debugTools.boss.start` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.hit` | `Bufo::Browser::Debug->expose / window.debugTools.boss.hit` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.win` | `Bufo::Browser::Debug->expose / window.debugTools.boss.win` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.lose` | `Bufo::Browser::Debug->expose / window.debugTools.boss.lose` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.status` | `Bufo::Browser::Debug->expose / window.debugTools.boss.status` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.multiplier` | `Bufo::Browser::Debug->expose / window.debugTools.boss.multiplier` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `boss.defeatedCount` | `Bufo::Browser::Debug->expose / window.debugTools.boss.defeatedCount` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `save.save` | `Bufo::Browser::Debug->expose / window.debugTools.save.save` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `save.load` | `Bufo::Browser::Debug->expose / window.debugTools.save.load` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `save.export` | `Bufo::Browser::Debug->expose / window.debugTools.save.export` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `save.import` | `Bufo::Browser::Debug->expose / window.debugTools.save.import` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `time.pause` | `Bufo::Browser::Debug->expose / window.debugTools.time.pause` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `time.resume` | `Bufo::Browser::Debug->expose / window.debugTools.time.resume` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `time.setTimeScale` | `Bufo::Browser::Debug->expose / window.debugTools.time.setTimeScale` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `time.getTimeScale` | `Bufo::Browser::Debug->expose / window.debugTools.time.getTimeScale` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `resources.get` | `Bufo::Browser::Debug->expose / window.debugTools.resources.get` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `resources.add` | `Bufo::Browser::Debug->expose / window.debugTools.resources.add` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `resources.set` | `Bufo::Browser::Debug->expose / window.debugTools.resources.set` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect.state` | `Bufo::Browser::Debug->expose / window.debugTools.inspect.state` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect.generators` | `Bufo::Browser::Debug->expose / window.debugTools.inspect.generators` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect.upgrades` | `Bufo::Browser::Debug->expose / window.debugTools.inspect.upgrades` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect.explorer` | `Bufo::Browser::Debug->expose / window.debugTools.inspect.explorer` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `inspect.production` | `Bufo::Browser::Debug->expose / window.debugTools.inspect.production` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events_debug.enableDebug` | `Bufo::Browser::Debug->expose / window.debugTools.events_debug.enableDebug` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events_debug.disableDebug` | `Bufo::Browser::Debug->expose / window.debugTools.events_debug.disableDebug` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events_debug.listEvents` | `Bufo::Browser::Debug->expose / window.debugTools.events_debug.listEvents` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `events_debug.emit` | `Bufo::Browser::Debug->expose / window.debugTools.events_debug.emit` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `logging.setLevel` | `Bufo::Browser::Debug->expose / window.debugTools.logging.setLevel` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `logging.getLevel` | `Bufo::Browser::Debug->expose / window.debugTools.logging.getLevel` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `logging.enableTimestamps` | `Bufo::Browser::Debug->expose / window.debugTools.logging.enableTimestamps` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `logging.enableConsoleColors` | `Bufo::Browser::Debug->expose / window.debugTools.logging.enableConsoleColors` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `generator_debug.unlockAll` | `Bufo::Browser::Debug->expose / window.debugTools.generator_debug.unlockAll` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `generator_debug.give` | `Bufo::Browser::Debug->expose / window.debugTools.generator_debug.give` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `upgrade_debug.unlockAll` | `Bufo::Browser::Debug->expose / window.debugTools.upgrade_debug.unlockAll` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `upgrade_debug.purchase` | `Bufo::Browser::Debug->expose / window.debugTools.upgrade_debug.purchase` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `reset.softReset` | `Bufo::Browser::Debug->expose / window.debugTools.reset.softReset` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `reset.hardReset` | `Bufo::Browser::Debug->expose / window.debugTools.reset.hardReset` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |
| `performance.measure` | `Bufo::Browser::Debug->expose / window.debugTools.performance.measure` in [lib/Bufo/Browser/Debug.pm](../lib/Bufo/Browser/Debug.pm) | debug adapter |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/utils/domUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `CreateElementOptions` | `Bufo::Browser::DOM::createElement id/classes/attributes/content/events/parent options` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | data contract |
| `createElement` | `Bufo::Browser::DOM::createElement` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `addClass` | `Bufo::Browser::DOM::addClass` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `removeClass` | `Bufo::Browser::DOM::removeClass` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `toggleClass` | `Bufo::Browser::DOM::toggleClass` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `setContent` | `Bufo::Browser::DOM::setContent` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `addEventListeners` | `Bufo::Browser::DOM::addEventListeners` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `querySelector` | `Bufo::Browser::DOM::querySelector` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `querySelectorAll` | `Bufo::Browser::DOM::querySelectorAll` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `removeElement` | `Bufo::Browser::DOM::removeElement` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |
| `setVisible` | `Bufo::Browser::DOM::setVisible` in [lib/Bufo/Browser/DOM.pm](../lib/Bufo/Browser/DOM.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/utils/index.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `* from './numberUtils'` | `Bufo::Util::Index->call(name, args) dispatches every numberUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './timeUtils'` | `Bufo::Util::Index->call(name, args) dispatches every timeUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './domUtils'` | `Bufo::Util::Index->call(name, args) dispatches every domUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './storageUtils'` | `Bufo::Util::Index->call(name, args) dispatches every storageUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './animationUtils'` | `Bufo::Util::Index->call(name, args) dispatches every animationUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './mathUtils'` | `Bufo::Util::Index->call(name, args) dispatches every mathUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `* from './validationUtils'` | `Bufo::Util::Index->call(name, args) dispatches every validationUtils operation listed below to its concrete implementation; AUTOLOAD supports the same method names` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | forwarding |
| `Logger` | `Bufo::Util::Index->Logger` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `generateId` | `Bufo::Util::Index->generateId` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `isDefined` | `Bufo::Util::Index->isDefined` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `isNullOrUndefined` | `Bufo::Util::Index->isNullOrUndefined` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `defaultIfNullOrUndefined` | `Bufo::Util::Index->defaultIfNullOrUndefined` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `deepClone` | `Bufo::Util::Index->deepClone` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `isPlainObject` | `Bufo::Util::Index->isPlainObject` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `safeJsonParse` | `Bufo::Util::Index->safeJsonParse` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `safeJsonStringify` | `Bufo::Util::Index->safeJsonStringify` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `delay` | `Bufo::Util::Index->delay` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `cancellableDelay` | `Bufo::Util::Index->cancellableDelay` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `attempt` | `Bufo::Util::Index->attempt` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `getRandomElement` | `Bufo::Util::Index->getRandomElement` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |
| `shuffleArray` | `Bufo::Util::Index->shuffleArray` in [lib/Bufo/Util/Index.pm](../lib/Bufo/Util/Index.pm) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/utils/logger.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `LogLevel` | `Bufo::Core::Logger::{NONE, ERROR, WARN, INFO, DEBUG, TRACE}` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | constant |
| `setLogLevel` | `Bufo::Core::Logger->setLogLevel` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `getLogLevel` | `Bufo::Core::Logger->getLogLevel` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `enableTimestamps` | `Bufo::Core::Logger->enableTimestamps` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `enableConsoleColors` | `Bufo::Core::Logger->enableConsoleColors` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `enableGrouping` | `Bufo::Core::Logger->enableGrouping` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `setContext` | `Bufo::Core::Logger->setContext` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `error` | `Bufo::Core::Logger->error` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `warn` | `Bufo::Core::Logger->warn` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `log` | `Bufo::Core::Logger->log` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `info` | `Bufo::Core::Logger->info` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `debug` | `Bufo::Core::Logger->debug` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `trace` | `Bufo::Core::Logger->trace` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `group` | `Bufo::Core::Logger->group` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `groupCollapsed` | `Bufo::Core::Logger->groupCollapsed` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `groupEnd` | `Bufo::Core::Logger->groupEnd` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `table` | `Bufo::Core::Logger->table` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `styled` | `Bufo::Core::Logger->styled` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `time` | `Bufo::Core::Logger->time` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |
| `createLogger` | `Bufo::Core::Logger->createLogger` in [lib/Bufo/Core/Logger.pm](../lib/Bufo/Core/Logger.pm) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/utils/mathUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `randomInt` | `Bufo::Util::Math->randomInt` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `randomFloat` | `Bufo::Util::Math->randomFloat` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `mapRange` | `Bufo::Util::Math->mapRange` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `inRange` | `Bufo::Util::Math->inRange` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `lerp` | `Bufo::Util::Math->lerp` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `inverseLerp` | `Bufo::Util::Math->inverseLerp` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `distance` | `Bufo::Util::Math->distance` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `angle` | `Bufo::Util::Math->angle` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `toDegrees` | `Bufo::Util::Math->toDegrees` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `toRadians` | `Bufo::Util::Math->toRadians` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `pointFromAngle` | `Bufo::Util::Math->pointFromAngle` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `smoothLerp` | `Bufo::Util::Math->smoothLerp` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `weightedRandom` | `Bufo::Util::Math->weightedRandom` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `factorial` | `Bufo::Util::Math->factorial` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `chance` | `Bufo::Util::Math->chance` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |
| `randomNormal` | `Bufo::Util::Math->randomNormal` in [lib/Bufo/Util/Math.pm](../lib/Bufo/Util/Math.pm) | callable |

Related checks: [t/util_differential.t](../t/util_differential.t), [t/util_services.t](../t/util_services.t).

## `src/utils/numberUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `roundTo` | `Bufo::Util::Number::roundTo` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `clamp` | `Bufo::Util::Number::clamp` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `calculateExponentialCost` | `Bufo::Util::Number::calculateExponentialCost` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `formatNumber` | `Bufo::Util::Number::formatNumber` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `formatNumberWithPrecision` | `Bufo::Util::Number::formatNumberWithPrecision` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `getNumberFullName` | `Bufo::Util::Number::getNumberFullName` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `formatDuration` | `Bufo::Util::Number::formatDuration` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `calculatePercentage` | `Bufo::Util::Number::calculatePercentage` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `formatPercentage` | `Bufo::Util::Number::formatPercentage` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `sum` | `Bufo::Util::Number::sum` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |
| `average` | `Bufo::Util::Number::average` in [lib/Bufo/Util/Number.pm](../lib/Bufo/Util/Number.pm) | callable |

Related checks: [t/util_differential.t](../t/util_differential.t), [t/util_services.t](../t/util_services.t).

## `src/utils/saveManager.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `ISaveManager` | `saveGame/loadGame/clearSave/exportSave/importSave service contract` in [lib/Bufo/Util/SaveManager.pm](../lib/Bufo/Util/SaveManager.pm) | data contract |
| `getSaveManager` | `Bufo::Util::SaveManager->getSaveManager` in [lib/Bufo/Util/SaveManager.pm](../lib/Bufo/Util/SaveManager.pm) | callable |

Related checks: [t/save.t](../t/save.t), [t/util_services.t](../t/util_services.t), [scripts/browser-faults.pl](../scripts/browser-faults.pl).

## `src/utils/saveManagerTypes.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `SaveData` | `legacy envelope: state, generators, upgrades, explorer, timestamp, version` in [lib/Bufo/Util/SaveManager.pm](../lib/Bufo/Util/SaveManager.pm) | data contract |

Related checks: [t/save.t](../t/save.t), [t/util_services.t](../t/util_services.t), [scripts/browser-faults.pl](../scripts/browser-faults.pl).

## `src/utils/stateUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `updateState` | `Bufo::Util::State::updateState` in [lib/Bufo/Util/State.pm](../lib/Bufo/Util/State.pm) | callable |
| `createDefaultState` | `Bufo::Util::State->createDefaultState` in [lib/Bufo/Util/State.pm](../lib/Bufo/Util/State.pm) | callable |
| `calculateDerivedState` | `Bufo::Util::State::calculateDerivedState` in [lib/Bufo/Util/State.pm](../lib/Bufo/Util/State.pm) | callable |
| `validateState` | `Bufo::Util::State::validateState` in [lib/Bufo/Util/State.pm](../lib/Bufo/Util/State.pm) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/utils/storageUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `isStorageAvailable` | `Bufo::Util::Storage->isStorageAvailable` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `saveToStorage` | `Bufo::Util::Storage->saveToStorage` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `loadFromStorage` | `Bufo::Util::Storage->loadFromStorage` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `clearStorage` | `Bufo::Util::Storage->clearStorage` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `clearAllStorage` | `Bufo::Util::Storage->clearAllStorage` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `exportToString` | `Bufo::Util::Storage->exportToString` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `importFromString` | `Bufo::Util::Storage->importFromString` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `getStorageSize` | `Bufo::Util::Storage->getStorageSize` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |
| `hasStorageKey` | `Bufo::Util::Storage->hasStorageKey` in [lib/Bufo/Util/Storage.pm](../lib/Bufo/Util/Storage.pm) | callable |

Related checks: [t/util.t](../t/util.t), [t/util_services.t](../t/util_services.t), [t/core_services.t](../t/core_services.t).

## `src/utils/timeUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `getCurrentTime` | `Bufo::Util::Time->getCurrentTime` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `calculateElapsedTime` | `Bufo::Util::Time->calculateElapsedTime` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `formatTimeAgo` | `Bufo::Util::Time->formatTimeAgo` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `throttle` | `Bufo::Util::Time->throttle` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `debounce` | `Bufo::Util::Time->debounce` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `calculateFPS` | `Bufo::Util::Time->calculateFPS` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |
| `formatTimestamp` | `Bufo::Util::Time->formatTimestamp` in [lib/Bufo/Util/Time.pm](../lib/Bufo/Util/Time.pm) | callable |

Related checks: [t/util_differential.t](../t/util_differential.t), [t/util_services.t](../t/util_services.t).

## `src/utils/tooltipUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `showTooltip` | `Bufo::Browser::Tooltip::showTooltip` in [lib/Bufo/Browser/Tooltip.pm](../lib/Bufo/Browser/Tooltip.pm) | callable |
| `cancelTooltip` | `Bufo::Browser::Tooltip::cancelTooltip` in [lib/Bufo/Browser/Tooltip.pm](../lib/Bufo/Browser/Tooltip.pm) | callable |
| `hideTooltip` | `Bufo::Browser::Tooltip::hideTooltip` in [lib/Bufo/Browser/Tooltip.pm](../lib/Bufo/Browser/Tooltip.pm) | callable |
| `updateTooltipPosition` | `Bufo::Browser::Tooltip::updateTooltipPosition` in [lib/Bufo/Browser/Tooltip.pm](../lib/Bufo/Browser/Tooltip.pm) | callable |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## `src/utils/validationUtils.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `isValidNumber` | `Bufo::Util::Validation::isValidNumber` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidInteger` | `Bufo::Util::Validation::isValidInteger` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isPositiveNumber` | `Bufo::Util::Validation::isPositiveNumber` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isNonNegativeNumber` | `Bufo::Util::Validation::isNonNegativeNumber` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isInRange` | `Bufo::Util::Validation::isInRange` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isNonEmptyString` | `Bufo::Util::Validation::isNonEmptyString` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidArray` | `Bufo::Util::Validation::isValidArray` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isNonEmptyArray` | `Bufo::Util::Validation::isNonEmptyArray` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidDate` | `Bufo::Util::Validation::isValidDate` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidObject` | `Bufo::Util::Validation::isValidObject` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `hasRequiredProperties` | `Bufo::Util::Validation::hasRequiredProperties` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `validateObject` | `Bufo::Util::Validation::validateObject` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidEmail` | `Bufo::Util::Validation::isValidEmail` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isValidUrl` | `Bufo::Util::Validation::isValidUrl` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `createValidationResult` | `Bufo::Util::Validation::createValidationResult` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `isOneOf` | `Bufo::Util::Validation::isOneOf` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |
| `validateSaveData` | `Bufo::Util::Validation::validateSaveData` in [lib/Bufo/Util/Validation.pm](../lib/Bufo/Util/Validation.pm) | callable |

Related checks: [t/util_differential.t](../t/util_differential.t), [t/util_services.t](../t/util_services.t).

## `styles/styleLoader.ts`

| Original declaration | Perl implementation | Contract |
| --- | --- | --- |
| `loadStylesheet` | `Bufo::Browser::StyleLoader::loadStylesheet` in [lib/Bufo/Browser/StyleLoader.pm](../lib/Bufo/Browser/StyleLoader.pm) | callable |
| `addStyles` | `Bufo::Browser::StyleLoader::addStyles` in [lib/Bufo/Browser/StyleLoader.pm](../lib/Bufo/Browser/StyleLoader.pm) | callable |
| `initializeStyles` | `Bufo::Browser::StyleLoader::initializeStyles` in [lib/Bufo/Browser/StyleLoader.pm](../lib/Bufo/Browser/StyleLoader.pm) | callable |
| `cleanupStyles` | `Bufo::Browser::StyleLoader::cleanupStyles` in [lib/Bufo/Browser/StyleLoader.pm](../lib/Bufo/Browser/StyleLoader.pm) | callable |
| `default` | `loadStylesheet, addStyles, initializeStyles, cleanupStyles` in [lib/Bufo/Browser/StyleLoader.pm](../lib/Bufo/Browser/StyleLoader.pm) | forwarding |

Related checks: [scripts/browser-ui.pl](../scripts/browser-ui.pl), [scripts/browser-test.pl](../scripts/browser-test.pl).

## Runtime and data adaptations

- Catalog JSON retains all generators, upgrades, and achievements. Enemy and drop metadata resides in `Bufo::Enemies`; boss definitions reside in `Bufo::Catalog`. Model enum maps retain their source spellings.
- Explorer model and manager algorithms remain separate. Delta time advances progress and healing; wall-clock time determines completed exploration duration. Manager-local combat context remains transient, as in the original. Exploration rewards update Explorer totals without crediting the main bank, matching the original unwired callback.
- Save reconstruction validates durable data and rebuilds derived effects. It does not replay currency rewards. Current-format data takes precedence over migration data, and corrupt current data does not trigger a destructive fallback.
- Browser adapters use platform DOM, URL, date, storage, and timer objects. Perl owns game logic and callbacks. Template actions accept Perl callbacks instead of JavaScript source strings.
- Deferred completion callbacks use Perl scheduling; this does not reproduce JavaScript microtask ordering. Native URL/date fallbacks are narrower than browser platform adapters.
- The browser default remains dark with white primary text. The visible Reset control affects owned game-save keys. The explicit development `hardReset` retains the original behavior of clearing all origin storage and reloading. Development debug tools are omitted from production bindings.
