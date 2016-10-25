class Api::StatusController < Api::ApplicationController
  include Api::Authorization

  before_action :authorize_client_or_signed_in_user!

  # [GET] /api/status(.:format)
  def index
    @status = {
      active_record: ActiveRecord::Base.connected?,
      api_version: Api::Version.to_s,
      environment: Rails.env,
      ruby_version: "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}",
      rails_version: "#{Rails::VERSION::STRING}",
      database_adapter: "#{ActiveRecord::Base.connection.instance_values["config"][:adapter]}",
      database_schema_version: "#{ActiveRecord::Migrator.current_version}",
      git_rev: `git rev-parse HEAD`.gsub("\n", ""),
      git_rev_short: `git rev-parse --short HEAD`.gsub("\n", "")
    }
    respond_with Api::Response.new(status: @status)
  end

end
