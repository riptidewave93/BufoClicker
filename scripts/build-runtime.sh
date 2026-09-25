#!/bin/sh
set -eu
runtime_sources=/opt/runtime-sources
runtime_prefix=/opt/wasm
mkdir -p "$runtime_sources" "$runtime_prefix"
cd "$runtime_sources"
curl -fsSL https://ftp.gnu.org/gnu/gnucobol/gnucobol-3.1.2.tar.xz -o gnucobol-3.1.2.tar.xz
curl -fsSL https://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz -o gmp-6.2.1.tar.xz
printf '%s\n' \
  '597005d71fd7d65b90cbe42bbfecd5a9ec0445388639404662e70d53ddf22574  gnucobol-3.1.2.tar.xz' \
  'fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2  gmp-6.2.1.tar.xz' | sha256sum -c -
tar -xf gmp-6.2.1.tar.xz
tar -xf gnucobol-3.1.2.tar.xz
cd gmp-6.2.1
emconfigure ./configure --host=none --build="$(gcc -dumpmachine)" \
  --disable-assembly --disable-shared --enable-static --prefix="$runtime_prefix"
emmake make -j"$(nproc)"
emmake make install
cd ../gnucobol-3.1.2
emconfigure ./configure --host=none --build="$(gcc -dumpmachine)" --disable-nls \
  --without-db --without-curses --without-xml2 --without-json --with-dl \
  --disable-shared --enable-static --with-math=gmp --prefix="$runtime_prefix" \
  CPPFLAGS="-I$runtime_prefix/include" LDFLAGS="-L$runtime_prefix/lib"
# The upstream cross-compile probe defines COB_LI_IS_LL even when its value
# is zero. libcob tests its presence, so wasm32 needs it undefined. Verify
# the target widths before supplying the two configure results explicitly.
printf '%s\n' '_Static_assert(sizeof(long) == 4, "wasm32 long");' \
  '_Static_assert(sizeof(long long) == 8, "wasm32 long long");' \
  | emcc -x c -c -o /tmp/wasm-widths.o -
sed -i 's/^#define COB_LI_IS_LL .*/\/\* #undef COB_LI_IS_LL \*\//; s/^#define COB_32_BIT_LONG .*/#define COB_32_BIT_LONG 1/' config.h
emmake make -C libcob -j"$(nproc)"
emmake make -C libcob install
cp libcob.h "$runtime_prefix/include/"
