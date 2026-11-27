import type { CatalogTitle, Provider } from "@optimus/shared";
export const providers:Provider[]=[{id:"stream-a",name:"Stream A"},{id:"stream-b",name:"Stream B"},{id:"stream-c",name:"Stream C"}];
// Fictional demo entries only. Replace with licensed catalog and availability data.
export const titles:CatalogTitle[]=[
{id:"demo-001",name:"The Last Meridian",type:"series",year:2025,genres:["Drama","Mystery"],rating:"TV-14",seasons:2,synopsis:"A remote coastal town discovers its newest arrival knows more about its history than anyone should.",offers:[{providerId:"stream-a",offerType:"subscription",region:"US",lastVerified:"demo"},{providerId:"stream-c",offerType:"rent",region:"US",lastVerified:"demo"}]},
{id:"demo-002",name:"Orbit of Ash",type:"movie",year:2024,genres:["Science Fiction","Adventure"],rating:"PG-13",runtime:"2h 08m",synopsis:"A salvage crew follows a mysterious signal beyond the edge of a mapped solar system.",offers:[{providerId:"stream-b",offerType:"subscription",region:"US",lastVerified:"demo"}]},
{id:"demo-003",name:"Small Hours",type:"series",year:2026,genres:["Comedy","Drama"],rating:"TV-MA",seasons:1,synopsis:"Three night-shift coworkers build an unlikely friendship while keeping a city hotel running.",offers:[{providerId:"stream-a",offerType:"subscription",region:"US",lastVerified:"demo"}]}
];
