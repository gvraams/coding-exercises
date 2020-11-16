# Sets UUID for records before creation
module SetPrimaryKey
  extend ActiveSupport::Concern

  def self.included(base)
    base.class_eval do
      before_create :set_primary_key
    end
  end

  private

  # Checks whether UUID is set before record creation.
  # If not, then a randomly generated UUID is assigned to the record.
  def set_primary_key
    return if self.uuid.present?

    self.uuid = SecureRandom.uuid
  end
end
