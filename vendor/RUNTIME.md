# Runtime dependencies

The build uses GnuCOBOL 3.1.2 without compiler source changes. Native builds use the compiler for the host architecture. WebAssembly C generation uses the Debian i386 compiler through QEMU, so pointer fields have the required four-byte layout. Emscripten 3.1.6 compiles the generated C and runtime libraries to WebAssembly.

| Dependency | Version | Distribution license |
| --- | --- | --- |
| GnuCOBOL libcob | 3.1.2 | [LGPL-3.0-or-later](licenses/LGPL-3.0.txt) |
| GMP | 6.2.1 | [LGPL-3.0-or-later](licenses/LGPL-3.0.txt), also offered under [GPL-2.0-or-later](licenses/GPL-2.0.txt) |
| cJSON | 1.7.19 | [MIT](licenses/cJSON-MIT.txt), also retained in [cJSON.c](../runtime/cJSON.c) and [cJSON.h](../runtime/cJSON.h) |
| Emscripten | 3.1.6 | [MIT and University of Illinois/NCSA](licenses/Emscripten.txt) |

The GnuCOBOL compiler uses [GPL-3.0-or-later](licenses/GPL-3.0.txt). The compiler, Emscripten, and QEMU are build dependencies and are not served to browsers. [The Dockerfile](../Dockerfile) defines the tools image and compiler wrapper.

## Upstream sources

These hashes identify the original source files, before the cJSON adjustment described below. [The runtime build script](../scripts/build-runtime.sh) verifies the GnuCOBOL and GMP archive hashes.

| Source | SHA-256 |
| --- | --- |
| [GnuCOBOL 3.1.2 archive](https://ftp.gnu.org/gnu/gnucobol/gnucobol-3.1.2.tar.xz) | `597005d71fd7d65b90cbe42bbfecd5a9ec0445388639404662e70d53ddf22574` |
| [GMP 6.2.1 archive](https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz) | `fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2` |
| [cJSON 1.7.19, cJSON.c](https://github.com/DaveGamble/cJSON/blob/v1.7.19/cJSON.c) | `298581a04a36c0165da4b0aade235c23088cb2faa58651d720ea2f3706ed0b0d` |
| [cJSON 1.7.19, cJSON.h](https://github.com/DaveGamble/cJSON/blob/v1.7.19/cJSON.h) | `25b0145150d500498e4d209cec69c18c42cf818bffcc54690be3b895a2a16dee` |

The tools image retains the GnuCOBOL and GMP source archives and configured source trees in `/opt/runtime-sources`. WebAssembly libraries are installed in `/opt/wasm`. [The application build script](../scripts/build.sh) links those libraries and copies the source archives and license notices into the site output. Replacing a runtime library requires relinking the application with that script.

## Runtime configuration

libcob uses `--disable-nls` because translated runtime messages triggered an Emscripten 3.1.6 locale lookup fault in Chromium. Database, curses, XML, and built-in JSON I/O are disabled. The application uses cJSON because GnuCOBOL 3.1.2 reports `JSON PARSE` as unimplemented.

The generated wasm32 `config.h` leaves `COB_LI_IS_LL` undefined and sets `COB_32_BIT_LONG` to `1`. The upstream cross-compile probe defines the former even when `long` and `long long` have different widths. libcob tests the macro with `#ifdef`, so the incorrect definition causes 64-bit integers to truncate.

The runtime build script checks that wasm32 `long` is four bytes and `long long` is eight bytes before it corrects those entries. This adjustment changes generated configuration. It does not patch GnuCOBOL, GMP, or compiler source.

## cJSON number serialization

The bundled `print_number` uses an exact double comparison to check its 15-digit rendering. Upstream uses an epsilon comparison, which can lose one binary unit when a large number is parsed again. If 15 digits do not round-trip exactly, cJSON uses its existing 17-digit path.

[The runtime JSON test](../tests/runtime/json.c) reproduces the original precision loss and verifies the adjustment. The application also uses its own exact recursive JSON comparator for state and component changes. That comparator does not modify cJSON's comparison function.

[The ABI reference](ABI.md) records module signatures, JSON ownership, numeric helpers, function bindings, and target-width requirements.
