# OPTIMUS Platform

A web-first entertainment discovery product for subscribers with multiple streaming services. OPTIMUS searches a shared catalog and returns only titles available through at least one service selected by the subscriber. It does not relay, proxy, or embed protected provider streams.

## Monorepo

- `apps/web` — React + TypeScript web client.
- `apps/api` — Hono API on Cloudflare Workers.
- `packages/shared` — shared TypeScript contracts.
- `roku` — native Roku SceneGraph/BrightScript client.

## Live catalog beta

The API now uses TMDB for movie/TV search, title details, US streaming-provider lists, and US watch availability.

- `GET /api/providers` — real US streaming provider list.
- `GET /api/catalog?q=...&providers=8,9` — search and return only titles with a subscription (flatrate) offer on one or more selected provider IDs.
- `GET /api/catalog` — trending titles, filtered by the supplied provider IDs.
- `GET /api/catalog/movie:123` or `/api/catalog/tv:456` — title details and US subscription offers.
- `GET /api/health` — API health.

The beta intentionally excludes rental and purchase offers from search results. Provider IDs are fetched from TMDB; do not hardcode provider IDs or provider names.

### Configure TMDB

1. Create a TMDB account and request an API Read Access Token from the API section of account settings.
2. Copy `apps/api/.dev.vars.example` to `apps/api/.dev.vars`.
3. Set `TMDB_READ_ACCESS_TOKEN` to your API Read Access Token in `.dev.vars`.
4. Run `npm install` and `npm run dev` from the repository root.

For a deployed Worker, set the token as a secret from `apps/api`:

```sh
npx wrangler secret put TMDB_READ_ACCESS_TOKEN
```

Never commit `.dev.vars` or expose the token in the web or Roku clients.

### TMDB licensing and attribution

The TMDB developer API is free for non-commercial use with attribution. TMDB states that projects whose primary purpose is generating revenue for the owner are commercial and require a commercial license. OPTIMUS is intended to become a commercial product, so obtain written permission/a commercial license from TMDB before public or revenue-generating use. This integration is a development/beta implementation, not a determination that commercial use is authorized.

The application must display the approved TMDB logo and this notice prominently in an About/Credits area:

> This product uses the TMDB API but is not endorsed or certified by TMDB.

See [TMDB API FAQ](https://developer.themoviedb.org/docs/faq) and [TMDB Getting Started](https://developer.themoviedb.org/docs/getting-started).

## Local development

Requires Node.js 20+.

```sh
npm install
npm run dev
```

Web: `http://localhost:5173`. API: `http://localhost:8787`.

## Current beta boundaries

- Service selections and watchlists are currently saved locally in the web browser and on the Roku device. Account registration, server-side user profiles, and cross-device synchronization are not implemented yet.
- The API uses live TMDB data, but availability can be incomplete or change after retrieval. It reports US subscription/flatrate availability, not proof that a user has an active paid entitlement.
- TMDB data is a replaceable adapter behind the OPTIMUS API; clients do not call TMDB directly.
- No streaming-provider passwords are collected. Playback and stream relay are not implemented.
- The Roku client consumes the same API. See [roku/README.md](roku/README.md) for sideloading and API configuration.
