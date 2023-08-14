//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 May 2011  Andy Frank  Creation
//   12 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Facets manages facet meta-data as a Str:Obj map.
 */
class Facets extends Obj {
  constructor(map) {
    super();
    this.#map = map;
    this.#list = null;
  }

  #map;
  #list;

  static #emptyVal = null;
  static #transientVal = null;

  empty() {
    let x = Facets.#emptyVal;
    if (x == null) {
      x = new Facets({});
      Facets.#emptyVal = x;
    }
    return x;
  }

  makeTransient() {
    let x = Facets.#transientVal;
    if (x == null)
    {
      let m = {};
      m[Transient.type$.qname()] = "";
      x = new Facets(m);
      Facets.#transientVal = x;
    }
    return x;
  }

  list() {
    if (this.#list == null)
    {
      this.#list = List.make(Facet.type$);
      for (let key in this.#map)
      {
        let type = Type.find(key);
        this.#list.add(this.get(type, true));
      }
      this.#list = this.#list.toImmutable();
    }
    return this.#list;
  }

  get(type, checked=true) {
    let val = this.#map[type.qname()];
    if (typeof val == "string")
    {
      let f = this.decode(type, val);
      this.#map[type.qname()] = f;
      return f;
    }
    //if (val instanceof fan.sys.Facet)
    if (val != null) return val;
    if (checked) throw UnknownFacetErr.make(type.qname());
    return null;
  }

  decode(type, s) {
    try
    {
      // if no string use make/defVal
      if (s.length == 0) return type.make();

      // decode using normal Fantom serialization
      return fanx_ObjDecoder.decode(s);
    }
    catch (e)
    {
      var msg = "ERROR: Cannot decode facet " + type + ": " + s;
      ObjUtil.echo(msg);
      delete this.#map[type.qname()];
      throw IOErr.make(msg, e);
    }
  }

  dup() {
    let dup = {};
    for (let key in this.#map) dup[key] = this.#map[key];
    return new Facets(dup);
  }

  inherit(facets) {
    let keys = [];
    for (let key in facets.#map) keys.push(key);
    if (keys.length == 0) return;

    this.#list = null;
    for (let i=0; i<keys.length; i++)
    {
      let key = keys[i];

      // if already mapped skipped
      if (this.#map[key] != null) continue;

      // if not an inherited facet skip it
      let type = Type.find(key);
      let meta = type.facet(FacetMeta.type$, false);
      if (meta == null || !meta.inherited) continue;

      // inherit
      this.#map[key] = facets.#map[key];
    }
  }
}