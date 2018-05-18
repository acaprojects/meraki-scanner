# Meraki Scanner

In memory micro service for making Meraki Location Analytics available to custom applications.
See: https://documentation.meraki.com/MR/Monitoring_and_Reporting/Location_Analytics#Scanning_API

## Environment Variables

* `MERAKI_VALIDATOR` for meraki to validate the service is for the organisation specified
* `MERAKI_SECRET` to confirm that the requests are coming from a meraki server

`MERAKI_SECRET` is also used as a bearer token for application requests to the server.
