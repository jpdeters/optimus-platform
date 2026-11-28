# OPTIMUS Roku client

Native Roku SceneGraph/BrightScript client. It consumes the same OPTIMUS API as the web application.

## Brand and interface

The Roku client now follows the OPTIMUS visual identity: midnight navy, bright cyan and electric blue highlights, violet/orange spectral accents, and the "YOUR STREAMING COMPANION" tagline. The interface remains high-contrast and remote-friendly for television viewing.

## API behavior

The client loads the live US streaming-provider list from `GET /api/providers`. Press OPTIONS from Discover to open My Services, then use OK to select or deselect subscription services. When returning to Discover, Roku requests only titles available through the selected services using `GET /api/catalog?providers=...`.

The catalog is powered by TMDB. Only US subscription/flatrate offers are included in Discover results; rentals and purchases are excluded. Service selections and watchlist entries remain stored locally on this Roku for now; account sign-in and cross-device synchronization are not implemented yet.

## Configure the API

The deployed API is already configured in `source/config.brs`. The TMDB token stays on the API Worker and is never shipped to Roku.

## External streaming app launch

On a title detail page, select **Open [service]** to hand off to the installed Roku channel. The current MVP maps common US services to Roku channel IDs: Netflix, Prime Video, Hulu, Disney+, Apple TV, Peacock, Paramount+, and Max. Unsupported services do not show a launch action.

The hand-off uses Roku's local External Control Protocol launch endpoint. It opens the provider app only; it does not start playback or bypass provider sign-in. Direct-to-title deep links are provider-specific and are not assumed because the catalog currently supplies TMDB title IDs, not each provider's playback ID.

## Remote controls

- OPTIONS from Discover: My Services.
- OK on a service: select/deselect it.
- BACK from My Services: return to Discover and refresh matched listings.
- OPTIONS cycles My Services, My Watchlist, and Discover.
- OK on a title: open title details.
- OPTIONS in title details: save/remove from Watchlist.
- BACK from title details: return to the current list.

## Sideload

The GitHub Actions workflow packages the contents of this directory so `manifest` is at the archive root. Upload the generated ZIP using the Roku Developer Application Installer at the Roku device's IP address.

The package is built and XML-validated in CI. The final appearance and provider hand-off still require testing on physical Roku hardware.
