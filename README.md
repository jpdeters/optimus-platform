OPTIMUS Platform

A web-first, provider-independent entertainment discovery prototype.

Product direction: unify discovery, provider availability, personal watchlists, and viewing organization for people who subscribe to multiple streaming services. OPTIMUS does not relay, proxy, or embed protected provider streams.

Monorepo: apps/web (React + TypeScript), apps/api (Hono on Cloudflare Workers), packages/shared (shared contracts).

Local development requires Node.js 20+. Run npm install, then npm run dev. Web: http://localhost:5173. API health: http://localhost:8787/api/health.

Prototype boundaries: catalog entries are fictional demonstration data; provider names and offers are illustrative, not real availability claims. Authentication, persistent user accounts, licensed metadata, and licensed availability feeds remain to be integrated. Never collect streaming-provider passwords or attempt unauthorized stream access.

Next milestones: production authentication and PostgreSQL persistence; licensed catalog and regional availability; persistent user libraries; Roku client using the same API; security, privacy, testing, and deployment hardening.