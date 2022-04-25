module Shopee
  module Oauth2
    class Client
      private

      def method
        :post
      end

      def uri
        "https://partner#{sandbox_env if sandbox?}.shopeemobile.com/api/v2/auth/access_token/get"
      end
    end
  end
end
