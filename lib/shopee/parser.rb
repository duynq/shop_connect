module Shopee
  class Parser
    attr_reader :res

    def initialize(res)
      @res = JSON.parse(res)
    end

    def request_id
      res.dig('request_id')
    end

    def msg
      res.dig('msg')
    end

    def error
      res.dig('error')
    end

    def success?
      error.blank?
    end
  end
end
