module Encryptable
  extend ActiveSupport::Concern

  included do
    private

    def encryption_key
      Rails.application.secrets.encryption_key
    end
  end
end
