require 'net/http'

module Shopee
  class Request < Shopee::Client
    attr_accessor :uri, :url, :method, :opts, :path_sign

    def initialize(opts = {})
      @url        = handle_url(opts)
      @method     = opts.delete(:method).to_s.camelize
      @path_sign  = opts.delete(:path_sign)
      @opts       = opts
    end

    def call
      @uri = URI.parse(url)
      if method == 'Get'
        uri.query = URI.encode_www_form(opts) if opts.present?
        req = Net::HTTP::Get.new(uri, headers)
      else
        req = Net::HTTP::Post.new(uri, headers)
        req.body = opts.to_json if opts.present?
      end

      Rails.logger.info opts if opts.present?
      http.start { |conn| conn.request(req) }
    end

    private

    def handle_url(opts)
      opts[:method].to_s.camelize == 'Get' ? opts.delete(:url) : "#{opts.delete(:url)}?partner_id=#{opts.delete(:partner_id)}&timestamp=#{opts.delete(:timestamp)}&access_token=#{opts.delete(:access_token)}&shop_id=#{opts.delete(:shop_id)}&sign=#{opts.delete(:sign)}"
    end

    def http
      httq = Net::HTTP.new(uri.host, uri.port)
      if uri.port == 443
        httq.use_ssl = true
        httq.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      httq
    end

    def headers
      {
        'Content-Type' => 'application/json',
        'Authorization' => api_key
      }
    end

    def api_key
      OpenSSL::HMAC.hexdigest('sha256', ::Shopee.secrets[:partner_key], "#{url}|#{opts.to_json}")
    end
  end
end
