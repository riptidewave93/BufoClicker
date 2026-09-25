# syntax=docker/dockerfile:1
FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171 AS tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnucobol3=3.1.2-5+b1 emscripten=3.1.6~dfsg-5 \
    build-essential ca-certificates curl xz-utils autoconf libtool libgmp-dev qemu-user-static \
    && dpkg --add-architecture i386 && apt-get update \
    && mkdir -p /opt/cobc32 /tmp/cobc32 && cd /tmp/cobc32 \
    && apt-get download gnucobol3:i386=3.1.2-5+b1 libcob4:i386=3.1.2-5+b1 \
    libc6:i386 libgmp10:i386 libncursesw6:i386 libtinfo6:i386 libdb5.3:i386 \
    libxml2:i386 libicu72:i386 libstdc++6:i386 libgcc-s1:i386 liblzma5:i386 zlib1g:i386 \
    && for package in *.deb; do dpkg-deb -x "$package" /opt/cobc32; done \
    && rm -rf /tmp/cobc32 /var/lib/apt/lists/*
RUN printf '#!/bin/sh\nexec qemu-i386-static -L /opt/cobc32 /opt/cobc32/lib/ld-linux.so.2 --library-path /opt/cobc32/lib/i386-linux-gnu:/opt/cobc32/usr/lib/i386-linux-gnu /opt/cobc32/usr/bin/cobc "$@"\n' > /usr/local/bin/cobc32 && chmod +x /usr/local/bin/cobc32
COPY scripts/build-runtime.sh /tmp/build-runtime.sh
RUN /tmp/build-runtime.sh
WORKDIR /app

FROM tools AS dev
COPY . .
CMD ["./scripts/dev.sh"]

FROM tools AS build
COPY . .
RUN ./scripts/build.sh

FROM nginx:1.28.0-alpine AS runtime
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
