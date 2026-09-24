# syntax=docker/dockerfile:1
FROM perl:5.40.2-slim-bookworm AS tools
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip binaryen=108-1 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
CMD ["perl", "scripts/build.pl"]

FROM tools AS build
RUN prove -lr t && perl scripts/build.pl

FROM nginx:1.28.0-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
