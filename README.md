# OPTIMUS Platform

A web-first entertainment discovery product for subscribers with multiple streaming services. OPTIMUS searches a shared catalog and returns only titles available through at least one service selected by the subscriber. It does not relay, proxy, or embed protected provider streams.

## Monorepo

- `apps/web` — React + TypeScript web client.
- `apps/api` — Hono API on Cloudflare Workers.
- `packages/shared` — shared TypeScript contracts.
- `roku` — native Roku SceneGraph/BrightScript companion client.

## Live catalog beta

The API uses TMDB for movie/TV search, title details, US streaming-provider lists, and US watch availability.

- `GET /api/providers` — US streaming provider list.
- `GET /api/catalog?q=...&providers=8,9` — search titles available through selected provider IDs.
- `GET /api/catalog` — trending titles, filtered by supplied provider IDs.
- `GET /api/catalog/movie:123` or `/api/catalog/tv:456` — title details and US subscription offers.
- `GET /api/health` — API health.

The beta excludes rental and purchase offers from search results. Provider IDs are fetched from TMDB; do not hardcode provider IDs or provider names.

## Accounts and Roku pairing

OPTIMUS supports account registration and sign-in on the web app. The account profile stores selected streaming services and the watchlist so the web and Roku clients can share those preferences.

To connect a Roku, request a pairing code in the Roku app, then approve that code from the signed-in web account. Pairing uses a short-lived code and a device token; it does not ask the user to enter an account password on the TV. The Roku uses the approved device token to access the shared profile.

OPTIMUS does not collect streaming-provider passwords or transfer provider sessions. Users still sign in directly within each streaming provider app on their Roku.

## Configure TMDB

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

- Account authentication, server-side profiles, Roku device pairing, and shared provider/watchlist synchronization are implemented in the current release branch. Deployment and end-to-end smoke-test status must be confirmed from the corresponding GitHub Actions run.
- Catalog availability can be incomplete or change after retrieval. It reports US subscription/flatrate availability, not proof that a user has an active paid entitlement.
- TMDB data is a replaceable adapter behind the OPTIMUS API; clients do not call TMDB directly.
- Playback and stream relay are not implemented. Roku can hand off to supported provider apps; provider sign-in and playback remain within those apps.
- The Roku client consumes the same API. See [roku/README.md](roku/README.md) for pairing, remote controls, and sideloading.
