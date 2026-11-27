import { useEffect, useMemo, useState } from "react";
import { Bookmark, Check, Compass, Search, Settings2, Tv, X } from "lucide-react";
import type { CatalogTitle, Provider } from "@optimus/shared";

type Section = "discover" | "services" | "library";

function readStorage<T>(key: string, fallback: T): T {
  try {
    const value = localStorage.getItem(key);
    return value ? (JSON.parse(value) as T) : fallback;
  } catch {
    return fallback;
  }
}

export default function App() {
  const [titles, setTitles] = useState<CatalogTitle[]>([]);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState<string[]>(() => readStorage("optimus-services", []));
  const [saved, setSaved] = useState<CatalogTitle[]>(() => readStorage("optimus-watchlist-items", []));
  const [error, setError] = useState("");
  const [providerLoading, setProviderLoading] = useState(true);
  const [loading, setLoading] = useState(false);
  const [section, setSection] = useState<Section>("discover");

  useEffect(() => {
    const controller = new AbortController();
    fetch("/api/providers", { signal: controller.signal })
      .then(async response => {
        const data = await response.json();
        if (!response.ok) throw new Error(data.error || "Could not load streaming services.");
        return data;
      })
      .then(data => {
        setProviders(Array.isArray(data.items) ? data.items : []);
        setError("");
      })
      .catch(reason => {
        if (reason.name !== "AbortError") setError(reason.message || "Could not load streaming services.");
      })
      .finally(() => {
        if (!controller.signal.aborted) setProviderLoading(false);
      });
    return () => controller.abort();
  }, []);

  useEffect(() => localStorage.setItem("optimus-services", JSON.stringify(selected)), [selected]);
  useEffect(() => localStorage.setItem("optimus-watchlist-items", JSON.stringify(saved)), [saved]);

  useEffect(() => {
    if (!selected.length) {
      setTitles([]);
      setLoading(false);
      return;
    }
    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      setLoading(true);
      const params = new URLSearchParams({ providers: selected.join(",") });
      if (query.trim()) params.set("q", query.trim());
      fetch("/api/catalog?" + params.toString(), { signal: controller.signal })
        .then(async response => {
          const data = await response.json();
          if (!response.ok) throw new Error(data.error || "Catalog request failed.");
          return data;
        })
        .then(data => {
          setTitles(Array.isArray(data.items) ? data.items : []);
          setError("");
        })
        .catch(reason => {
          if (reason.name !== "AbortError") setError(reason.message || "Catalog request failed.");
        })
        .finally(() => {
          if (!controller.signal.aborted) setLoading(false);
        });
    }, 250);
    return () => {
      window.clearTimeout(timer);
      controller.abort();
    };
  }, [query, selected]);

  const toggleProvider = (id: string) => {
    setSelected(current => current.includes(id) ? current.filter(item => item !== id) : [...current, id]);
  };
  const toggleSaved = (title: CatalogTitle) => {
    setSaved(current => current.some(item => item.id === title.id)
      ? current.filter(item => item.id !== title.id)
      : [title, ...current]);
  };
  const providerName = (id: string) => providers.find(provider => provider.id === id)?.name || id;
  const library = useMemo(() => saved, [saved]);
  const isSaved = (id: string) => saved.some(item => item.id === id);

  const card = (title: CatalogTitle) => (
    <article className="card" key={title.id}>
      <div className="poster">
        <small>{title.type.toUpperCase()}</small>
        <strong>{title.name}</strong>
        <span>{title.year || "Release year unknown"}</span>
      </div>
      <div className="details">
        <div className="titleRow">
          <h3>{title.name}</h3>
          <button className="iconButton" onClick={() => toggleSaved(title)} aria-label={isSaved(title.id) ? "Remove from watchlist" : "Save to watchlist"} aria-pressed={isSaved(title.id)}>
            {isSaved(title.id) ? <Check /> : <Bookmark />}
          </button>
        </div>
        <small>{title.year || "Year unknown"} · {title.rating || "Unrated"} · {title.type === "series" ? "Series" : title.runtime || "Movie"}</small>
        <p>{title.synopsis}</p>
        <div className="offers">{title.offers.map((offer, index) => <span key={offer.providerId + index}>{providerName(offer.providerId)} · INCLUDED</span>)}</div>
      </div>
    </article>
  );

  return (
    <main className="shell">
      <header>
        <a className="brand" href="#" onClick={event => { event.preventDefault(); setSection("discover"); }}><b>O</b> OPTIMUS</a>
        <nav aria-label="Main navigation">
          <button className={section === "discover" ? "current" : ""} onClick={() => setSection("discover")}><Compass /> Discover</button>
          <button className={section === "library" ? "current" : ""} onClick={() => setSection("library")}><Bookmark /> My Library</button>
          <button className={section === "services" ? "current" : ""} onClick={() => setSection("services")}><Tv /> Services</button>
        </nav>
      </header>

      <section className="hero">
        <label>YOUR ENTERTAINMENT, UNIFIED</label>
        <h1>Less searching.<br /><em>More watching.</em></h1>
        <p>One place to discover what’s worth watching across the services you already have.</p>
      </section>

      {section === "services" ? (
        <section className="catalog">
          <label>YOUR SUBSCRIPTIONS</label>
          <h2>Which services do you use?</h2>
          <p className="muted">Choose every service included in your subscriptions. OPTIMUS will only show titles available on at least one selected service.</p>
          {providerLoading ? <p className="muted">Loading available streaming services…</p> : (
            <div className="filters serviceGrid">
              {providers.map(provider => (
                <button type="button" className={selected.includes(provider.id) ? "active" : ""} key={provider.id} onClick={() => toggleProvider(provider.id)} aria-pressed={selected.includes(provider.id)}>
                  {selected.includes(provider.id) ? <Check /> : null}{provider.name}
                </button>
              ))}
            </div>
          )}
          {!providerLoading && providers.length === 0 && <p className="empty">No streaming services are available. Check the API connection and TMDB configuration.</p>}
          <p className="selectionCount">{selected.length} {selected.length === 1 ? "service" : "services"} selected</p>
          <button className="primary" onClick={() => setSection("discover")}>Save services &amp; discover</button>
        </section>
      ) : section === "library" ? (
        <section className="section">
          <label>YOUR PERSONAL COLLECTION</label>
          <h2>My watchlist</h2>
          <div className="grid">{library.map(card)}</div>
          {library.length === 0 && <p className="empty">Your watchlist is empty. Save titles while browsing to keep them here.</p>}
        </section>
      ) : (
        <>
          <section className="catalog">
            <label>THE UNIFIED CATALOG · UNITED STATES</label>
            <h2>Find something worth your time.</h2>
            <div className="search"><Search /><input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search movies, series…" aria-label="Search movies and series" /></div>
            <div className="filters">
              <span><Settings2 /> My subscriptions:</span>
              {selected.length ? selected.map(id => <button className="active" key={id} onClick={() => toggleProvider(id)}>{providerName(id)} <X /></button>) : <span>Select services to begin</span>}
              <button onClick={() => setSection("services")}>Edit services</button>
            </div>
          </section>
          <section className="section">
            <label>MATCHED TO YOUR SERVICES</label>
            <h2>{query ? "Search results" : "Worth watching now"}</h2>
            {loading && <p className="muted">Searching streaming catalogs…</p>}
            {!loading && selected.length === 0 && <p className="empty">Choose your streaming subscriptions to see matching titles.</p>}
            <div className="grid">{titles.map(card)}</div>
            {!loading && selected.length > 0 && titles.length === 0 && <p className="empty">No titles match your selected services. Try another search.</p>}
          </section>
        </>
      )}

      {error && <p className="error" role="alert">{error}</p>}
      <footer>
        <span>OPTIMUS · One interface. Many ways to watch.</span>
        <small>Availability: United States · Powered by TMDB</small>
        <small>This product uses the TMDB API but is not endorsed or certified by TMDB.</small>
      </footer>
    </main>
  );
}
