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

fan.sys.Func.prototype.$ctor = function() {}
fan.sys.Func.prototype.type = function() { return fan.sys.Type.find("sys::Func"); }

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Func.make = function(f, params, ret)
{
  var types = [];
  for (var i=0; i<params.length; i++)
    types.push(params[i].m_of);
  f.$fanParams = params;
  f.$fanType = new fan.sys.FuncType(types, ret);
  return f;
}

fan.sys.Func.params   = function(f) { return f.$fanParams; }
fan.sys.Func.ret      = function(f) { return f.$fanType.ret; }
fan.sys.Func.call     = function(f)
{
  var args = Array.prototype.slice.call(arguments).slice(1);
  return f.apply(null, args);
}
fan.sys.Func.callList = function(f, args) { return f.apply(null, args); }
fan.sys.Func.callOn   = function(f, obj, args)
{
  var acc = args.slice();
  acc.unshift(obj);
  return f.apply(null, acc);
}

fan.sys.Func.curry = function(f, args)
{
  var t = f.$fanType;
  if (args.length == 0) return f;
  if (args.length > t.params.length)
    throw fan.sys.ArgErr.make("args.size > params.size");

  var len = t.params.length - args.length;
  var newParams = [];
  for (var i=0; i<len; i++)
    newParams.push(t.params[args.length+i])

  return fan.sys.Func.make(function() {
    var curried = args.slice();
    for (var i=0; i<arguments.length; i++)
      curried.push(arguments[i]);
    return f.apply(null, curried);
  }, newParams, t.ret);
}