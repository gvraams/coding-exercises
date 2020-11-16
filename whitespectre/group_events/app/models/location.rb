class Location < ApplicationRecord
  validates :uuid, presence: true, uniqueness: true
  validates :name, presence: true

  has_many :group_events, dependent: :destroy
end
