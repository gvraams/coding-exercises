class GroupEvent < ApplicationRecord
  # Supports "mark as deleted" feature
  include SoftDeletable
  include ChangedPrimaryKey

  # Associations
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User', inverse_of: :group_events
  belongs_to :location

  # Space out enum values to accommodate future changes without data migration
  enum status: {
    draft:     10,
    published: 20,
  }

  # Optional validations apply when the GroupEvent is set to be published
  validates :name,        presence: true, if: Proc.new { |a| a.published? }
  validates :description, presence: true, if: Proc.new { |a| a.published? }

  validates_length_of :name, maximum: 100

  # Custom validations
  validate :has_valid_period?, on: [:create, :update]
  validate :has_valid_dates?,  on: [:create, :update]

  before_save :try_computing_event_duration

  private

  # Determines whether this GroupEvent has a valid period
  # @returns [Boolean] true if `draft` else atleast 2 out of `duration`, `start_date`, and `end_date` should be present.
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
      self.errors.add(:start_date, "can't be blank") unless self.start_date?
      self.errors.add(:end_date, "can't be blank") unless self.end_date?

      return false
    end

    return true
  end

  # Determines whether the supplied start_date & end_date are valid
  def has_valid_dates?
    return true unless self.start_date? && self.end_date?

    is_valid = true

    if self.start_date < Time.zone.now
      self.errors.add(:start_date, "Start date cannot be in the past")
      is_valid = false
    end

    if self.end_date < Time.zone.now
      self.errors.add(:end_date, "End date cannot be in the past")
      is_valid = false
    end

    if self.start_date > self.end_date
      self.errors.add(:base, "End date cannot be lesser than start date")
      is_valid = false
    end

    return is_valid
  end

  def try_computing_event_duration
    if self.duration? && self.duration > 0
      unless self.start_date?
        self.start_date = self.end_date - self.duration + 1.day if self.end_date?
      end

      unless self.end_date?
        self.end_date = self.start_date + self.duration - 1.day if self.start_date?
      end

      # Overrides `duration` attribute assigned to the record
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
