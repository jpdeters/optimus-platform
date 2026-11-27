import {useEffect,useMemo,useState} from "react";
import {Bookmark,Check,Compass,Search,Settings2,Tv} from "lucide-react";
import type {CatalogTitle,Provider} from "@optimus/shared";
export default function App(){
 const [titles,setTitles]=useState<CatalogTitle[]>([]);
 const [providers,setProviders]=useState<Provider[]>([]);
 const [q,setQ]=useState("");
 const [selected,setSelected]=useState<string[]>(()=>JSON.parse(localStorage.getItem("optimus-services")||"[]"));
 const [saved,setSaved]=useState<string[]>(()=>JSON.parse(localStorage.getItem("optimus-watchlist")||"[]"));
 const [error,setError]=useState("");
 const [loading,setLoading]=useState(false);
 const [section,setSection]=useState<"discover"|"services"|"library">("discover");
 useEffect(()=>{fetch("/api/providers").then(async r=>{if(!r.ok)throw new Error((await r.json()).error||"Could not load streaming services");return r.json();}).then(p=>setProviders(p.items||[])).catch(e=>setError(e.message));},[]);
 useEffect(()=>localStorage.setItem("optimus-services",JSON.stringify(selected)),[selected]);
 useEffect(()=>localStorage.setItem("optimus-watchlist",JSON.stringify(saved)),[saved]);
 useEffect(()=>{
  if(!selected.length){setTitles([]);return;}
  const controller=new AbortController();const timer=setTimeout(()=>{
   setLoading(true);const params=new URLSearchParams({providers:selected.join(",")});if(q.trim())params.set("q",q.trim());
   fetch("/api/catalog?"+params.toString(),{signal:controller.signal}).then(async r=>{const data=await r.json();if(!r.ok)throw new Error(data.error||"Catalog request failed");return data;}).then(data=>{setTitles(data.items||[]);setError("");}).catch(e=>{if(e.name!=="AbortError")setError(e.message);}).finally(()=>setLoading(false));
  },250);
  return ()=>{clearTimeout(timer);controller.abort();};
 },[q,selected]);
 const toggle=(id:string)=>setSelected(current=>current.includes(id)?current.filter(x=>x!==id):[...current,id]);
 const toggleSaved=(id:string)=>setSaved(current=>current.includes(id)?current.filter(x=>x!==id):[...current,id]);
 const providerName=(id:string)=>providers.find(p=>p.id===id)?.name||id;
 const matched=titles;
 const library=useMemo(()=>titles.filter(t=>saved.includes(t.id)),[titles,saved]);
 const card=(t:CatalogTitle)=><article className="card" key={t.id}><div className="poster"><small>{t.type.toUpperCase()}</small><strong>{t.name}</strong><span>{t.year||"Release year unknown"}</span></div><div className="details"><div className="titleRow"><h3>{t.name}</h3><button onClick={()=>toggleSaved(t.id)} aria-label="Toggle watchlist">{saved.includes(t.id)?<Check/>:<Bookmark/>}</button></div><small>{t.year||"Year unknown"} · {t.rating||"Unrated"} · {t.type==="series"?"Series":t.runtime||"Movie"}</small><p>{t.synopsis}</p><div className="offers">{t.offers.map((o,i)=><span key={o.providerId+i}>{providerName(o.providerId)} · INCLUDED</span>)}</div></div></article>;
 return <main className="shell"><header><a className="brand"><b>O</b> OPTIMUS</a><nav><a onClick={()=>setSection("discover")}><Compass/> Discover</a><a onClick={()=>setSection("library")}><Bookmark/> My Library</a><a onClick={()=>setSection("services")}><Tv/> Services</a></nav></header><section className="hero"><label>YOUR ENTERTAINMENT, UNIFIED</label><h1>Less searching.<br/><em>More watching.</em></h1><p>One place to discover what’s worth watching across the services you already have.</p></section>
 {section==="services"?<section className="catalog"><label>YOUR SUBSCRIPTIONS</label><h2>Which services do you use?</h2><p className="muted">Choose every service included in your subscriptions. OPTIMUS will only show titles available on at least one selected service.</p><div className="filters serviceGrid">{providers.map(p=><button className={selected.includes(p.id)?"active":""} key={p.id} onClick={()=>toggle(p.id)}>{selected.includes(p.id)?"✓ ":""}{p.name}</button>)}</div><button className="primary" onClick={()=>setSection("discover")}>Save services & discover</button></section>:section==="library"?<section className="section"><label>YOUR PERSONAL COLLECTION</label><h2>My watchlist</h2><div className="grid">{library.map(card)}</div>{saved.length===0&&<p className="empty">Save titles while browsing to build your watchlist.</p>}</section>:<><section className="catalog"><label>THE UNIFIED CATALOG · UNITED STATES</label><h2>Find something worth your time.</h2><div className="search"><Search/><input value={q} onChange={e=>setQ(e.target.value)} placeholder="Search movies, series…"/></div><div className="filters"><span><Settings2/> My subscriptions:</span>{selected.length?selected.map(id=><button className="active" key={id} onClick={()=>toggle(id)}>{providerName(id)} ×</button>):<span>Select services to begin</span>}<button onClick={()=>setSection("services")}>Edit services</button></div></section><section className="section"><label>MATCHED TO YOUR SERVICES</label><h2>{q?"Search results":"Worth watching now"}</h2>{loading&&<p className="muted">Searching streaming catalogs…</p>}{!loading&&selected.length===0&&<p className="empty">Choose your streaming subscriptions to see matching titles.</p>}<div className="grid">{matched.map(card)}</div>{!loading&&selected.length>0&&matched.length===0&&<p className="empty">No titles match your selected services. Try another search.</p>}</section></>}
 {error&&<p className="error">{error}</p>}<footer><span>OPTIMUS · One interface. Many ways to watch.</span><small>Availability: United States · Powered by TMDB</small></footer></main>;
}
