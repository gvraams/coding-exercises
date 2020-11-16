# Defines a default scope to be used in every ActiveRecord::Model
module DefaultScopes
  extend ActiveSupport::Concern

  # Default scope to order ActiveRecord::Model records
  # Default sorting is :id => :asc which doesn't work as ID is now UUID;
  def self.included(base)
    base.class_eval do
      default_scope { order(created_at: :asc) }
    end
  end
end
