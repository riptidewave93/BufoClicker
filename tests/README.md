# Verification

The [README](../README.md#verify-a-change) describes the native, WebAssembly, and browser gates. [.github/workflows/ci.yml](../.github/workflows/ci.yml) runs those gates and the focused API, component, Explorer, and Firefox lifecycle checks. The [module map](../docs/cobol-module-map.md) links each original module to its replacement and execution evidence.

## Reproduce source expectations

The TypeScript reference is commit `fe02bde429b650d32591f22a824f7dad8a0d4dd9`. Restore it into an ignored directory and build its dependency image:

```sh
mkdir -p build/source-reference
git archive fe02bde429b650d32591f22a824f7dad8a0d4dd9 | tar -x -C build/source-reference
docker build --target deps -t bufo-typescript-oracle build/source-reference
```

Regenerate the component, Explorer, and finite numeric expectations by executing that source in Docker:

```sh
docker run --rm -v "$PWD/build/source-reference:/source:ro" -v "$PWD/tests/components:/out" \
  bufo-typescript-oracle node /out/original.cjs
docker run --rm -v "$PWD/build/source-reference:/source:ro" -v "$PWD/tests/explorer:/out" \
  bufo-typescript-oracle node /out/oracle.cjs
docker run --rm -v "$PWD/build/source-reference:/source:ro" -v "$PWD/tests/services:/out" \
  bufo-typescript-oracle node /out/numeric-source.cjs > tests/services/numeric-edges.json
```

These commands replace the corresponding fixtures and provenance records. Review their diff before accepting new expectations. The source hashes identify the baseline; the test harnesses document mocked boundaries and deliberate transport or theme adaptations.

No TypeScript source or compiler is part of the application build. The reference image is used only to regenerate test expectations.
