//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 09  Brian Frank  Creation
//

**
** Status enumeration indicates data quality.
**
enum class Status
{
  ** Normal status condition.
  ok,

  ** Data is ok, but local override is in effect.
  overridden,

  ** Past alarm condition remains unacknowledged.
  unacked,

  ** Object is currently in an alarm state.
  alarm,

  ** Object is currently in an the alarm state which has not been acknowledged.
  unackedAlarm,

  ** Communications failure.
  down,

  ** Object data is not available or trustworth due to failure condition.
  fault,

  ** Object has been disabled from normal operation.
  disabled
}