export type ContentType = "movie" | "series";
export type OfferType = "subscription" | "rent" | "buy" | "free";
export interface Provider { id:string; name:string; }
export interface AvailabilityOffer { providerId:string; offerType:OfferType; planName?:string; region:string; lastVerified:string; }
export interface CatalogTitle { id:string; name:string; type:ContentType; year:number; genres:string[]; synopsis:string; rating?:string; runtime?:string; seasons?:number; imageUrl?:string; backdropUrl?:string; offers:AvailabilityOffer[]; }
export interface CatalogResponse { items:CatalogTitle[]; total:number; }
export interface HealthResponse { status:"ok"; service:"optimus-api"; version:string; }
