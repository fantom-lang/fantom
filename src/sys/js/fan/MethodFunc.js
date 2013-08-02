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
      temp[0] = new fan.sys.Param("this", this.m_parent, 0);
      fparams = fan.sys.List.make(fan.sys.Param.$typeof, temp.concat(mparams));
    }
    this.m_fparams = fparams.ro();
  }
  return this.m_fparams;
}
fan.sys.MethodFunc.prototype.method = function() { return this.m_method; }
fan.sys.MethodFunc.prototype.isImmutable = function() { return true; }

fan.sys.MethodFunc.prototype.call = function()
{
  return this.m_method.call.apply(this.m_method, arguments);
}

fan.sys.MethodFunc.prototype.callList = function(args)
{
  println("### MethodFunc.callList");
  return this.m_func.apply(null, args.m_values);
}

fan.sys.MethodFunc.prototype.callOn = function(obj, args)
{
  println("### MethodFunc.callOn");
  return this.m_func.apply(obj, args.m_values);
}

