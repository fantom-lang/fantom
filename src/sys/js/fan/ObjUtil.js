//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 09  Andy Frank  Creation
//

fan.sys.ObjUtil = function() {};

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

fan.sys.ObjUtil.hash = function(obj)
{
  // TODO
  return 0;
}

fan.sys.ObjUtil.equals = function(a, b)
{
  if (a instanceof fan.sys.Obj) return a.equals(b);
  else if (a instanceof Long) return fan.sys.Int.equals(a, b);
  else if ((typeof a) == "number") return fan.sys.Int.equals(a, b);
  else
  {
    if (a != null && a.$fanType != null)
      return fan.sys.Float.equals(a, b);
    else
      return a == b;
   }
}

fan.sys.ObjUtil.compare = function(a, b)
{
  if (a instanceof fan.sys.Obj)
  {
    if (b == null) return +1;
    return a.compare(b);
  }
  else if (a != null && a.$fanType != null)
  {
    return fan.sys.Float.compare(a, b);
  }
  else
  {
    if (a == null)
    {
      if (b != null) return -1;
      return 0;
    }
    if (b == null) return 1;
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
  }
}

fan.sys.ObjUtil.compareNE = function(a,b) { return !fan.sys.ObjUtil.equals(a,b) }
fan.sys.ObjUtil.compareLT = function(a,b) { return fan.sys.ObjUtil.compare(a,b) <  0 }
fan.sys.ObjUtil.compareLE = function(a,b) { return fan.sys.ObjUtil.compare(a,b) <= 0 }
fan.sys.ObjUtil.compareGE = function(a,b) { return fan.sys.ObjUtil.compare(a,b) >= 0 }
fan.sys.ObjUtil.compareGT = function(a,b) { return fan.sys.ObjUtil.compare(a,b) >  0 }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

fan.sys.ObjUtil.is = function(obj, type)
{
  if (obj == null) return false;
  return fan.sys.ObjUtil.type(obj).is(type);
}

fan.sys.ObjUtil.as = function(obj, type)
{
  if (obj == null) return null;
  var t = fan.sys.ObjUtil.type(obj);
  if (t.is(fan.sys.Func.$type)) return t.as(obj, type);
  if (t.is(fan.sys.List.$type)) return t.as(obj, type);
  if (t.is(fan.sys.Map.$type))  return t.as(obj, type);
  if (t.is(type)) return obj;
  return null;
}

fan.sys.ObjUtil.coerce = function(obj, type)
{
  if (obj == null)
  {
    if (type.isNullable()) return obj;
    throw fan.sys.NullErr.make("Coerce to non-null");
  }

  var v = fan.sys.ObjUtil.as(obj, type);
  if (v == null)
  {
    var t = fan.sys.ObjUtil.type(obj);
    throw fan.sys.CastErr.make(t + " cannot be cast to " + type);
  }

  return obj;
}

fan.sys.ObjUtil.type = function(obj)
{
  if (obj instanceof fan.sys.Obj) return obj.type();
  else return fan.sys.Type.toFanType(obj);
}

fan.sys.ObjUtil.trap = function(obj, name, args)
{
  if (obj instanceof fan.sys.Obj) return obj.trap(name, args);
  throw fan.sys.Err.make("ObjUtil.trap primitive support incomplete");
}

//////////////////////////////////////////////////////////////////////////
// Const
//////////////////////////////////////////////////////////////////////////

fan.sys.ObjUtil.isImmutable = function(obj)
{
  if (obj instanceof fan.sys.Obj) return obj.isImmutable();
  else if (obj == null) return true;
  else
  {
    if ((typeof obj) == "boolean" || obj instanceof Boolean) return true;
    if ((typeof obj) == "number"  || obj instanceof Number) return true;
    if ((typeof obj) == "string"  || obj instanceof String) return true;
    if (obj.$fanType != null) return true;
  }
  throw fan.sys.UnknownTypeErr.make("Not a Fantom type: " + obj);
}

fan.sys.ObjUtil.toImmutable = function(obj)
{
  if (obj instanceof fan.sys.Obj) return obj.toImmutable();
  else if (obj == null) return null;
  else
  {
    if ((typeof obj) == "boolean" || obj instanceof Boolean) return obj;
    if ((typeof obj) == "number"  || obj instanceof Number) return obj;
    if ((typeof obj) == "string"  || obj instanceof String) return obj;
    if (obj.$fanType != null) return obj;
  }
  throw fan.sys.UnknownTypeErr.make("Not a Fantom type: " + obj);
}

//////////////////////////////////////////////////////////////////////////
// with
//////////////////////////////////////////////////////////////////////////

fan.sys.ObjUtil.$with = function(self, f)
{
  if (self instanceof fan.sys.Obj)
  {
    return self.$with(f);
  }
  else
  {
    f.call(self);
    return self;
  }
}

//////////////////////////////////////////////////////////////////////////
// toStr
//////////////////////////////////////////////////////////////////////////

fan.sys.ObjUtil.toStr = function(obj)
{
  if (obj == null) return "null";
  if (typeof obj == "string") return obj;
//  if (obj.constructor == Array) return fan.sys.List.toStr(obj);

  // TODO - can't for the life of me figure how the
  // heck Error.toString would ever try to call Obj.toStr
  // so trap it for now
//  if (obj instanceof Error) return Error.prototype.toString.call(obj);

// TEMP
if (obj.$fanType === fan.sys.Float.$type) return fan.sys.Float.toStr(obj);

  return obj.toString();
}

fan.sys.ObjUtil.echo = function(obj)
{
  var s = fan.sys.ObjUtil.toStr(obj);
  try { console.log(s); }
  catch (e1)
  {
    try { println(s); }
    catch (e2) {} //alert(s); }
  }
}

