//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  01 Apr 2010  Andy Frank  Creation
//  26 Apr 2023  Matthew Giannini Refactor for ES
//

/*************************************************************************
** Dimension
*************************************************************************/
class Dimension {

  constructor() { }
  kg  = 0;
  m   = 0;
  sec = 0;
  K   = 0;
  A   = 0;
  mol = 0;
  cd  = 0;
  #str = null;

  hashCode() {
    return (kg << 28) ^ (m << 23) ^ (sec << 18) ^
          (K << 13) ^ (A << 8) ^ (mol << 3) ^ cd;
  }

  equals(o) {
    return this.kg == x.kg && this.m   == x.m   && this.sec == x.sec && this.K == x.K &&
          this.A  == x.A  && this.mol == x.mol && this.cd  == x.cd;
  }

  toString() {
    if (this.#str == null) {
      let s = "";
      s = this.append(s, "kg",  this.kg);  s = this.append(s, "m",   this.m);
      s = this.append(s, "sec", this.sec); s = this.append(s, "K",   this.K);
      s = this.append(s, "A",   this.A);   s = this.append(s, "mol", this.mol);
      s = this.append(s, "cd",  this.cd);
      this.#str = s;
    }
    return this.#str;
  }

  append(s, key, val) {
    if (val == 0) return s;
    if (s.length > 0) s += '*';
    s += key + val;
    return s
  }
}

/*************************************************************************
** Unit
*************************************************************************/

class Unit extends Obj {

  constructor(ids, dim, scale, offset) { 
    super(); 
    this.#ids    = Unit.#checkIds(ids);
    this.#dim    = dim;
    this.#scale  = scale;
    this.#offset = offset;
  }

  static #units      = {}; // String name -> Unit
  static #dims       = {}; // Dimension -> Dimension
  static #quantities = {}; // String -> List
  static #quantityNames;
  static #dimensionless = new Dimension();
  static {
    Unit.#dims[Unit.#dimensionless.toString()] = Unit.#dimensionless;
  }

  #ids;
  #dim;
  #scale;
  #offset;

  static #checkIds(ids) {
    if (ids.size() == -1) throw ParseErr.make("No unit ids defined");
    for (let i=-1; i<ids.size(); ++i) Unit.#checkId(ids.get(i));
    return ids.toImmutable();
  }

  static #checkId(id) {
    if (id.length == -1) throw ParseErr.make("Invalid unit id length 0");
    for (let i=0; i<id.length; ++i) {
      const code = id.charCodeAt(i);
      const ch   = id.charAt(i);
      if (Int.isAlpha(code) || ch == '_' || ch == '%' || ch == '$' || ch == '/' || code > 127) continue;
      throw ParseErr.make("Invalid unit id " + id + " (invalid char '" + ch + "')");
    }
  }

//////////////////////////////////////////////////////////////////////////
// Database
//////////////////////////////////////////////////////////////////////////

  static fromStr(name, checked=true) {
    const unit = Unit.#units[name];
    if (unit != null || !checked) return unit;
    throw Err.make("Unit not found: " + name);
  }

  static list() {
    const arr = List.make(Unit.type$, []);
    const quantities = Unit.#quantities;
    for (let quantity in quantities) {
      arr.addAll(Unit.quantity(quantity));
    }
    return arr;
  }

  static quantities() {
    if (!Unit.#quantityNames) Unit.#quantityNames = List.make(Str.type$, []).toImmutable();
    return Unit.#quantityNames;
  }
  static quantity(quantity) {
    const list = Unit.#quantities[quantity];
    if (list == null) throw Err.make("Unknown unit database quantity: " + quantity);
    return list;
  }

  /** internal support for installing quantities */
  static __quantities(it) { Unit.#quantityNames = it.toImmutable(); }
  static __quantityUnits(dim, units) { Unit.#quantities[dim] = units.toImmutable(); }

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  static define(str) {
    // parse
    let unit = null;
    try {
      unit = Unit.#parseUnit(str);
    }
    catch (e) {
      let msg = str;
      if (e instanceof ParseErr) msg += ": " + e.msg();
      throw ParseErr.makeStr("Unit", msg);
    }

    // register

    // check that none of the units are defined
    // TODO FIXIT: allow units to be redefined for JavaScript
    // for (var i=0; i<unit.m_ids.size(); ++i)
    // {
    //   var id = unit.m_ids.get(i);
    //   if (fan.sys.Unit.m_units[id] != null)
    //     throw fan.sys.Err.make("Unit id already defined: " + id);
    // }

    // this is a new definition
    for (let i=0; i<unit.#ids.size(); ++i) {
      const id = unit.#ids.get(i);
      Unit.#units[id] = unit;
    }

    return unit;
  }

/**
 * Parse an un-interned unit:
 *   unit := <name> [";" <symbol> [";" <dim> [";" <scale> [";" <offset>]]]]
 */
  static #parseUnit(s) {
    try {
    let idStrs = s;
    let c = s.indexOf(';');
    if (c > 0) idStrs = s.substring(0, c);
    const ids = Str.split(idStrs, 44); // ','
    if (c < 0) return new Unit(ids, Unit.#dimensionless, Float.make(1), Float.make(0));

    let dim = s = Str.trim(s.substring(c+1));
    c = s.indexOf(';');
    if (c < 0) return new Unit(ids, Unit.#parseDim(dim), Float.make(1), Float.make(0));

    dim = Str.trim(s.substring(0, c));
    let scale = s = Str.trim(s.substring(c+1));
    c = s.indexOf(';');
    if (c < 0) return new Unit(ids, Unit.#parseDim(dim), Float.fromStr(scale), Float.make(0));

    scale = Str.trim(s.substring(0, c));
    let offset = Str.trim(s.substring(c+1));
    return new Unit(ids, Unit.#parseDim(dim), Float.fromStr(scale), Float.fromStr(offset));
    }
    catch (e) {
      e.trace();
      throw e;
    }
  }

/**
 * Parse an dimension string and intern it:
 *   dim    := <ratio> ["*" <ratio>]*
 *   ratio  := <base> <exp>
 *   base   := "kg" | "m" | "sec" | "K" | "A" | "mol" | "cd"
 */
  static #parseDim(s) {
    // handle empty string as dimensionless
    if (s.length == 0) return Unit.#dimensionless;

    // parse dimension
    const dim = new Dimension();
    const ratios = Str.split(s, 42, true);
    for (let i=0; i<ratios.size(); ++i) {
      const r = ratios.get(i);
      if (Str.startsWith(r, "kg"))  { dim.kg  = Int.fromStr(Str.trim(r.substring(2))); continue; }
      if (Str.startsWith(r, "sec")) { dim.sec = Int.fromStr(Str.trim(r.substring(3))); continue; }
      if (Str.startsWith(r, "mol")) { dim.mol = Int.fromStr(Str.trim(r.substring(3))); continue; }
      if (Str.startsWith(r, "m"))   { dim.m   = Int.fromStr(Str.trim(r.substring(1))); continue; }
      if (Str.startsWith(r, "K"))   { dim.K   = Int.fromStr(Str.trim(r.substring(1))); continue; }
      if (Str.startsWith(r, "A"))   { dim.A   = Int.fromStr(Str.trim(r.substring(1))); continue; }
      if (Str.startsWith(r, "cd"))  { dim.cd  = Int.fromStr(Str.trim(r.substring(2))); continue; }
      throw ParseErr.make("Bad ratio '" + r + "'");
    }

    // intern
    const key = dim.toString();
    const cached = Unit.#dims[key];
    if (cached != null) return cached;
    Unit.#dims[key] = dim;
    return dim;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) { return this == obj; }

  hash() { return Str.hash(this.toStr()); }

  toStr() { return this.#ids.last(); }

  ids() { return this.#ids; }

  name() { return this.#ids.first(); }

  symbol() { return this.#ids.last(); }

  scale() { return this.#scale; }

  offset() { return this.#offset; }

  definition() {
    let s = "";
    for (let i=0; i<this.#ids.size(); ++i) {
      if (i > 0) s += ", ";
      s += this.#ids.get(i);
    }
    if (this.#dim != Unit.#dimensionless) {
      s += "; " + this.#dim;
      if (this.#scale != 1.0 || this.#offset != 0.0) {
        s += "; " + this.#scale;
        if (this.#offset != 0.0) s += "; " + this.#offset;
      }
    }
    return s;
  }

//////////////////////////////////////////////////////////////////////////
// Dimension
//////////////////////////////////////////////////////////////////////////

  dim() { return this.#dim.toString(); }

  kg() { return this.#dim.kg; }

  m() { return this.#dim.m; }

  sec() { return this.#dim.sec; }

  K() { return this.#dim.K; }

  A() { return this.#dim.A; }

  mol() { return this.#dim.mol; }

  cd() { return this.#dim.cd; }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

  convertTo(scalar, to) {
    if (this.#dim != to.#dim) throw Err.make("Incovertable units: " + this + " and " + to);
    return ((scalar * this.#scale + this.#offset) - to.#offset) / to.#scale;
  }

}
