# TravelEd — Roadmap

TravelEd is a personal travel app built on the open-source [Wonderous](https://wonderous.app)
Flutter app (gskinner, MIT). It starts from Wonderous as a base and expands it from a static
"famous structures" showcase into a functional travel companion: save places, plan trips, and
generate a beautiful, interactive itinerary.

This document captures the product direction, the design language, the feature build order, and
the technical notes for the accommodation and AI pieces. It is the living plan — update it as
decisions change.

---

## The epic

Turn the showcase into a tool that does three things well:

1. **Discover** — browse countries and places on a map, save the ones worth visiting.
2. **Plan** — group saved places into trips with dates.
3. **Itinerary** — generate a designed, interactive day-by-day plan, and hand off to book stays.

The **AI itinerary is the centerpiece**, rendered as a designed screen — not a wall of generated
text. Booking is a **handoff**: we deep-link out to the booking provider rather than booking
in-app (see API notes below for why).

---

## The "expedition journal" design

The itinerary leans hard into the inherited Wonderous aesthetic, which treats its subjects
reverently — like chapters in an illustrated book. The itinerary should read like an **expedition
journal**, not a calendar grid.

Design DNA (real tokens from `lib/styles/`):

- **Colors** — background `#1E1B18` / `#272625`, parchment cards `#F8ECE5`, terracotta accent
  `#E4935D`, warm taupe `#BEABA1`, body text `#514F4D`.
- **Type** — Yeseva One (large serif titles), Cinzel (all-caps labels and quotes), Tenor Sans
  (subtitles), Raleway (body), B612Mono (time labels).
- **Motifs reused from the base app** — full-bleed photo header with a dark scrim and serif title;
  the compass divider between sections; and the `TimelineEventCard` pattern (time on a left rail +
  vertical divider + node dot + parchment content card).

Screen structure:

- **Hero** — destination name over an Unsplash photo with a dark scrim.
- **Day rail** — horizontal day pills; each day is a "chapter."
- **Day header** — day title (Yeseva) + area subtitle (Tenor) + a compass divider.
- **Timeline** — a vertical list of activity cards. Each activity has a *kind*
  (sight / food / stay / transit) that drives its icon and accent.
- **Interactions** — tap a card to expand its note and actions (Open in Maps, Book). Stay cards
  carry a terracotta "Book on Booking.com" deep-link. A "Regenerate day with AI" action re-rolls a
  single day without touching the rest of the trip.
- **AI CTA** — per-day regenerate, so generation is scoped, not all-or-nothing.

---

## Feature build order

The itinerary depends on Trips, which depends on a Places foundation. Build bottom-up:

| Step | Feature | Depends on | Notes |
|------|---------|-----------|-------|
| **A** | **Saved Places** | — | Foundation. A dynamic, id-based `Place` model + `PlacesLogic`. Nothing else works without it. |
| **B** | **Trips** | A | A trip = destination + dates + a grouped list of places. |
| **E** | **AI Itinerary + journal screen** | A, B | The centerpiece. Structured Claude output renders into the journal UI. **D is embedded here.** |
| **D** | **Book handoff** | A, B | Deep-link buttons on stay/activity cards. Embedded into the itinerary card; trivial once A–B exist. |
| **C** | **Map discovery** | A | Browse and pin places via Google Places. Slots in alongside A/B. |
| **F** | **In-app hotel data** (stretch) | — | Real search + prices via Amadeus or Travelpayouts. Only if/when there's appetite. |

Practical sequence: **A → B → E (with D embedded)**, with **C alongside**, and **F** deferred.

---

## API & integration notes

### Booking is a handoff, not in-app

- **Airbnb has no public API.** No official way to search or book programmatically; scraping
  violates their ToS. What *is* allowed: deep-linking to a pre-filled Airbnb search URL.
- **Booking.com is partner-gated.** The Demand API and the affiliate program both require an
  approved application — not a self-serve key. Deep-links with an affiliate tag are the realistic
  entry point.
- **Decision:** discover → deep-link out to Booking/Airbnb search (via `url_launcher`, already a
  dependency), pre-filled with location + dates + guests. The user completes the booking on the
  provider's site, then returns and we record it in the trip. Affiliate tagging can come later.

### Self-serve APIs that are actually accessible

| Need | Option | Notes |
|------|--------|-------|
| Map + place/POI search | Google Places (we already depend on `google_maps_flutter`) or Mapbox | Free tier, then pay-per-call. |
| Real hotel search + prices | Amadeus Self-Service APIs | Legit self-serve; free test env. Production booking needs approval. |
| Accommodation aggregator + commission | Travelpayouts (Hotellook) | Easier approval than Booking direct; monetizable links. |
| Itinerary generation | Claude API (`claude-opus-4-8` / `claude-sonnet-4-6`) | The differentiator. See below. |

### Structured output is what makes the itinerary a *screen*

The itinerary is a designed UI rather than a text blob because the Claude API call requests
**structured JSON output** via a tool/schema — roughly:

```jsonc
{
  "days": [
    {
      "day": 2,
      "area": "Arashiyama & the West",
      "activities": [
        { "time": "09:30", "kind": "sight", "name": "Bamboo Grove",
          "note": "Go early; best light before 10am.", "lat": 35.0, "lng": 135.6 }
      ]
    }
  ]
}
```

The model fills the *content*; the app owns the *presentation*. The app deserializes this into
`Itinerary → ItineraryDay → Activity` models and lays it into the journal UI. `kind` maps to the
activity icon + accent; `lat`/`lng` power the Map and the "Open in Maps" deep-link.

### Keys & accounts this will eventually need

- Google Maps Platform key (Places API enabled + billing).
- Anthropic API key (AI itineraries).
- For stretch hotel data: Amadeus or Travelpayouts account.
- For monetization (optional, later): Booking.com affiliate and/or Travelpayouts approval.

---

## How features plug into the codebase

The base app's architecture (see the code for detail):

- **State** — `get_it` singletons registered in `lib/main.dart`, reactive via `ValueNotifier` +
  `get_it_mixin`.
- **Routing** — `go_router`, all routes + path helpers in `lib/router.dart`.
- **Content** — hardcoded in Dart under `lib/logic/data/`.
- **User data** — persisted as JSON in `SharedPreferences` via `ThrottledSaveLoadMixin`.

A new feature is therefore: a new `*Logic` class (registered in `registerSingletons()` with a
global accessor), persisted via `ThrottledSaveLoadMixin` if it stores user data, a screen folder
under `lib/ui/screens/`, and an `AppRoute` + `ScreenPaths` entry in `lib/router.dart`.

**Key constraint:** the base app is keyed off a fixed `WonderType` enum. User-generated places
must be a **new, dynamic, id-based `Place` model** — not an enum — so the list can grow at runtime.

---

## Deferred

- Renaming the internal Dart package from `wonders` to `traveled` — pure churn; do it as one
  isolated commit after the first feature lands.
- Stripping the collectibles subsystem (the most showcase-only part) — revisit once the travel
  features take shape.
