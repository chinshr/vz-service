class ChunkPolicy < IngestPolicy
  def create?
    backend_role?
  end

  def permitted_attributes(action_name = nil)
    [:type, :position, :offset, :duration, :start_time,
      :end_time, :text, :score, :response, :processing_status]
  end
end