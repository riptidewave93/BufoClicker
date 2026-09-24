# Development interfaces

Build the development preview with `docker compose run --rm build`, then start
`docker compose up dev`. The explicit `--development` build flag exposes
`window.debugTools` in the browser console. The production image and default
`perl scripts/build.pl` build omit that binding.

## Inspect and control the game

The console objects call the running Perl services through WebPerl. They share
the same state and EventBus as the visible game. Importing or resetting a game
rebinds calls to the replacement instance.

```js
debugTools.inspect.state();
debugTools.inspect.production();
debugTools.resources.add(1000);
debugTools.generators.getAllGenerators();
debugTools.time.setTimeScale(2);
debugTools.time.setTimeScale(1);
```

The original groups remain available: `state`, `events`, `gameCore`, `gameLoop`,
`ui`, `generators`, `upgrades`, `explorer`, `prestige`, `golden`, `boss`, `save`,
`time`, `resources`, `inspect`, `events_debug`, `logging`, `generator_debug`,
`upgrade_debug`, `reset`, and `performance`. Call `debugTools.help()` for the
command catalog.

## Explorer and combat

Explorer has no player panel in the original application. Its public operations
remain available, and the game loop advances it while the page is visible.

```js
debugTools.explorer.getAvailableAreas();
debugTools.explorer.startExploration("Pond");
debugTools.explorer.getExplorer();
debugTools.explorer.getCurrentEnemy();
debugTools.explorer.getCurrentCombat();
```

Once an encounter starts, `performCombatAction("attack")`,
`performCombatAction("defend")`, and `performCombatAction("flee")` use the
original combat rules. `autoResolveCombat()` runs the original automatic
simulation. The source operation map describes the separate pure-model API.

Explorer data, equipment, stat upgrades, and accumulated rewards are saved.
Encounter and combat objects are transient, as in the original client. Reloading
an active fight preserves the Explorer's fighting state but cannot reconstruct
its opponent. The original Explorer reset clears transient context but also leaves that state
unchanged. A full game reset clears it. This conversion preserves that limitation
and does not invent a new encounter save format.

## Native Perl interfaces

`Bufo::API` provides the original Game facade. Its `game` callback resolves the
current `Bufo::Game`, and its `clock` callback supplies epoch milliseconds.
Browser lifecycle and persistence operations use injected hooks. The browser
owns storage writes and validates a replacement before accepting it.

Managers retain the original camelCase methods. Manager purchase operations
return a cost without spending the main currency bank. The Game facade spends
that cost once. Model helpers retain the source copy behavior. Most return updated copies, but
combat actions append to the shared combat log, as in the original. The original singleton getters map to application-owned
service instances, avoiding separate state stores.

`Bufo::Core::StateManager` returns snapshots and supports subscriptions and
batches. `Bufo::Core::EventBus` dispatches named events synchronously. Utility
services accept clock, timer, transport, storage, and console adapters so their
behavior can be tested under native Perl and WebPerl.

See the [complete source map](source-map.md) for individual operations and the
[verification record](verification.md) for executed checks.
