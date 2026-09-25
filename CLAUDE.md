# Contributor instructions

## Run tools in Docker

Run every Node, npm, and npx command for this repository inside a container. The host does not need a Node toolchain. Use the committed Docker and Compose configuration. Build output under `build/` and `dist/` is generated and ignored.

See [README.md](README.md) for development, build, and verification commands. Restart the development service after source changes to rebuild. Production output contains no developer facade.

## Preserve the application boundary

COBOL owns game rules, save policy, UI markup, actions, components, and developer helpers. C and JavaScript provide generic runtime and browser operations. Put a new game decision in COBOL, even when the browser host would make it convenient to implement elsewhere.

Before changing pointer handling, JSON bindings, numeric operations, or the toolchain, read [vendor/ABI.md](vendor/ABI.md). Before changing save behavior or compatibility, read [the architecture decision](docs/adr/0001-port-client-to-cobol-and-webassembly.md) and [parity reference](docs/cobol-parity.md).

## Keep these behaviors intact

- Shop and upgrade buttons remain clickable when unaffordable. Show feedback from the purchase result. Native `disabled` swallows that interaction.
- Accept every click. Click effects have bounded lifetimes and cannot prevent later clicks.
- Keep boss result controls inert for 800 ms after a fight ends, so an in-flight click cannot dismiss the result.
- Render click effects in a fixed viewport layer and keep them within mobile viewport bounds.
- Save purchases and the first transition to hidden. Repeated hidden events are idempotent. A failed visible resume retains one uncredited source and pauses the loop until recovery succeeds.
- Build each save candidate with permanent derived values. Saving during a frenzy does not cancel the live frenzy, and loading achievements does not replay one-time currency rewards.
- Use en-US number formatting. Check large rounded prices with exact affordability comparisons. A plain numeric getter assignment uses `MOVE`, not `COMPUTE`.
- New catalog effect or condition types need matching COBOL behavior and a focused check. Unknown types must not silently unlock content.

## Verify changes

Run the relevant native check and the corresponding WebAssembly or browser check. Native success does not prove the browser ABI. For a regression, capture a failing-before and passing-after execution at the affected public boundary.

Keep source-derived oracle fixtures and their provenance. The operation contracts under `tests/` distinguish public behavior from transport adaptations. Add a focused scenario when an existing fixture does not cover the change. Review the browser console and screenshots for UI work.

Run `scripts/test.sh` in the tools container before delivery. Browser checks use their separate Playwright container and exercise both root and `/BufoClicker/` paths. Keep source archives and dependency notices in production output when changing the runtime build.
