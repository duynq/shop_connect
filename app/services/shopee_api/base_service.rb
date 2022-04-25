module ShopeeApi
  class BaseService < ::BaseService
    attr_reader :shopid

    def initialize(shopid)
      @shopid = shopid
    end

    def call_api
      res = client.call(query)
      result = Shopee::Parser.new(res)
      self.message = result.error unless result.success?
      self.res = result.res
    end
  end
end
