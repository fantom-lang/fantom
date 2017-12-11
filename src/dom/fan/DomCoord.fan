//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 2017  Andy Frank  Creation
//

**
** DomCoord models a DOM Coordinate object.
**
@Js class DomCoord
{
  ** Private ctor.
  private new make() {}

  ** Returns a float representing the position's latitude in decimal degrees.
  native Float lat()

  ** Returns a float representing the position's longitude in decimal degrees.
  native Float lng()

  ** Returns a float representing the accuracy of the latitude and
  ** longitude properties, expressed in meters.
  native Float accuracy()

  ** Returns a float representing the position's altitude in meters, relative
  ** to sea level. This value can be 'null' if the implementation cannot
  ** provide the data.
  native Float? altitude()

  ** Returns a float representing the accuracy of the altitude expressed in
  ** meters. This value can be 'null'.
  native Float? altitudeAccuracy()

  ** Returns a float representing the direction in which the device is
  ** traveling. This value, specified in degrees, indicates how far off from
  ** heading true north the device is. 0 degrees represents true north, and
  ** the direction is determined clockwise (which means that east is 90 degrees
  ** and west is 270 degrees). If speed is 0, heading is NaN. If the device is
  ** unable to provide heading information, this value is 'null'.
  native Float? heading()

  ** Returns a double representing the velocity of the device in meters per
  ** second. This value can be 'null'.
  native Float? speed()

  ** Optional timestamp of when this location was retrieved.
  native Duration? ts()

  override Str toStr()
  {
    "{ lat=$lat lng=$lng accuracy=$accuracy altitude=$altitude" +
     " altitudeAccuracy=$altitudeAccuracy heading=$heading speed=$speed ts=$ts }"
  }
}