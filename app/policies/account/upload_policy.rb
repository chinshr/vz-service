class Account::UploadPolicy < UploadPolicy

  def create?
    !!user
  end

  def update?
    !!user
  end

  def permitted_attributes(action_name)
    if create? && action_name == "create"
      [:type, :file_name, :file_type, :file_size, :s3_url, :locale, :privacy]
    elsif update? && action_name == "update"
      [:title, :description, {:tag_list => []}, :locale, :privacy, :event]
    else
      super
    end
  end

end