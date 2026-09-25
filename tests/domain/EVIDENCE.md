# Domain execution evidence

The native and WebAssembly runners compile the same seven domain modules. `verify.py` exercises 1,557 calls through their public operations, including 1,000 original-order clicks. The saved model oracle was executed from the original TypeScript; its five source hashes are unchanged at baseline `fe02bde429b650d32591f22a824f7dad8a0d4dd9`.

Run inside the repository:

```sh
docker run --rm -v "$PWD:/app" -w /app bufoclicker-cobol-tools ./tests/domain/run.sh
docker run --rm -v "$PWD:/app" -w /app bufoclicker-cobol-tools ./tests/domain/run-wasm.sh
docker run --rm -v "$PWD:/app" -w /app bufoclicker-cobol-tools ./tests/domain/run-asan.sh
```

The acceptance check first failed because no COBOL domain executable existed. Subsequent failing checks exposed rounded-Max comparisons, an IEEE price rounding difference, lossy JSON number printing, early achievement predicate satisfaction, achievement discovery during rebuild, and nonfinite production silently becoming zero. Each corresponding check now passes. The original linear-cost bulk helper's NaN result uses the explicit nonfinite tag, while manager purchases reject that cost.

AddressSanitizer exposed a GnuCOBOL UDF allocation leak that killed the 1,000-click run. Generic C ABI wrappers now reuse return fields, and a separate formatting alias prevents double initialization of a GMP constant. The full native acceptance run now passes AddressSanitizer and LeakSanitizer without reported leaks or invalid accesses.

The WebAssembly suite runs the actual compiled 32-bit module under Node in Docker. Browser DOM, storage transactions and lifecycle acceptance remain separate integration evidence. The suite checks all shipped generator prices, production flags, manager versus facade purchases, all achievement predicate thresholds, prestige and permanent reward restoration, boss scaling/countdown/pause/outcomes, and golden reward boundaries/expiry cancellation. It does not claim exhaustive equivalence for arbitrary invalid model inputs.
