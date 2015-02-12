def scoped_chart_series(scope, start_time)
  scoped_by_day = scope.where(:created_at => start_time.beginning_of_day..Time.zone.now.end_of_day).
    group("DATE(created_at)").
    select("DATE(created_at) AS created_on, COUNT(created_at) AS total_count")

  (start_time.to_date..Date.today).map do |date|
    record = scoped_by_day.detect {|r| r.created_on.to_date == date}
    record && record.total_count.to_f || 0
  end.inspect
end