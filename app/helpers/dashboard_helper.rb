module DashboardHelper
  def dashboard_range_options
    [
      ["fy", "FY #{Date.current.year}"],
      ["quarter", "Q#{((Date.current.month - 1) / 3) + 1}"],
      ["last30", "Last 30 days"]
    ]
  end
end
