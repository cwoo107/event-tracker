class CalendarMonth
  DayCell = Struct.new(:date, :in_month, :events, keyword_init: true)

  def initialize(account:, year:, month:, pool: nil)
    @account = account
    @date = Date.new(year, month, 1)
    @pool = (pool || account.liaisons.active).to_a
  end

  def year
    @date.year
  end

  def month
    @date.month
  end

  def label
    @date.strftime("%B %Y")
  end

  def previous_month
    @date.prev_month
  end

  def next_month
    @date.next_month
  end

  # A 2D grid: each row is one calendar week (always starting Sunday
  # regardless of Rails' configured week start, to match a conventional
  # month-calendar layout), padded with the trailing days of the prior/next
  # month so every row has 7 cells.
  def weeks
    @weeks ||= build_weeks
  end

  def week_number_range
    iso_weeks = weeks.flatten.map { |cell| cell.date.strftime("%V").to_i }.uniq.sort
    return iso_weeks.first.to_s if iso_weeks.size == 1

    "#{iso_weeks.first}-#{iso_weeks.last}"
  end

  # Events actually within the calendar month (not the padding days from
  # adjacent months shown in the grid) that count toward pacing.
  def filled_slots
    events_in_month.counted_toward_load.count
  end

  def total_slots
    distinct_weeks = weeks.size
    @pool.size * AssignmentSetting.for(@account).weekly_target * distinct_weeks
  end

  private

  def build_weeks
    first_day = @date.beginning_of_month
    first_grid_day = first_day - first_day.wday.days
    last_day = @date.end_of_month
    last_grid_day = last_day + (6 - last_day.wday).days

    events_by_date = events_in_grid(first_grid_day, last_grid_day).group_by { |event| event.starts_at.to_date }

    (first_grid_day..last_grid_day).each_slice(7).map do |week_dates|
      week_dates.map do |date|
        DayCell.new(date: date, in_month: date.month == month, events: events_by_date[date] || [])
      end
    end
  end

  def events_in_grid(first_grid_day, last_grid_day)
    @account.events.includes(:liaisons).where(starts_at: first_grid_day.beginning_of_day..last_grid_day.end_of_day).order(:starts_at)
  end

  def events_in_month
    @account.events.where(starts_at: @date.beginning_of_month.beginning_of_day..@date.end_of_month.end_of_day)
  end
end
