ActiveAdmin.register_page "Dashboard" do
  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Recent registrations", priority: 2 do
          table_for Registration.order(aasm_state: :desc).recent(5) do |t|
            t.column(:email) {|r| link_to(r.email, [:admin, r])}
            t.column(:state) {|r| status_tag(r.aasm_state.to_s, {:pending => :grey, :accepted => :ok, :declined => :error}[r.aasm_state.to_sym])}
          end
          div do
            link_to "See all...", admin_registrations_path
          end
        end
      end

      column do
        panel "Quick Stats", priority: 1 do
          ul do
            li do
              "%s organic registrations" % Registration.organic.count
            end
            li do
              "%s accepted, %s declined, %s pending registrations" % [Registration.accepted.count, Registration.declined.count, Registration.pending.count]
            end
            li do
              "%s total, %s confirmed users" % [User.count, User.confirmed.count]
            end
            li do
              "%s total, %s public, %s private documents" % [Document.count, Document.with_privacy("public").count, Document.with_privacy("private").count]
            end
          end
        end
      end
    end

    columns do
      column do
        panel "Registrations Chart", priority: 4 do
          div :class => "chart_container" do
            render "chart"
          end
        end
      end

      column do
        panel "Registrations Location", priority: 5 do
          render "map"
        end
      end
    end
  end # content
end
