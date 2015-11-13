# Status support extends AASM to use "status" values to initially determine the "state" of the object.
# The main purpose is to be backward compatible to AR model that use "status" values.
# This must be included after the AASM module.
#
#    class Example < ActiveRecord::Base
#      include AASM
#      include Model::AASM::Support
#    end
#
# A hash lookup of state mapped to status integer values is required. By default, STATES constant is referenced
# for this, but can be defined in the model using #aasm_set_status_lookup.
#
# The assumption here is that users consuming the API can only set the state thru changing the status value.
# Therefore there should only be one valid event that triggers this transition of both status values and state.
module Model::AASM::Support
  extend ActiveSupport::Concern

  included do
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
      if to_state = self.class.aasm_status_lookup.key(value)
        events = self.class.aasm.events.select { |e| e.transitions_to_state?(to_state) && e.may_fire?(self, to_state) }
      end
      unless call_transition_to_state_with(events, to_state)
        @status_error = true
      end
    end
  end

  # force an event to fire
  # TODO: Security concern, should test if event exists,
  # not only from list of available events.
  def event=(value)
    send(:"#{value}") if value && respond_to?(value.to_sym)
  rescue AASM::InvalidTransition => ex
    @status_error = ex.message
  end

  def events
    aasm.events.map(&:name)
  end

  protected

  def check_status
    if @status_error == true
      errors.add(:status, I18n.t("lib.model.aasm_support.status", :current_state => aasm.current_state))
    elsif @status_error.is_a?(String)
      errors.add(:status, @status_error)
    end
  end

  def set_state_updated
    @state_updated = aasm_state_changed?
  end

  def state_updated?
    !!@state_updated
  end

  private

  def may_transition?(events, to_state = nil)
    if to_state
      events.present? ? events.any? {|e| e.may_fire?(self, to_state)} == to_state : false
    else
      events.present? ? events.any? {|e| e.may_fire?(self, to_state)} : false
    end
  end

  def call_transition_to_state_with(events, to_state)
    if event = events.find {|e| e.may_fire?(self, to_state) == to_state ? e : false}
      return send(:"#{event.name}")
    end
    false
  end

  def call_transition_with(events, to_state = nil)
    if event = events.find {|e| e.may_fire?(self, to_state) == to_state ? e : false}
      return send(:"#{event.name}")
    end
    false
  end
end