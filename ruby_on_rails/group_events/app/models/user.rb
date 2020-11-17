class User < ApplicationRecord
  include ChangedPrimaryKey

  validates :name,     presence: true
  validates :password, presence: true
  validates :email,    presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates_format_of :email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/

  has_many :group_events, as: :created_by, dependent: :destroy

  before_save :downcase_email

  private

  # Converts the given email into lower case before saving the record
  def downcase_email
    self.email = self.email.downcase rescue nil
  end
end
