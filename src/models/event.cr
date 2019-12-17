class MerakiHeader
  JSON.mapping(
    version: String,
    secret: String,
    type: String
  )
end

class Location
  JSON.mapping(
    lat: Float64 | String,      # latitude in degrees N of the equator
    lng: Float64 | String,      # longitude in degrees E of the prime meridian
    unc: Float64 | String,      # Uncertainty in meters
    x: Array(Float64 | String), # x offsets (in meters) from lower-left corner
    y: Array(Float64 | String)  # y offsets (in meteres) from lower-left corner
  )
end

class Observation
  JSON.mapping(
    # This is never actually directly in this model
    floors: {type: Array(String), nilable: true},

    clientMac: String,
    seenTime: String,
    seenEpoch: Int64,
    ipv4: {type: String, nilable: true},
    ipv6: {type: String, nilable: true},
    ssid: {type: String, nilable: true},
    rssi: Int64,
    manufacturer: {type: String, nilable: true},
    os: {type: String, nilable: true},
    location: {type: Location, nilable: true}
  )
end

class AccessPoint
  JSON.mapping(
    apMac: String,
    apTags: Array(String),
    apFloors: Array(String),
    observations: Array(Observation)
  )
end

class DevicesSeen
  JSON.mapping(
    version: String,
    secret: String,
    type: String,
    data: AccessPoint
  )
end
