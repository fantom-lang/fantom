//
// Copyright (c) 2011 Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jan 11  Andy Frank  Creation
//

/**
 * Facet.
 */
fan.sys.Facet = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Facet.prototype.$ctor = function() {}

/**
 * NoDoc facet
 */
fan.sys.NoDoc = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.NoDoc.prototype.$ctor = function() {}
fan.sys.NoDoc.m_defVal = new fan.sys.NoDoc();
fan.sys.NoDoc.prototype.$typeof = function() { fan.sys.NoDoc.$type; }
fan.sys.NoDoc.prototype.toStr = function() { return this.$typeof().qname(); }
