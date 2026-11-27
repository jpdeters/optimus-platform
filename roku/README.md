# OPTIMUS Roku client

Native Roku SceneGraph/BrightScript client. It consumes the same OPTIMUS API as the web application.

## API behavior

The client loads the live US streaming-provider list from `GET /api/providers`. Press OPTIONS from Discover to open My Services, then use OK to select or deselect subscription services. When returning to Discover, Roku requests only titles available through the selected services using `GET /api/catalog?providers=...`.

The catalog is powered by TMDB. Only US subscription/flatrate offers are included in Discover results; rentals and purchases are excluded. Service selections and watchlist entries remain stored locally on this Roku for now; account sign-in and cross-device synchronization are not implemented yet.

## Configure the API

Edit `source/config.brs`:

- `OptimusApiBase()`: API origin, without a trailing slash.
- `OptimusApiPath()`: `/api/catalog`.

The API must be configured with a TMDB API Read Access Token. See the root README for setup. Do not put the TMDB token in the Roku app; it belongs only in the API Worker secret.

For local Wrangler development, use your development computer's LAN IP, not `localhost`. Example: `http://192.168.1.20:8787`. The Roku and development computer must be on the same network and the firewall must allow the connection. Alternatively, use the deployed HTTPS Worker URL.

## External streaming app launch

On a title detail page, select **Open [service]** to hand off to the installed Roku channel. The current MVP maps common US services to Roku channel IDs: Netflix, Prime Video, Hulu, Disney+, Apple TV, Peacock, Paramount+, and Max. Unsupported services do not show a launch action.

The hand-off uses Roku's local External Control Protocol launch endpoint. It opens the provider app only; it does not start playback or bypass provider sign-in. Direct-to-title deep links are provider-specific and are not assumed because the catalog currently supplies TMDB title IDs, not each provider's playback ID. This local ECP hand-off must be verified on the target Roku hardware.


- OPTIONS from Discover: My Services.
- OK on a service: select/deselect it.
- BACK from My Services: return to Discover and refresh matched listings.
- OPTIONS cycles My Services, My Watchlist, and Discover.
- OK on a title: open title details.
- OPTIONS in title details: save/remove from Watchlist.
- BACK from title details: return to the current list.

## Sideload

Zip the contents of this directory so `manifest` is at the archive root. Upload the ZIP using the Roku Developer Application Installer at the Roku device's IP address.

This remains an early prototype and must be packaged and tested on physical Roku hardware after each client update. Search keyboard, artwork rows, and account synchronization are subsequent tasks.
