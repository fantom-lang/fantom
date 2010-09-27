//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Type models sys::Type.  Implementation classes are:
 *   - ClassType
 *   - GenericType (ListType, MapType, FuncType)
 *   - NullableType
 */
fan.sys.Type = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.$ctor = function(qname, base, mixins, flags)
{
  // workaround for inhertiance
  if (qname === undefined) return;

  // mixins
  if (fan.sys.Type.$type != null)
  {
    var acc = fan.sys.List.make(fan.sys.Type.$type, []);
    for (var i=0; i<mixins.length; i++)
      acc.add(fan.sys.Type.find(mixins[i]));
    this.m_mixins = acc.ro();
  }

  var s = qname.split("::");
  this.m_qname    = qname;
  this.m_pod      = fan.sys.Pod.find(s[0]);
  this.m_name     = s[1];
  this.m_base     = base == null ? null : fan.sys.Type.find(base);
  this.m_slots    = [];
  this.m_flags    = flags;
  this.m_$qname   = 'fan.' + this.m_pod + '.' + this.m_name;
  this.m_isMixin  = false;
  this.m_nullable = new fan.sys.NullableType(this);
}

//////////////////////////////////////////////////////////////////////////
// Naming
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.pod = function() { return this.m_pod; }
fan.sys.Type.prototype.name = function() { return this.m_name; }
fan.sys.Type.prototype.qname = function() { return this.m_qname; }
fan.sys.Type.prototype.signature = function() { return this.m_qname; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.isAbstract  = function() { return (this.flags() & fan.sys.FConst.Abstract) != 0; }
fan.sys.Type.prototype.isClass     = function() { return (this.flags() & (fan.sys.FConst.Enum|fan.sys.FConst.Mixin)) == 0; }
fan.sys.Type.prototype.isConst     = function() { return (this.flags() & fan.sys.FConst.Const) != 0; }
fan.sys.Type.prototype.isEnum      = function() { return (this.flags() & fan.sys.FConst.Enum) != 0; }
fan.sys.Type.prototype.isFinal     = function() { return (this.flags() & fan.sys.FConst.Final) != 0; }
fan.sys.Type.prototype.isInternal  = function() { return (this.flags() & fan.sys.FConst.Internal) != 0; }
fan.sys.Type.prototype.isMixin     = function() { return (this.flags() & fan.sys.FConst.Mixin) != 0; }
fan.sys.Type.prototype.isPublic    = function() { return (this.flags() & fan.sys.FConst.Public) != 0; }
fan.sys.Type.prototype.isSynthetic = function() { return (this.flags() & fan.sys.FConst.Synthetic) != 0; }
fan.sys.Type.prototype.flags = function() { return this.m_flags; };

fan.sys.Type.prototype.trap = function(name, args)
{
  // private undocumented access
  if (name == "flags") return this.flags();
  return fan.sys.Obj.prototype.trap.call(this, name, args);
}

//////////////////////////////////////////////////////////////////////////
// Value Types
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.isVal = function()
{
  return this === fan.sys.Bool.$type ||
         this === fan.sys.Int.$type ||
         this === fan.sys.Float.$type;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.isClass = function()   { return !this.m_isMixin && this.m_base.m_qname != "sys::Enum"; }
fan.sys.Type.prototype.isEnum = function()    { return this.m_base != null && this.m_base.m_qname == "sys::Enum"; }
fan.sys.Type.prototype.isMixin = function()   { return this.m_isMixin; }
fan.sys.Type.prototype.log = function()       { return fan.sys.Log.get(this.m_pod.m_name); }
fan.sys.Type.prototype.toStr = function()     { return this.signature(); }
fan.sys.Type.prototype.toLocale = function()  { return this.signature(); }
fan.sys.Type.prototype.$typeof = function()   { return fan.sys.Type.$type; }

fan.sys.Type.prototype.toListOf = function()
{
  if (this.m_listOf == null) this.m_listOf = new fan.sys.ListType(this);
  return this.m_listOf;
}

fan.sys.Type.prototype.emptyList = function()
{
  if (this.$emptyList == null)
    this.$emptyList = fan.sys.List.make(this).toImmutable();
  return this.$emptyList;
}

fan.sys.Type.prototype.isNullable = function() { return false; }
fan.sys.Type.prototype.toNonNullable = function() { return this; }

fan.sys.Type.prototype.toNullable = function() { return this.m_nullable; }
fan.sys.Type.prototype.toNonNullable = function() { return this; }

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.make = function(args)
{
  if (args === undefined) args = null;

  var make = this.method("make", false);
  if (make != null && make.isPublic())
  {
    var numArgs = args == null ? 0 : args.size();
    var params = make.params();
    if ((numArgs == params.size()) ||
        (numArgs < params.size() && params.get(numArgs).hasDefault()))
      return make.invoke(null, args);
  }

  var defVal = this.slot("defVal", false);
  if (defVal != null && defVal.isPublic())
  {
    if (defVal instanceof fan.sys.Field) return defVal.get(null);
    if (defVal instanceof fan.sys.Method) return defVal.invoke(null, null);
  }

  throw Err.make("Type missing 'make' or 'defVal' slots: " + this).val;
}

//////////////////////////////////////////////////////////////////////////
// Slots
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.slots = function()
{
  // TODO FIXIT: include inheritance; cache
  var acc = [];
  for (var i in this.m_slots)
    acc.push(this.m_slots[i]);
  return fan.sys.List.make(fan.sys.Slot.$type, acc);
}

fan.sys.Type.prototype.methods = function()
{
  // TODO FIXIT: include inheritance; cache
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof fan.sys.Method)
      acc.push(this.m_slots[i]);
  return fan.sys.List.make(fan.sys.Method.$type, acc);
}

fan.sys.Type.prototype.fields = function()
{
  // TODO FIXIT: include inheritance; cache
  var acc = [];
  for (var i in this.m_slots)
    if (this.m_slots[i] instanceof fan.sys.Field)
      acc.push(this.m_slots[i]);
  return fan.sys.List.make(fan.sys.Field.$type, acc);
}

fan.sys.Type.prototype.slot = function(name, checked)
{
  if (checked === undefined) checked = true;
  var s = this.$slot(name);
  if (s == null && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return s;
}

fan.sys.Type.prototype.method = function(name, checked)
{
  if (checked === undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof fan.sys.Method)) && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

fan.sys.Type.prototype.field = function(name, checked)
{
  if (checked === undefined) checked = true;
  var f = this.$slot(name);
  if ((f == null || !(f instanceof fan.sys.Field)) && checked)
    throw fan.sys.UnknownSlotErr.make(this.m_qname + "." + name);
  return f;
}

// addMethod
fan.sys.Type.prototype.$am = function(name, flags, params)
{
  var m = new fan.sys.Method(this, name, flags, params);
  this.m_slots[name] = m;
  return this;
}

// addField
fan.sys.Type.prototype.$af = function(name, flags, of)
{
  // TODO: Map.def - not sure how to handle this yet
  if (of == 'sys::V?') return this;

  var t = fanx_TypeParser.load(of);
  var f = new fan.sys.Field(this, name, flags, t);
  this.m_slots[name] = f;
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.base = function()
{
  return this.m_base;
}

fan.sys.Type.prototype.mixins = function()
{
  // lazy-build mxins list for Obj and Type
  if (this.m_mixins == null)
    this.m_mixins = fan.sys.List.make(fan.sys.Type.$type, []).ro();
  return this.m_mixins;
}


// TODO
//fan.sys.Type.prototype.inheritance = function()
//{
//}

fan.sys.Type.prototype.fits = function(that) { return this.is(that); }
fan.sys.Type.prototype.is = function(that)
{
  // we don't take nullable into account for fits
  if (that instanceof fan.sys.NullableType)
    that = that.m_root;

  if (this.equals(that)) return true;

  // check for void
  if (this === fan.sys.Void.$type) return false;

  // check base class
  var base = this.m_base;
  while (base != null)
  {
    if (base.equals(that)) return true;
    base = base.m_base;
  }

  // check mixins
  var t = this;
  while (t != null)
  {
    var m = t.mixins();
    for (var i=0; i<m.size(); i++)
      if (fan.sys.Type.checkMixin(m.get(i), that)) return true;
    t = t.m_base;
  }

  return false;
}

fan.sys.Type.checkMixin = function(mixin, that)
{
  if (mixin.equals(that)) return true;
  var m = mixin.m_mixins;
  for (var i=0; i<m.length; i++)
    if (fan.sys.Type.checkMixin(m[i], that))
      return true;
  return false;
}

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

fan.sys.Type.prototype.$slot = function(name)
{
  // check self first
  var slot = this.m_slots[name];
  if (slot != null) return slot;

  // walk inheritance
  var base = this.m_base;
  while (base != null)
  {
    slot = base.m_slots[name];
    if (slot != null) return slot;
    base = base.m_base;
  }

  // not found
  return null;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

/**
 * Find the Fantom type for this qname.
 */
fan.sys.Type.find = function(sig, checked)
{
  return fanx_TypeParser.load(sig, checked);
}

/**
 * Get the Fantom type
 */
fan.sys.Type.of = function(obj)
{
  if (obj instanceof fan.sys.Obj)
    return obj.$typeof();
  else
    return fan.sys.Type.toFanType(obj);
}

/**
 * Get the Fantom type
 */
fan.sys.Type.toFanType = function(obj)
{
  if (obj == null) throw fan.sys.Err.make("sys::Type.toFanType: obj is null");
  if (obj.$fanType != undefined) return obj.$fanType;
  if ((typeof obj) == "boolean" || obj instanceof Boolean) return fan.sys.Bool.$type;
  if ((typeof obj) == "number"  || obj instanceof Number)  return fan.sys.Int.$type;
  if ((typeof obj) == "string"  || obj instanceof String)  return fan.sys.Str.$type;
  throw fan.sys.Err.make("sys::Type.toFanType: Not a Fantom type: " + obj);
}

fan.sys.Type.common = function(objs)
{
  if (objs.length == 0) return fan.sys.Obj.$type.toNullable();
  var nullable = false;
  var best = null;
  for (var i=0; i<objs.length; i++)
  {
    var obj = objs[i];
    if (obj == null) { nullable = true; continue; }
    var t = fan.sys.ObjUtil.$typeof(obj);
    if (best == null) { best = t; continue; }
    while (!t.is(best))
    {
      best = best.base();
      if (best == null) return nullable ? fan.sys.Obj.$type.toNullable() : fan.sys.Obj.$type;
    }
  }
  if (best == null) best = fan.sys.Obj.$type;
  return nullable ? best.toNullable() : best;
}

/*************************************************************************
 * NullableType
 ************************************************************************/

fan.sys.NullableType = fan.sys.Obj.$extend(fan.sys.Type)
fan.sys.NullableType.prototype.$ctor = function(root)
{
  this.m_root = root;
  this.m_signature = root.signature() + "?";
}

fan.sys.NullableType.prototype.pod = function() { return this.m_root.pod(); }
fan.sys.NullableType.prototype.name = function() { return this.m_root.name(); }
fan.sys.NullableType.prototype.qname = function() { return this.m_root.qname(); }
fan.sys.NullableType.prototype.signature = function() { return this.m_signature; }
fan.sys.NullableType.prototype.flags = function() { return this.m_root.flags(); }

fan.sys.NullableType.prototype.base = function() { return this.m_root.base(); }
fan.sys.NullableType.prototype.mixins = function() { return this.m_root.mixins(); }
fan.sys.NullableType.prototype.inheritance = function() { return this.m_root.inheritance(); }
fan.sys.NullableType.prototype.is = function(type) { return this.m_root.is(type); }

fan.sys.NullableType.prototype.isVal = function() { return this.m_root.isVal(); }

fan.sys.NullableType.prototype.isNullable = function() { return true; }
fan.sys.NullableType.prototype.toNullable = function() { return this; }
fan.sys.NullableType.prototype.toNonNullable = function() { return this.m_root; }

fan.sys.NullableType.prototype.isGenericType = function() { return this.m_root.isGenericType(); }
fan.sys.NullableType.prototype.isGenericInstance = function() { return this.m_root.isGenericInstance(); }
fan.sys.NullableType.prototype.isGenericParameter = function() { return this.m_root.isGenericParameter(); }
fan.sys.NullableType.prototype.getRawType = function() { return this.m_root.getRawType(); }
fan.sys.NullableType.prototype.params = function() { return this.m_root.params(); }
fan.sys.NullableType.prototype.parameterize = function(params) { return this.m_root.parameterize(params).toNullable(); }

fan.sys.NullableType.prototype.fields = function() { return this.m_root.fields(); }
fan.sys.NullableType.prototype.methods = function() { return this.m_root.methods(); }
fan.sys.NullableType.prototype.slots = function() { return this.m_root.slots(); }
fan.sys.NullableType.prototype.slot = function(name, checked) { return this.m_root.slot(name, checked); }

fan.sys.NullableType.prototype.facets = function(inherited) { return this.m_root.facets(inherited); }
fan.sys.NullableType.prototype.facet = function(key, def, inherited) { return this.m_root.facet(key, def, inherited); }

fan.sys.NullableType.prototype.doc = function() { return this.m_root.doc(); }

/*************************************************************************
 * ListType
 ************************************************************************/

fan.sys.ListType = fan.sys.Obj.$extend(fan.sys.Type)
fan.sys.ListType.prototype.$ctor = function(v)
{
  this.v = v;
  this.m_mixins = [];
}

fan.sys.ListType.prototype.base = function() { return fan.sys.List.$type; }
fan.sys.ListType.prototype.signature = function() { return this.v.signature() + '[]'; }
fan.sys.ListType.prototype.$slot = function(name) { return fan.sys.List.$type.$slot(name); }
fan.sys.ListType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.ListType)
    return this.v.equals(that.v);
  else
    return false;
}

fan.sys.ListType.prototype.is = function(that)
{
  if (that instanceof fan.sys.ListType)
  {
    if (that.v.qname() == "sys::Obj") return true;
    return this.v.is(that.v);
  }
  if (that instanceof fan.sys.Type)
  {
    if (that.qname() == "sys::List") return true;
    if (that.qname() == "sys::Obj")  return true;
  }
  return false;
}

fan.sys.ListType.prototype.as = function(obj, that)
{
  var objType = fan.sys.ObjUtil.$typeof(obj);

  if (objType instanceof fan.sys.ListType &&
      objType.v.qname() == "sys::Obj" &&
      that instanceof fan.sys.ListType)
    return obj;

  if (that instanceof fan.sys.NullableType &&
      that.m_root instanceof fan.sys.ListType)
    that = that.m_root;

  return objType.is(that) ? obj : null;
}

fan.sys.ListType.prototype.toNullable = function()
{
  if (this.m_nullable == null) this.m_nullable = new fan.sys.NullableType(this);
  return this.m_nullable;
}

/*************************************************************************
 * MapType
 ************************************************************************/

fan.sys.MapType = fan.sys.Obj.$extend(fan.sys.Type);

fan.sys.MapType.prototype.$ctor = function(k, v)
{
  this.k = k;
  this.v = v;
  this.m_mixins = [];
}

fan.sys.MapType.prototype.signature = function()
{
  return "[" + this.k.signature() + ':' + this.v.signature() + ']';
}

fan.sys.MapType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.MapType)
    return this.k.equals(that.k) && this.v.equals(that.v);
  else
    return false;
}

fan.sys.MapType.prototype.is = function(that)
{
  if (that.isNullable()) that = that.m_root;

  if (that instanceof fan.sys.MapType)
  {
    return this.k.is(that.k) && this.v.is(that.v);
  }
  if (that instanceof fan.sys.Type)
  {
    if (that.qname() == "sys::Map") return true;
    if (that.qname() == "sys::Obj")  return true;
  }
  return false;
}

fan.sys.MapType.prototype.as = function(obj, that)
{
  var objType = fan.sys.ObjUtil.$typeof(obj);

  if (objType instanceof fan.sys.MapType &&
      objType.k.qname() == "sys::Obj" &&
      objType.v.qname() == "sys::Obj" &&
      that instanceof fan.sys.MapType)
    return obj;

  //if (that instanceof fan.sys.NullableType &&
  //    that.m_root instanceof fan.sys.MapType)
  //  that = that.m_root;

  return objType.is(that) ? obj : null;
}

fan.sys.MapType.prototype.toNullable = function()
{
  if (this.m_nullable == null) this.m_nullable = new fan.sys.NullableType(this);
  return this.m_nullable;
}

/*************************************************************************
 * FuncType
 ************************************************************************/

fan.sys.FuncType = fan.sys.Obj.$extend(fan.sys.Type);

fan.sys.FuncType.prototype.$ctor = function(params, ret)
{
  this.params = params;
  this.ret = ret;
  this.m_mixins = [];
}

fan.sys.FuncType.prototype.signature = function()
{
  var s = '|'
  for (var i=0; i<this.params.length; i++)
  {
    if (i > 0) s += ',';
    s += this.params[i].signature();
  }
  s += '->';
  s += this.ret.signature();
  s += '|';
  return s;
}

fan.sys.FuncType.prototype.equals = function(that)
{
  if (that instanceof fan.sys.FuncType)
  {
    if (this.params.length != that.params.length) return false;
    for (var i=0; i<this.params.length; i++)
      if (!this.params[i].equals(that.params[i])) return false;
    return this.ret.equals(that.ret);
  }
  return false;
}

fan.sys.FuncType.prototype.is = function(that)
{
  if (this == that) return true;
  if (that instanceof fan.sys.FuncType)
  {
    // match return type (if void is needed, anything matches)
    if (that.ret.m_qname != "sys::Void" && !this.ret.is(that.ret)) return false;

    // match params - it is ok for me to have less than
    // the type params (if I want to ignore them), but I
    // must have no more
    if (this.params.length > that.params.length) return false;
    for (var i=0; i<this.params.length; ++i)
      if (!that.params[i].is(this.params[i])) return false;

    // this method works for the specified method type
    return true;
  }
  // TODO FIXIT - need to add as FuncType in Type.$af
  if (that.toString() == "sys::Func") return true;
  if (that.toString() == "sys::Func?") return true;
  return this.base().is(that);
}

fan.sys.FuncType.prototype.as = function(that)
{
  // TODO FIXIT
  return that;
}

