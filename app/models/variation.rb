class Variation < ApplicationRecord
  belongs_to :store_account, foreign_key: :shop_id, primary_key: :shop_id
  belongs_to :product, foreign_key: :item_id, primary_key: :item_id, optional: true
end
