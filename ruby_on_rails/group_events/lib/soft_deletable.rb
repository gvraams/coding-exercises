# group_event = GroupEvent.create uuid: SecureRandom.uuid, created_by: User.last, location: Location.last

module SoftDeletable
  # "Mark as Deleted" - Custom implementation on top of Discard gem
  #
  # Implemented methods:
  # Mark for deletion:
  #  :soft_delete [Sets deleted_at for a record]
  #  :soft_delete_all [Sets deleted_at for a collection of records]
  #  :soft_destroy [Sets deleted_at for a record & invokes callbacks]
  #  :soft_destroy_all [Sets deleted_at for a collection of records & invokes callbacks]
  #
  # Restore records:
  #  :undo_delete [Unsets deleted_at for a record]
  #  :undo_delete_all [Unsets deleted_at for a collection of records]
  #  :undo_destroy [Unsets deleted_at for a record & invokes callbacks]
  #  :undo_destroy_all [Unsets deleted_at for a collection of records & invokes callbacks]
  #
  # Destroy methods succeed when the ActiveRecord is already marked for deletion or
  # invoked with +:SoftDeletable.allow_active_record_destroy+ block.
  #  :destroy & :destroy_all will only succeed on records that have been marked for deletion.
  def self.included(base)
    base.class_eval do
      include Discard::Model

      self.discard_column = :deleted_at

      scope :with_soft_deleted, -> { unscope(where: self.discard_column) }
      scope :active,            -> { with_soft_deleted.where(self.discard_column => nil) }
      scope :soft_deleted,      -> { with_soft_deleted.where.not(self.discard_column => nil) }

      before_destroy :prevent_destroy

      default_scope -> { SoftDeletable.disable_soft_delete? ? with_soft_deleted : active }
    end

    base.extend(ClassMethods)
  end

  # Prevents records from being destroyed unless they're marked for deletion
  def prevent_destroy
    unless self.discarded?
      self.errors[:base] << "Cannot destroy records that are not marked for deletion"
      throw :abort
    end
  end

  # Soft deletes with callbacks.
  # ==== Examples
  #  
  #  GroupEvent.first.soft_destroy
  def soft_destroy
    discard
  end

  # Restores with callbacks.
  # ==== Examples
  #  
  #  GroupEvent.first.undo_destroy
  def undo_destroy
    undiscard
  end

  # Soft deletes without callbacks
  # ==== Examples
  #  
  #  GroupEvent.first.soft_delete
  def soft_delete
    update(self.discard_column => Time.current)
  end

  # Restores without callbacks
  # ==== Examples
  #  
  #  GroupEvent.first.undo_delete
  def undo_delete
    update(self.discard_column => nil)
  end

  # Determines whether this record is not marked for deletion
  # @return [Boolean] true if record is not marked for deletion, false otherwise
  def active?
    !discarded?
  end

  module ClassMethods
    # Marks all records for deletion with callbacks for each
    def soft_destroy_all
      discard_all
    end

    # Restores all records with callbacks for each
    def undo_destroy_all
      undiscard_all
    end

    # Marks all records for deletion without callbacks
    def soft_delete_all
      update_all(self.discard_column => Time.current)
    end

    # Restores all records without callbacks
    def undo_delete_all
      update_all(self.discard_column => nil)
    end
  end

  class << self
    # Accepts a block in which queries include records that have been marked for deletion.
    #
    # ==== Examples
    #  
    #  GroupEvent.with_soft_deleted.count #2
    #  
    #  GroupEvent.all.count #1
    #  
    #  SoftDeletable.with_soft_deleted do
    #    GroupEvent.all.count #2
    #  end
    def with_soft_deleted(&block)
      raise ArgumentError, "block required" if block.nil?
      old_value = disable_soft_delete?
      self.disable_soft_delete = true

      return block.call
    ensure
      self.disable_soft_delete = old_value
    end

    # Returns true when invoked within `with_soft_deleted` block.
    def disable_soft_delete?
      !!Thread.current[:disable_soft_delete]
    end

    private

    # With this enabled, queries returns records that are marked for deletion. Check `default_scope` definition.
    # It is critical to restore it at the end in an `ensure` block to prevent undesirable side effects.
    def disable_soft_delete=(disable)
      Thread.current[:disable_soft_delete] = disable
    end
  end
end
