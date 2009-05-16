//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

/**
 * Slot.
 */
var sys_Slot = sys_Obj.extend(
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  $ctor: function() {},
  type: function() { return sys_Type.find("sys::Slot"); },
  toStr: function() { return this.m_qname; },

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  parent: function() { return this.m_parent; },
  qname: function() { return this.m_qname; },
  name: function() { return this.m_name; },

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  isAbstract: function()  { return (this.m_flags & sys_FConst.Abstract)  != 0; },
  isConst: function()     { return (this.m_flags & sys_FConst.Const)     != 0; },
  isCtor: function()      { return (this.m_flags & sys_FConst.Ctor)      != 0; },
  isInternal: function()  { return (this.m_flags & sys_FConst.Internal)  != 0; },
  isNative: function()    { return (this.m_flags & sys_FConst.Native)    != 0; },
  isOverride: function()  { return (this.m_flags & sys_FConst.Override)  != 0; },
  isPrivate: function()   { return (this.m_flags & sys_FConst.Private)   != 0; },
  isProtected: function() { return (this.m_flags & sys_FConst.Protected) != 0; },
  isPublic: function()    { return (this.m_flags & sys_FConst.Public)    != 0; },
  isStatic: function()    { return (this.m_flags & sys_FConst.Static)    != 0; },
  isSynthetic: function() { return (this.m_flags & sys_FConst.Synthetic) != 0; },
  isVirtual: function()   { return (this.m_flags & sys_FConst.Virtual)   != 0; },

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  $name: function(n)
  {
    // must keep in sync with compilerJavascript::JavascriptWriter
    switch (n)
    {
      case "char":   return "$char";
      case "delete": return "$delete";
      case "in":     return "$in";
      case "var":    return "$in";
      case "with":   return "$with";
    }
    return n;
  },

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  m_parent: null,
  m_qname: null,
  m_name: null,
  m_flags: null

});

