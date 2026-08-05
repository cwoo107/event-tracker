# USAN Event & Liaison Tracker — domain model + schema

This is hand-written to Rails 8 / RSpec conventions, built against your actual
mockups (screenshots + `USAN_Event_Liaison_Tracker_dc.html`), not the original
written spec alone. It's meant to be dropped into a fresh Rails 8 app - I
can't execute Ruby/Rails/Postgres in the sandbox I wrote this in, so treat the
syntax as verified (`ruby -c` passed on all 54 files) but the app itself as
unexercised until you run migrations and specs for real.

## Getting this running

```bash
rails new usan_events --database=postgresql --css=tailwind
cd usan_events
bin/rails generate authentication   # creates User/Session/Current -
                                     # then replace its output with the
                                     # versions here (adds role, name, job_title)
```

Add to your `Gemfile`:

```ruby
gem "activerecord-postgis-adapter"
gem "rgeo"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end
```

Then:

```bash
bundle install
bin/rails generate rspec:install
```

Copy this repo's `db/migrate/`, `app/models/`, and `spec/` into your app
(overwriting the generator's `create_users`/`create_sessions` migrations and
`User`/`Session`/`Current` models with the versions here), then:

```bash
bin/rails db:create db:migrate
bundle exec rspec
```

`config/database.yml` needs `adapter: postgis` (not `postgresql`) for the
geography column type to be available - the `activerecord-postgis-adapter`
gem's README covers this in one line.

## What changed from the original written spec, and why

The mockups you shared surfaced several concrete requirements that weren't in
the original description, or that I'd guessed differently. Grounded in
specific screens:

- **Co-staffing.** Settings → Hard Rules: *"Events over 500 expected
  attendees require two liaisons."* `Event` has no `liaison_id` column;
  its current liaison(s) come from `has_many :liaisons, through:
  active_assignments` (see `Event#assign_to!` / `#reassign_to!` /
  `#unassign!`, and `#co_staffed?` / `#requires_second_liaison?`).
- **The six real scoring weights** (Settings → Assignment engine): drive
  time from HQ (traffic-adjusted - traffic is *not* a separate weight),
  weekly load balance, weekend weighting, hours of day, regional
  familiarity, back-to-back travel. `ScoringWeight::CRITERIA` matches this
  exactly. Regional familiarity is why `Liaison#region` and `Event#county`
  exist.
- **Hard rules are a separate, boolean concept** from the weighted score -
  `AssignmentRule` (max weekly events, overnight-approval threshold,
  no-consecutive-long-haul, departure/return window, weekend annual cap,
  co-staffing threshold). Enforcement is scoring-engine work for the next
  phase; this phase just gives it a home.
- **The 46-week/2-per-week calendar basis is global**, not per-liaison - the
  Settings screen shows one shared panel and the dashboard holds every
  liaison to the same 92. That's `AssignmentSetting`, a singleton row, not
  a column on `Liaison`.
- **Load holds** - the liaison profile's *"Load hold active... will not
  offer Dwight events over 90 minutes of drive time or any weekend date
  until the week of Aug 24"* banner is `LiaisonLoadHold#blocks?(event)`.
- Smaller fixes: `Event#source` is `public_form` / `member_portal` /
  `manual` (three real intake channels from the Requests screen, not my
  earlier guess of two); `Assignment#assignment_status` (accepted/declined,
  seen on the map card); `Liaison#region` / `#home_city` / `#skills`; `User`
  gained `name` / `job_title` (every screenshot's nav shows "Caleb B. ·
  Program Manager").

## The assignment scoring engine

`Scoring::Ranking` is the object that actually ranks liaisons for an
unassigned event - the "ranked suggestion list with a score per liaison"
and "score breakdown bars" from the assignment_ui spec:

```ruby
ranking = Scoring::Ranking.new(event)   # pool: Liaison.active by default

ranking.candidates   # every liaison, best score first, blocked ones last
ranking.eligible      # candidates with no rule/hold violations
ranking.best          # the top eligible candidate, or nil - what
                       # one-click "Auto-assign" would use

candidate = ranking.best
candidate.score       # 0-100
candidate.breakdown   # {"drive_time" => 18.0, "weekly_load_balance" => 22.0, ...}
                       # - point contribution per criterion, for the bars
candidate.blocked?    # true if a hard rule or load hold disqualifies them
candidate.block_reasons # human-readable reasons - what "Manual override
                         # with a warning" would show
```

It composes six small, independently-testable criterion objects (one per
`ScoringWeight::CRITERIA` entry, `app/models/scoring/criteria/`) and five
hard-rule checkers (one per relevant `AssignmentRule::KEYS` entry,
`app/models/scoring/rules/`), plus `LiaisonLoadHold`. Each criterion returns
a 0.0-1.0 "goodness" score that `Ranking` multiplies by its configured
weight; each rule returns `nil` or a violation string. Deliberately not
classes with a single `.call` method - each is a small object with enough
state to do its one job, independently unit-tested
(`spec/models/scoring/`).

A few judgment calls worth knowing about, since the mockup's descriptions
were sometimes one-line hints rather than full specs:

- **"Drive time from HQ" doesn't differentiate liaisons directly** - the
  drive is from the same office for everyone. Instead it rewards liaisons
  with *lower cumulative YTD drive hours* than the team average, which is
  what actually varies person-to-person and is what "prevent burnout"
  is about.
- **"Hours of day" and the departure/return hard rule are the same for
  every candidate on a given event** (again, the drive is uniform) - that's
  expected, not a bug; they still affect the total score and still need
  to render as their own bar per the mockup.
- **"Regional familiarity"** gives 1.0 for a prior event with the same
  requester organization, 0.6 for same-county-only, 0.0 for neither - a
  reasonable v1 reading of "prior events with the same requester or
  county," not something the mockup fully specified.
- **Weights and rules are read live** from `ScoringWeight`/`AssignmentRule`
  each time you rank, so changing the Settings screen's sliders takes
  effect on the next call - no caching to invalidate.
- **Scale**: a handful of small queries per liaison per ranking call. Fine
  for ~8 liaisons; would want batch-loading if the roster grew a lot.

`db/seeds.rb` populates the weights and rules with the exact values shown
in the Settings mockup (30/22/18/12/10/8, hard rules on except the weekend
cap, which the mockup shows unchecked) - run `bin/rails db:seed` after
migrating so the engine is correctly configured out of the box.

## What's still not built

- **Drive time/distance population.** `Event#drive_distance_meters` /
  `#drive_time_seconds` are nullable and meant to be filled by a Mapbox
  Directions API call when an event is geocoded.
- **Burnout risk flag** (the HIGH/WATCH/OK/LOW badges) - computable from
  what's already modeled but not yet its own method.
- **Wiring the engine into the app**: a controller action that calls
  `Scoring::Ranking` and renders the ranked list / explanation panel, and
  the "Auto-assign" button that calls `event.assign_to!(ranking.best.liaison,
  by: current_user, assignment_method: :auto, score: ranking.best.score,
  score_breakdown: ranking.best.breakdown)`.
- Controllers, views, Turbo Frames/Streams, the retheme, Mapbox integration,
  Chart.js dashboards - all later phases.

## The map/sidebar screen (real Rails implementation)

Routes, controller, ERB views, and Stimulus controllers for the actual
screen - not just the static preview HTML from the retheme review.

**Files**: `config/routes.rb`, `app/controllers/events_controller.rb`,
`app/views/events/*`, `app/javascript/controllers/{mapbox,selection,auto_submit}_controller.js`,
`app/assets/tailwind/application.css` (brand color theme).

**Architecture, and why**:
- Only the detail panel is wrapped in a `turbo_frame_tag "event_detail"`.
  Clicking a sidebar row or map marker is a real link
  (`data-turbo-frame: "event_detail"`) - no custom fetch/render JS, Turbo
  does the whole thing. A tiny `selection` Stimulus controller only handles
  the *cosmetic* cross-highlighting between the clicked sidebar row and its
  matching map marker (toggling a class) - it doesn't touch data.
- Assign/unassign/reassign are `turbo_frame: "_top"` redirects (full Turbo
  Drive visit, not frame-scoped) on purpose: those actions change the
  sidebar's counts and list membership, the map marker's color, and the
  detail panel all at once, so a full-page-equivalent visit is the correct
  scope, not a narrower one.
- The map container carries `data-turbo-permanent` so those same visits
  don't tear down and reinitialize the live Mapbox instance - it persists
  across navigations, only the detail panel and sidebar counts change.
- Search/type-filter is a real `form_with` (GET, `turbo_frame:
  "sidebar_lists"`) with a debounced auto-submit Stimulus controller for
  the text field - server-side filtering via Turbo, not a client-side JS
  duplicate of the data (unlike the static preview, which had no backend to
  talk to).
- The radius rings around HQ are an approximation (minutes -> straight-line
  miles at an assumed ~45mph), positioned with the standard Web Mercator
  ground-resolution formula so they stay geographically accurate as you
  pan/zoom - not literal isochrones, which would need a per-liaison routing
  call. Said plainly in a code comment so it doesn't read as more precise
  than it is.

**Setup needed before this runs**:
1. `bin/rails credentials:edit` and add:
   ```yaml
   mapbox:
     access_token: pk.your_real_token
   ```
2. `bin/importmap pin mapbox-gl` - the pin in `config/importmap.rb` is
   illustrative (this sandbox has no network access to jspm/esm.sh to
   resolve the real one). Update the Mapbox GL CSS `<link>` version in the
   layout to match whatever version it resolves.
3. That's the only external JS dependency - `turbo-rails` and
   `stimulus-rails` are assumed already installed from the Rails 8 default.
4. `bin/rails tailwindcss:build` (or run the watcher in dev) to compile
   `app/assets/tailwind/application.css`.

**Deliberately out of scope for this pass** (separate screens per your
original scope list): the intake form ("+ New event request"), Dashboard,
Calendar, Requests, Settings, and Liaison profile. Their nav links are
inert placeholders rather than broken routes.

## New this round: intake form, settings screen, ranked assignment UI

**Intake form** (`events#new/create`, `app/views/events/new.html.erb`) - a
plain staff-entry form. Address geocoding is a client-side call to
Mapbox's Geocoding API (`geocoder_controller.js`) using the same public
token the map already uses, filling in city/county/state/zip and hidden
lat/lng fields. `Event` gained virtual `latitude=`/`longitude=` writers
(paired with the existing readers) plus a `before_validation` that builds
the real `location` point from them - the view never touches RGeo
directly.

**Settings screen** (`SettingsController`, `SettingsForm`,
`app/views/settings/edit.html.erb`) - edits `ScoringWeight`,
`AssignmentRule`, and `AssignmentSetting` as one transaction.
`SettingsForm` is a plain form object (not a "Service" - it holds the
loaded state and both the interactive `#save` and the shared
`.reset_to_defaults!` used by both the "Reset to defaults" button and
`db/seeds.rb`, so the default values live in exactly one place). Hard-rule
thresholds aren't editable here, matching the mockup - only enabled/
disabled; a rule toggled on for the first time gets seeded with its
default threshold rather than a null one.

**Ranked assignment UI** (`events#candidates`/`#assign_candidate`,
`app/views/events/_candidates.html.erb`) - the full ranked list with a
score and a per-criterion breakdown bar for every active liaison, reached
via "View ranked suggestions" (unassigned events) or "Reassign" (assigned
ones, which now opens this list instead of blindly picking an alternate -
a real behavior change from the previous round). Selecting a blocked
candidate shows Rails' built-in `turbo_confirm` warning naming the specific
rule it breaks before submitting - that's the "manual override" from the
spec. The score is always recomputed server-side in `assign_candidate`
rather than trusting a client-submitted value, so the stored
`score_breakdown` can't be tampered with via the form. `auto_assign` (the
one-click path) is unchanged and still bypasses this list entirely.

## A note on the other files you attached

`styles.css`, `readme.md`, `_adherence.oxlintrc.json`, `_ds_bundle.js`, and
`_ds_manifest.json` describe a design system called "Modernist" - a
near-mono **red** accent, zero border-radius, Archivo font. Confirmed with
the team: this was bundled with the mockup export but isn't the intended
styling for this project. The real palette (greens/yellow-green) comes from
the actual screenshots and `USAN_Event_Liaison_Tracker_dc.html`, and that's
what the retheme phase will use.
