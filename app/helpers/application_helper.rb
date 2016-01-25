module ApplicationHelper

  def pretty_exception(exception, exception_group = "Application handled exception")
    <<-HEREDOC
    #{"="*40}
    #{exception_group}: #{exception.message}
    #{exception.backtrace ? exception.backtrace.join("\n") : "No backtrace"}
    #{"="*40}
    HEREDOC
  end

end
