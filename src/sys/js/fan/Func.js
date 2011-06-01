//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Func.
 */
fan.sys.Func = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Func.prototype.$ctor = function()
{
}

fan.sys.Func.make = function(params, ret, func)
{
  var self = new fan.sys.Func();
  fan.sys.Func.make$(self, params, ret, func);
  return self;
}

fan.sys.Func.make$ = function(self, params, ret, func)
{
  var types = [];
  for (var i=0; i<params.size(); i++)
    types.push(params.get(i).m_type);

  self.m_params = params;
  self.m_return = ret;
  self.m_type   = new fan.sys.FuncType(types, ret);
  self.m_func   = func;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Func.prototype.$typeof = function() { return this.m_type; }

fan.sys.Func.prototype.toImmutable = function()
{
  if (this.isImmutable()) return this;
  throw fan.sys.NotImmutableErr.make("Func");
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Func.prototype.params = function() { return this.m_params; }
fan.sys.Func.prototype.returns = function() { return this.m_return; }

fan.sys.Func.prototype.call = function() { return this.m_func.apply(null, arguments); }
fan.sys.Func.prototype.callList = function(args) { return this.m_func.apply(null, args.m_values); }
fan.sys.Func.prototype.callOn = function(obj, args) { return this.m_func.apply(obj, args.m_values); }

fan.sys.Func.prototype.enterCtor = function(obj) {}
fan.sys.Func.prototype.exitCtor = function() {}
fan.sys.Func.prototype.checkInCtor = function(obj) {}
