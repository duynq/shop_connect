module Shop
  module Oauth2
    module RefeshToken
      class Client < Shopee::Oauth2::Client
        attr_reader :refresh_token

        def initialize(refresh_token)
          @refresh_token = refresh_token
        end

        private

        def auth2_refresh_token(refresh_token)
          body = { 'shop_id': shopid, 'refresh_token': refresh_token, 'partner_id': partner_id }
          path = '/api/v2/auth/access_token/get'
          base_string = "#{partner_id}#{path}#{timest}#{shopid}"
          sign = OpenSSL::HMAC.hexdigest('SHA256', partner_key, base_string)
          path_url = "#{path}?partner_id=#{partner_id}&shop_id=#{shopid}&sign=#{sign}&timestamp=#{timest}"

          request_result = post_request(path_url, body)
          response = JSON.parse(request_result.body)

          response.key?('access_token') ? { ok: response } : { error: response }
        end
      end
    end
  end
end
