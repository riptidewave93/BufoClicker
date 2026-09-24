# BufoClicker

Click cartoon frogs. Buy generators, unlock upgrades, fight bosses and transcend
for permanent bonuses. The game runs entirely in your browser, with game rules
and UI behavior written in Perl.

This fork of [pjscheetz/BufoClicker](https://github.com/pjscheetz/BufoClicker)
uses [WebPerl](https://webperl.zero-g.net/) to run Perl through WebAssembly.
It remains a static site. No application server, account or database is required.

## Run locally

Install Docker with Compose. Build the static site, then start its preview:

```sh
docker compose run --build --rm build
docker compose up dev
```

Open [localhost:9000](http://localhost:9000). Rebuild after editing Perl or assets,
then refresh the page. This development build exposes `window.debugTools`, including
Explorer/combat, resource controls, events, logging, and time scaling. The production
image omits that binding. The same preview supports
[the GitHub Pages path](http://localhost:9000/BufoClicker/).

For a production image with its assets included:

```sh
docker compose up --build site
```

Open [localhost:8080](http://localhost:8080). Stop the containers with
`docker compose down`.

## Check a change

Run the browser-independent tests:

```sh
docker compose run --build --rm test
```

Run real browser flows against the production image:

```sh
docker compose --profile browser run --build --rm browser-test
docker compose run --rm build
docker compose --profile browser run --rm browser-ui
docker compose --profile browser down
```

The browser command starts isolated Selenium Chromium and nginx containers.
It writes screenshots to ignored `artifacts/`. It does not use your normal
browser profile. See the [verification record](docs/verification.md) for the
measured results and remaining browser coverage.

On Linux, prefix the commands that write mounted files with
`BUFO_UID=$(id -u) BUFO_GID=$(id -g)` if your user is not UID/GID 1000.

## Saves

Progress lives in your browser's local storage. The Perl client writes
`bufo_idle_save_perl_v1`. On first use, it can migrate the original
`bufo_idle_save` without changing that original value. A valid Perl save takes
precedence afterward. Invalid saves show recovery choices instead of silently
starting over.

Open **Stats** for save export and import. Export before moving to another
origin or clearing browser data. Old export strings remain compatible. Neither
GitHub nor this repository stores your progress.

## Build and deploy

`scripts/build.pl` produces `dist/`, including the pinned WebPerl runtime,
Perl application, CSS, JSON and artwork. The build verifies the runtime archive's
SHA256. It caches the download in `.cache/`. Both directories are generated.

The Pages workflow builds and tests with Docker, then publishes `dist/` when
`main` changes. Configure the repository's Pages source as **GitHub Actions**.
The artifact supports both `/` and `/BufoClicker/`. Opening `index.html` directly
with a `file://` URL does not provide the HTTP environment WebPerl needs.

## Code and design

| Path | Responsibility |
| --- | --- |
| `lib/Bufo/` | Content validation, game rules, number formatting and save migration |
| `web/` | Perl browser UI and static loading shell |
| `assets/data/` | Generator, upgrade and achievement catalogs |
| `assets/images/`, `styles/` | Existing artwork and responsive styles |
| `scripts/` | Perl build and browser verification |
| `t/` | Native Perl tests and legacy save fixtures |

Read the [architecture decision](docs/adr/0001-port-client-to-perl-and-webassembly.md),
[migration description](docs/perl-wasm-migration.md), and
[parity matrix](docs/parity.md), [complete source map](docs/source-map.md), and
[development interfaces](docs/development.md) for implementation details.

WebPerl includes supplied JavaScript bridge/loader files. Application logic is
Perl; HTML, CSS and JSON remain their native formats. The runtime is a pinned
beta and adds about 16 MB before compression. This port claims no download-size
or performance improvement over the TypeScript client.
