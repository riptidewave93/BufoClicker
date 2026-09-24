# Perl/WASM migration

This port replaces the application language while retaining static hosting.
The [ADR](adr/0001-port-client-to-perl-and-webassembly.md) explains the runtime
choice. This document describes the implementation boundaries and compatibility
rules for reviewing the change.

## Architecture

```mermaid
flowchart LR
  JSON[Static content JSON] --> Catalog[Perl catalog validation]
  Catalog --> Game[Perl game engine]
  Save[Perl save validation] --> Game
  Game --> UI[Perl browser UI]
  UI --> Bridge[WebPerl DOM bridge]
  Bridge --> Browser[Browser DOM and localStorage]
  Game --> Tests[Native Perl tests]
```

The engine receives time as an argument. Economy, achievement rewards, boss
health and prestige do not depend on a browser or a wall-clock lookup. Views
read one authoritative state. They do not maintain independent copies of
purchase counts or click power.

Catalogs retain the original JSON format and IDs: 14 generators, 91 upgrades
and 50 achievements. Boss definitions retain the seven original IDs and health
values. The browser loads all three catalogs before accepting a save or
starting timers. Invalid data produces a startup error, not an empty game.

## State and effects

Durable state stores current and run-total currency, click count, generator
ownership, purchased upgrades, achievement unlocks and custom event flags,
prestige, boss history and game settings. Generator definitions and derived
production are reconstructed from the catalogs.

Click power combines the base value, click upgrades and achievement rewards,
prestige, banked boss rewards and any active click frenzy. Production uses
its own upgrade and achievement multipliers. A production upgrade does not
multiply clicks. The engine rebuilds these values in one place.

The browser controls Golden Bufo appearance and positioning. The engine
classifies a supplied random sample and applies the resulting reward. Boss
countdowns and temporary frenzy expiry belong to the engine. UI movement and
result-modal guards do not determine whether damage or rewards count.

## Save migration

| Input | Result |
| --- | --- |
| Valid Perl key | Restore Perl progress, regardless of any legacy key. |
| No Perl key, valid legacy key | Validate legacy nested state, create Perl progress, keep legacy value. |
| Invalid Perl key | Show recovery choices and block automatic writes. |
| Invalid legacy key on first migration | Show recovery choices and preserve the original value. |
| No saved keys | Start a fresh game. |
| Failed import or reset write | Keep current game and stored progress. |

The old envelope contains duplicate generator, upgrade and explorer values
outside `state`. Migration uses the nested state, matching the original loader.
Missing prestige and boss fields use backward-compatible defaults. Older
prestige saves can use `points` when `lifetimePoints` is absent.

The new schema has its own version and storage key. The legacy save remains a
recovery source, not a second target for ongoing writes. Moving between origins
still requires export/import because browser storage belongs to an origin.

Two baseline effect bugs are corrected explicitly: reloads do not replay
one-time achievement payouts, and prestige retains the effects of retained
achievements. Bulk Max purchases also verify the rounded actual price instead
of trusting only a logarithmic estimate. These corrections preserve earned
progress and the documented reward rules; catalog balance is unchanged.

## Time and lifecycle

The visible game updates from a bounded timer. Hiding the tab saves and pauses
the game. A paused fight keeps its remaining time; temporary frenzies stop.
Returning to the tab credits permanent generator production for the elapsed
gap before resuming. It does not run the boss timer through the hidden period.

Reload credit has a one-minute floor. Tab return has no floor. Both paths cap
credited time at 12 hours. Neither path restores a temporary frenzy. Purchases,
manual Save, periodic autosave and page lifecycle handlers persist progress.

## Packaging and hosting

The Perl build script concatenates application packages in dependency order.
It registers bundled module names in `%INC` before later packages use them.
Custom application modules use methods rather than compile-time Exporter lists.
The result is a single `app.pl` loaded by an external `text/perl` script tag.

The build copies the existing styles, images and catalogs. CSS imports occur
before style rules so native browser loading follows the same module order as
the old webpack loader. `mobile.css` remains the last base import. Relative
URLs support both site-root hosting and `/BufoClicker/` without a server API.

Docker supplies native Perl, download tools and pinned Binaryen 108. The build
applies the arithmetic compatibility transform described in the ADR before
packaging WASM. nginx serves the resulting
static tree. GitHub Actions builds that same tree for Pages. Browser checks use
a Perl WebDriver client against an isolated Selenium Chromium container; no
Node application toolchain is required.

## Review evidence

The [parity matrix](parity.md) maps gameplay and persistence behavior to checks.
The [verification record](verification.md) records actual commands, browser
coverage, measured runtime costs and screenshots. Native tests prove rules;
browser tests prove wiring and interactions. Screenshots establish rendered
appearance, not gameplay correctness.
