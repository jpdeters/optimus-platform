export async function onRequest(context: { request: Request }): Promise<Response> {
  const incoming = new URL(context.request.url);
  const upstream = new URL(incoming.pathname + incoming.search, "https://optimus-api.jpdeters1.workers.dev");
  return fetch(new Request(upstream, context.request));
}
