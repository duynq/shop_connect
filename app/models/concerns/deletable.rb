module Deletable
  extend ActiveSupport::Concern

  included do
    validates :is_deleted, inclusion: { in: [true, false] }

    scope :not_deleted, -> { where(is_deleted: false) }

    def deleted!
      update!(is_deleted: true)
    end

    def not_deleted!
      update!(is_deleted: false)
    end

    def not_deleted?
      !is_deleted?
    end
  end
end
