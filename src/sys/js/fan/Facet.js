//
// Copyright (c) 2011 Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jan 11  Andy Frank  Creation
//

/*************************************************************************
 * Facet
 ************************************************************************/

fan.sys.Facet = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Facet.prototype.$ctor = function() {}

/*************************************************************************
 * Deprecated facet
 ************************************************************************/

fan.sys.Deprecated = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Deprecated.prototype.$ctor = function() { this.m_msg = ""; }
fan.sys.Deprecated.prototype.$typeof = function() { return fan.sys.Deprecated.$type; }
fan.sys.Deprecated.prototype.toStr = function() { return fanx_ObjEncoder.encode(this); }
fan.sys.Deprecated.make = function(func)
{
  if (func === undefined) func = null;
  var self = new fan.sys.Deprecated();
  if (func != null)
  {
    func.enterCtor(self);
    func.call(self);
    func.exitCtor();
  }
  return self;
}

/*************************************************************************
 * FacetMeta facet
 ************************************************************************/

fan.sys.FacetMeta = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.FacetMeta.prototype.$ctor = function() { this.m_inherited = false; }
fan.sys.FacetMeta.prototype.$typeof = function() { return fan.sys.FacetMeta.$type; }
fan.sys.FacetMeta.prototype.toStr = function() { return fanx_ObjEncoder.encode(this); }
fan.sys.FacetMeta.make = function(func)
{
  if (func === undefined) func = null;
  var self = new fan.sys.FacetMeta();
  if (func != null)
  {
    func.enterCtor(self);
    func.call(self);
    func.exitCtor();
  }
  return self;
}

/*************************************************************************
 * Js facet
 ************************************************************************/

fan.sys.Js = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Js.prototype.$ctor = function() {}
fan.sys.Js.m_defVal = new fan.sys.Js();
fan.sys.Js.prototype.$typeof = function() { return fan.sys.Js.$type; }
fan.sys.Js.prototype.toStr = function() { return this.$typeof().qname(); }

/*************************************************************************
 * NoDoc facet
 ************************************************************************/

fan.sys.NoDoc = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.NoDoc.prototype.$ctor = function() {}
fan.sys.NoDoc.m_defVal = new fan.sys.NoDoc();
fan.sys.NoDoc.prototype.$typeof = function() { return fan.sys.NoDoc.$type; }
fan.sys.NoDoc.prototype.toStr = function() { return this.$typeof().qname(); }

/*************************************************************************
 * Operator facet
 ************************************************************************/

fan.sys.Operator = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Operator.prototype.$ctor = function() {}
fan.sys.Operator.m_defVal = new fan.sys.Operator();
fan.sys.Operator.prototype.$typeof = function() { return fan.sys.Operator.$type; }
fan.sys.Operator.prototype.toStr = function() { return this.$typeof().qname(); }

/*************************************************************************
 * Serializable facet
 ************************************************************************/

fan.sys.Serializable = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Serializable.prototype.$ctor = function()
{
  this.m_simple = false;
  this.m_collection = false;
}
fan.sys.Serializable.prototype.$typeof = function() { return fan.sys.Serializable.$type; }
fan.sys.Serializable.prototype.toStr = function() { return fanx_ObjEncoder.encode(this); }
fan.sys.Serializable.make = function(func)
{
  if (func === undefined) func = null;
  var self = new fan.sys.Serializable();
  if (func != null)
  {
    func.enterCtor(self);
    func.call(self);
    func.exitCtor();
  }
  return self;
}

/*************************************************************************
 * Transient facet
 ************************************************************************/

fan.sys.Transient = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Transient.prototype.$ctor = function() {}
fan.sys.Transient.m_defVal = new fan.sys.Transient();
fan.sys.Transient.prototype.$typeof = function() { return fan.sys.Transient.$type; }
fan.sys.Transient.prototype.toStr = function() { return this.$typeof().qname(); }


