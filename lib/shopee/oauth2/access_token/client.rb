module Shopee
  module Oauth2
    module AccessToken
      class Client < Shopee::Oauth2::Client
        attr_reader :refresh_token

        def initialize(code, shop_id)
          @code = code
          @shop_id = shop_id
        end
      end
    end
  end
end
