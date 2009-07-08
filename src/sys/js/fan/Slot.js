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
var sys_Slot = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Slot.prototype.$ctor = function()
{
  this.m_parent = null;
  this.m_qname  = null;
  this.m_name   = null;
  this.m_flags  = null;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_Slot.prototype.type = function() { return sys_Type.find("sys::Slot"); }
sys_Slot.prototype.toStr = function() { return this.m_qname; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Slot.prototype.parent = function() { return this.m_parent; }
sys_Slot.prototype.qname = function() { return this.m_qname; }
sys_Slot.prototype.name = function() { return this.m_name; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

sys_Slot.prototype.isAbstract = function()  { return (this.m_flags & sys_FConst.Abstract)  != 0; }
sys_Slot.prototype.isConst = function()     { return (this.m_flags & sys_FConst.Const)     != 0; }
sys_Slot.prototype.isCtor = function()      { return (this.m_flags & sys_FConst.Ctor)      != 0; }
sys_Slot.prototype.isInternal = function()  { return (this.m_flags & sys_FConst.Internal)  != 0; }
sys_Slot.prototype.isNative = function()    { return (this.m_flags & sys_FConst.Native)    != 0; }
sys_Slot.prototype.isOverride = function()  { return (this.m_flags & sys_FConst.Override)  != 0; }
sys_Slot.prototype.isPrivate = function()   { return (this.m_flags & sys_FConst.Private)   != 0; }
sys_Slot.prototype.isProtected = function() { return (this.m_flags & sys_FConst.Protected) != 0; }
sys_Slot.prototype.isPublic = function()    { return (this.m_flags & sys_FConst.Public)    != 0; }
sys_Slot.prototype.isStatic = function()    { return (this.m_flags & sys_FConst.Static)    != 0; }
sys_Slot.prototype.isSynthetic = function() { return (this.m_flags & sys_FConst.Synthetic) != 0; }
sys_Slot.prototype.isVirtual = function()   { return (this.m_flags & sys_FConst.Virtual)   != 0; }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

sys_Slot.prototype.$name = function(n)
{
  // must keep in sync with compilerJs::JsWriter
  switch (n)
  {
    case "char":   return "$char";
    case "delete": return "$delete";
    case "in":     return "$in";
    case "var":    return "$var";
    case "with":   return "$with";
  }
  return n;
}

