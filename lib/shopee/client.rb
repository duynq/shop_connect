module Shopee
  class Client
    # https://open.shopee.com/documents?module=63&type=2&id=54&version=1
    attr_reader :shopid

    def initialize(opts = {})
      @shopid = opts.delete(:shopid)
    end

    def self.call(opts = {})
      new(opts).call
    end

    private

    def default_opts
      {
        shop_id:      shopid,
        partner_id:   ::Shopee.secrets[:partner_id],
        timestamp:    timestamp,
        url:          url,
        method:       method,
        access_token: access_token,
        path_sign:    path_sign,
        sign:         sign
      }
    end

    def request_opts
      default_opts.merge(client_opts).transform_values(&:presence).compact
    end

    def url
      "https://partner#{::Shopee.sandbox_env if ::Shopee.sandbox?}.shopeemobile.com/api/v2/#{path}"
    end

    def timestamp
      Time.current.to_i
    end

    def access_token
      store_account = StoreAccount.find_by!(shop_id: shopid)
      unless store_account&.token_expired_at&.future?
        store_account_authen = Settings::StoreAccounts::Authentication::ShopeeService.new({ shop_id: shopid })
        response = store_account_authen.make_refresh_token_request(store_account)
        if response[:error].blank?
          access_token = response['access_token']
          refresh_token = response['refresh_token']
          store_account.token = access_token
          store_account.refresh_token = refresh_token
          store_account.token_expired_at = access_token ? Time.current.since(response['expire_in']) : nil
          store_account.save!
        end
      end
      store_account.token
    end

    def path_sign
      "/api/v2/#{path}"
    end

    def sign
      base_string = "#{::Shopee.secrets[:partner_id]}#{path_sign}#{timestamp}#{access_token}#{shopid}"
      OpenSSL::HMAC.hexdigest('SHA256', ::Shopee.secrets[:partner_key], base_string)
    end
  end
end
