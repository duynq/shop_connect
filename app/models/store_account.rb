class StoreAccount < ApplicationRecord
  include Deletable
  include Encryptable

  attr_encrypted :token, key: :encryption_key

  has_many :products, foreign_key: :shop_id, primary_key: :shop_id, dependent: :destroy
end
