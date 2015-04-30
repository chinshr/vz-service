# Status support extends AASM to use "status" values to initially determine the "state" of the object.
# The main purpose is to be backward compatible to AR model that use "status" values.
# This must be included after the AASM module.
#
#    class Example < ActiveRecord::Base
#      include AASM
#      include Model::AASM::StatusSupport
#    end
#
# A hash lookup of state mapped to status integer values is required. By default, STATES constant is referenced
# for this, but can be defined in the model using #aasm_set_status_lookup.
#
# The assumption here is that users consuming the API can only set the state thru changing the status value.
# Therefore there should only be one valid event that triggers this transition of both status values and state.
module Model::AASM::StatusSupport
  extend ActiveSupport::Concern

  included do
    alias_method_chain :aasm_write_state, :status
    alias_method_chain :aasm_write_state_without_persistence, :status

    validate :check_status
    validates :state, :presence => true

    after_save :set_state_updated
  end

  module ClassMethods
    def aasm_status_lookup
      @aasm_status_lookup ||= self::STATES.symbolize_keys
    end
  end

  # Alias for AASM current state E.g. :finished
  def state
    aasm.current_state
  end

  # e.g. an integer representation of state, like 9 (=finished)
  def status
    self.class::STATES.symbolize_keys[aasm.current_state]
  end

  def status=(value)
    value = value.to_i if /^[-+]?[0-9]+$/ === value
    if status != value  # CHANGED: self[:status] != value
      events = []
      if new_state = self.class.aasm_status_lookup.key(value)
        events = self.class.aasm.events.values.select { |e| e.transitions_to_state?(new_state) }
        events.map! { |e| e.name }
      end

      if may_transition?(events)
        call_transition_with(events)
      else
        @status_error = true
      end
    end
  end

  def aasm_write_state_with_status(state)
    # write_attribute(:status, self.class.aasm_status_lookup[state])
    aasm_write_state_without_status(state)
  end

  def aasm_write_state_without_persistence_with_status(state)
    # write_attribute(:status, self.class.aasm_status_lookup[state])
    aasm_write_state_without_persistence_without_status(state)
  end

  protected

  def check_status
    errors.add(:status, I18n.t("lib.model.status_support.status", :current_state => aasm.current_state)) if @status_error
  end

  def set_state_updated
    @state_updated = aasm_state_changed?
  end

  def state_updated?
    !!@state_updated
  end

  private

  def may_transition?(events)
    events.present? ? events.any? {|e| send(:"may_#{e}?")} : false
  end

  def call_transition_with(events)
    if event = events.find {|e| send(:"may_#{e}?") ? e : false}
      return send(:"#{event}")
    end
    false
  end
end