module Model::Iteration
  extend ActiveSupport::Concern

  included do
    class_attribute :__iteration_source__

    self.__iteration_source__ ||= :ingest # by default the interation source is set to ingest

    before_validation :set_iteration

    filtered_scopes :iteration_eq
    scope :iteration_eq, -> (param) { where(self.arel_table[:iteration].eq(param)) }
  end

  module ClassMethods
    def iteration_source=(source_model)
      self.__iteration_source__ = source_model.to_sym
    end
  end

  private

  def set_iteration
    if self.new_record?
      self.iteration = self.send("#{self.__iteration_source__}").try(:iteration) || 0
    end
    true # needed so that callbacks do not invalidated the record if not a #new_record?
  end
end