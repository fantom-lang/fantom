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
var sys_Func = sys_Obj.$extend(sys_Obj);

sys_Func.prototype.$ctor = function() {}
sys_Func.prototype.type = function() { return sys_Type.find("sys::Func"); }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Func.make = function(f, params, ret)
{
  var types = [];
  for (var i=0; i<params.length; i++)
    types.push(params[i].m_of);
  f.$fanParams = params;
  f.$fanType = new sys_FuncType(types, ret);
  return f;
}

sys_Func.params   = function(f) { return f.$fanParams; }
sys_Func.ret      = function(f) { return f.$fanType.ret; }
sys_Func.call     = function(f) { return f.apply(null, arguments); }
sys_Func.callList = function(f, args) { return f.apply(null, args); }
sys_Func.callOn   = function(f, obj, args)
{
  var acc = args.slice();
  acc.unshift(obj);
  return f.apply(null, acc);
}

sys_Func.curry = function(f, args)
{
  var t = f.$fanType;
  if (args.length == 0) return f;
  if (args.length > t.params.length)
    throw sys_ArgErr.make("args.size > params.size");

  var len = t.params.length - args.length;
  var newParams = [];
  for (var i=0; i<len; i++)
    newParams.push(t.params[args.length+i])

  return sys_Func.make(function() {
    var curried = args.slice();
    for (var i=0; i<arguments.length; i++)
      curried.push(arguments[i]);
    return f.apply(null, curried);
  }, newParams, t.ret);
}