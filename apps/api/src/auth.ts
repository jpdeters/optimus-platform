import type { Hono, Context } from "hono";

export type AuthBindings = { APP_VERSION?: string; TMDB_READ_ACCESS_TOKEN?: string; FANART_API_KEY?: string; OPTIMUS_DB: D1Database };
type AuthContext = Context<{ Bindings: AuthBindings }>;
type Profile = { providers: string[]; watchlist: unknown[]; updatedAt?: string };
const SESSION_SECONDS = 60 * 60 * 24 * 30;
const encoder = new TextEncoder();
const hex = (bytes: Uint8Array) => [...bytes].map(x => x.toString(16).padStart(2, "0")).join("");
const randomHex = (length: number) => { const bytes = new Uint8Array(length); crypto.getRandomValues(bytes); return hex(bytes); };
async function digest(value: string) { return hex(new Uint8Array(await crypto.subtle.digest("SHA-256", encoder.encode(value)))); }
async function passwordHash(password: string, salt: string) {
  const key = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
  return hex(new Uint8Array(await crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt: encoder.encode(salt), iterations: 310000 }, key, 256)));
}
function cookieValue(cookie: string, name: string) {
  return cookie.split(";").map(x => x.trim()).find(x => x.startsWith(name + "="))?.slice(name.length + 1);
}
function jsonError(message: string, status: number) { return Response.json({ error: message }, { status }); }

export function registerAuthRoutes(app: Hono<{ Bindings: AuthBindings; Variables: Variables }>) {
  app.post("/api/auth/register", async c => {
    const body = await c.req.json<{ email?: string; password?: string }>().catch(() => ({}));
    const email = (body.email || "").trim().toLowerCase();
    const password = body.password || "";
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) return jsonError("Enter a valid email address.", 400);
    if (password.length < 12 || password.length > 128) return jsonError("Use a password between 12 and 128 characters.", 400);
    const id = crypto.randomUUID(), salt = randomHex(16), hash = await passwordHash(password, salt);
    try {
      await c.env.OPTIMUS_DB.prepare("INSERT INTO users (id,email,password_salt,password_hash,created_at) VALUES (?,?,?,?,?)").bind(id,email,salt,hash,new Date().toISOString()).run();
    } catch { return jsonError("An account with that email may already exist.", 409); }
    return createSession(c, id);
  });
  app.post("/api/auth/login", async c => {
    const body = await c.req.json<{ email?: string; password?: string }>().catch(() => ({}));
    const email = (body.email || "").trim().toLowerCase(), password = body.password || "";
    const user = await c.env.OPTIMUS_DB.prepare("SELECT id,password_salt,password_hash FROM users WHERE email=?").bind(email).first<{id:string;password_salt:string;password_hash:string}>();
    if (!user || !password || await passwordHash(password,user.password_salt) !== user.password_hash) return jsonError("Email or password is incorrect.", 401);
    return createSession(c,user.id);
  });
  app.post("/api/auth/logout", async c => {
    const token = cookieValue(c.req.header("Cookie") || "", "optimus_session");
    if (token) await c.env.OPTIMUS_DB.prepare("DELETE FROM sessions WHERE token_hash=?").bind(await digest(token)).run();
    c.header("Set-Cookie", "optimus_session=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0");
    return c.json({ ok: true });
  });
  app.get("/api/auth/me", async c => {
    const userId = await currentUser(c);
    if (!userId) return c.json({ user: null });
    const user = await c.env.OPTIMUS_DB.prepare("SELECT email,created_at FROM users WHERE id=?").bind(userId).first<{email:string;created_at:string}>();
    return c.json({ user: user ? { email: user.email, createdAt: user.created_at } : null });
  });
  app.get("/api/profile", async c => {
    const userId = await currentUser(c);
    if (!userId) return jsonError("Sign in to sync your OPTIMUS profile.", 401);
    const row = await c.env.OPTIMUS_DB.prepare("SELECT data,updated_at FROM profiles WHERE user_id=?").bind(userId).first<{data:string;updated_at:string}>();
    return c.json({ profile: row ? { ...JSON.parse(row.data), updatedAt: row.updated_at } : null });
  });
  app.put("/api/profile", async c => {
    const userId = await currentUser(c);
    if (!userId) return jsonError("Sign in to sync your OPTIMUS profile.", 401);
    const body = await c.req.json<Profile>().catch(() => null);
    if (!body || !Array.isArray(body.providers) || !Array.isArray(body.watchlist) || body.providers.length > 100 || body.watchlist.length > 500) return jsonError("Invalid profile data.", 400);
    const data = JSON.stringify({ providers: body.providers.filter(x => typeof x === "string").slice(0,100), watchlist: body.watchlist.slice(0,500) });
    const updatedAt = new Date().toISOString();
    await c.env.OPTIMUS_DB.prepare("INSERT INTO profiles (user_id,data,updated_at) VALUES (?,?,?) ON CONFLICT(user_id) DO UPDATE SET data=excluded.data,updated_at=excluded.updated_at").bind(userId,data,updatedAt).run();
    return c.json({ ok: true, updatedAt });
  });

  async function currentUser(c: AuthContext) {
    const token = cookieValue(c.req.header("Cookie") || "", "optimus_session");
    if (!token) return null;
    const row = await c.env.OPTIMUS_DB.prepare("SELECT user_id FROM sessions WHERE token_hash=? AND expires_at>?").bind(await digest(token),Math.floor(Date.now()/1000)).first<{user_id:string}>();
    return row?.user_id || null;
  }
  async function createSession(c: AuthContext, userId: string) {
    const token = randomHex(32), expires = Math.floor(Date.now()/1000) + SESSION_SECONDS;
    await c.env.OPTIMUS_DB.prepare("INSERT INTO sessions (token_hash,user_id,expires_at,created_at) VALUES (?,?,?,?)").bind(await digest(token),userId,expires,new Date().toISOString()).run();
    c.header("Set-Cookie", `optimus_session=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=${SESSION_SECONDS}`);
    const user = await c.env.OPTIMUS_DB.prepare("SELECT email FROM users WHERE id=?").bind(userId).first<{email:string}>();
    return c.json({ user: { email: user?.email } });
  }
}