module Settings
  module StoreAccounts
    module Authentication
      class ShopeeService < ::BaseService
        attr_accessor :code, :shop_id, :time

        EXPIRES_IN = 14_400

        def initialize(params)
          @code = params.dig(:code)
          @shop_id = params.dig(:shop_id)
          @time = Time.current.to_i
        end

        def execute
          store_account = StoreAccount.find_or_initialize_by(shop_id: shop_id)
          # user access token as a common request parametter for certain APIs. Valid for multiple use, expires in 4 hours
          return if store_account.token_expired_at.present? && store_account.token_expired_at > Time.current

          response = make_request(store_account)
          return self.message = response[:error] if response[:error].present?

          access_token = response['access_token']
          refresh_token = response['refresh_token']
          store_account.token = access_token
          store_account.refresh_token = refresh_token
          store_account.token_expired_at = access_token ? Time.current.since(response['expire_in']) : nil

          return if store_account.save

          self.message = store_account.errors.full_messages
        rescue StandardError => e
          log_error(e)
          self.message = e.message
        end

        def make_refresh_token_request(store_account)
          get_refresh_access_token(store_account.refresh_token)
        end

        private

        def make_request(store_account)
          if store_account.refresh_token.present?
            get_refresh_access_token(store_account.refresh_token)
          else
            auth2_get_access_token
          end
        end

        def auth2_get_access_token
          body = { code: code, shop_id: shop_id.to_i, partner_id: ::Shopee.secrets[:partner_id] }
          path = '/api/v2/auth/token/get'
          base_string = "#{::Shopee.secrets[:partner_id]}#{path}#{time}"
          sign = OpenSSL::HMAC.hexdigest('SHA256', ::Shopee.secrets[:partner_key], base_string)
          path_url = "#{path}?partner_id=#{::Shopee.secrets[:partner_id]}&sign=#{sign}&timestamp=#{time}"

          request_result = post_request(path_url, body)
          response = JSON.parse(request_result.body)

          response.key?('access_token') ? response : { error: response }
        end

        def get_refresh_access_token(refresh_token)
          body = { refresh_token: refresh_token, shop_id: shop_id.to_i, partner_id: ::Shopee.secrets[:partner_id] }
          path = '/api/v2/auth/access_token/get'
          base_string = "#{::Shopee.secrets[:partner_id]}#{path}#{time}"
          sign = OpenSSL::HMAC.hexdigest('SHA256', ::Shopee.secrets[:partner_key], base_string)
          path_url = "#{path}?partner_id=#{::Shopee.secrets[:partner_id]}&sign=#{sign}&timestamp=#{time}"

          request_result = post_request(path_url, body)
          response = JSON.parse(request_result.body)

          response.key?('access_token') ? response : { error: response }
        end

        def post_request(path, body = {})
          url = URI("#{endpoint_url}#{path}")
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = Net::HTTP::Post.new(url, headers_request)
          request.body = body.to_json
          http.request(request)
        end

        def headers_request
          { 'Content-Type': 'application/json' }
        end

        def endpoint_url
          "https://partner#{::Shopee.sandbox_env if ::Shopee.sandbox?}.shopeemobile.com"
        end
      end
    end
  end
end
