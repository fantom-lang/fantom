//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Method.
 */
fan.sys.Method = fan.sys.Obj.$extend(fan.sys.Slot);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.$ctor = function(parent, name, flags, returns, params, facets)
{
  this.m_parent  = parent;
  this.m_name    = name;
  this.m_qname   = parent.qname() + "." + name;
  this.m_flags   = flags;
  this.m_returns = returns;
  this.m_params  = params;
  this.m_func    = new fan.sys.MethodFunc(this, returns);
  this.m_$name   = this.$$name(name);
  this.m_$qname  = this.m_parent.m_$qname + '.' + this.m_$name;
  this.m_facets  = new fan.sys.Facets(facets);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.invoke = function(instance, args)
{
  var func = (this.isCtor() || this.isStatic())
    ? eval(this.m_$qname)
    : instance[this.m_$name];
  var vals = args==null ? [] : args.m_values;

  // if not found, assume this is primitive that needs
  // to map into a static call
  if (func == null && instance != null)
  {
    func = eval(this.m_$qname);
    vals.splice(0, 0, instance);
    instance = null;
  }

  // TODO FIXIT: if func is null - most likley native
  // method hasn't been implemented
  return func.apply(instance, vals);
}

fan.sys.Method.prototype.$typeof = function() { return fan.sys.Method.$type; }
fan.sys.Method.prototype.returns = function() { return this.m_returns; }
fan.sys.Method.prototype.params  = function() { return this.m_params.ro(); }
fan.sys.Method.prototype.func = function() { return this.m_func; }

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

fan.sys.Method.prototype.callOn = function(target, args) { return this.invoke(target, args); }
fan.sys.Method.prototype.call = function()
{
  var instance = null;
  var args = arguments;

  if (!this.isStatic())
  {
    instance = args[0];
    args = Array.prototype.slice.call(args).slice(1);
  }

  return this.invoke(instance, fan.sys.List.make(fan.sys.Obj.$type, args));
}

fan.sys.Method.prototype.callList = function(args)
{
  var instance = null;
  if (!this.isStatic() && (this.m_flags & fan.sys.FConst.Static == 0))
  {
    instance = args.get(0);
    args = args.getSlice(1, -1);
  }
  return this.invoke(instance, args);
}

/*************************************************************************
 * MethodFunc
 ************************************************************************/

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

