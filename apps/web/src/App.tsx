import { useEffect, useMemo, useState } from "react";
import { Bookmark, Check, ChevronDown, ChevronRight, Clapperboard, Compass, Film, Search, Settings2, Sparkles, Tv, X, UserRound, LogOut } from "lucide-react";
import type { CatalogTitle, Provider } from "@optimus/shared";

type Section = "discover" | "services" | "library";
function readStorage<T>(key: string, fallback: T): T {
  try { const value = localStorage.getItem(key); return value ? JSON.parse(value) as T : fallback; }
  catch { return fallback; }
}
const image = (path?: string, size = "w500") => path ? (path.startsWith("http") ? path : `https://image.tmdb.org/t/p/${size}${path}`) : "";

// Provider search destinations are used instead of guessing provider-specific
// content IDs. A direct title deep link can be added when a provider exposes one.
const providerWatchUrl = (providerId: string, title: string) => {
  const q = encodeURIComponent(title);
  const destinations: Record<string, string> = {
    "8": `https://www.netflix.com/search?q=${q}`,
    "9": `https://www.primevideo.com/search/ref=atv_nb_sr?phrase=${q}`,
    "15": `https://www.hulu.com/search?q=${q}`,
    "337": `https://www.disneyplus.com/search?q=${q}`,
    "1899": `https://www.max.com/search?q=${q}`,
    "531": `https://www.paramountplus.com/search/?query=${q}`,
    "386": `https://www.peacocktv.com/search?q=${q}`,
    "350": `https://tv.apple.com/search?term=${q}`
  };
  return destinations[providerId] || ({
    "8":"https://www.netflix.com",
    "9":"https://www.primevideo.com",
    "15":"https://www.hulu.com",
    "337":"https://www.disneyplus.com",
    "1899":"https://www.max.com",
    "531":"https://www.paramountplus.com",
    "386":"https://www.peacocktv.com",
    "350":"https://tv.apple.com"
  }[providerId] || "");
};
export default function App() {
  const [titles,setTitles]=useState<CatalogTitle[]>([]);
  const [providers,setProviders]=useState<Provider[]>([]);
  const [query,setQuery]=useState("");
  const [providerQuery,setProviderQuery]=useState("");
  const [selected,setSelected]=useState<string[]>(()=>readStorage("optimus-services",[]));
  const [saved,setSaved]=useState<CatalogTitle[]>(()=>readStorage("optimus-watchlist-items",[]));
  const [section,setSection]=useState<Section>("discover");
  const [active,setActive]=useState<CatalogTitle|null>(null);
  const [error,setError]=useState("");
  const [providerLoading,setProviderLoading]=useState(true);
  const [loading,setLoading]=useState(false);
  const [type,setType]=useState<"all"|"movie"|"series">("all");
  const [account,setAccount]=useState<string|null>(null);
  const [accountOpen,setAccountOpen]=useState(false);
  const [accountMode,setAccountMode]=useState<"login"|"register">("login");
  const [accountEmail,setAccountEmail]=useState("");
  const [accountPassword,setAccountPassword]=useState("");
  const [accountError,setAccountError]=useState("");
  const [accountBusy,setAccountBusy]=useState(false);
  const [profileReady,setProfileReady]=useState(false);

  const activateAccount=async(email:string)=>{
    setAccount(email);
    const response=await fetch("/api/profile");
    if(!response.ok)throw Error("Your account is signed in, but its profile could not be loaded.");
    const data=await response.json() as {profile?:{providers?:string[];watchlist?:CatalogTitle[]}|null};
    if(data.profile){setSelected(data.profile.providers||[]);setSaved(data.profile.watchlist||[]);}
    else{
      const savedResponse=await fetch("/api/profile",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify({providers:selected,watchlist:saved})});
      if(!savedResponse.ok)throw Error("Your initial profile could not be saved.");
    }
    setProfileReady(true);
  };
  useEffect(()=>{
    let cancelled=false;
    fetch("/api/auth/me").then(r=>r.json()).then(async d=>{
      if(cancelled||!d.user?.email)return;
      setAccount(d.user.email);
      const response=await fetch("/api/profile");
      if(!response.ok)throw Error("Unable to load your OPTIMUS profile.");
      const data=await response.json() as {profile?:{providers?:string[];watchlist?:CatalogTitle[]}|null};
      if(cancelled)return;
      if(data.profile){setSelected(data.profile.providers||[]);setSaved(data.profile.watchlist||[]);}
      else await fetch("/api/profile",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify({providers:selected,watchlist:saved})});
      if(!cancelled)setProfileReady(true);
    }).catch(e=>{if(!cancelled)setError(e.message||"Account connection unavailable.");});
    return()=>{cancelled=true;};
  },[]);
  useEffect(()=>{
    if(!account||!profileReady)return;
    const timer=window.setTimeout(()=>{fetch("/api/profile",{method:"PUT",headers:{"Content-Type":"application/json"},body:JSON.stringify({providers:selected,watchlist:saved})}).catch(()=>setError("Your changes could not sync. Check your connection."));},500);
    return()=>clearTimeout(timer);
  },[account,profileReady,selected,saved]);
  const submitAccount=async()=>{
    setAccountBusy(true);setAccountError("");
    try{
      const response=await fetch("/api/auth/"+accountMode,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email:accountEmail,password:accountPassword})});
      const contentType=response.headers.get("content-type")||"";
      const data=contentType.includes("application/json")?await response.json():{error:(await response.text()).slice(0,240)||`Server returned HTTP ${response.status}`};
      if(!response.ok)throw Error(data.error||`Unable to complete account request (HTTP ${response.status}).`);
      if(!data.user?.email)throw Error("The server did not confirm the account. Please try again.");
      await activateAccount(data.user.email);
      setAccountPassword("");setAccountOpen(false);
    }catch(e){setAccountError(e instanceof Error?e.message:"Unable to complete account request.");}
    finally{setAccountBusy(false);}
  };
  const signOut=async()=>{await fetch("/api/auth/logout",{method:"POST"});setAccount(null);setProfileReady(false);setAccountOpen(false);};
  useEffect(()=>{const c=new AbortController();fetch("/api/providers",{signal:c.signal}).then(async r=>{const d=await r.json();if(!r.ok)throw Error(d.error||"Unable to load services");return d;}).then(d=>{setProviders(Array.isArray(d.items)?d.items:[]);setError("");}).catch(e=>{if(e.name!=="AbortError")setError(e.message||"Unable to load services");}).finally(()=>{if(!c.signal.aborted)setProviderLoading(false);});return()=>c.abort();},[]);
  useEffect(()=>{localStorage.setItem("optimus-services",JSON.stringify(selected));},[selected]);
  useEffect(()=>{localStorage.setItem("optimus-watchlist-items",JSON.stringify(saved));},[saved]);
  useEffect(()=>{
    if(!saved.length)return;
    let cancelled=false;
    Promise.all(saved.filter(t=>!t.imageUrl&&!t.backdropUrl).map(async t=>{
      try{
        const direct=await fetch("/api/catalog/"+encodeURIComponent(t.id));
        if(direct.ok){
          const fresh=await direct.json() as CatalogTitle;
          if(fresh.imageUrl||fresh.backdropUrl)return {id:t.id,imageUrl:fresh.imageUrl,backdropUrl:fresh.backdropUrl};
        }
        const providers=t.offers.map(o=>o.providerId).join(",");
        if(!providers)return null;
        const params=new URLSearchParams({q:t.name,providers});
        const search=await fetch("/api/catalog?"+params.toString());
        if(!search.ok)return null;
        const data=await search.json() as {items?:CatalogTitle[]};
        const match=(data.items||[]).find(x=>x.id===t.id)||(data.items||[]).find(x=>x.name.toLowerCase()===t.name.toLowerCase());
        return match&&(match.imageUrl||match.backdropUrl)?{id:t.id,imageUrl:match.imageUrl,backdropUrl:match.backdropUrl}:null;
      }catch{return null;}
    })).then(updates=>{
      if(cancelled)return;
      const byId=new Map(updates.filter((x):x is NonNullable<typeof x>=>!!x).map(x=>[x.id,x]));
      if(byId.size)setSaved(current=>current.map(t=>{const u=byId.get(t.id);return u?{...t,imageUrl:u.imageUrl,backdropUrl:u.backdropUrl}:t;}));
    });
    return()=>{cancelled=true;};
  },[saved]);

  useEffect(()=>{if(!selected.length){setTitles([]);return;}const c=new AbortController();const timer=window.setTimeout(()=>{setLoading(true);const p=new URLSearchParams({providers:selected.join(",")});if(query.trim())p.set("q",query.trim());fetch("/api/catalog?"+p,{signal:c.signal}).then(async r=>{const d=await r.json();if(!r.ok)throw Error(d.error||"Catalog search failed");return d;}).then(d=>{setTitles(Array.isArray(d.items)?d.items:[]);setError("");}).catch(e=>{if(e.name!=="AbortError")setError(e.message||"Catalog search failed");}).finally(()=>{if(!c.signal.aborted)setLoading(false);});},300);return()=>{clearTimeout(timer);c.abort();};},[query,selected]);
  const toggleProvider=(id:string)=>setSelected(v=>v.includes(id)?v.filter(x=>x!==id):[...v,id]);
  const toggleSaved=(title:CatalogTitle)=>setSaved(v=>v.some(x=>x.id===title.id)?v.filter(x=>x.id!==title.id):[title,...v]);
  const isSaved=(id:string)=>saved.some(x=>x.id===id);
  const providerName=(id:string)=>providers.find(p=>p.id===id)?.name||id;
  const filteredProviders=useMemo(()=>providers.filter(p=>p.name.toLowerCase().includes(providerQuery.trim().toLowerCase())),[providers,providerQuery]);
  const visible=useMemo(()=>titles.filter(t=>type==="all"||(type==="movie"?t.type==="movie":t.type==="series")),[titles,type]);
  const featured=visible[0];
  const list=section==="library"?saved:visible;
  const nav=(s:Section)=>{setSection(s);setActive(null);};
  const titleCard=(t:CatalogTitle)=><article className="posterCard" key={t.id} onClick={()=>setActive(t)} tabIndex={0} onKeyDown={e=>{if(e.key==="Enter")setActive(t);}}>
    <div className="artwork">{t.imageUrl||t.backdropUrl?<img src={image(t.imageUrl||t.backdropUrl,t.imageUrl?"w500":"w780")} data-fallback={t.backdropUrl?image(t.backdropUrl,"w780"):""} onError={e=>{const el=e.currentTarget;if(el.dataset.fallback&&el.src!==el.dataset.fallback){el.src=el.dataset.fallback;el.dataset.fallback="";}else{el.style.display="none";}}} alt="" loading="lazy"/>:<div className="artFallback"><Film size={34}/><span>{t.name}</span></div>}<button className={"saveButton "+(isSaved(t.id)?"isSaved":"")} onClick={e=>{e.stopPropagation();toggleSaved(t);}} aria-label={isSaved(t.id)?"Remove from watchlist":"Add to watchlist"}>{isSaved(t.id)?<Check size={17}/>:<Bookmark size={17}/>}</button><span className="typeTag">{t.type==="series"?"SERIES":"FILM"}</span></div>
    <div className="posterMeta"><h3>{t.name}</h3><p>{t.year||"Year unknown"} <span>·</span> {t.rating||"Unrated"}</p><div className="providerDots">{t.offers.slice(0,3).map(o=><span key={o.providerId}>{providerName(o.providerId)}</span>)}</div></div>
  </article>;
  return <div className="appShell">
    <aside className="sidebar"><a className="wordmark" href="#" onClick={e=>{e.preventDefault();nav("discover");}}><span className="brandGlyph">O</span><span>OPTIMUS<small>STREAMING, REFINED</small></span></a>
      <div className="sideLabel">YOUR SPACE</div><nav className="sideNav"><button className={section==="discover"?"selected":""} onClick={()=>nav("discover")}><Compass/>Discover</button><button className={section==="library"?"selected":""} onClick={()=>nav("library")}><Bookmark/>My watchlist <span className="count">{saved.length||""}</span></button><button className={section==="services"?"selected":""} onClick={()=>nav("services")}><Tv/>My services</button></nav>
      <div className="sidebarBottom"><div className="planMark"><Sparkles size={15}/><span>YOUR STREAMING, IN SYNC</span></div><p>One place for everything worth watching.</p></div>
    </aside>
    <main className="mainPanel"><header className="topbar"><div className="mobileBrand"><span className="brandGlyph">O</span> OPTIMUS</div><div className="breadcrumb">YOUR ENTERTAINMENT <span>/</span> {section==="discover"?"DISCOVER":section==="library"?"MY WATCHLIST":"SERVICES"}</div><div className="topActions"><button className="accountPill" onClick={()=>setAccountOpen(true)}><UserRound size={15}/>{account?account:"Sign in"}</button><button className="servicePill" onClick={()=>nav("services")}><Tv size={15}/>{selected.length} services <ChevronDown size={14}/></button></div></header>
      {section==="services"?<section className="contentArea servicesPage"><div className="eyebrow">PERSONALIZE YOUR CATALOG</div><h1>Your services.<br/><i>Your universe.</i></h1><p className="intro">Select the streaming subscriptions you already pay for. OPTIMUS will only surface titles included with those services—not rentals or purchases.</p>{providerLoading?<p className="muted">Loading available services…</p>:<><div className="providerSearch"><Search size={18}/><input value={providerQuery} onChange={e=>setProviderQuery(e.target.value)} placeholder="Search streaming services…" aria-label="Search streaming services"/>{providerQuery&&<button onClick={()=>setProviderQuery("")} aria-label="Clear service search"><X size={16}/></button>}<span>{filteredProviders.length} FOUND</span></div><div className="serviceGrid">{filteredProviders.map(p=><button key={p.id} className={selected.includes(p.id)?"chosen":""} onClick={()=>toggleProvider(p.id)}>{selected.includes(p.id)?<Check size={17}/>:<span className="emptyCheck"/>}{p.name}</button>)}</div>{!filteredProviders.length&&<p className="emptyState">No services match “{providerQuery}”. Try another name.</p>}</>}{!providerLoading&&!providers.length&&<p className="emptyState">Streaming services could not be loaded. Please try again shortly.</p>}<div className="serviceFooter"><span>{selected.length} SERVICES SELECTED</span><button className="goldButton" onClick={()=>nav("discover")}>Save & explore <ChevronRight size={16}/></button></div></section>
      :section==="library"?<section className="contentArea"><div className="eyebrow">SAVED FOR LATER</div><h1>Your watchlist.</h1><p className="intro">A considered collection of things you want to watch.</p>{list.length?<div className="posterGrid">{list.map(titleCard)}</div>:<div className="emptyPanel"><Bookmark size={27}/><h2>Your list starts here.</h2><p>Save films and series while exploring your catalog.</p><button className="textButton" onClick={()=>nav("discover")}>Explore titles <ChevronRight size={15}/></button></div>}</section>
      :<><section className="welcomeBlock"><div><div className="eyebrow">A BETTER WAY TO DECIDE WHAT TO WATCH</div><h1>Less searching.<br/><i>More watching.</i></h1><p>Discover what’s included with the streaming services you already have.</p><button className="outlineButton" onClick={()=>nav("services")}>Manage subscriptions <ChevronRight size={15}/></button></div><div className="welcomeOrb"><div className="orbInner"><Clapperboard size={44}/><span>ONE PLACE.<br/>ALL YOUR SERVICES.</span></div></div></section>
        <section className="contentArea discoveryArea"><div className="sectionHeading"><div><div className="eyebrow">YOUR PERSONALIZED CATALOG</div><h2>Find your next favorite.</h2></div><div className="serviceSummary" onClick={()=>nav("services")}><span className="liveDot"/>{selected.length} SERVICES CONNECTED <ChevronRight size={14}/></div></div>
          <div className="searchBar"><Search size={19}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search films, series, or a title…" aria-label="Search films and series"/>{query&&<button onClick={()=>setQuery("")} aria-label="Clear search"><X size={16}/></button>}<kbd>SEARCH</kbd></div>
          <div className="filterRow"><div className="typeFilters">{(["all","movie","series"] as const).map(v=><button key={v} className={type===v?"active":""} onClick={()=>setType(v)}>{v==="all"?"All titles":v==="movie"?"Films":"Series"}</button>)}</div><button className="editServices" onClick={()=>nav("services")}><Settings2 size={15}/> Edit services</button></div>
          {!selected.length?<div className="emptyPanel"><Tv size={28}/><h2>Start with your subscriptions.</h2><p>Select the streaming services you use to build your personal catalog.</p><button className="goldButton" onClick={()=>nav("services")}>Choose services <ChevronRight size={16}/></button></div>:loading?<div className="loadingState"><span className="spinner"/>Finding titles included with your services…</div>:visible.length?<><div className="resultsLabel">{query?"SEARCH RESULTS":"AVAILABLE WITH YOUR SUBSCRIPTIONS"} <span>{visible.length} TITLES</span></div>{featured&&!query&&<div className="featuredStrip"><div className="featuredArt">{featured.backdropUrl?<img src={image(featured.backdropUrl,"w1280")} alt=""/>:featured.imageUrl?<img src={image(featured.imageUrl)} alt=""/>:<Film/>}</div><div className="featuredCopy"><div className="eyebrow">A PLACE TO START</div><h2>{featured.name}</h2><p>{featured.synopsis}</p><button className="goldButton" onClick={()=>setActive(featured)}>Explore title <ChevronRight size={16}/></button></div></div>}<div className="posterGrid">{visible.map(titleCard)}</div></>:<div className="emptyPanel"><Search size={28}/><h2>No matches this time.</h2><p>Try a different search or review your selected services.</p><button className="textButton" onClick={()=>nav("services")}>Review services <ChevronRight size={15}/></button></div>}
        </section></>}
      {error&&<div className="errorBanner" role="alert">{error}</div>}
      <footer><span>OPTIMUS</span><span>Availability in the United States · Powered by TMDB</span><span>This product uses the TMDB API but is not endorsed or certified by TMDB.</span></footer>
    </main>
    {accountOpen&&<div className="modalBackdrop" onClick={()=>setAccountOpen(false)}><section className="accountModal" role="dialog" aria-modal="true" aria-label="OPTIMUS account" onClick={e=>e.stopPropagation()}><button className="closeModal" onClick={()=>setAccountOpen(false)} aria-label="Close"><X/></button>{account?<><div className="eyebrow">YOUR OPTIMUS IDENTITY</div><h2>Your streaming, wherever you go.</h2><p className="accountLead">Signed in as <strong>{account}</strong>. Your services and watchlist sync across your devices.</p><div className="syncStatus"><Check size={17}/> Your profile is {profileReady?"synced":"connecting"}</div><button className="accountSubmit secondary" onClick={signOut}><LogOut size={16}/> Sign out</button></>:<><div className="eyebrow">{accountMode==="login"?"WELCOME BACK":"CREATE YOUR OPTIMUS ACCOUNT"}</div><h2>{accountMode==="login"?"Your watchlist travels with you.":"One account. Every device."}</h2><p className="accountLead">Your services and watchlist stay with your OPTIMUS account—not the television you're using.</p><label>Email address<input type="email" autoComplete="email" value={accountEmail} onChange={e=>setAccountEmail(e.target.value)} placeholder="you@example.com"/></label><label>Password<input type="password" autoComplete={accountMode==="login"?"current-password":"new-password"} value={accountPassword} onChange={e=>setAccountPassword(e.target.value)} placeholder={accountMode==="login"?"Your password":"At least 12 characters"}/></label>{accountError&&<p className="accountError" role="alert">{accountError}</p>}<button className="accountSubmit" disabled={accountBusy||!accountEmail||!accountPassword} onClick={submitAccount}>{accountBusy?"Please wait…":accountMode==="login"?"Sign in":"Create account"}</button><button className="accountSwitch" onClick={()=>{setAccountMode(accountMode==="login"?"register":"login");setAccountError("");}}>{accountMode==="login"?"New to OPTIMUS? Create an account":"Already have an account? Sign in"}</button><p className="accountFine">Use a unique password. Email verification and password recovery will be added before public launch.</p></>}</section></div>}
    {active&&<div className="modalBackdrop" onClick={()=>setActive(null)}><section className="detailModal" role="dialog" aria-modal="true" aria-label={active.name} onClick={e=>e.stopPropagation()}><button className="closeModal" onClick={()=>setActive(null)} aria-label="Close"><X/></button><div className="detailHero">{(active.backdropUrl||active.imageUrl)&&<img src={image(active.backdropUrl||active.imageUrl,active.backdropUrl?"w1280":"w780")} alt=""/>}<div/></div><div className="detailContent"><div className="eyebrow">{active.type==="series"?"SERIES":"FILM"} · {active.year||"YEAR UNKNOWN"} · {active.rating||"UNRATED"}</div><h2>{active.name}</h2><p>{active.synopsis}</p><div className="detailProviders"><span>INCLUDED WITH</span>{active.offers.map(o=><b key={o.providerId}>{providerName(o.providerId)}</b>)}</div><div className="watchActions">{active.offers.filter(o=>o.offerType==="subscription").map(o=>{const url=providerWatchUrl(o.providerId,active.name);return url?<a className="watchButton" key={o.providerId} href={url} target="_blank" rel="noopener noreferrer"><Tv size={15}/> Watch on {providerName(o.providerId)}</a>:null;})}</div><button className="goldButton" onClick={()=>toggleSaved(active)}>{isSaved(active.id)?<Check size={16}/>:<Bookmark size={16}/>} {isSaved(active.id)?"Saved to watchlist":"Add to watchlist"}</button></div></section></div>}
  </div>;
}
