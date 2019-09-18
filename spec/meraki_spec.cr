require "./spec_helper"

describe Meraki do
  # ==============
  # Test Responses
  # ==============
  with_server do
    it "should respond with validator" do
      result = curl("GET", "/meraki")
      result.body.includes?("example").should eq(true)
    end

    it "should accept an event with DevicesSeen" do
      data = {
        "secret":  "secret",
        "version": "2.0",
        "type":    "DevicesSeen",
        "data":    {
          "apMac":        "11:22:33:44:55:66",
          "apTags":       ["left", "near lifts"],
          "apFloors":     ["San Francisco>500 TF>5th"],
          "observations": [
            {
              "clientMac":    "aa:bb:cc:dd:ee:ff",
              "seenTime":     "1970-01-01T00:00:00Z",
              "seenEpoch":    2,
              "ipv4":         "/123.45.67.89",
              "ipv6":         "/ff11:2233:4455:6677:8899:0:aabb:ccdd",
              "ssid":         "Cisco WiFi",
              "rssi":         24,
              "manufacturer": "Meraki",
              "os":           "Linux",
              "location":     {
                "lat": 37.77057805947924,
                "lng": -122.38765965945927,
                "unc": 15.13174349529074,
                "x":   [3.2],
                "y":   [5.8],
              },
            },
          ],
        },
      }.to_json

      result = curl("POST", "/meraki", {"Content-Type" => "application/json"}, data)
      result.status_code.should eq(200)
    end

    it "should be able to look up devices" do
      raise "device lookup is missing entries" unless Meraki::DEVICE_LOOKUP.size == 3

      result = curl("GET", "/meraki/aabbCCddEEff")
      result.status_code.should eq(403)

      result = curl("GET", "/meraki/aabbCCddEEff", {"Authorization" => "Bearer secret"})
      result.status_code.should eq(200)

      result = curl("GET", "/meraki/123.45.67.89", {"Authorization" => "Bearer secret"})
      result.status_code.should eq(200)

      result = curl("GET", "/meraki/ff11:2233:4455:6677:8899:0:aabb:ccdd", {"Authorization" => "Bearer secret"})
      result.status_code.should eq(200)
    end
  end
end
