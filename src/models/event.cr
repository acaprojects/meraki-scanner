
class MerakiHeader
  JSON.mapping(
    version: String,
    secret: String,
    type: String
  )
end

class Location
  JSON.mapping(
    lat: Float64,       # latitude in degrees N of the equator
    lng: Float64,       # longitude in degrees E of the prime meridian
    unc: Float64,       # Uncertainty in meters
    x: Array(Float64),  # x offsets (in meters) from lower-left corner
    y: Array(Float64)   # y offsets (in meteres) from lower-left corner
  )
end

class Observation
  JSON.mapping(
    clientMac: String,
    ipv4: {type: String, nilable: true},
    ipv6: {type: String, nilable: true},
    seenTime: String,
    seenEpoch: Int64,
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
