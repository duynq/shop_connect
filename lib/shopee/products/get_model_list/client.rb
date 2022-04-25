module Shopee
  module Products
    module GetModelList
      class Client < Shopee::Client
        # https://open.shopee.com/documents?module=89&type=1&id=612&version=2

        attr_reader :opts

        def call(opts = {})
          @opts = opts
          res = Shopee::Request.call(request_opts)
          res.body
        end

        private

        def path
          'product/get_model_list'
        end

        def method
          :get
        end

        def client_opts
          {
            item_id: opts[:item_id]
          }
        end
      end
    end
  end
end
