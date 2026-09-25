# UI library operations

`BUFO-COMPONENTS(request, context, response)` receives three JSON handles by value.
Requests use `operation` and positional `args`. Results are returned in `result`.
Component references are `{"$component":"..."}`, element references are
`{"$element":"..."}`, and callback references are `{"$callback":"..."}`.

- `templates.*` accepts the original TypeScript positional arguments and returns HTML.
- `component.create(kind, options)` returns a component reference. Kinds are Component,
  Container, ResourceDisplay, ClickArea, GeneratorItem, GeneratorList, ShopItem,
  Shop and UpgradeItem and UpgradeList. `component.method(reference, ...args)` and
  `container.method(reference, ...args)` expose the corresponding instance methods.
  Concrete methods also accept the lower-camel kind prefix, such as
  `shop.setPurchaseAmount(reference, amount)` and `generatorList.refreshGenerators(reference)`.
- `dom.*` accepts the original positional arguments. Browser queries return live
  element references. The native fixture supplies deterministic DOM query responses.
- `animation.*` accepts the original positional arguments; `animation.Easing.name(t)`
  returns a number. Animation handles support `animation.cancel(handle)`.
- `tooltip.*` accepts the original arguments, with plain mouse-event coordinates.
- `styles.*` accepts the original stylesheet loader arguments.

All DOM mutation and measurement uses generic commands. Browser callbacks resume
COBOL through request operations; application markup and callback decisions are COBOL.
No browser query is represented as an unconditional null success.

Concrete kinds also include ProductionStats, GoldenBufo and BossFight. The latter
own independently initialized overlay roots and share the real game's COBOL
presentation queries. Destroy removes those owned roots.

The six named factory operations retain the original parameters:
`component.createResourceDisplay(options)`, `createClickArea(options)`,
`createGeneratorList(containerId)`, `createShop(containerId)`,
`createUpgradeList(containerId)` and `createProductionStats(containerId)`.
`component.initializeUI()` initializes all six and returns their named references.
`uiConstants.NAME` and `uiStyles.NAME` expose every original exported value;
`.get(name)` and `.get()` return one value or the namespace dictionary.

Animation results carry `$promise` and `$animation`; decoded promises retain their
reference token and can be passed to `animation.cancel`. Stylesheet operations
return `$promise` tokens and emit resolve/reject commands. External callbacks are
`domCallback` response commands, invoked only after COBOL returns. Selector and
custom-easing results resume `component.selected` and `animation.eased`; a removed
subscription or cancelled animation discards its pending continuation. The host
also defers synchronous DOM events that occur during a WASM call.

`uiLibrary.needsNotifications` is true while a state/event subscription or an
initialized auto-refresh component needs notifications. Lazy facade adapters alone
do not enable state cloning. Destroy recomputes the flag.

The generic DOM bridge owns live element handles and listeners. Public DOM remove
operations retain externally referenced handles. Tooltip delayed removal releases
its internally owned handle. `dom.focus(element)` exposes the same generic focus
primitive used by the host.

See [execution evidence](EVIDENCE.md) for comparison scope and intentional UI
adaptations. Main-screen information buttons open accessible detail dialogs using
the same concrete component tooltip markup. The dark layout remains the owner’s
chosen presentation.
