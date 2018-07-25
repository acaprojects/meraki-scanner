class Meraki < Application
  base "/meraki"

  private VALIDATOR = ENV["MERAKI_VALIDATOR"]? || "example"
  private SECRET = ENV["MERAKI_SECRET"]? || "secret"
  private MAX_AGE = (ENV["MERAKI_MAX_AGE"]? || "60").to_i
  private MIN_AGE = (MAX_AGE / 2).to_i

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

    mac = params["id"].gsub(/[^0-9A-Fa-f\.\:]/, "").downcase
    device = DEVICE_LOOKUP[mac]?

    if device
      render json: device
    else
      head :not_found
    end
  end

  # IP address data is stored as most recently seen
  # Mac address data is most accurate recent location
  protected def map_data(floors, device)
    return if device.seenEpoch == 0
    device.floors = floors

    # IPv4 Lookup
    ip = device.ipv4
    if ip
      ip = ip.gsub(/[^0-9\.]/, "")
      existing = DEVICE_LOOKUP[ip]?
      if !(existing && existing.seenEpoch > device.seenEpoch)
        DEVICE_LOOKUP[ip] = device
      end
    end

    # IPv6 Lookup
    ip = device.ipv6
    if ip
      ip = ip.gsub(/[^0-9A-Fa-f\.\:]/, "").downcase
      existing = DEVICE_LOOKUP[ip]?
      if !(existing && existing.seenEpoch > device.seenEpoch)
        DEVICE_LOOKUP[ip] = device
      end
    end

    # MAC Address Lookup (used for location tracking)
    mac = device.clientMac.gsub(/[^0-9A-Fa-f]/, "").downcase
    existing = DEVICE_LOOKUP[mac]?

    if existing
      max_age = existing.seenEpoch + MAX_AGE
      min_age = existing.seenEpoch - MIN_AGE

      # Only compare fresh data and then keep the most confident readings
      return if device.seenEpoch < min_age
      if device.seenEpoch <= max_age
        return if device.location.not_nil!.unc > existing.location.not_nil!.unc
      end
    end
    DEVICE_LOOKUP[mac] = device
  end
end
