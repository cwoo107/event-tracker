<!--
  USAN internal app style guide - single-file, opt-in.
  To use it in another app, copy this file into that repo and tell Claude to follow it
  (for example, add "Follow STYLE_GUIDE.md for all UI work" to that repo's CLAUDE.md).
  Repos without this file don't use it.
-->

# USAN internal app style guide

This is the visual and interaction system from the **USAN Event Liaison Tracker** (`usan_events`).
Every USAN internal app should look like part of the same product family: quiet slate neutrals,
a deep forest-green brand, one loud lime call to action per screen, small dense type, thin borders,
no heavy shadows.

**Before you write any UI, read this file in full. Then reread the section for the thing you are building:**

| Building… | Read |
|---|---|
| A new app, or the layout, nav, CSS, or head | [Starting a new app](#starting-a-new-app), then copy the [templates](#templates) |
| Buttons, inputs, badges, tables, cards, stat tiles, alerts, menus | [Components](#components) |
| A whole page (index, dashboard, form, master/detail, auth) | [Page patterns](#page-patterns) |
| Labels, empty states, dates, numbers, confirmations | [Voice, copy, and data formatting](#voice-copy-and-data-formatting) |
| Mobile, native app (Ruby Native), or email | [Mobile, native app, and email](#mobile-native-app-and-email) |

## Stack (don't change it)

- Rails 8, **Propshaft**, **importmap** (no Node bundler, no React)
- **tailwindcss-rails (Tailwind v4)** with an `@theme` block, no `tailwind.config.js`
- **Turbo** (frames for master/detail and panels) + **Stimulus** for every bit of JS
- Third-party browser libs (Chart.js, Mapbox GL) load as **plain `<script>` tags in the layout**,
  not through importmap ESM pins. Their workers and globals break when re-exported through ESM CDNs.
- Inline SVG icons (Feather/Lucide-style strokes). No icon font, no icon gem.
- Font: **Inter** 400/500/600/700 from Google Fonts.

## The rules

1. **Tokens, not hex.** Use `brand-*`, `lime-*`, and Tailwind `slate-*`. Raw hex is only allowed for
   data-driven colors (per-person colors set inline) and in email/Chart.js where classes can't reach.
2. **Base text is 14px; UI text is 13px.** The body is `text-[14px]`. Almost every control, table cell,
   and paragraph is `text-[13px]`. Meta text is `text-[12px]`/`text-[11px]`. Section eyebrows are
   `text-[11px] font-semibold uppercase tracking-wide`. Page titles are `text-xl font-semibold`. Don't use
   `text-base` or larger anywhere inside the app shell except stat values and page titles.
3. **One lime button per screen.** `bg-lime-400 hover:bg-lime-500 text-brand-900 font-semibold` is the
   "create / do the main thing" CTA. Everything else that's primary is `bg-brand-700 hover:bg-brand-800 text-white`.
   Secondary is white with a `border-slate-200`. Tertiary is a text link in `text-brand-700`.
4. **Borders over shadows.** Surfaces are `bg-white border border-slate-200 rounded-lg`. Inner dividers are
   `divide-slate-100` / `border-slate-100`. Shadows only on floating things: dropdowns (`shadow-lg`),
   the bottom sheet, and the lime CTA's faint `shadow-sm shadow-lime-400/30`.
5. **Radius scale:** `rounded-md` for controls (buttons, inputs, nav items), `rounded-lg` for cards and
   tables, `rounded-full` for avatars, dots, and filter pills, `rounded` for tiny badges.
6. **Page canvas is `bg-slate-50`; content surfaces are white.** The header, sidebars, and cards are white.
7. **Selected = brand-50 tint + brand-700 text.** Nav items, rows, and tabs all use the same active treatment
   (`bg-brand-50 text-brand-700`, or a brand-700 bottom border for tabs, or a left border for list rows).
   Segmented/filter choices that are "on" go solid: `bg-brand-700 text-white`.
8. **Every list has an empty state**, written in plain, slightly human language in `text-slate-400`
   (for example "Nothing waiting on triage.").
9. **Mobile-first responsive and native-aware.** Every page works at 375px, tables scroll horizontally
   (`overflow-x-auto`), multi-pane layouts collapse to tabs or bottom sheets below `md`, and every page calls
   `native_navbar_tag("Title")` and hides the web nav when `native_app?`.
10. **Put shared class strings and color rules in helpers.** Form fields, labels, badges, and status→color maps live
    in helpers (see the `ui_helper.rb` [template](#templates)) so the views can't drift apart. One method decides what color a
    status is, and every view calls it.
11. **Full-width pages.** No `max-w-*xl` page wrappers. Only login-type and small forms are narrow (see below).

## Palette at a glance

```
brand-50  #f0f7f1  active/selected tint, subtle highlight
brand-100 #dcebe0
brand-200 #b9d7c2
brand-300 #8fbd9c
brand-600 #2f7a3e  focus ring, progress bars, chart default, checkbox accent
brand-700 #1f4d2b  PRIMARY: buttons, avatars, active text, links, native tint
brand-800 #173a24  primary hover
brand-900 #0f2818  text on lime, darkest brand

lime-50   #fbfce8  callout background
lime-100  #f3f6c6  "special" badge bg
lime-400  #c3d117  CTA background, "watch" badge
lime-500  #aebe14  CTA hover, callout border
lime-700  #6d7a0d  text on lime-100

Neutrals: Tailwind slate. 900 headings, 700 body/labels, 500 secondary, 400 meta/empty, 300 disabled,
200 borders, 100 dividers/badge bg, 50 canvas/hover.
Danger: rose (rose-600 solid, rose-50/rose-700 soft). Warning: amber-50/amber-700.
Success flash: green-50/green-700. Error flash: red-50/red-700.
```

## Workflow when building UI

1. Find the closest existing page pattern in [Page patterns](#page-patterns) and start from it. Don't invent a layout.
2. Build with the components in [Components](#components), copying class strings exactly. If a string is
   used three or more times, move it into a helper.
3. Write copy with [Voice, copy, and data formatting](#voice-copy-and-data-formatting): sentence case, terse, `|` as the inline separator,
   `&mdash;` for missing values.
4. Add `content_for :title, "<Page> | <App name>"` and `native_navbar_tag("<Page>")` at the top of the view.
5. Check it at 375px, 768px, and 1280px widths. Check empty, one-item, and many-item states.
6. Run the review checklist below before calling it done.

## Review checklist

- [ ] No raw hex in classes except data-driven colors
- [ ] No `text-sm`/`text-base` drift; controls are `text-[13px]`
- [ ] At most one lime CTA visible
- [ ] Cards and tables: `bg-white border border-slate-200 rounded-lg`; rows use `divide-y divide-slate-100`
- [ ] Inputs use `form_field_class`; labels use `form_label_class`
- [ ] Focus visible: `focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600`
- [ ] Every icon-only button has `aria-label`; every decorative SVG has `aria-hidden="true"`
- [ ] Destructive actions use `data: { turbo_confirm: "…?" }` and are understated (`text-slate-400 hover:text-rose-600`)
- [ ] Empty state present
- [ ] Table wrapped in `overflow-x-auto`; multi-pane layout collapses below `md`
- [ ] `content_for :title` and `native_navbar_tag` set
- [ ] All JS behavior is a Stimulus controller with a header comment explaining *why*
- [ ] No `max-w-*xl` on a page wrapper (only auth or small-form pages get `max-w-sm`/`max-w-md`)

## Pages are full width. No `max-w-*xl` page wrappers.

Never wrap a page in `max-w-3xl`, `max-w-6xl`, `max-w-7xl`, or any other `max-w-*xl` container. Pages fill the
viewport with `px-4 sm:px-6` gutters. When content would get too wide, lay it out in grid columns instead of
narrowing the page.

The **only** exception is a small, single-purpose form centered on the page: sign in, password reset,
registration, or a 2–4 field dialog-style form. These use `max-w-sm` (or `max-w-md`) with `mx-auto`.

Width caps *inside* a page are fine when they serve the component: dropdown widths, sidebar rails, the 560px email body.


---

## Starting a new app

### 1. Generate

```bash
rails new <app_name> --database=postgresql --css=tailwind --javascript=importmap
cd <app_name>
bin/rails generate authentication          # Rails 8 built-in auth (Current.user, sessions, passwords)
```

Add to the Gemfile if needed: `ruby_native` (mobile shell), `letter_opener` (dev group), `rspec-rails`,
`factory_bot_rails`, `faker` (dev/test).

### 2. Copy the templates

All of these are in the [Templates](#templates) section at the end of this file.

| Template | Destination |
|---|---|
| `application.css` | `app/assets/tailwind/application.css` (replace) |
| `application.html.erb` | `app/views/layouts/application.html.erb` (replace) |
| `_nav.html.erb` | `app/views/layouts/_nav.html.erb` |
| `mailer.html.erb` | `app/views/layouts/mailer.html.erb` (replace) |
| `ui_helper.rb` | `app/helpers/ui_helper.rb` |
| `controllers/*.js` | `app/javascript/controllers/` (`pin_all_from` picks them up) |
| `ruby_native.yml` | `config/ruby_native.yml` (only if shipping native) |

Copy the **logo** (`app/assets/images/811 Icon - Right.jpg` in `usan_events`) into `app/assets/images/`.
It's the left-most element of the header, 64px wide on mobile and 100px on desktop.

### 3. Fill in the placeholders

Search the copied files for `APP_NAME`, `APP_SHORT_NAME`, and the `NAV_ITEMS` array in `ui_helper.rb`:

- **App full name** goes in `<title>` defaults and page titles ("USAN Event Liaison Tracker").
- **App short name** goes in the header lockup under the logo and the email header ("Event tracker"),
  in sentence case.
- **Nav items** are 3–6 top-level sections in sentence case. The most-used one comes first and is also the logo link target.
- **Primary CTA** is the single lime "New …" action in the header.

### 4. Conventions to carry over

- `Current.user` provides `initials`, `short_name`, and `job_title`, all used by the header user menu.
- If the app is multi-tenant, `Current.account` shows its name under the app short name in the header, and the user
  menu has a "Switch account" group.
- Secrets come from **Hatchbox env vars** in production, not `credentials.yml.enc`.
- Shared data→color logic (status colors, per-person colors) gets **one helper method**. Map markers, list
  dots, calendar bars, and dashboard rows all call it.
- Stimulus controllers start with a comment explaining *why* the controller exists and any non-obvious decision.
  Comments explain reasons, not mechanics. Match that density.

### 5. Verify

Boot the app and look at `/` signed out and signed in, at 375px and 1280px wide. Check the header lockup, nav active
state, the lime CTA, and an empty state against the source app's screenshots in
`usan_events/app/assets/images/marketing/`.


---

## Components

Copy these class strings exactly. They come from production views in `usan_events`.
Helper names refer to the `ui_helper.rb` [template](#templates). In new apps, prefer the helpers (`btn_class(:cta)`, `form_field_class`, `tag_pill`, `level_badge`, `stat_tile`, `eyebrow`, `flash_messages`, `nav_link_to`) over pasting raw strings. The raw strings below show what the helpers produce.

### Buttons

| Role | Classes |
|---|---|
| **CTA (lime)**, one per screen: "New X", "Auto-assign", "Create an account" | `flex items-center gap-1.5 bg-lime-400 hover:bg-lime-500 text-brand-900 text-[13px] font-semibold px-3.5 py-2 rounded-md shadow-sm shadow-lime-400/30` |
| **Primary**: submit, save, complete | `bg-brand-700 hover:bg-brand-800 text-white text-[13px] font-semibold px-4 py-2.5 rounded-md cursor-pointer border-0` |
| **Secondary** (outlined) | `text-[12px] font-medium text-brand-700 hover:text-brand-800 border border-slate-200 rounded-md px-2.5 py-1.5` |
| **Text action** | `text-[12px] font-medium text-brand-700 hover:text-brand-800` |
| **Quiet / cancel / reset** | `text-[13px] font-medium text-slate-500 hover:text-slate-700 bg-transparent border-0 cursor-pointer` |
| **Destructive (understated)** | `text-[12px] text-slate-400 hover:text-rose-600 bg-transparent border-0 cursor-pointer` + `data: { turbo_confirm: "Delete X?" }` |
| **Icon square** (prev/next) | `w-8 h-8 flex items-center justify-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50` + `aria: { label: "…" }` |
| **Full-width form submit** | add `w-full` to Primary |
| **Compact in-table** | Same as above at `text-[12px] px-2.5 py-1.5` |

`button_to` renders a `<button>`, so always include `border-0 cursor-pointer` (and `bg-transparent` for text buttons).

CTA with plus icon:

```erb
<%= link_to new_thing_path, class: "flex items-center gap-1.5 bg-lime-400 hover:bg-lime-500 text-brand-900 text-[13px] font-semibold px-3.5 py-2 rounded-md shadow-sm shadow-lime-400/30" do %>
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg>
  New thing
<% end %>
```

### Form fields

```ruby
# ui_helper.rb
def form_field_class
  "w-full px-3 py-2 text-[13px] rounded-md border border-slate-200 bg-white " \
    "focus:outline-none focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600"
end

def form_label_class
  "block text-[13px] font-medium text-slate-700 mb-1"
end
```

```erb
<div>
  <%= f.label :title, class: form_label_class %>
  <%= f.text_field :title, class: form_field_class, placeholder: "Sac Valley Ag Field Day" %>
</div>
```

- Use the same class for `select`, `number_field`, `datetime_field`, and `email_field`.
- **Two-up rows:** `grid grid-cols-1 sm:grid-cols-2 gap-4`
- **Checkbox:** `rounded border-slate-300 text-brand-600 focus:ring-brand-600/30`, wrapped in
  `<label class="flex items-center gap-2 text-[13px] text-slate-700">`
- **Range slider:** `w-full accent-brand-700`
- **Help text under a section heading:** `text-[12px] text-slate-400 -mt-2`
- **Readonly / not-yet-filled field:** inline `background-color:#f8fafc; color:#94a3b8;`
- **Search input with icon:**

```erb
<div class="relative">
  <svg class="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
  <%= f.text_field :q, value: params[:q], placeholder: "Search events, cities, requesters...",
        data: { action: "input->auto-submit#debouncedSubmit" },
        class: "w-full pl-9 pr-3 py-2 text-[13px] rounded-md border border-slate-200 bg-slate-50 focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600 placeholder:text-slate-400" %>
</div>
```

Filter forms auto-submit through the `auto-submit` Stimulus controller and target a Turbo Frame, so there's no submit button.

### Form sections

```erb
<section class="space-y-4">
  <h2 class="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Schedule</h2>
  …fields…
</section>
```

Stack sections with `space-y-8` (or `space-y-10` on settings pages). The footer action bar:

```erb
<div class="flex items-center justify-end gap-3 pt-2 border-t border-slate-100">
  <%= link_to "Cancel", back_path, class: "text-[13px] font-medium text-slate-500 hover:text-slate-700" %>
  <%= f.submit "Save", class: "bg-brand-700 hover:bg-brand-800 text-white text-[13px] font-semibold px-4 py-2.5 rounded-md cursor-pointer border-0" %>
</div>
```

### Filter pills and segmented ranges

```erb
<%# pill (rounded-full), used for category filters %>
<label class="px-2.5 py-1 rounded-full text-[12px] font-medium cursor-pointer <%= active ? 'bg-brand-700 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200' %>">
  <%= f.radio_button :type, value, checked: active, class: "hidden", data: { action: "change->auto-submit#submit" } %>
  <%= label %>
</label>

<%# segmented link (rounded-md), used for time ranges %>
<%= link_to label, path, class: "px-3 py-1.5 text-[12px] font-medium rounded-md #{active ? 'bg-brand-700 text-white' : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'}" %>
```

### Badges and tags

| Kind | Classes |
|---|---|
| Neutral tag (type, source) | `text-[11px] font-medium text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded` |
| Highlight tag (weekend, special) | `text-[11px] font-medium text-lime-700 bg-lime-100 px-1.5 py-0.5 rounded` |
| Warning tag (long haul) | `text-[11px] font-medium text-rose-700 bg-rose-50 px-1.5 py-0.5 rounded` |
| Skill chip | `text-[10px] font-medium text-slate-500 bg-slate-100 px-1.5 py-0.5 rounded uppercase tracking-wide` |
| Risk/level badge (uppercase) | `text-[10px] font-semibold px-1.5 py-0.5 rounded` + level color below |

Level colors (`ApplicationHelper::RISK_BADGE_CLASSES` pattern):

```ruby
high:  "bg-rose-600 text-white"
watch: "bg-lime-400 text-brand-900"
ok:    "bg-white text-slate-500 border border-slate-200"
low:   "bg-white text-slate-400 border border-slate-200"
```

Put a `title:` tooltip on a badge that explains *why* (for example the reasons it was flagged).

### Status dots and avatars

- **Dot:** `<span class="w-2 h-2 rounded-full flex-none" style="background: <%= color %>"></span>`
  (`w-1.5 h-1.5` before section labels, `w-2.5 h-2.5` with a border for "assigned but upcoming").
- **Avatar (user):** `w-8 h-8 rounded-full bg-brand-700 text-white text-[12px] font-semibold flex items-center justify-center flex-none` showing initials.
- **Avatar (person with own color):** same shape, `style="background: <%= person.color %>"`. Sizes are `w-9` (rows) and `w-14 text-[16px]` (profile header).
- People and entities that appear on maps or calendars get a **stored per-record color**. Use it everywhere
  that record appears (dot, avatar, calendar bar, chart, active-row left border through the `--row-color` CSS var).

### Cards and surfaces

- **Card:** `bg-white border border-slate-200 rounded-lg p-3` (or `p-4`)
- **List card:** `bg-white border border-slate-200 rounded-lg divide-y divide-slate-100`, with each row
  `flex items-center justify-between px-4 py-2.5 hover:bg-slate-50`
- **Inset tile** inside a panel: `bg-slate-50 rounded-lg p-3`
- **Section heading above a card:** `<h2 class="text-[13px] font-semibold text-slate-900 mb-3">Per-liaison breakdown</h2>`

### Stat tiles (KPI row)

```erb
<div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 mb-8">
  <div class="border border-slate-200 rounded-lg p-3 bg-white">
    <p class="text-[11px] text-slate-400">Open requests</p>
    <p class="text-[20px] font-semibold text-slate-900"><%= @report.open_requests_count %></p>
  </div>
</div>
```

Use `text-[18px]` on profile pages, and `text-[15px]` when the tile holds an editable input.
Show "x / y" ratios inline (`3 / 5`).

### Key/value grid (detail panels)

Hairline grid made from gap-px on a slate background:

```erb
<div class="grid grid-cols-2 gap-px bg-slate-100">
  <div class="bg-white p-3">
    <p class="text-[11px] text-slate-400">Date</p>
    <p class="text-[13px] font-medium text-slate-800">Tue, Oct 14</p>
  </div>
</div>
```

### Tables

```erb
<div class="border border-slate-200 rounded-lg overflow-hidden overflow-x-auto bg-white">
  <table class="w-full text-[13px]">
    <thead>
      <tr class="border-b border-slate-100 text-left text-[11px] uppercase tracking-wide text-slate-400">
        <th class="px-3 py-2">Event</th>
        <th class="px-3 py-2 text-right">Miles</th>
      </tr>
    </thead>
    <tbody class="divide-y divide-slate-100">
      <tr class="hover:bg-slate-50">
        <td class="px-3 py-2.5">
          <%= link_to event.title, event_path(event), class: "font-medium text-slate-900 hover:text-brand-700" %>
          <p class="text-[11px] text-slate-500">Outreach | Woodland</p>
        </td>
        <td class="px-3 py-2.5 text-right">1,204</td>
      </tr>
      <% if rows.none? %>
        <tr><td colspan="2" class="px-3 py-6 text-center text-slate-400">Nothing waiting on triage.</td></tr>
      <% end %>
    </tbody>
  </table>
</div>
```

- Numbers are right-aligned. Dates and durations get `whitespace-nowrap`.
- Two-line cells: primary text, then a `text-[11px] text-slate-500` sub-line.
- Row actions go in the last column, right-aligned, `flex items-center justify-end gap-2`.
- **Inline progress bar:** `w-20 h-1.5 bg-slate-100 rounded-full overflow-hidden` with an inner `h-full bg-brand-600` and `style="width: N%"`.

### Alerts and callouts

```erb
<%# flash %>
<p class="py-2 px-3 bg-red-50 mb-5 text-red-700 text-[13px] font-medium rounded-md" id="alert"><%= alert %></p>
<p class="py-2 px-3 bg-green-50 mb-5 text-green-700 text-[13px] font-medium rounded-md" id="notice"><%= notice %></p>

<%# inline warning %>
<p class="text-[12px] text-amber-700 bg-amber-50 rounded-md px-2.5 py-1.5">This event needs a second liaison.</p>

<%# brand callout (state the user should know about) %>
<div class="rounded-lg bg-lime-50 border-l-2 border-lime-500 px-4 py-3 text-[13px] text-brand-900">Load hold active. …</div>
```

### Colored header band (detail panel)

Detail panels open with a solid status-colored header:

```erb
<div class="<%= status_bg_class(record) %> px-5 py-4 text-white">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-2 text-[11px] font-medium uppercase tracking-wide text-white/70">
      <span><%= record.status %></span><span>|</span><span><%= record.reference_code %></span>
    </div>
    <div class="flex items-center gap-3">
      <%= link_to "Edit", edit_path, class: "text-white/70 hover:text-white text-[12px] font-medium" %>
      <%= link_to close_path, class: "text-white/70 hover:text-white text-lg leading-none", aria: { label: "Close" } do %>&times;<% end %>
    </div>
  </div>
  <p class="text-lg font-semibold mt-1"><%= record.title %></p>
  <p class="text-[13px] text-white/80"><%= record.subtitle %></p>
</div>
```

After the band, stack sections as `<div class="p-4 border-b border-slate-100">` and start each with an eyebrow:
`<p class="text-[11px] font-semibold uppercase tracking-wide text-slate-500 mb-2">Requester</p>`.

### Sidebar list rows

```erb
<%= link_to path, data: { turbo_frame: "detail" },
      style: "--row-color: #{color}",
      class: class_names("sidebar-row block px-4 py-3 border-l-2 border-transparent hover:bg-slate-50", "is-active" => selected) do %>
  <div class="flex items-center justify-between gap-2">
    <p class="text-[13px] font-medium text-slate-900 truncate">Title</p>
    <p class="text-[11px] text-slate-400 flex-none">Tue, Oct 14</p>
  </div>
  <p class="text-[12px] text-slate-500 mt-0.5">City | 09:00–12:00 | 42m drive</p>
<% end %>
```

Group headers inside a scrolling list are sticky:
`px-4 pt-4 pb-1 flex items-center gap-2 sticky top-0 bg-white`, holding a dot, an uppercase eyebrow, and a `text-[11px] text-slate-400` count.

### Dropdown menu

Use the `dropdown` controller (the dropdown controller [template](#templates)).

```erb
<div class="relative" data-controller="dropdown">
  <button type="button" data-action="click->dropdown#toggle" class="… cursor-pointer border-0 bg-transparent">…</button>
  <div data-dropdown-target="panel" class="hidden absolute right-0 top-full mt-1 w-52 bg-white border border-slate-200 rounded-md shadow-lg py-1 z-20">
    <%= link_to "Account settings", path, class: "block px-3 py-2 text-[13px] text-slate-700 hover:bg-slate-50" %>
    <div class="border-t border-slate-100 mt-1 pt-1">
      <p class="px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-slate-400">Group label</p>
      …
    </div>
  </div>
</div>
```

### Empty states

- **In a list or table:** a single `text-[13px] text-slate-400` line (table: `px-3 py-6 text-center`).
- **Whole panel:** centered icon and sentence:

```erb
<div class="h-full flex flex-col items-center justify-center text-center px-6 text-slate-400">
  <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="mb-3" aria-hidden="true">…</svg>
  <p class="text-[13px]">Select an event from the sidebar or map to see its details.</p>
</div>
```

### Charts (Chart.js via `bar-chart` controller)

- The canvas goes in `bg-white border border-slate-200 rounded-lg p-3` with a fixed `style="height: 200px;"`.
- Bars: default color `#2f7a3e` (brand-600), over-limit bars `#dc2626`, `borderRadius: 4`, `maxBarThickness: 28`.
- No legend, no x gridlines, y starts at 0 with integer ticks.
- Pass data with Stimulus values: `data-bar-chart-labels-value="<%= labels.to_json %>"`.

### Icons

Inline SVG, `viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round"`, and `aria-hidden="true"`.
Use stroke-width 2 normally, 2.5 for small bold glyphs (plus, chevron in a button), and 1.5 for large empty-state icons.
Sizes: 14–16px in controls, 20px for the hamburger, 32px for empty states. Copy paths from Lucide.


---

## Page patterns

Every screen in a USAN app is one of these six shapes. Pick one before writing markup.

Every page is **full width** with `px-4 sm:px-6` gutters. Never use a `max-w-*xl` page wrapper. Shape 6 is the only page that gets a width cap.

Every view starts with:

```erb
<% content_for :title, "Requests | USAN Event Liaison Tracker" %>
<%= native_navbar_tag("Requests") %>
```

### 1. Index / table page (for example Requests, Liaisons)

```erb
<div class="px-4 sm:px-6 py-6 sm:py-8">
  <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
    <div>
      <h1 class="text-xl font-semibold text-slate-900">Incoming requests</h1>
      <p class="text-[13px] text-slate-500 mt-1"><%= pluralize(@requests.size, "event") %> awaiting assignment</p>
    </div>
    <%# lime CTA %>
  </div>

  <%# table component (components.md → Tables) %>
</div>
```

- The subtitle is a **live count or context sentence**, not marketing copy.
- The header stacks on mobile (`flex-col sm:flex-row`).

### 2. Dashboard

```
H1 + segmented range links (right)
context line (text-[13px] text-slate-500 mb-6): "48-week calendar | 3 events per liaison per week | showing FY 2026"
KPI row: grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 mb-8
Main row: grid-cols-1 lg:grid-cols-3 gap-6 mb-8
  ├─ lg:col-span-2  → h2 + table
  └─ 1 col          → h2 + "watch list" card (dot + name + reason sentences)
Charts row: grid-cols-1 sm:grid-cols-2 gap-6 mb-8 (200px chart cards)
Upcoming list: h2 + list card of link rows
```

Section titles inside a dashboard are `text-[13px] font-semibold text-slate-900 mb-3`, not eyebrows.
Keep the query logic in a PORO report object (`DashboardReport`) and make the view only render.

### 3. Master / detail (map page, people directory)

A full-height split under the header:

```erb
<div class="flex flex-col md:flex-row" style="height: calc(100vh - var(--app-header-height));">
  <aside class="hidden md:flex flex-col w-full md:w-[300px] md:flex-none border-r border-slate-200 bg-white">
    <%= render "things/sidebar" %>   <%# filter form (p-4 border-b border-slate-100) + scrolling list (flex-1 overflow-y-auto) %>
  </aside>
  <main class="flex-1 min-w-0 overflow-y-auto">
    <%= turbo_frame_tag "thing_detail" do %> … <% end %>
  </main>
</div>
```

- Sidebar widths: `300px` (people), `340px` (events). An optional third rail is `380px` with `border-l`.
- `--app-header-height` is set on `<body>` (64px on web, 0px in the native app). Always use it for full-height layouts.
- Sidebar rows navigate the detail **Turbo Frame** (`data: { turbo_frame: "thing_detail" }`). The filter form
  targets the sidebar's own frame, so the detail panel survives searching.
- Use `turbo_frame: "_top"` on actions that change list membership (assign, complete, delete).
- **Mobile:** the sidebar becomes its own page (index shows the list, show hides it and adds a back link),
  *or* use the `mobile-tabs` controller (List | Map tabs), *or* use the `bottom-sheet` controller for a detail
  over a map. See [Mobile, native app, and email](#mobile-native-app-and-email).

Mobile back link on show pages:

```erb
<%= link_to things_path, class: "md:hidden flex items-center gap-1.5 px-4 pt-4 text-[13px] font-medium text-brand-700 hover:text-brand-800" do %>
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>
  All things
<% end %>
```

### 4. Profile / record show (inside the detail area)

```
<div class="p-4 sm:p-6">
  optional lime callout (state banner)
  header row: avatar w-14 + h1 text-lg + meta line + chips | right side: big number text-2xl + badge + Edit/Delete text actions
  KPI tiles grid-cols-2 sm:grid-cols-4 gap-3 mb-8 (text-[18px])
  sections: h2 text-[13px] font-semibold + card/table/chart
```

### 5. Form page (new / edit / settings)

```erb
<div class="px-4 sm:px-6 py-6 sm:py-10">
  <h1 class="text-xl font-semibold text-slate-900">New event request</h1>
  <p class="text-[13px] text-slate-500 mt-1 mb-8">One sentence on what happens after submit.</p>

  <%= form_with model: @thing, class: "space-y-8" do |f| %>
    <%= render "form_errors", object: @thing %>
    <section class="space-y-4">…eyebrow + fields…</section>
    <section class="space-y-4">…</section>
    <div class="flex items-center justify-end gap-3 pt-2 border-t border-slate-100">…</div>
  <% end %>
</div>
```

- Full width, like every other page. Don't narrow the form with a `max-w-*xl` wrapper.
  Use the width instead: pair short fields two-up (`grid-cols-1 sm:grid-cols-2`), go three- or four-up at
  `lg` for short numeric fields, or put sections side by side (`grid grid-cols-1 lg:grid-cols-2 gap-8`).
- Group fields into named sections with uppercase eyebrows.
- Keep the fields in a `_form_fields` partial so new, edit, and inline-panel edit share them.
- Settings pages use `space-y-10` and may put editable stat tiles in the grid.
- Form errors use the red flash style, listing `full_messages` as `text-[12px]`.

### 6. Auth pages and small forms (sign in, reset, register)

This is the **only** page shape that gets a width cap. Auth pages have no nav (`Current.user` is nil).
The same narrow centered column also works for any small single-purpose form of 2–4 fields:

```erb
<div class="max-w-sm mx-auto px-6 py-10 sm:py-16">
  <h1 class="text-xl font-semibold text-slate-900 mb-1">Sign in</h1>
  <p class="text-[13px] text-slate-500 mb-6">Welcome back.</p>
  <%# flash alert / notice %>
  <%= form_with url: session_path, class: "space-y-4" do |f| %> … full-width primary submit … <% end %>
  <%= link_to "Forgot password?", new_password_path, class: "block text-center text-[12px] text-slate-500 hover:text-slate-700 mt-4" %>
</div>
```

### Marketing / landing page (optional)

This is the only place larger type is allowed: `text-5xl sm:text-6xl tracking-tight text-balance` hero,
`font-mono text-xs uppercase tracking-widest text-brand-700` kicker, and a soft gradient panel
`bg-linear-115 from-white via-brand-50 to-lime-100 rounded-4xl ring-1 ring-brand-900/5 ring-inset`.
Same buttons, same logo lockup as the app header.

### Calendar grid

A CSS grid with 7 columns (`min-w-[700px]` inside `overflow-x-auto`), cells `p-1.5 border-b border-r border-slate-100`
`min-height: 96px`, out-of-month cells `bg-slate-50/60` with `text-slate-300` dates, and event bars
`text-[10px] px-1.5 py-0.5 rounded truncate` colored by the shared status/person color helper. Show at most 3 per cell, then "+N more".


---

## Voice, copy, and data formatting

### Voice

USAN apps are tools for colleagues. Write like a competent coworker: plain, brief, a little warm, never cute.

- **Sentence case everywhere**: buttons, headings, nav ("Assignment settings", "New event request").
  The one exception is uppercase eyebrows and badges, which get it from CSS (`uppercase`).
- **Headings describe the job**, not the table: "Liaison load & balance", "Incoming requests", "Burnout watch".
- **Buttons are verbs**: "Auto-assign", "Review", "Save & re-score queue", "Complete", "Reassign".
  Say what will happen, including side effects.
- **Subtitles carry live context**: counts, the active filter, the rule in force.
  For example "12 events awaiting assignment" or "48-week calendar | 3 events per liaison per week".
- **Empty states are human sentences**: "Nothing waiting on triage." "Nobody's flagged right now."
  "Nothing in the next 30 days." "No activity yet." End them with a period.
- **Explanations sit next to the control**, in `text-[12px] text-slate-500`. For example, under each
  weight slider: "Minutes each way, traffic-adjusted for the departure hour".
- **Confirmations are questions** naming the consequence: "Unassign this event?",
  "Delete Jane Doe? This removes their login too."
- **Disabled actions explain themselves** in a `title`: "Has assignment history - deactivate instead of deleting".
- **Avoid** exclamation points, "Oops", "Successfully", emoji, and Title Case.

### Separators and punctuation

- Use `|` with spaces between inline facts: `Woodland | 09:00–12:00 | 42m drive`
- Use `&ndash;` for ranges (`09:00&ndash;12:00`)
- Use `&mdash;` for a missing value in tables and grids, or a short phrase ("Not yet calculated") in detail panels
- Use `&times;` for close buttons and multipliers ("Weekend &times;1.5")
- Write `&amp;` in headings ("Materials &amp; equipment")

### Formats

| Data | Format | Ruby |
|---|---|---|
| Short date | `Tue, Oct 14` | `strftime("%a, %b %-d")` |
| Short date (no weekday) | `Oct 14` | `strftime("%b %-d")` |
| Full date | `Oct 14, 2026` | `strftime("%b %-d, %Y")` |
| Email long date | `Tuesday, October 14, 2026` | `strftime("%A, %B %-d, %Y")` |
| Time | 24-hour `09:00` | `strftime("%H:%M")` |
| Relative | `3 hours ago` | `"#{time_ago_in_words(t)} ago"` |
| Duration | `3h 15m` / `52m` | `format_drive_time` pattern |
| Distance | `42mi` | `"#{n}mi"` |
| Week label | `W42` | `strftime("W%V")` |
| Ratio | `3 / 5` (stat tile) or `3/5` (inline in table) | |
| Large numbers | `1,204` | `number_with_delimiter` |
| Counts with nouns | `12 events` | `pluralize` |
| Person, compact | first name only in tight spots ("Jane") | `name.split.first` |
| Initials | avatar text | `initials` model method |

### Page titles

`content_for :title, "<Page> | <App full name>"`, for example `"Dashboard | USAN Event Liaison Tracker"`.
For a record page use the record name: `"#{@liaison.name} | USAN Event Liaison Tracker"`.


---

## Mobile, native app, and email

### Responsive rules

- Breakpoints are standard Tailwind. **`md` (768px) is the desktop/mobile switch** for layout and nav.
  `sm` handles small tweaks (two-up fields, header stacking), and `lg` adds dashboard columns and the user's name in the header.
- Gutters: `px-4 sm:px-6`. Vertical: `py-6 sm:py-8`.
- **Nav:** desktop links are `hidden md:flex`. Below `md`, a hamburger toggles a stacked panel that uses the same
  `dropdown` controller. The lime CTA moves into that panel below `sm`.
- **Tables:** never reflow into cards. Wrap them in `overflow-x-auto` and let them scroll.
- **Multi-pane:** below `md`, use one of these:
  1. **Separate pages**: the index shows the list; show hides the sidebar (`hidden md:flex`) and adds a back link.
  2. **Tabs** (`mobile-tabs` controller): a `md:hidden` tab strip with `flex-1 py-3 text-center border-b-2`,
     active `border-brand-700 text-brand-700`, inactive `border-transparent text-slate-500`.
  3. **Bottom sheet** (`bottom-sheet` controller): the detail overlays a map with snap points
     peek 14% / half 50% / expanded 88%. It has `rounded-t-2xl`, a `shadow-[0_-8px_24px_rgba(15,23,42,0.15)]`
     shadow, and a drag handle `w-10 h-1.5 rounded-full bg-slate-300`. At `md+` it becomes a static 380px rail.
- Controllers that only matter on mobile must **no-op on desktop** (check `matchMedia("(min-width: 768px)")`)
  and say so in their header comment.

### Native app (Ruby Native gem)

USAN apps ship to iOS/Android through **`ruby_native`** (Hotwire Native under the hood).

- Layout `<head>` includes `<%= stylesheet_link_tag :ruby_native %>`, and the viewport includes `viewport-fit=cover`.
- `<body class="native-inset …" style="--app-header-height: <%= native_app? ? "0px" : "64px" %>;">`
- Render the web nav only `unless native_app?`, and render `<%= native_tabs_tag %>` after it.
- Every page calls `native_navbar_tag("Title")`. The native bar shows that title.
- `config/ruby_native.yml` (see the `ruby_native.yml` [template](#templates)):
  - `app.mode: advanced` (native transitions)
  - `appearance.tint_color: "#1f4d2b"` (brand-700), `background_color: "#FFFFFF"`
  - `navbar.background_color: "#FFFFFF"`, `foreground_color: "#0f2818"` (brand-900), `status_bar: dark`
  - Tabs mirror the primary web nav (max 5) with SF Symbol icons (`map`, `chart.bar`, `calendar`, `tray`, `person.2`).
    Settings and admin pages stay web-only, reached from a menu.

### Email (ActionMailer)

Email can't use Tailwind, so every style is inline. The palette is the same, written as hex. Use the mailer layout [template](#templates) as the layout.

- Canvas `#f8fafc`, max-width 560px, centered, 32px/16px padding
- **Header band** `#1f4d2b` with the logo (100px wide) and the app name in `rgba(255,255,255,0.7)` 13px, radius `8px 8px 0 0`
- **Body card** white, `1px solid #e2e8f0`, no top border, radius `0 0 8px 8px`, text `#1e293b` 14px/1.6
- **Footer** `#94a3b8` 11px centered: "<Account name> | This is an automated message."
- **Key/value table:** label cell `#64748b` 130px, value cell `#1e293b` weight 600, 6px vertical padding
- **Eyebrow:** `#64748b` 12px uppercase, letter-spacing 0.05em
- **Button:** `background:#1f4d2b; color:#fff; padding:10px 20px; border-radius:6px; font-weight:600; font-size:13px; text-decoration:none`
- Greeting uses the first name: "Hi Jane,"
- Always ship a matching `.text.erb` part.
- Dev uses `letter_opener`.


---

## Templates

Copy each file into a new app at the path shown, then replace the `APP_NAME` / `APP_SHORT_NAME` placeholders and fill in `NAV_ITEMS`.

### `app/assets/tailwind/application.css`

````css
@import "tailwindcss";

/*
  USAN internal-app design tokens. Neutrals are Tailwind's stock slate -
  only the brand greens and the lime accent are custom. Don't add colors
  here without updating the style guide (SKILL.md → Palette).
*/
@theme {
  --color-brand-50: #f0f7f1;
  --color-brand-100: #dcebe0;
  --color-brand-200: #b9d7c2;
  --color-brand-300: #8fbd9c;
  --color-brand-600: #2f7a3e;
  --color-brand-700: #1f4d2b;
  --color-brand-800: #173a24;
  --color-brand-900: #0f2818;

  --color-lime-50: #fbfce8;
  --color-lime-100: #f3f6c6;
  --color-lime-300: #dbe36a;
  --color-lime-400: #c3d117;
  --color-lime-500: #aebe14;
  --color-lime-600: #8a9710;
  --color-lime-700: #6d7a0d;

  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
}

/*
  Selected sidebar row. Plain CSS rather than utilities because the accent
  is per-record and data-driven (set inline as --row-color), not a theme color.
*/
.sidebar-row.is-active {
  background: var(--color-brand-50);
  border-left-color: var(--row-color, var(--liaison-color, var(--color-brand-700)));
}
````

### `app/views/layouts/application.html.erb`

````erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "APP_NAME" %></title>
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">

    <%# Remove if the app doesn't ship a Ruby Native mobile shell. %>
    <%= stylesheet_link_tag :ruby_native %>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

    <%# Third-party browser libs load as plain global scripts, not importmap
        ESM pins - their internal workers/globals can fail silently when
        re-exported through an ESM CDN. Uncomment what the app needs. %>
    <%# <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script> %>

    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="native-inset bg-slate-50 text-slate-900 antialiased text-[14px] font-sans"
        style="--app-header-height: <%= native_app? ? "0px" : "64px" %>;">
    <% if Current.user.present? %>
      <%= render "layouts/nav" unless native_app? %>
      <%= native_tabs_tag %>
    <% end %>
    <%= yield %>
  </body>
</html>
````

### `app/views/layouts/_nav.html.erb`

````erb
<%# Web header. Hidden inside the native app (see layout). Nav items come from
    UiHelper::NAV_ITEMS so desktop and mobile menus can't drift apart. %>
<div data-controller="dropdown">
<header class="h-16 flex items-center gap-3 md:gap-6 px-4 md:px-6 border-b border-slate-200 bg-white">
  <%= link_to root_path, class: "flex items-center gap-2.5 min-w-0" do %>
    <%= image_tag "811 Icon - Right.jpg", class: "w-16 md:w-[100px] h-auto", alt: "USAN" %>
    <div class="h-8 w-px bg-slate-200 mx-1 hidden sm:block"></div>
    <div class="leading-tight text-left hidden sm:block min-w-0">
      <p class="text-sm font-semibold text-slate-900 truncate">APP_SHORT_NAME</p>
      <p class="text-[11px] text-slate-500 truncate"><%= Current.respond_to?(:account) && Current.account ? Current.account.name : "USAN" %></p>
    </div>
  <% end %>

  <nav class="hidden md:flex items-center gap-1 text-[13px] font-medium text-slate-500">
    <% nav_items.each do |label, path| %>
      <%= nav_link_to label, path %>
    <% end %>
  </nav>

  <div class="flex-1"></div>

  <%# The one lime CTA in the header - the app's most common "create" action. %>
  <%# link_to new_thing_path, class: "hidden sm:flex #{btn_class(:cta)}" do %>
    <%# plus_icon %>
    <%# New thing %>
  <%# end %>

  <button type="button" data-action="click->dropdown#toggle" aria-label="Menu"
          class="md:hidden flex items-center justify-center w-9 h-9 -mr-1 rounded-md text-slate-500 hover:bg-slate-50 cursor-pointer border-0 bg-transparent">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
  </button>

  <div class="relative pl-3 border-l border-slate-200" data-controller="dropdown">
    <button type="button" data-action="click->dropdown#toggle"
            class="flex items-center gap-2.5 rounded-md p-1 -m-1 hover:bg-slate-50 cursor-pointer border-0 bg-transparent">
      <div class="w-8 h-8 rounded-full bg-brand-700 text-white text-[12px] font-semibold flex items-center justify-center flex-none">
        <%= Current.user.initials %>
      </div>
      <div class="leading-tight text-left hidden lg:block">
        <p class="text-[13px] font-medium text-slate-900"><%= Current.user.short_name %></p>
        <p class="text-[11px] text-slate-500"><%= Current.user.job_title %></p>
      </div>
    </button>

    <div data-dropdown-target="panel"
         class="hidden absolute right-0 top-full mt-1 w-52 bg-white border border-slate-200 rounded-md shadow-lg py-1 z-20">
      <%# Admin / settings links go here %>
      <div class="border-t border-slate-100 mt-1 pt-1">
        <%= button_to "Log out", session_path, method: :delete,
              class: "w-full text-left px-3 py-2 text-[13px] text-slate-700 hover:bg-slate-50 bg-transparent border-0 cursor-pointer" %>
      </div>
    </div>
  </div>
</header>

<div data-dropdown-target="panel" class="hidden md:hidden border-b border-slate-200 bg-white px-3 py-2 space-y-0.5 text-[13px] font-medium text-slate-500">
  <% nav_items.each do |label, path| %>
    <%= nav_link_to label, path, mobile: true %>
  <% end %>
</div>
</div>
````

### `app/views/layouts/mailer.html.erb`

````erb
<!DOCTYPE html>
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
  </head>
  <body style="margin: 0; padding: 0; background: #f8fafc; font-family: -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif;">
    <div style="max-width: 560px; margin: 0 auto; padding: 32px 16px;">
      <div style="background: #1f4d2b; padding: 16px 24px; border-radius: 8px 8px 0 0;">
        <%= image_tag("811 Icon - Right.jpg", width: "100px", height: "auto", alt: "USAN") %>
        <span style="color: rgba(255,255,255,0.7); font-size: 13px; margin-left: 8px;">APP_SHORT_NAME</span>
      </div>
      <div style="background: #ffffff; padding: 24px; border-radius: 0 0 8px 8px; border: 1px solid #e2e8f0; border-top: none; color: #1e293b; font-size: 14px; line-height: 1.6;">
        <%= yield %>
      </div>
      <p style="text-align: center; color: #94a3b8; font-size: 11px; margin-top: 16px;">
        <%= @account&.name || "APP_SHORT_NAME" %> | This is an automated message.
      </p>
    </div>
  </body>
</html>
````

### `app/helpers/ui_helper.rb`

````ruby
# Shared UI class strings and small components for USAN internal apps.
# Views call these instead of repeating Tailwind strings, so every form
# field, button, and badge looks the same and can only drift in one place.
# See STYLE_GUIDE.md for the full style guide.
module UiHelper
  # [label, path_helper] - drives both the desktop and mobile nav menus.
  # First entry is the app's home section.
  NAV_ITEMS = [
    # ["Dashboard", :dashboard_path],
  ].freeze

  BUTTON_CLASSES = {
    cta: "flex items-center gap-1.5 bg-lime-400 hover:bg-lime-500 text-brand-900 text-[13px] font-semibold " \
         "px-3.5 py-2 rounded-md shadow-sm shadow-lime-400/30",
    primary: "bg-brand-700 hover:bg-brand-800 text-white text-[13px] font-semibold px-4 py-2.5 rounded-md " \
             "cursor-pointer border-0",
    secondary: "text-[12px] font-medium text-brand-700 hover:text-brand-800 border border-slate-200 rounded-md " \
               "px-2.5 py-1.5 bg-white cursor-pointer",
    text: "text-[12px] font-medium text-brand-700 hover:text-brand-800 bg-transparent border-0 cursor-pointer",
    quiet: "text-[13px] font-medium text-slate-500 hover:text-slate-700 bg-transparent border-0 cursor-pointer",
    danger: "text-[12px] text-slate-400 hover:text-rose-600 bg-transparent border-0 cursor-pointer"
  }.freeze

  TAG_CLASSES = {
    neutral: "text-slate-500 bg-slate-100",
    highlight: "text-lime-700 bg-lime-100",
    warning: "text-rose-700 bg-rose-50"
  }.freeze

  LEVEL_BADGE_CLASSES = {
    high: "bg-rose-600 text-white",
    watch: "bg-lime-400 text-brand-900",
    ok: "bg-white text-slate-500 border border-slate-200",
    low: "bg-white text-slate-400 border border-slate-200"
  }.freeze

  def nav_items
    NAV_ITEMS.map { |label, helper| [label, public_send(helper)] }
  end

  def nav_link_to(label, path, mobile: false)
    state = current_page?(path) ? "bg-brand-50 text-brand-700" : "hover:bg-slate-50 hover:text-slate-900"
    shape = mobile ? "block px-3 py-2.5 rounded-md" : "px-3 py-2 rounded-md"
    link_to label, path, class: "#{shape} #{state}"
  end

  def btn_class(kind = :primary)
    BUTTON_CLASSES.fetch(kind)
  end

  def form_field_class
    "w-full px-3 py-2 text-[13px] rounded-md border border-slate-200 bg-white " \
      "focus:outline-none focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600"
  end

  def form_label_class
    "block text-[13px] font-medium text-slate-700 mb-1"
  end

  def checkbox_class
    "rounded border-slate-300 text-brand-600 focus:ring-brand-600/30"
  end

  def eyebrow(text, tag: :h2, **opts)
    content_tag(tag, text, class: class_names("text-[11px] font-semibold uppercase tracking-wide text-slate-500", opts[:class]))
  end

  def tag_pill(text, kind = :neutral)
    content_tag(:span, text, class: "text-[11px] font-medium px-1.5 py-0.5 rounded #{TAG_CLASSES.fetch(kind)}")
  end

  # level: :high / :watch / :ok / :low. reason shows as a hover tooltip.
  def level_badge(level, reason: nil)
    content_tag(:span, level.to_s.upcase,
                class: "text-[10px] font-semibold px-1.5 py-0.5 rounded #{LEVEL_BADGE_CLASSES.fetch(level, LEVEL_BADGE_CLASSES[:ok])}",
                title: reason)
  end

  def stat_tile(label, value)
    tag.div(class: "border border-slate-200 rounded-lg p-3 bg-white") do
      tag.p(label, class: "text-[11px] text-slate-400") +
        tag.p(value, class: "text-[20px] font-semibold text-slate-900")
    end
  end

  def flash_messages
    safe_join([
      (tag.p(flash[:alert], id: "alert", class: "py-2 px-3 bg-red-50 mb-5 text-red-700 text-[13px] font-medium rounded-md") if flash[:alert]),
      (tag.p(flash[:notice], id: "notice", class: "py-2 px-3 bg-green-50 mb-5 text-green-700 text-[13px] font-medium rounded-md") if flash[:notice])
    ].compact)
  end

  def plus_icon(size: 15)
    tag.svg(tag.path(d: "M12 5v14M5 12h14"), width: size, height: size, viewBox: "0 0 24 24", fill: "none",
            stroke: "currentColor", "stroke-width": "2.5", "stroke-linecap": "round", "aria-hidden": "true")
  end

  # "3h 15m" / "52m"
  def format_minutes(minutes)
    return nil if minutes.nil?

    hours, mins = minutes.divmod(60)
    hours.positive? ? "#{hours}h #{mins}m" : "#{mins}m"
  end
end
````

### `config/ruby_native.yml`

````yaml
# USAN defaults for the Ruby Native shell. https://rubynative.com/docs
app:
  mode: advanced

appearance:
  tint_color: "#1f4d2b"        # brand-700
  background_color: "#FFFFFF"
  navbar:
    # No logo - each screen sets its own title via native_navbar_tag.
    background_color: "#FFFFFF"
    foreground_color: "#0f2818" # brand-900
    status_bar: dark

# Mirror the primary web nav (max 5). Icons are SF Symbols / Material.
tabs:
  - title: Home
    path: /
    icon: house
````

### `app/javascript/controllers/dropdown_controller.js`

````js
import { Controller } from "@hotwired/stimulus"

// Generic toggle-a-panel-on-click dropdown, closing on an outside click
// or Escape - used by the nav's user menu, but not specific to it.
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.outsideClickListener = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.outsideClickListener)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickListener)
  }

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }
}
````

### `app/javascript/controllers/auto_submit_controller.js`

````js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), 300)
  }
}
````

### `app/javascript/controllers/mobile_tabs_controller.js`

````js
import { Controller } from "@hotwired/stimulus"

// Below the md breakpoint, the map page's two tabs (list / map) can't both
// fit on screen at once, so this shows one at a time. At md and up,
// Tailwind's `md:flex` classes keep both panes visible no matter what this
// toggles, so it has no visible effect on desktop.
export default class extends Controller {
  static targets = ["pane", "tabButton"]

  show(event) {
    this.showTab(event.currentTarget.dataset.tab)
  }

  showMap() {
    this.showTab("map")
  }

  showTab(tab) {
    this.paneTargets.forEach((pane) => pane.classList.toggle("hidden", pane.dataset.tab !== tab))
    this.tabButtonTargets.forEach((button) => {
      const active = button.dataset.tab === tab
      button.classList.toggle("border-brand-700", active)
      button.classList.toggle("text-brand-700", active)
      button.classList.toggle("border-transparent", !active)
      button.classList.toggle("text-slate-500", !active)
    })
  }
}
````

### `app/javascript/controllers/bottom_sheet_controller.js`

````js
import { Controller } from "@hotwired/stimulus"

// Below the md breakpoint, the map's event-detail frame renders as a
// draggable bottom sheet over the map (Apple/Google Maps style) instead of
// its own 380px rail. At md and up this is a no-op - every method bails out
// via isDesktop() and `md:` classes on the target put the sheet back to a
// plain static column, so desktop is untouched.
const SNAP_POINTS = { hidden: 0, peek: 0.14, half: 0.5, expanded: 0.88 }

export default class extends Controller {
  static targets = ["sheet", "handle"]
  static values = { initial: { type: String, default: "hidden" } }

  connect() {
    this.state = this.initialValue
    this.mediaQuery = window.matchMedia("(min-width: 768px)")
    this.onBreakpointChange = () => this.syncBreakpoint()
    this.mediaQuery.addEventListener("change", this.onBreakpointChange)
    this.syncBreakpoint()
  }

  disconnect() {
    this.mediaQuery.removeEventListener("change", this.onBreakpointChange)
  }

  isDesktop() {
    return this.mediaQuery.matches
  }

  syncBreakpoint() {
    if (this.isDesktop()) {
      this.sheetTarget.classList.remove("hidden")
      this.sheetTarget.style.height = ""
      this.sheetTarget.style.transition = ""
    } else {
      this.applyState(this.state)
    }
  }

  // Called after the event_detail turbo-frame loads - shows the sheet at
  // its default height, or hides it entirely when the loaded frame is the
  // empty state (see data-detail-empty in events/_detail_empty.html.erb).
  syncFrame(event) {
    if (this.isDesktop()) return
    const isEmpty = event.currentTarget.querySelector("[data-detail-empty]") !== null
    this.applyState(isEmpty ? "hidden" : "half")
  }

  applyState(state) {
    this.state = state
    if (this.isDesktop()) return

    this.sheetTarget.style.transition = "height 0.2s ease-out"
    if (state === "hidden") {
      this.sheetTarget.classList.add("hidden")
      this.sheetTarget.style.height = ""
    } else {
      this.sheetTarget.classList.remove("hidden")
      this.sheetTarget.style.height = `${SNAP_POINTS[state] * 100}%`
    }
  }

  dragStart(event) {
    if (this.isDesktop()) return
    this.dragging = true
    this.startY = event.clientY
    this.startHeight = this.sheetTarget.getBoundingClientRect().height
    this.containerHeight = this.sheetTarget.parentElement.getBoundingClientRect().height
    this.sheetTarget.style.transition = "none"
    this.handleTarget.setPointerCapture(event.pointerId)
  }

  dragMove(event) {
    if (!this.dragging) return
    const delta = this.startY - event.clientY
    const min = this.containerHeight * SNAP_POINTS.peek
    const max = this.containerHeight * SNAP_POINTS.expanded
    const height = Math.min(Math.max(this.startHeight + delta, min), max)
    this.sheetTarget.style.height = `${height}px`
    event.preventDefault()
  }

  dragEnd(event) {
    if (!this.dragging) return
    this.dragging = false
    this.handleTarget.releasePointerCapture(event.pointerId)

    const ratio = this.sheetTarget.getBoundingClientRect().height / this.containerHeight
    const nearest = Object.keys(SNAP_POINTS)
      .filter((name) => name !== "hidden")
      .reduce((best, name) => (Math.abs(ratio - SNAP_POINTS[name]) < Math.abs(ratio - SNAP_POINTS[best]) ? name : best), "peek")
    this.applyState(nearest)
  }
}
````

### `app/javascript/controllers/bar_chart_controller.js`

````js
import { Controller } from "@hotwired/stimulus"

// The controller's own element must be a <canvas> - Chart.js draws
// directly onto it, it isn't a wrapper/target situation like the map.
// Chart.js is loaded as a plain global script in the layout, not an ESM
// import - see the layout comment for why.
export default class extends Controller {
  static values = {
    labels: Array,
    values: Array,
    colors: Array
  }

  connect() {
    this.chart = new Chart(this.element, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [
          {
            data: this.valuesValue,
            backgroundColor: this.hasColorsValue ? this.colorsValue : "#2f7a3e",
            borderRadius: 4,
            maxBarThickness: 28
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: { displayColors: false }
        },
        scales: {
          y: { beginAtZero: true, ticks: { precision: 0 } },
          x: { grid: { display: false } }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}
````
