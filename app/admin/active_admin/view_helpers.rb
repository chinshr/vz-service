def registrations_chart_series(registrations, start_time)
  registrations_by_day = registrations.where(:created_at => start_time.beginning_of_day..Time.zone.now.end_of_day).
    group("date(created_at)").
    select("date(created_at) AS created_on, count(created_at) AS total_registrations")

  (start_time.to_date..Date.today).map do |date|
    registration = registrations_by_day.detect {|registration| registration.created_on.to_date == date}
    registration && registration.total_registrations.to_f || 0
  end.inspect
end