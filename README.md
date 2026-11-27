# OPTIMUS Platform

A web-first, provider-independent entertainment discovery prototype.

Product direction: unify discovery, provider availability, personal watchlists, and viewing organization for people who subscribe to multiple streaming services. OPTIMUS does not relay, proxy, or embed protected provider streams.

## Monorepo

- `apps/web` — React + TypeScript web client.
- `apps/api` — Hono API on Cloudflare Workers.
- `packages/shared` — shared TypeScript contracts.
- `roku` — native Roku SceneGraph/BrightScript client.

## Shared API

The web and Roku clients use the same API. The catalog endpoint is `GET /api/catalog`; provider data is `GET /api/providers`; health check is `GET /api/health`.

Local development requires Node.js 20+. Run `npm install`, then `npm run dev`. Web: `http://localhost:5173`. API: `http://localhost:8787`.

## Roku development

See [roku/README.md](roku/README.md) for API configuration and sideload instructions. Set `OptimusApiBase()` in `roku/source/config.brs` to the API origin. For a local API, use the development computer's LAN IP address, not `localhost`.

The Roku client is an early prototype. It has not yet been compiled, packaged, or tested on physical hardware. Roku package artwork still needs to be added before a sideload-ready ZIP can be produced.

## Prototype boundaries

Catalog entries are fictional demonstration data; provider names and offers are illustrative, not real availability claims. Authentication, persistent user accounts, licensed metadata, and licensed availability feeds remain to be integrated. Never collect streaming-provider passwords or attempt unauthorized stream access.

Playback is not implemented.
