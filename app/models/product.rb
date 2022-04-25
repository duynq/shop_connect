class Product < ApplicationRecord
  belongs_to :store_account, foreign_key: :shop_id, primary_key: :shop_id
  has_many :variations, foreign_key: :item_id, primary_key: :item_id, dependent: :restrict_with_exception

  enum item_status: {
    normal:  0,
    banned:  1,
    deleted: 2,
    unlist:  3
  }

  scope :by_shop, ->(shop_id) { where(shop_id: shop_id) }
  scope :for_get_model, -> { where(is_got_model_list: false, has_model: true).normal }
end
