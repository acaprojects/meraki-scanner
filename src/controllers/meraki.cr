class Meraki < Application
  base "/meraki"

  private VALIDATOR = ENV["MERAKI_VALIDATOR"]? || "example"
  private SECRET = ENV["MERAKI_SECRET"]? || "secret"

  def index
    render text: VALIDATOR
  end

  def create
    content_type = request.headers["Content-Type"]?
    if content_type != "application/json"
      logger.warn "got post with unexpected content type: #{content_type}"
      head :not_acceptable
    end

    begin
      body = request.body.not_nil!.gets_to_end
      logger.info "recieved:\n#{body}"
      seen = DevicesSeen.from_json(body)

      if seen.secret != SECRET
        logger.warn "got post with bad secret: #{seen.secret}"
        head :forbidden
      end

      logger.info "version is #{seen.version}"
      if seen.version != "2.0"
        logger.warn "got post with unexpected version: #{seen.version}"
        head :not_acceptable
      end

      if seen.type != "DevicesSeen"
        logger.warn "got post for event that we're not interested in: #{seen.type}"
        head :not_acceptable
      end

      seen.data.observations.each do |device|
        map_data(seen.data.apFloors, device) unless device.location.nil?
      end

      head :ok
    rescue e
      logger.error "Error parsing\n#{body}\n#{e.message}\n#{e.backtrace.join("\n")}"
      raise e
    end
  end


  DEVICE_LOOKUP = {} of String => Observation


  def show
    security = request.headers["Authorization"]?
    if security.nil? || security.split(' ')[1] != SECRET
      head :forbidden
    end

    mac = params["id"].gsub(/[^0-9A-Fa-f]/, "").downcase
    device = DEVICE_LOOKUP[mac]?

    if device
      render json: device
    else
      head :not_found
    end
  end

  protected def map_data(floors, device)
    device.floors = floors
    mac = device.clientMac.gsub(/[^0-9A-Fa-f]/, "").downcase

    return if device.seenEpoch == 0

    existing = DEVICE_LOOKUP[mac]?
    return if existing && existing.seenEpoch > device.seenEpoch

    DEVICE_LOOKUP[mac] = device
  end
end
