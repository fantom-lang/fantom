//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 10  Andy Frank  Creation
//

/**
 * Env.
 */
fan.sys.Env = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.cur = function()
{
  if (fan.sys.Env.$cur == null) fan.sys.Env.$cur = new fan.sys.Env();
  return fan.sys.Env.$cur;
}

fan.sys.Env.prototype.$ctor = function()
{
  this.m_args = fan.sys.List.make(fan.sys.Str.$type).toImmutable();
  this.m_vars = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type).toImmutable();
}

fan.sys.Env.prototype.$setVars = function(vars)
{
  if (vars.$typeof().toStr() != "[sys::Str:sys::Str]")
    throw fan.sys.ArgErr("Invalid type");
  this.m_vars = vars.toImmutable();
}

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.runtime = function() { return "js"; }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

fan.sys.Env.prototype.args = function() { return this.m_args; }

fan.sys.Env.prototype.vars = function() { return this.m_vars; }