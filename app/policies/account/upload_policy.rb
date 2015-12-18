class Account::UploadPolicy < UploadPolicy

  def create?
    !!user
  end

  def update?
    !!user
  end

  def permitted_attributes(action_name = nil)
    if create? && action_name == "create"
      [:file_name, :file_type, :file_size, :source_url, :locale, :privacy, :use_source_annotations]
    elsif update? && action_name == "update"
      [:title, :description, {:tag_list => []}, :locale, :privacy, :event]
    else
      super(action_name)
    end
  end

end