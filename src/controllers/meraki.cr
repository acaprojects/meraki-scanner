class Meraki < Application
  base "/events"

  def index
    render text: ENV["MERAKI_VALIDATOR"]
  end

  def create
    if request.content_type != "application/json"
      logger.warn "got post with unexpected content type: #{request.content_type}"
      head :not_acceptable
    end

    body = request.body.not_nil!
    header = MerakiHeader.from_json(body)

    logger.info "version is #{header.version}"
    if header.version != "2.0"
      logger.warn "got post with unexpected version: #{header.version}"
      head :not_acceptable
    end

    if header.type != "DevicesSeen"
      logger.warn "got post for event that we're not interested in: #{header.type}"
      head :not_acceptable
    end

    seen = DevicesSeen.from_json(body)
    seen.data.observations.each do |device|
      map_data(seen.data.apFloors, device) unless device.location.nil?
    end

    head :ok
  end

  def show

  end

  protected

  def map_data(floors, device)
    # TODO:: Store a hash of all observed MAC addresses
  end
end
