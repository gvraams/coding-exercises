class GroupEvent < ApplicationRecord
  # Supports "mark as deleted" feature
  include SoftDeletable
  include DefaultScopes

  # Associations
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User', inverse_of: :group_events
  belongs_to :location

  # Space out enum values for future changes without migration
  enum status: {
    draft:     10,
    published: 20,
  }

  # Validations
  validates :uuid,          presence: true, uniqueness: true
  validates :name,          presence: true
  validates :created_by_id, presence: true
  validates :location_id,   presence: true
  validates :description,   presence: true

  # Custom validations
  validate :has_valid_status?, on: [:create, :update]
  validate :has_valid_period?, on: [:create, :update]
  validate :has_valid_dates?,  on: [:create, :update]

  before_save :try_computing_event_duration

  private

  # Validation: Determines whether this GroupEvent has a valid status.
  # @returns [Boolean] true if `draft` else `duration`, `start_date`, and `end_date` should be present.
  def has_valid_status?
    return true if self.draft?

    return self.duration? && self.start_date? && self.end_date?
  end

  # Determines whether this GroupEvent has a valid period
  # @returns [Boolean] true if `draft` else 2 out of `duration`, `start_date`, and `end_date` should be present.
  def has_valid_period?
    return true if self.draft?

    if self.duration?
      if self.start_date.blank? && self.end_date.blank?
        self.errors.add(:start_date, "can't be blank")
        self.errors.add(:end_date, "can't be blank")

        return false
      end

      return true
    end

    if self.start_date.blank? || self.end_date.blank?
      self.errors.add(:duration, "can't be blank")
      self.errors.add(:start_date, "can't be blank") if self.start_date.blank?
      self.errors.add(:end_date, "can't be blank") if self.end_date.blank?

      return false
    end

    return true
  end

  def has_valid_dates?
    if self.start_date? && self.end_date? && self.start_date > self.end_date
      self.errors.add(:base, "End date cannot be lesser than start date")
      return false
    end

    return true
  end

  def try_computing_event_duration
    if self.duration?
      if self.start_date.blank?
        self.start_date = self.end_date - self.duration + 1.day if self.end_date?
      end

      if self.end_date.blank?
        self.end_date = self.start_date + self.duration - 1.day if self.start_date?
      end

      if self.start_date? && self.end_date?
        self.duration = self.end_date - self.start_date + 1.day
      end

      return
    end

    if self.start_date? && self.end_date?
      difference = (self.end_date - self.start_date).to_i

      self.duration = difference < 0 ? 0 : difference + 1.day
    end
  end
end
