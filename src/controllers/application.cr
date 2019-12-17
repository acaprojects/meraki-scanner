require "uuid"

abstract class Application < ActionController::Base
  before_action :set_request_id

  # Max age, after which we accept positions that are less confident
  MAX_AGE = (ENV["MERAKI_MAX_AGE"]? || "60").to_i

  # Min age, before which we don't accept more confident positions (probably not required)
  MIN_AGE = (MAX_AGE / 2).to_i

  # Max Uncertainty in meters - we don't accept positions that are lower than this
  MAX_UNCERTAINTY = (ENV["MERAKI_MAX_UNCERTAINTY"]? || "30").to_f

  # We will always accept a reading with a confidence lower than this
  ACCEPTABLE_CONFIDENCE = (ENV["MERAKI_ACCEPTABLE_CONFIDENCE"]? || "5").to_f

  # Anything that is 300 seconds newer than the current value will be immediately accepted
  MAX_TIME_DIFF = (ENV["MERAKI_MAX_TIME_DIFF"]? || "300").to_i

  # How much confidence do we have in this new value (300 == 1 max confidence, MAX_AGE == 0 zero confidence)
  TIME_MULTIPLIER = 1.0 / (MAX_TIME_DIFF - MAX_AGE).to_f

  # How much confidence do we factor into the current position (5m == 1 max confidence, 30m == 0 zero confidence)
  CONFIDENCE_MULTIPLIER = 1.0 / (MAX_UNCERTAINTY - ACCEPTABLE_CONFIDENCE)

  struct Status
    property error_count, updated_at, version, version_mismatch, secret_mismatch, bluetooth
    @version : String = "2.0"
    @bluetooth : Int32 = 0
    @updated_at : Int64 = 0
    @error_count : Int32 = 0
    @secret_mismatch : Int32 = 0
    @version_mismatch : Int32 = 0
  end

  # This makes it simple to match client requests with server side logs.
  # When building microservices this ID should be propagated to upstream services.
  def set_request_id
    logger.client_ip = client_ip
    response.headers["X-Request-ID"] = logger.request_id = UUID.random.to_s

    # If this is an upstream service, the ID should be extracted from a request header.
    # response.headers["X-Request-ID"] = logger.request_id = request.headers["X-Request-ID"]? || UUID.random.to_s
  end
end
