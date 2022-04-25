class BaseService
  attr_accessor :message, :res

  def self.call(*args)
    new(*args).call
  end

  def success?
    message.blank?
  end

  private

  def log_error(exception, extra = {})
    Rails.logger.error exception.message
    Rails.logger.error exception.backtrace.join("\n")
    Raven.capture_message(exception, extra: extra)
  end

  def log_message(message, extra = {})
    Rails.logger.error message
    Raven.capture_message(message, extra: extra) unless message == 'error_sign'
  end
end
