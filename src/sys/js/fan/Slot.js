//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Slot.
 */
fan.sys.Slot = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.prototype.$ctor = function()
{
  this.m_parent = null;
  this.m_qname  = null;
  this.m_name   = null;
  this.m_flags  = null;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.prototype.$typeof = function() { return fan.sys.Slot.$type; }
fan.sys.Slot.prototype.toStr = function() { return this.m_qname; }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.findMethod = function(qname, checked)
{
  var slot = fan.sys.Slot.find(qname, checked);
  return fan.sys.ObjUtil.coerce(slot, fan.sys.Method.$type);
}

fan.sys.Slot.findField = function(qname, checked)
{
  var slot = fan.sys.Slot.find(qname, checked);
  return fan.sys.ObjUtil.coerce(slot, fan.sys.Field.$type);
}

fan.sys.Slot.find = function(qname, checked)
{
  if (checked === undefined) checked = true;
  var typeName, slotName;
  try
  {
    var dot = qname.indexOf('.');
    typeName = qname.substring(0, dot);
    slotName = qname.substring(dot+1);
  }
  catch (e)
  {
    throw fan.sys.Err.make("Invalid slot qname \"" + qname + "\", use <pod>::<type>.<slot>");
  }
  var type = fan.sys.Type.find(typeName, checked);
  if (type == null) return null;
  return type.slot(slotName, checked);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.prototype.parent = function() { return this.m_parent; }
fan.sys.Slot.prototype.qname = function() { return this.m_qname; }
fan.sys.Slot.prototype.name = function() { return this.m_name; }
fan.sys.Slot.prototype.isField = function() { return this instanceof fan.sys.Field; }
fan.sys.Slot.prototype.isMethod = function() { return this instanceof fan.sys.Method; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.prototype.isAbstract = function()  { return (this.m_flags & fan.sys.FConst.Abstract)  != 0; }
fan.sys.Slot.prototype.isConst = function()     { return (this.m_flags & fan.sys.FConst.Const)     != 0; }
fan.sys.Slot.prototype.isCtor = function()      { return (this.m_flags & fan.sys.FConst.Ctor)      != 0; }
fan.sys.Slot.prototype.isInternal = function()  { return (this.m_flags & fan.sys.FConst.Internal)  != 0; }
fan.sys.Slot.prototype.isNative = function()    { return (this.m_flags & fan.sys.FConst.Native)    != 0; }
fan.sys.Slot.prototype.isOverride = function()  { return (this.m_flags & fan.sys.FConst.Override)  != 0; }
fan.sys.Slot.prototype.isPrivate = function()   { return (this.m_flags & fan.sys.FConst.Private)   != 0; }
fan.sys.Slot.prototype.isProtected = function() { return (this.m_flags & fan.sys.FConst.Protected) != 0; }
fan.sys.Slot.prototype.isPublic = function()    { return (this.m_flags & fan.sys.FConst.Public)    != 0; }
fan.sys.Slot.prototype.isStatic = function()    { return (this.m_flags & fan.sys.FConst.Static)    != 0; }
fan.sys.Slot.prototype.isSynthetic = function() { return (this.m_flags & fan.sys.FConst.Synthetic) != 0; }
fan.sys.Slot.prototype.isVirtual = function()   { return (this.m_flags & fan.sys.FConst.Virtual)   != 0; }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

fan.sys.Slot.prototype.$name = function(n)
{
  // must keep in sync with compilerJs::JsNode
  switch (n)
  {
    case "char":   return "$char";
    case "delete": return "$delete";
    case "fan":    return "$fan";
    case "import": return "$import";
    case "in":     return "$in";
    case "typeof": return "$typeof";
    case "var":    return "$var";
    case "with":   return "$with";
  }
  return n;
}

