class Plan < ActiveRecord::Base
  include Koudoku::Plan

  has_many :subscriptions
end
