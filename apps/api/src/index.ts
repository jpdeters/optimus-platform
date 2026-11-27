import { Hono } from "hono";
import { cors } from "hono/cors";
import type { CatalogResponse, CatalogTitle, HealthResponse, Provider } from "@optimus/shared";

type Bindings = { APP_VERSION?: string; TMDB_READ_ACCESS_TOKEN?: string };
type TmdbProvider = { provider_id: number; provider_name: string; logo_path?: string };
type TmdbTitle = {
  id: number; media_type?: "movie" | "tv"; title?: string; name?: string;
  overview?: string; release_date?: string; first_air_date?: string;
  genre_ids?: number[]; vote_average?: number; poster_path?: string; backdrop_path?: string;
  runtime?: number; number_of_seasons?: number; adult?: boolean;
};
const app = new Hono<{ Bindings: Bindings }>();
app.use("/api/*", cors({ origin: "*", allowMethods: ["GET", "OPTIONS"], allowHeaders: ["Content-Type", "Authorization"] }));

const TMDB = "https://api.themoviedb.org/3";
const genreNames: Record<number, string> = {
  28:"Action",12:"Adventure",16:"Animation",35:"Comedy",80:"Crime",99:"Documentary",
  18:"Drama",10751:"Family",14:"Fantasy",36:"History",27:"Horror",10402:"Music",
  9648:"Mystery",10749:"Romance",878:"Science Fiction",10770:"TV Movie",53:"Thriller",
  10752:"War",37:"Western",10759:"Action & Adventure",10762:"Kids",10763:"News",
  10764:"Reality",10765:"Sci-Fi & Fantasy",10766:"Soap",10767:"Talk",10768:"War & Politics"
};
async function tmdb<T>(path: string, token: string): Promise<T> {
  const response = await fetch(TMDB + path, { headers: { Authorization: `Bearer ${token}`, accept: "application/json" } });
  if (!response.ok) throw new Error(`TMDB request failed (${response.status})`);
  return response.json<T>();
}
function mapTitle(raw: TmdbTitle, mediaType: "movie" | "tv", offers: CatalogTitle["offers"]): CatalogTitle {
  const date = raw.release_date || raw.first_air_date || "";
  return {
    id: `${mediaType}:${raw.id}`, name: raw.title || raw.name || "Untitled",
    type: mediaType === "tv" ? "series" : "movie", year: date ? Number(date.slice(0,4)) : 0,
    genres: (raw.genre_ids || []).map(id => genreNames[id]).filter(Boolean),
    synopsis: raw.overview || "No synopsis supplied.",
    rating: raw.vote_average ? raw.vote_average.toFixed(1) + "/10" : undefined,
    runtime: raw.runtime ? `${raw.runtime} min` : undefined,
    seasons: raw.number_of_seasons, imageUrl: raw.poster_path || undefined, backdropUrl: raw.backdrop_path || undefined, offers
  };
}
async function getSubscriptionOffers(mediaType: "movie" | "tv", id: number, token: string) {
  const data = await tmdb<{ results?: Record<string, { flatrate?: TmdbProvider[] }> }>(`/${mediaType}/${id}/watch/providers`, token);
  const us = data.results?.US;
  return (us?.flatrate || []).map(p => ({
    providerId: String(p.provider_id), offerType: "subscription" as const,
    region: "US", lastVerified: new Date().toISOString()
  }));
}
app.get("/api/health", c => {
  const result: HealthResponse = { status: "ok", service: "optimus-api", version: c.env.APP_VERSION ?? "0.2.0" };
  return c.json(result);
});
app.get("/api/providers", async c => {
  const token = c.env.TMDB_READ_ACCESS_TOKEN;
  if (!token) return c.json({ error: "TMDB is not configured. Add TMDB_READ_ACCESS_TOKEN to the API environment." }, 503);
  try {
    const [movies, shows] = await Promise.all([
      tmdb<{ results: TmdbProvider[] }>("/watch/providers/movie?watch_region=US&language=en-US", token),
      tmdb<{ results: TmdbProvider[] }>("/watch/providers/tv?watch_region=US&language=en-US", token)
    ]);
    const unique = new Map<number, Provider>();
    for (const p of [...(movies.results || []), ...(shows.results || [])]) unique.set(p.provider_id, { id: String(p.provider_id), name: p.provider_name });
    return c.json({ items: [...unique.values()].sort((a,b) => a.name.localeCompare(b.name)), region: "US" });
  } catch (error) {
    return c.json({ error: error instanceof Error ? error.message : "Provider lookup failed" }, 502);
  }
});
app.get("/api/catalog", async c => {
  const token = c.env.TMDB_READ_ACCESS_TOKEN;
  if (!token) return c.json({ error: "TMDB is not configured. Add TMDB_READ_ACCESS_TOKEN to the API environment." }, 503);
  const query = (c.req.query("q") || "").trim();
  const selected = (c.req.query("providers") || "").split(",").map(x => x.trim()).filter(Boolean);
  if (!selected.length) return c.json({ items: [], total: 0, message: "Select at least one streaming service." } satisfies CatalogResponse & {message:string});
  try {
    const endpoint = query
      ? `/search/multi?query=${encodeURIComponent(query)}&include_adult=false&language=en-US&page=1`
      : "/trending/all/week?language=en-US&page=1";
    const found = await tmdb<{ results: TmdbTitle[] }>(endpoint, token);
    const candidates = (found.results || []).filter(x => x.media_type === "movie" || x.media_type === "tv").slice(0, 24);
    const enriched = await Promise.all(candidates.map(async raw => {
      const mediaType = raw.media_type as "movie" | "tv";
      try {
        const offers = await getSubscriptionOffers(mediaType, raw.id, token);
        const matching = offers.filter(o => selected.includes(o.providerId));
        return matching.length ? mapTitle(raw, mediaType, matching) : null;
      } catch { return null; }
    }));
    const items = enriched.filter((x): x is CatalogTitle => x !== null);
    const result: CatalogResponse = { items, total: items.length };
    return c.json(result);
  } catch (error) {
    return c.json({ error: error instanceof Error ? error.message : "Catalog search failed" }, 502);
  }
});
app.get("/api/catalog/:id", async c => {
  const token = c.env.TMDB_READ_ACCESS_TOKEN;
  if (!token) return c.json({ error: "TMDB is not configured." }, 503);
  const [mediaType, rawId] = c.req.param("id").split(":");
  if ((mediaType !== "movie" && mediaType !== "tv") || !/^\d+$/.test(rawId || "")) return c.json({ error: "Invalid title ID" }, 400);
  try {
    const [raw, offers] = await Promise.all([
      tmdb<TmdbTitle & { genres?: { id:number; name:string }[]; runtime?:number; number_of_seasons?:number }>(`/${mediaType}/${rawId}?language=en-US`, token),
      getSubscriptionOffers(mediaType, Number(rawId), token)
    ]);
    const title = mapTitle({ ...raw, genre_ids: raw.genres?.map(g => g.id) }, mediaType, offers);
    title.genres = raw.genres?.map(g => g.name) || title.genres;
    return c.json(title);
  } catch (error) {
    return c.json({ error: error instanceof Error ? error.message : "Title lookup failed" }, 502);
  }
});
app.notFound(c => c.json({ error: "Not found" }, 404));
export default app;
