module ShopeeApi
  module Products
    class GetModelListService < ::ShopeeApi::BaseService
      attr_reader :opts

      BATCH_SIZE = 100

      def execute
        @opts = opts
        if item_ids.empty?
          Product.by_shop(shopid).update_all(is_got_model_list: false)
          return
        end

        self.res = { request_id: [], variations: [] }
        item_ids.each do |item_id|
          result = Shopee::Parser.new(client.call(query(item_id)))
          return log_message(result.error, shopid: shopid) unless result.success?

          res[:request_id] << result.res['request_id']
          res[:variations] += handle_variations_data(result.res['response']['model'], item_id, shopid)
        end

        ActiveRecord::Base.transaction do
          handle_variations(res[:variations])
          handle_variations_not_in_shopee(res[:variations])
          products_model_list.update_all(is_got_model_list: true)
        end
      rescue StandardError => e
        log_error(e)
      end

      private

      def client
        Shopee::Products::GetModelList::Client.new(shopid: shopid)
      end

      def query(item_id)
        {
          item_id: item_id
        }
      end

      def products_model_list
        @products_model_list ||= Product.by_shop(shopid).for_get_model.limit(BATCH_SIZE)
      end

      def item_ids
        products_model_list.pluck(:item_id)
      end

      def handle_variations_data(variations, item_id, shop_id)
        data = []

        variations.each do |variation|
          item = Variation.find_or_initialize_by(
            shop_id:  shop_id,
            item_id:  item_id,
            model_id: variation['model_id']
          )
          item.assign_attributes(
            model_sku:     variation['model_sku'],
            current_price: variation['price_info'].first['current_price'],
            normal_stock:  normal_stock(variation['stock_info']),
            is_deleted:    false
          )
          data << item
        end
        data
      end

      def normal_stock(stock_info)
        # Normal Stock quantity of Seller Stock
        return 0 unless stock_info

        normal_stock = 0
        stock_info.map { |info| normal_stock = info['normal_stock'] if info['stock_type'] == 2 }
        normal_stock
      end

      def handle_variations(variations)
        return if variations.empty?

        Variation.import variations, on_duplicate_key_update: %i[model_sku current_price normal_stock]
      end

      def handle_variations_not_in_shopee(variations)
        return if variations.empty?

        model_skus = variations.pluck(:model_sku)
        variations_deleted = Variation.where(item_id: item_ids).where.not(model_sku: model_skus)
        variations_deleted.update_all(is_deleted: true) unless variations_deleted.empty?
      end
    end
  end
end
