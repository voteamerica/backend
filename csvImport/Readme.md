The csv format is intended for organizations to bulk import riders and drivers into the database.

The existing csv format mirrors the database and has the following fields:

For RIDERS:

```
RiderLastName (required) - Last name of the rider
RiderEmail - Email address of the rider, if available
RiderPhone - Phone number of the rider, if available
RiderCollectionZIP (required) - Pick up location zip code
RiderDropOffZIP (required) - Drop off location zip code
AvailableRideTimesJSON - Available times in the local timezone in ISO8601 delineated by \'|' (e.g. '2018-10-01T02:00/2018-10-01T03:00|2019-10-01T02:00/2019-10-01T03:00')
TotalPartySize (required) - Defaults to 1
TwoWayTripNeeded (required) - true/false
RiderIsVulnrable (required) - true/false
RiderWillNotTalkPolitics (required) - true/false
PleaseStayInTouch (required) - true/false
NeedWheelchair (required) - true/false
RiderPreferredContact - Email;Text;Phone
RiderAccommodationNotes - Accommodation requirements e.g. service animal, assistance folding equipment, assistance entering/exiting the vehicle, etc.
RiderLegalConsent (required) - true/false
RiderWillBeSafe (required) - true/false
RiderCollectionAddress - Address of rider's pick up location
RiderDestinationAddress - Address of the destination
```
