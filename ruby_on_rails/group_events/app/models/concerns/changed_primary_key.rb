# Defines a default scope to be used in every ActiveRecord::Model
module ChangedPrimaryKey
  extend ActiveSupport::Concern

  # Validates presence and uniqueness of UUID
  # Default scope to order ActiveRecord::Model records
  # Default sorting is :id => :asc which doesn't work as ID is now UUID;
  def self.included(base)
    base.class_eval do
      validates :uuid, presence: true, uniqueness: true

      default_scope { order(created_at: :asc) }
    end
  end
end
