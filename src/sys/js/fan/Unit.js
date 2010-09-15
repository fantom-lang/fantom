//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Apr 10  Andy Frank  Creation
//

/*************************************************************************
** Dimension
*************************************************************************/

fan.sys.Dimension = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Dimension.prototype.$ctor = function()
{
  this.kg  = 0;
  this.m   = 0;
  this.sec = 0;
  this.K   = 0;
  this.A   = 0;
  this.mol = 0;
  this.cd  = 0;
}

fan.sys.Dimension.prototype.hashCode = function()
{
  return (kg << 28) ^ (m << 23) ^ (sec << 18) ^
         (K << 13) ^ (A << 8) ^ (mol << 3) ^ cd;
}

fan.sys.Dimension.prototype.equals = function(o)
{
  return this.kg == x.kg && this.m   == x.m   && this.sec == x.sec && this.K == x.K &&
         this.A  == x.A  && this.mol == x.mol && this.cd  == x.cd;
}

fan.sys.Dimension.prototype.toString = function()
{
  if (this.m_str == null)
  {
    var s = "";
    s = this.append(s, "kg",  this.kg);  s = this.append(s, "m",   this.m);
    s = this.append(s, "sec", this.sec); s = this.append(s, "K",   this.K);
    s = this.append(s, "A",   this.A);   s = this.append(s, "mol", this.mol);
    s = this.append(s, "cd",  this.cd);
    this.m_str = s;
  }
  return this.m_str;
}

fan.sys.Dimension.prototype.append = function(s, key, val)
{
  if (val == 0) return s;
  if (s.length > 0) s += '*';
  s += key + val;
  return s
}

/*************************************************************************
** Unit
*************************************************************************/

fan.sys.Unit = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Unit.prototype.$ctor = function() {}
fan.sys.Unit.prototype.$typeof = function() { return fan.sys.Unit.$type; }

//////////////////////////////////////////////////////////////////////////
// Database
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.fromStr = function(name, checked)
{
  if (checked === undefined) checked = true;
  var unit = fan.sys.Unit.m_units[name];
  if (unit != null || !checked) return unit;
  throw fan.sys.Err.make("Unit not found: " + name);
}

fan.sys.Unit.list = function()
{
  var arr = [];
  var units = fan.sys.Unit.m_units;
  for (p in units) arr.push(units[p]);
  return fan.sys.List.make(fan.sys.Unit.$type, arr);
}

fan.sys.Unit.quantities = function()
{
  return fan.sys.Unit.m_quantityNames;
}

fan.sys.Unit.quantity = function(quantity)
{
  var list = fan.sys.Unit.m_quantities[quantity];
  if (list == null) throw fan.sys.Err.make("Unknown unit database quantity: " + quantity);
  return list;
}

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.define = function(str)
{
  // parse
  var unit = null;
  try
  {
    unit = fan.sys.Unit.parseUnit(str);
  }
  catch (e)
  {
    var msg = str;
    if (e instanceof fan.sys.ParseErr) msg += ": " + e.m_msg;
    throw fan.sys.ParseErr.make("Unit", msg);
  }

  // register

  // check that none of the units are defined
  // TODO FIXIT: allow units to be redefined for JavaScript
  /*
  for (var i=0; i<unit.m_ids.size(); ++i)
  {
    var id = unit.m_ids.get(i);
    if (fan.sys.Unit.m_units[id] != null)
      throw fan.sys.Err.make("Unit id already defined: " + id);
  }
  */

  // this is a new definition
  for (var i=0; i<unit.m_ids.size(); ++i)
  {
    var id = unit.m_ids.get(i);
    fan.sys.Unit.m_units[id] = unit;
  }

  return unit;
}

/**
 * Parse an un-interned unit:
 *   unit := <name> [";" <symbol> [";" <dim> [";" <scale> [";" <offset>]]]]
 */
fan.sys.Unit.parseUnit = function(s)
{
  var idStrs = s;
  var c = s.indexOf(';');
  if (c > 0) idStrs = s.substring(0, c);
  var ids = fan.sys.Str.split(idStrs, 44); // ','
  if (c < 0) return fan.sys.Unit.make(ids, fan.sys.Unit.m_dimensionless, fan.sys.Float.make(1), fan.sys.Float.make(0));

  var dim = s = fan.sys.Str.trim(s.substring(c+1));
  c = s.indexOf(';');
  if (c < 0) return fan.sys.Unit.make(ids, fan.sys.Unit.parseDim(dim), fan.sys.Float.make(1), fan.sys.Float.make(0));

  dim = fan.sys.Str.trim(s.substring(0, c));
  var scale = s = fan.sys.Str.trim(s.substring(c+1));
  c = s.indexOf(';');
  if (c < 0) return fan.sys.Unit.make(ids, fan.sys.Unit.parseDim(dim), fan.sys.Float.fromStr(scale), fan.sys.Float.make(0));

  scale = fan.sys.Str.trim(s.substring(0, c));
  var offset = fan.sys.Str.trim(s.substring(c+1));
  return fan.sys.Unit.make(ids, fan.sys.Unit.parseDim(dim), fan.sys.Float.fromStr(scale), fan.sys.Float.fromStr(offset));
}

/**
 * Parse an dimension string and intern it:
 *   dim    := <ratio> ["*" <ratio>]*
 *   ratio  := <base> <exp>
 *   base   := "kg" | "m" | "sec" | "K" | "A" | "mol" | "cd"
 */
fan.sys.Unit.parseDim = function(s)
{
  // handle empty string as dimensionless
  if (s.length == 0) return fan.sys.Unit.m_dimensionless;

  // parse dimension
  var dim = new fan.sys.Dimension();
  var ratios = fan.sys.Str.split(s, 42, true);
  for (var i=0; i<ratios.size(); ++i)
  {
    var r = ratios.get(i);
    if (fan.sys.Str.startsWith(r, "kg"))  { dim.kg  = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(2))); continue; }
    if (fan.sys.Str.startsWith(r, "sec")) { dim.sec = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(3))); continue; }
    if (fan.sys.Str.startsWith(r, "mol")) { dim.mol = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(3))); continue; }
    if (fan.sys.Str.startsWith(r, "m"))   { dim.m   = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(1))); continue; }
    if (fan.sys.Str.startsWith(r, "K"))   { dim.K   = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(1))); continue; }
    if (fan.sys.Str.startsWith(r, "A"))   { dim.A   = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(1))); continue; }
    if (fan.sys.Str.startsWith(r, "cd"))  { dim.cd  = fan.sys.Int.fromStr(fan.sys.Str.trim(r.substring(2))); continue; }
    throw fan.sys.ParseErr.make("Bad ratio '" + r + "'");
  }

  // intern
  var key = dim.toString();
  var cached = fan.sys.Unit.m_dims[key];
  if (cached != null) return cached;
  fan.sys.Unit.m_dims[key] = dim;
  return dim;
}

/**
 * Private constructor.
 */
fan.sys.Unit.make = function(ids, dim, scale, offset)
{
  var instance = new fan.sys.Unit();
  instance.m_ids    = fan.sys.Unit.checkIds(ids);
  instance.m_dim    = dim;
  instance.m_scale  = scale;
  instance.m_offset = offset;
  return instance;
}

fan.sys.Unit.checkIds = function(ids)
{
  if (ids.size() == 0) throw fan.sys.ParseErr.make("No unit ids defined");
  for (var i=0; i<ids.size(); ++i) fan.sys.Unit.checkId(ids.get(i));
  return ids.toImmutable();
}

fan.sys.Unit.checkId = function(id)
{
  if (id.length == 0) throw fan.sys.ParseErr.make("Invalid unit id length 0");
  for (var i=0; i<id.length; ++i)
  {
    var code = id.charCodeAt(i);
    var ch   = id.charAt(i);
    if (fan.sys.Int.isAlpha(code) || ch == '_' || ch == '%' || ch == '/' || code > 128) continue;
    throw fan.sys.ParseErr.make("Invalid unit id " + id + " (invalid char '" + ch + "')");
  }
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.prototype.equals = function(obj) { return this == obj; }

fan.sys.Unit.prototype.hash = function() { return fan.sys.Str.hash(this.toStr()); }

fan.sys.Unit.prototype.$typeof = function() { return fan.sys.Unit.$type; }

fan.sys.Unit.prototype.toStr = function() { return this.m_ids.last(); }

fan.sys.Unit.prototype.ids = function() { return this.m_ids; }

fan.sys.Unit.prototype.name = function() { return this.m_ids.first(); }

fan.sys.Unit.prototype.symbol = function() { return this.m_ids.last(); }

fan.sys.Unit.prototype.scale = function() { return this.m_scale; }

fan.sys.Unit.prototype.offset = function() { return this.m_offset; }

fan.sys.Unit.prototype.definition = function()
{
  var s = "";
  for (var i=0; i<this.m_ids.size(); ++i)
  {
    if (i > 0) s += ", ";
    s += this.m_ids.get(i);
  }
  if (this.m_dim != fan.sys.Unit.m_dimensionless)
  {
    s += "; " + this.m_dim;
    if (this.m_scale != 1.0 || this.m_offset != 0.0)
    {
      s += "; " + this.m_scale;
      if (this.m_offset != 0.0) s += "; " + this.m_offset;
    }
  }
  return s;
}

//////////////////////////////////////////////////////////////////////////
// Dimension
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.prototype.kg = function() { return this.m_dim.kg; }

fan.sys.Unit.prototype.m = function() { return this.m_dim.m; }

fan.sys.Unit.prototype.sec = function() { return this.m_dim.sec; }

fan.sys.Unit.prototype.K = function() { return this.m_dim.K; }

fan.sys.Unit.prototype.A = function() { return this.m_dim.A; }

fan.sys.Unit.prototype.mol = function() { return this.m_dim.mol; }

fan.sys.Unit.prototype.cd = function() { return this.m_dim.cd; }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.prototype.convertTo = function(scalar, to)
{
  if (this.m_dim != to.m_dim) throw fan.sys.Err.make("Incovertable units: " + this + " and " + to);
  return ((scalar * this.m_scale + this.m_offset) - to.m_offset) / to.m_scale;
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

fan.sys.Unit.m_units      = {}; // String name -> Unit
fan.sys.Unit.m_dims       = {}; // Dimension -> Dimension
fan.sys.Unit.m_quantities = {}; // String -> List
fan.sys.Unit.m_quantityNames;
fan.sys.Unit.m_dimensionless = new fan.sys.Dimension();
fan.sys.Unit.m_dims[fan.sys.Unit.m_dimensionless.toString()] =  fan.sys.Unit.m_dimensionless;


