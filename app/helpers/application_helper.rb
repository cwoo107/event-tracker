module ApplicationHelper
  RISK_BADGE_CLASSES = {
    high: "bg-rose-600 text-white",
    watch: "bg-lime-400 text-brand-900",
    ok: "bg-white text-slate-500 border border-slate-200",
    low: "bg-white text-slate-400 border border-slate-200"
  }.freeze

  def risk_badge(result)
    return "".html_safe unless result

    classes = RISK_BADGE_CLASSES.fetch(result.level, RISK_BADGE_CLASSES[:ok])
    content_tag(:span, result.level.to_s.upcase,
                class: "text-[10px] font-semibold px-1.5 py-0.5 rounded #{classes}",
                title: result.reasons.presence&.join("; "))
  end

  # Shared by the liaison profile's "load history" chart and the
  # dashboard's "weekly pacing" chart - both Liaison#weekly_pacing_history
  # and DashboardReport#weekly_pacing_series return the same
  # {week_start:, count:, over_target:} shape.
  def weekly_pacing_chart_data(series)
    {
      labels: series.map { |point| point[:week_start].strftime("W%V") },
      values: series.map { |point| point[:count] },
      colors: series.map { |point| point[:over_target] ? "#dc2626" : "#2f7a3e" }
    }
  end

  # Shared by every location-picker field (event address, account home
  # office) that's only ever filled in by clicking a Mapbox suggestion,
  # never typed directly - readonly always, but styled grey/disabled
  # until it actually holds a real geocoded value. The
  # location-picker Stimulus controller clears this same inline style
  # (rather than toggling a class) when it fills a field in, so the two
  # have to stay in sync.
  def location_field_class
    "w-full px-3 py-2 text-[13px] rounded-md border border-slate-200 focus:outline-none " \
      "focus:ring-2 focus:ring-brand-600/20 focus:border-brand-600"
  end

  def location_field_style(value)
    "background-color: #f8fafc; color: #94a3b8;" unless value.present?
  end
end
