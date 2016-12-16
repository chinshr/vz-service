def scoped_chart_series(scope, start_time)
  scoped_by_day = scope.where(:created_at => start_time.beginning_of_day..Time.zone.now.end_of_day).
    group("DATE(created_at)").
    select("DATE(created_at) AS created_on, COUNT(created_at) AS total_count")

  (start_time.to_date..Date.today).map do |date|
    record = scoped_by_day.detect {|r| r.created_on.to_date == date}
    record && record.total_count.to_f || 0
  end.inspect
end

def resource_progress_tag(resource)
  %(<div class="progressbar"><div style="width:#{resource.progress}%"></div></div>).html_safe
end

def resource_state_status_tag(resource)
  resource_status_tag(resource.state)
end

def resource_status_tag(state)
  colors = {
    :created => :grey, :starting => :grey, :started => :ok, :restarting => :grey,
    :stopping => :grey, :stopped => :error, :resetting => :warning, :reset => :warning,
    :finished => :ok, :removing => :warning, :removed => :warning, :running => :warning
  }
  status_tag(state.to_s, colors[state.to_sym])
end