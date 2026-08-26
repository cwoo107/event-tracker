module EventsHelper
  STATUS_BG_CLASSES = {
    "assigned" => "bg-brand-700",
    "unassigned" => "bg-slate-400",
    "completed" => "bg-slate-300",
    "cancelled" => "bg-slate-400"
  }.freeze

  def status_bg_class(event)
    STATUS_BG_CLASSES.fetch(event.status, "bg-slate-400")
  end

  # Filter pills on the sidebar - derived from the account's own EventType
  # catalog so it can't drift out of sync with what admins have configured.
  def event_type_filter_options
    [["all", "All types"]] + Current.account.event_types.active.order(:name).pluck(:id, :name).map { |id, name| [id.to_s, name] }
  end

  # The one place status + liaison map to a color, so the map markers,
  # sidebar row dots, calendar bars, and dashboard list all agree with
  # each other instead of three separate approximations of the same rule:
  #   unassigned          - white fill, neutral border (no liaison yet)
  #   assigned (upcoming) - neutral fill, liaison-colored ring - not
  #                         "locked in" with solid color until it actually
  #                         happens
  #   completed           - solid liaison-colored fill - this event
  #                         happened, its color is now the permanent record
  MarkerStyle = Struct.new(:fill, :border, :text_dark, keyword_init: true)

  NEUTRAL_MARKER_FILL = "#cbd5e1" # slate-300
  UNASSIGNED_BORDER = "#94a3b8" # slate-400

  def marker_style(event)
    liaison = event.liaisons.first

    if liaison && event.completed?
      MarkerStyle.new(fill: liaison.color, border: "#ffffff", text_dark: false)
    elsif liaison && event.assigned?
      MarkerStyle.new(fill: NEUTRAL_MARKER_FILL, border: liaison.color, text_dark: true)
    else
      MarkerStyle.new(fill: "#ffffff", border: UNASSIGNED_BORDER, text_dark: true)
    end
  end

  # Compact marker data for the Mapbox Stimulus controller. Only what the
  # map needs to draw and link a pin - full event details are fetched over
  # Turbo when a marker is actually clicked, not embedded here. Color
  # comes from marker_style so the map can't disagree with the sidebar or
  # calendar about what an event's dot should look like.
  def events_for_map(events)
    events.map do |event|
      style = marker_style(event)
      {
        id: event.id,
        path: event_path(event),
        lng: event.longitude,
        lat: event.latitude,
        fill: style.fill,
        border: style.border,
        completed: event.completed?
      }
    end
  end

  def mapbox_access_token
    AppCredentials.mapbox_access_token
  end

  # Shared Tailwind classes for the intake form's text/select/number inputs,
  # so every field looks the same without repeating the class string
  # a dozen times in the view.
  def form_field_class
    "w-full px-3 py-2 text-[13px] rounded-md border border-slate-200 bg-white " \
      "focus:outline-none focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600"
  end

  def form_label_class
    "block text-[13px] font-medium text-slate-700 mb-1"
  end

  # "3h 15m" / "52m" - used by the requests table's Drive column.
  def format_drive_time(minutes)
    return nil if minutes.nil?

    hours, mins = minutes.divmod(60)
    hours.positive? ? "#{hours}h #{mins}m" : "#{mins}m"
  end
end
