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
end
