//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Aug 2013  Andy Frank  Break out from Method.js to fix dependency order
//

/**
 * MethodFunc.
 */
fan.sys.MethodFunc = fan.sys.Obj.$extend(fan.sys.Func);
fan.sys.MethodFunc.prototype.$ctor = function(method, returns)
{
  this.m_method = method;
  this.m_returns = returns;
  this.m_type = null;
}
fan.sys.MethodFunc.prototype.returns = function() { return this.m_returns; }
fan.sys.MethodFunc.prototype.arity = function() { return this.params().size(); }
fan.sys.MethodFunc.prototype.params = function()
{
  // lazy load functions param
  if (this.m_fparams == null)
  {
    var mparams = this.m_method.m_params;
    var fparams = mparams;
    if ((this.m_method.m_flags & (fan.sys.FConst.Static|fan.sys.FConst.Ctor)) == 0)
    {
      var temp = [];
      temp[0] = new fan.sys.Param("this", this.m_method.m_parent, 0);
      fparams = fan.sys.List.make(fan.sys.Param.$type, temp.concat(mparams.m_values));
    }
    this.m_fparams = fparams.ro();
  }
  return this.m_fparams;
}
fan.sys.MethodFunc.prototype.method = function() { return this.m_method; }
fan.sys.MethodFunc.prototype.isImmutable = function() { return true; }

fan.sys.MethodFunc.prototype.$typeof = function()
{
  // lazy load type and params
  if (this.m_type == null)
  {
    var params = this.params();
    var types = [];
    for (var i=0; i<params.size(); i++)
      types.push(params.get(i).m_type);
    this.m_type = new fan.sys.FuncType(types, this.m_returns);
  }
  return this.m_type;
}

fan.sys.MethodFunc.prototype.call = function()
{
  return this.m_method.call.apply(this.m_method, arguments);
}

fan.sys.MethodFunc.prototype.callList = function(args)
{
  return this.m_method.callList.apply(this.m_method, arguments);
}

fan.sys.MethodFunc.prototype.callOn = function(obj, args)
{
  return this.m_method.callOn.apply(this.m_method, arguments);
}

fan.sys.MethodFunc.prototype.retype = function(t)
{
  if (t instanceof fan.sys.FuncType)
  {
    var params = [];
    for (var i=0; i < t.pars.length; ++i)
      params.push(new fan.sys.Param(String.fromCharCode(i+65), t.pars[i], 0));
    var paramList = fan.sys.List.make(fan.sys.Param.$type, params);

    var func = new fan.sys.MethodFunc(this.m_method, t.ret);
    func.m_type = t;
    func.m_fparams = paramList;
    return func;
  }
  else
    throw fan.sys.ArgErr.make(fan.sys.Str.plus("Not a Func type: ", t));
}
