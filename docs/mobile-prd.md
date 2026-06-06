# Theta Mobile App PRD

## 1. Purpose

Theta mobile helps users turn Instagram food reels into trustworthy restaurant decisions.

The app should make it easy to:

- Share an Instagram reel to Theta without opening the app.
- Track reel analysis progress.
- Discover restaurants through search, map, and community-saved places.
- Decide whether a restaurant is worth visiting.
- Save and organise places for later.

This PRD focuses on the Flutter mobile app experience. Backend contracts live in `docs/api.md`.

## 2. Product Positioning

### Core Promise

Find places worth eating at, without scrolling through hundreds of food reels.

### User Problem

Food discovery through Instagram is noisy. A reel may look good, but users still need to know:

- Where is this place?
- Is it actually good?
- Is the reel sponsored or overhyped?
- What do other people say?
- Is it nearby?
- Should I save it for later?

### Product Answer

Theta turns reels and public food discoveries into searchable, mappable, trusted restaurant recommendations.

## 3. Primary Users

### Food Explorers

People who save or share Instagram reels when they find a restaurant they may want to visit later.

### Local Decision Makers

People looking for nearby places to eat now.

### Trip Planners

People collecting restaurants for a food trip, weekend outing, or city visit.

### Social Discoverers

People who want to see restaurants saved or trusted by other Theta users, without using Theta as a full social network.

## 4. MVP Principles

- Mobile-first.
- Share-first.
- Map and search are equal discovery paths.
- Public social signals are aggregate-first, not follower-first.
- Trust signals should be visible before long AI text.
- Users can browse as guests, but saving, lists, and personal history require login.

## 5. Navigation

Use five bottom tabs:

1. Home
2. Explore
3. Map
4. Saved
5. Profile

Primary floating action:

- Add Reel

The Add Reel action should be available from Home and optionally from Explore.

## 6. Core User Flows

### Flow A: Share Reel From Instagram

1. User taps share on an Instagram reel.
2. User selects Theta.
3. Theta saves the link silently and returns user to Instagram.
4. When user opens Theta, the reel appears in Home.
5. Reel starts or resumes processing.
6. When complete, user opens the restaurant detail.

### Flow B: Paste Reel Manually

1. User opens Theta.
2. User taps Add Reel.
3. User pastes Instagram URL.
4. Theta validates URL.
5. Theta submits reel for processing.
6. User sees progress.
7. User lands on restaurant detail when complete.

### Flow C: Search For Food

1. User opens Explore.
2. User searches by restaurant, dish, cuisine, or area.
3. User applies filters.
4. User opens a restaurant result.
5. User saves, opens directions, or adds to a list.

### Flow D: Explore Nearby On Map

1. User opens Map.
2. Theta asks for location permission only when needed.
3. User sees pins around them.
4. User toggles layers like trusted, saved by others, trending, and my saved.
5. User taps a pin.
6. Bottom sheet shows restaurant summary.
7. User opens restaurant detail or directions.

### Flow E: Save And Organise

1. User opens restaurant detail.
2. User taps Save.
3. User optionally adds restaurant to a list.
4. User can return from Saved or Lists later.

## 7. Screen Requirements

## 7.1 Launch / Onboarding

### Goal

Explain Theta quickly and route users to browse, share, or sign in.

### Required UI

- Product headline.
- Short value explanation.
- Continue as guest.
- Sign in with Google.
- Privacy note.

### States

- First install.
- Logged-out returning user.
- Logged-in returning user should skip onboarding.

### Copy

Headline:

> Turn food reels into places worth visiting.

Subcopy:

> Share Instagram reels to Theta. We extract the restaurant, analyse the signals, and help you decide where to eat.

Primary CTA:

> Continue

Secondary CTA:

> Sign in with Google

Guest CTA:

> Browse as guest

Privacy note:

> Theta uses shared reel links to generate food insights. You control what you save.

## 7.2 Home / Reel Inbox

### Goal

Show the user's shared reels, processing progress, and completed results.

### Required UI

- Header with app name and count.
- List of recent shared reels.
- Processing status cards.
- Completed restaurant preview cards.
- Failed cards with retry.
- Empty state.
- Add Reel action.
- Pull to refresh.

### Card Types

Pending reel card:

- Reel shortcode or thumbnail.
- Submitted time.
- Current status.
- Progress label.

Completed card:

- Restaurant name.
- Area and cuisine.
- Trust score.
- Summary snippet.
- Save state.

Failed card:

- Error reason.
- Retry action.
- Delete action.

### Copy

Screen title:

> Theta

Empty title:

> No reels yet

Empty body:

> Share a food reel from Instagram or paste a link to start building your food map.

Empty CTA:

> Add reel

Processing labels:

> Waiting to analyse

> Finding the restaurant

> Reading comments

> Building the verdict

Success toast:

> Reel added to Theta

Failure title:

> We could not analyse this reel

Retry CTA:

> Try again

## 7.3 Add Reel

### Goal

Let users paste an Instagram reel URL manually.

### Required UI

- Text input.
- Paste affordance.
- Submit button.
- URL validation.
- Error state.

### Validation

Accept:

- `instagram.com/reel/...`
- `instagram.com/reels/...`
- `instagram.com/p/...`
- `instagram.com/tv/...`

Reject:

- Non-Instagram URLs.
- Empty strings.
- Unsupported Instagram pages.

### Copy

Dialog title:

> Add reel link

Input placeholder:

> Paste Instagram reel URL

Primary CTA:

> Analyse reel

Cancel CTA:

> Cancel

Validation error:

> Paste a valid Instagram reel link.

Duplicate state:

> This reel is already in Theta.

## 7.4 Processing Reel

### Goal

Set expectations while a reel is being processed.

### Required UI

- Reel thumbnail or placeholder.
- Processing stepper.
- Current step.
- Background-safe message.
- Failure state.
- Completed state redirects or unlocks restaurant detail.

### Processing Steps

1. Queued
2. Extracting reel
3. Reading caption and audio
4. Finding the restaurant
5. Checking comments
6. Creating trust summary
7. Ready

### Copy

Title:

> Analysing reel

Body:

> Theta is turning this reel into a restaurant insight. You can leave this screen and come back later.

Queued:

> Your reel is in the queue.

Restaurant detection:

> Finding the place mentioned in the reel.

Comment analysis:

> Checking what people are saying.

Summary:

> Building a quick verdict.

Failed:

> We could not finish analysing this reel.

Failed body:

> The reel may be unavailable, private, or missing enough restaurant details.

Retry CTA:

> Retry analysis

## 7.5 Restaurant Detail

### Goal

Help the user decide whether the restaurant is worth visiting.

### Required UI

- Restaurant name.
- Photo carousel.
- Area, city, cuisine, price level.
- Trust score.
- Verdict.
- Best dishes.
- Common praise.
- Common complaints.
- Source reels.
- Map preview.
- Open directions.
- Open Instagram reel.
- Save.
- Add to list.

### Information Hierarchy

1. Name and place context.
2. Trust score and verdict.
3. Best dishes and practical reasons to visit.
4. Complaints and caveats.
5. Source reels and evidence.
6. Actions.

### Copy

Trust label:

> Trust score

Verdict heading:

> Quick verdict

Praise heading:

> People liked

Complaints heading:

> Watch out for

Dishes heading:

> Dishes mentioned

Sources heading:

> Based on these reels

Save CTA:

> Save place

Saved state:

> Saved

Directions CTA:

> Open directions

Reel CTA:

> Open original reel

No complaints copy:

> No repeated complaints found yet.

Low confidence copy:

> Theta needs more signals before giving a strong verdict.

## 7.6 Explore Search

### Goal

Let users discover restaurants through text search and filters.

### Required UI

- Search bar.
- Recent searches.
- Suggested categories.
- Filter chips.
- Result list.
- Sort control.
- Empty state.

### Search Inputs

Users can search by:

- Restaurant name.
- Dish.
- Cuisine.
- Area.
- City.

### Filters

- City.
- Area.
- Cuisine.
- Budget.
- Minimum trust score.
- Distance.
- Open now, later.

### Sort

- Trust.
- Distance.
- Recently analysed.
- Most saved.

### Copy

Search placeholder:

> Search restaurants, dishes, or areas

Filter CTA:

> Filters

Result count:

> Places found

No result title:

> No places found

No result body:

> Try a nearby area, fewer filters, or share a reel for this place.

Clear filters CTA:

> Clear filters

## 7.7 Explore Results

### Goal

Show scannable restaurant cards from a search or filter query.

### Required UI

- Restaurant cards.
- Thumbnail.
- Name, area, cuisine.
- Trust score.
- Distance when available.
- Saved count.
- Reels analysed count.
- Save action.

### Card Copy

Trust badge:

> 87 trusted

Social proof:

> Saved by 23 people

Source count:

> 6 reels analysed

Distance:

> 1.2 km away

## 7.8 Map Explore

### Goal

Let users visually explore nearby restaurants and public food discoveries.

### Required UI

- Full-screen map.
- Search field.
- Current location button.
- Search this area button.
- Layer toggles.
- Restaurant pins.
- Bottom sheet for selected pin.
- Permission state.
- No results state.

### Map Layers

- Trusted places.
- Saved by others.
- Trending.
- My saved.
- Recently analysed.

### Pin Types

Trusted:

- High-trust restaurants from analysed reels.

Saved by others:

- Restaurants saved by multiple users or public lists.

Trending:

- Recently submitted or repeatedly saved restaurants.

My saved:

- User's personal saved places.

### Bottom Sheet Content

- Restaurant name.
- Trust score.
- Area.
- Cuisine.
- Distance.
- Saved count.
- Primary action: View details.
- Secondary action: Directions.

### Copy

Tab label:

> Map

Search placeholder:

> Search this area

Permission title:

> Find food near you

Permission body:

> Allow location to show trusted places around you. You can still search manually.

Permission CTA:

> Use my location

Manual CTA:

> Search manually

Layer heading:

> Show on map

Search area CTA:

> Search this area

No results title:

> No places here yet

No results body:

> Move the map, widen filters, or share a reel from this area.

## 7.9 Saved

### Goal

Give users quick access to restaurants they saved.

### Required UI

- Saved restaurant list.
- Search within saved.
- Filter chips.
- Empty state.
- Remove save.
- Add to list.

### Copy

Title:

> Saved

Empty title:

> No saved places yet

Empty body:

> Save restaurants from search, map, or reel insights to build your food list.

CTA:

> Explore places

Remove toast:

> Removed from saved

## 7.10 Lists

### Goal

Help users organise saved restaurants into useful collections.

### Required UI

- List overview.
- Create list.
- Edit list.
- Delete list.
- List detail.
- Add or remove restaurant.
- Optional note per restaurant.
- Public/private state reserved for later.

### Example Lists

- Best Shawarmas
- Kozhikode Food Trip
- Places To Try
- Budget Eats
- Weekend Cafes

### Copy

Title:

> Lists

Create CTA:

> Create list

Name placeholder:

> List name

Description placeholder:

> Add a note, like “places for Saturday”

Empty title:

> Organise your food finds

Empty body:

> Create lists for trips, cravings, and places you want to try.

## 7.11 Surprise Me

### Goal

Reduce decision fatigue by recommending one trusted restaurant.

### Placement

Surprise Me can appear as:

- A card in Explore.
- A floating action from Map.
- A button in empty or filtered states.

### Required UI

- Location filter.
- Cuisine filter.
- Budget filter.
- Minimum trust score.
- Result card.
- Try again.

### Copy

Title:

> Surprise me

Body:

> Pick a trusted place when you do not want to decide.

CTA:

> Find a place

Try again:

> Show another

No match:

> No matching place found. Try fewer filters.

## 7.12 Profile / Settings

### Goal

Handle account, privacy, and app controls.

### Required UI

- Login state.
- Sign in with Google.
- Logout.
- App version.
- Privacy.
- Help.
- Clear local cache.

### Copy

Logged-out title:

> Save places across devices

Logged-out body:

> Sign in to keep your saved restaurants, lists, and reel history.

Sign-in CTA:

> Sign in with Google

Logout CTA:

> Log out

Privacy label:

> Privacy

Help label:

> Help

## 8. Social Discovery Rules

Theta can use public aggregate signals without becoming a feed-based social app.

### Allowed In MVP

- Saved count on restaurants.
- Restaurants from public lists.
- Map layer for places saved by others.
- Trending based on recent saves or reel submissions.
- Public list view if user chooses to publish.

### Not In MVP

- Follower graph.
- User profiles as a main discovery surface.
- Direct messages.
- Likes on individual restaurants.
- Social comments.

### Copy Rules

Use aggregate, non-creepy language:

- Good: `Saved by 23 people`
- Good: `Recently popular near you`
- Avoid: `People like you saved this`
- Avoid: exposing who saved a place unless the list is explicitly public.

## 9. States And Edge Cases

### Offline

Copy:

> You are offline. Saved places are still available.

### API Error

Copy:

> Something went wrong. Try again in a moment.

### Private Or Deleted Reel

Copy:

> This reel may be private or unavailable.

### Low Confidence Restaurant Match

Copy:

> We found a possible match, but need more signals to be sure.

### Location Permission Denied

Copy:

> Location is off. Search an area to explore places manually.

### Logged-Out Save Attempt

Copy:

> Sign in to save this place.

CTA:

> Sign in

## 10. API Dependencies

### Reels

- `POST /api/reels`
- `GET /api/reels/:id/status`
- `GET /api/reels/:id`

### Restaurants

- `GET /api/restaurants/:slug`
- `GET /api/restaurants/search`

### Map

Map can use `GET /api/restaurants/search` with:

- `lat`
- `lng`
- `radiusKm`
- filters
- sort by distance or trust

Future map-specific endpoint may be useful:

- `GET /api/restaurants/map`

Expected map item shape:

- id
- slug
- name
- lat
- lng
- trustScore
- cuisine
- area
- thumbnailUrl
- savedCount
- sourceType

### Saves

- `GET /api/saves`
- `POST /api/saves`
- `DELETE /api/saves/:restaurantId`

### Lists

- `GET /api/lists`
- `POST /api/lists`
- `GET /api/lists/:id`
- `PATCH /api/lists/:id`
- `DELETE /api/lists/:id`
- `POST /api/lists/:id/items`
- `DELETE /api/lists/:id/items/:restaurantId`

### Surprise Me

- `GET /api/surprise`

## 11. Analytics Events

Track:

- `reel_shared_to_app`
- `reel_added_manually`
- `reel_processing_started`
- `reel_processing_completed`
- `reel_processing_failed`
- `restaurant_detail_opened`
- `restaurant_saved`
- `restaurant_unsaved`
- `directions_opened`
- `instagram_reel_opened`
- `search_submitted`
- `search_filter_applied`
- `map_opened`
- `map_pin_selected`
- `map_layer_toggled`
- `map_search_this_area`
- `list_created`
- `restaurant_added_to_list`
- `surprise_me_used`
- `sign_in_started`
- `sign_in_completed`

## 12. MVP Scope

### Phase 1

- Silent reel share.
- Manual add reel.
- Home reel inbox.
- Processing status.
- Restaurant detail.
- Explore search.
- Map tab with trusted and saved-by-others layers.
- Save restaurant.
- Basic profile.

### Phase 1.5

- Lists.
- Surprise Me.
- Better map filters.
- Public aggregate saved counts.

### Phase 2

- Public foodlists.
- Community feedback.
- Creator credibility.
- AI food assistant.
- Food trails.

## 13. Open Questions

1. Should Map show all public saved places immediately, or only places that have been analysed by Theta?
2. Should saved-by-others be city-level, nearby-only, or global with filters?
3. Do guests get a local saved list, or is save login-only from day one?
4. Should processing start automatically on silent share, or only when the app opens and syncs pending shares?
5. Do we want a separate Map endpoint for better performance, or reuse restaurant search for MVP?
6. What is the minimum signal needed before a restaurant appears publicly on Map?
7. Should public lists be included in MVP or reserved for Phase 1.5?

## 14. Success Metrics

### Activation

- Percentage of users who add or share at least one reel.
- Percentage of shared reels that reach restaurant detail.

### Discovery

- Search to restaurant detail open rate.
- Map pin selection rate.
- Map to directions rate.

### Retention

- Saved restaurant count per active user.
- Return rate after saving a restaurant.
- Repeat reel shares per user.

### Trust

- Restaurant detail save rate.
- Directions click rate after viewing trust summary.
- Failed processing rate.

