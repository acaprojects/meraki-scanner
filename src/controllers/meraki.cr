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

    return if existing && !should_update?(existing, device)
    DEVICE_LOOKUP[mac] = device
  end

  protected def should_update?(existing, update)
    # If the existing value really old?
    cutoff_age = existing.seenEpoch + MAX_TIME_DIFF
    return true if cutoff_age < update.seenEpoch

    max_age = existing.seenEpoch + MAX_AGE
    min_age = existing.seenEpoch - MIN_AGE

    # Is the new value too old
    return false if update.seenEpoch < min_age

    # Does the new value have acceptable confidence
    new_uncertainty = update.location.not_nil!.unc
    return true if new_uncertainty <= ACCEPTABLE_CONFIDENCE

    # Is the new value less uncertain than the last value
    old_uncertainty = existing.location.not_nil!.unc
    return true if new_uncertainty <= old_uncertainty

    # Are we still happy with the current value given the time period
    return false if update.seenEpoch < max_age

    # Has the floor changed?
    return true if existing.floors.not_nil![0]? != update.floors.not_nil![0]?

    # % confidence in the location accuracy
    confidence_factor = 1.0 - (CONFIDENCE_MULTIPLIER * (new_uncertainty - ACCEPTABLE_CONFIDENCE))
    confidence_factor = 0.0 if confidence_factor < 0

    # % difference in time from the last confident location
    time_diff = update.seenEpoch - existing.seenEpoch
    time_factor = TIME_MULTIPLIER * (time_diff - MAX_AGE)
    time_factor = 0.0 if time_factor < 0

    # Average of the confidence factors
    average_multiplier = (confidence_factor + time_factor) / 2.0

    # Factor the difference between the x and y values
    new_location = update.location.not_nil!
    old_location = existing.location.not_nil!

    new_x = new_location.x[0] # 10
    new_y = new_location.y[0]
    old_x = old_location.x[0] # 5
    old_y = old_location.y[0]

    # 7.5 =   5   + ((  10  -  5   ) * 0.5)
    new_x = old_x + ((new_x - old_x) * average_multiplier)
    new_y = old_y + ((new_y - old_y) * average_multiplier)
    new_uncertainty = old_uncertainty + ((new_uncertainty - old_uncertainty) * average_multiplier)

    new_location.x[0] = new_x
    new_location.y[0] = new_y
    new_location.unc = new_uncertainty

    true
  end
end
