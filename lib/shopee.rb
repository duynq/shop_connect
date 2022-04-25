module Shopee
  class << self
    def sandbox?
      !Rails.env.production?
    end

    def sandbox_env
      '.test-stable'
    end

    def secrets
      sandbox? ? Rails.application.secrets.shopee[:sandbox] : Rails.application.secrets.shopee
    end

    def auth_link
      # https://open.shopee.com/documents?module=63&type=2&id=53&version=2
      timest = Time.current.to_i
      path = '/api/v2/shop/auth_partner'
      base_string = "#{secrets[:partner_id]}#{path}#{timest}"
      params = {
        timestamp:  timest,
        partner_id: secrets[:partner_id],
        sign:       OpenSSL::HMAC.hexdigest('SHA256', secrets[:partner_key], base_string),
        redirect:   secrets[:redirect_url]
      }

      "https://partner#{sandbox_env if sandbox?}.shopeemobile.com/api/v2/shop/auth_partner?" \
      "#{URI.encode_www_form(params)}"
    end
  end
end
