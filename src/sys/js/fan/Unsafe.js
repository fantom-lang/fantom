//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jun 10  Brian Frank  Creation
//

/**
 * Unsafe.
 */
fan.sys.Unsafe = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Unsafe.make = function(val)
{
  var self = new fan.sys.Unsafe();
  self.m_val = val;
  return self;
}

fan.sys.Unsafe.prototype.$ctor = function()
{
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Unsafe.prototype.val = function() { return this.m_val; }

