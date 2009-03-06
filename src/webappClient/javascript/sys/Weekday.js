//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Mar 09  Andy Frank  Creation
//

/**
 * Weekday
 */
var sys_Weekday = sys_Enum.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function(ordinal, name)
  {
    this.$make(ordinal, name);
  },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  increment: function()
  {
    var arr = sys_Weekday.values;
    return arr[(this.m_ordinal+1) % arr.length];
  },

  decrement: function()
  {
    var arr = sys_Weekday.values;
    return this.m_ordinal == 0 ? arr[arr.length-1] : arr[this.m_ordinal-1];
  },

  type: function()
  {
    return sys_Type.find("sys::Weekday");
  },

});

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////
// Static Fields
//////////////////////////////////////////////////////////////////////////

sys_Weekday.sun = new sys_Weekday(0,  "sun");
sys_Weekday.mon = new sys_Weekday(1,  "mon");
sys_Weekday.tue = new sys_Weekday(2,  "tue");
sys_Weekday.wed = new sys_Weekday(3,  "wed");
sys_Weekday.thu = new sys_Weekday(4,  "thu");
sys_Weekday.fri = new sys_Weekday(5,  "fri");
sys_Weekday.sat = new sys_Weekday(6,  "sat");

sys_Weekday.values =
[
  sys_Weekday.sun,
  sys_Weekday.mon,
  sys_Weekday.tue,
  sys_Weekday.wed,
  sys_Weekday.thu,
  sys_Weekday.fri,
  sys_Weekday.sat
];