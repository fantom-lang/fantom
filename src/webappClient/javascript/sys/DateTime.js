//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 09  Andy Frank  Creation
//

/**
 * DateTime
 */
var sys_DateTime = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  type: function()
  {
    return sys_Type.find("sys::DateTime");
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_DateTime.isLeapYear = function(year)
{
  if ((year & 3) != 0) return false;
  return (year % 100 != 0) || (year % 400 == 0);
}

sys_DateTime.dayOfYear = function(year, mon, day)
{
  return sys_DateTime.isLeapYear(year) ?
    sys_DateTime.dayOfYearForFirstOfMonLeap[mon] + day - 1 :
    sys_DateTime.dayOfYearForFirstOfMon[mon] + day - 1;
}

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

// number of days in each month indexed by month (0-11)
sys_DateTime.daysInMon     = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
sys_DateTime.daysInMonLeap = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

// day of year (0-365) for 1st day of month (0-11)
sys_DateTime.dayOfYearForFirstOfMon     = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
sys_DateTime.dayOfYearForFirstOfMonLeap = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
for (var i=1; i<12; ++i)
{
  sys_DateTime.dayOfYearForFirstOfMon[i] =
    sys_DateTime.dayOfYearForFirstOfMon[i-1] + sys_DateTime.daysInMon[i-1];

  sys_DateTime.dayOfYearForFirstOfMonLeap[i] =
    sys_DateTime.dayOfYearForFirstOfMonLeap[i-1] + sys_DateTime.daysInMonLeap[i-1];
}