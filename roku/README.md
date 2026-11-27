# OPTIMUS Roku client

Native Roku SceneGraph/BrightScript prototype. It consumes the same Hono API as the web application.

## Shared API contract

The web client currently calls `/api/catalog` and `/api/providers`. The Roku client calls `GET /api/catalog` and reads the shared response shape:

```json
{ "items": [{ "id": "…", "name": "Title", "synopsis": "…", "type": "series" }] }
```

## Configure the API

Edit `source/config.brs`:

- `OptimusApiBase()`: API origin, without a trailing slash.
- `OptimusApiPath()`: currently `/api/catalog`.

For local Wrangler development, use your development computer's LAN IP, not `localhost`. Example: `http://192.168.1.20:8787`. The Roku and development computer must be on the same network and the firewall must allow the connection. Alternatively, use the deployed HTTPS Worker URL.

## Sideload

Zip the contents of this directory so `manifest` is at the archive root. Upload the ZIP using the Roku Developer Application Installer at the Roku device's IP address.

This is an early prototype and has not yet been compiled, packaged, or tested on physical Roku hardware. The current screen supports title-list navigation, API-backed title detail pages, availability offer display, and Back navigation to Discover. Search keyboard, artwork rows, and authentication are subsequent tasks.
