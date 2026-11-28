# OPTIMUS Roku client

Native Roku SceneGraph/BrightScript companion client. It consumes the same OPTIMUS API as the web application.

## Interface

The Roku client provides a graphical poster catalog, service selection, and on-device search. Catalog artwork is loaded from the API, with a fallback card when artwork is unavailable.

## Catalog and services

The client loads the live US streaming-provider list from `GET /api/providers`. Use the service picker to select or deselect the streaming services you subscribe to. Discover requests only titles available through the selected services using `GET /api/catalog?providers=...`; search uses the same provider filter.

The catalog is powered by TMDB. Only US subscription/flatrate offers are included in Discover results; rentals and purchases are excluded. Availability does not verify that a user has an active paid entitlement.

## Account pairing and shared profile

Sign in or create an account in the OPTIMUS web app. On Roku, start device pairing and enter the displayed short code in the signed-in web account's Roku connection area. The TV never asks for your account password.

After approval, Roku receives a device token and synchronizes the account's selected services and watchlist through the shared profile API. If the pairing code expires, start a new pairing request.

Pairing does not transfer Netflix, Prime Video, or other provider credentials or sessions. Sign in directly inside each provider app on the Roku.

## API configuration

The deployed API is configured in `source/config.brs`. The TMDB token stays on the API Worker and is never shipped to Roku.

## External streaming app launch

On a supported title detail page, select **Open [service]** to hand off to the installed Roku channel. The current MVP maps common US services to Roku channel IDs. The hand-off opens the provider app only; it does not start playback or bypass provider sign-in. Direct-to-title deep links are provider-specific and are not assumed.

## Remote controls

- OPTIONS from Discover: open the service picker.
- OK on a service: select/deselect it.
- BACK from the service picker: return to Discover and refresh matched listings.
- Search key: open on-device search; results retain the selected service filter.
- OK on a title: open title details.
- BACK from title details: return to the current list.
- Use the pairing screen's on-screen controls to request/cancel pairing as presented.

## Sideload

The **Package OPTIMUS Roku** GitHub Actions workflow creates an `optimus-roku-sideload` artifact ZIP with `manifest` at the archive root. Download that artifact from the successful workflow run and upload the ZIP using the Roku Developer Application Installer at the Roku device's IP address.

CI validates the manifest and XML files and verifies the ZIP layout. The final appearance, remote navigation, pairing behavior, and provider hand-off still require testing on physical Roku hardware.
