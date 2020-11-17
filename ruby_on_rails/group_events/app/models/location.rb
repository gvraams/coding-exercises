class Location < ApplicationRecord
  include ChangedPrimaryKey

  validates :name, presence: true

  has_many :group_events, dependent: :destroy
end
