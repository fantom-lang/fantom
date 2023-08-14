//
// Copyright (c) 2019, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 2019  Matthew Giannini  Creation
//   22 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * ConcurrentMap
 */
class ConcurrentMap extends sys.Obj {
  constructor() {
    super();
    this.#map = sys.Map.make(sys.Obj.type$, sys.Obj.type$);
  }

  #map;

  static make(capacity) {
    const self = new ConcurrentMap();
    return self;
  }

  typeof$() { return ConcurrentMap.type$; }

  isEmpty() { return this.#map.isEmpty(); }

  size() { return this.#map.size(); }

  get(key) { return this.#map.get(key); }

  set(key, val) { this.#map.set(key, this.#checkImmutable(val)); }

  getAndSet(key, val) {
    const old = this.get(key);
    this.set(key, val);
    return old;
  }

  add(key, val) {
    if (this.containsKey(key)) throw sys.Err(`Key already mapped: ${key}`);
    this.#map.add(key, this.#checkImmutable(val));
  }

  getOrAdd(key, defVal) {
    let val = this.get(key);
    if (val == null) this.add(key, val = defVal);
    return val;
  }

  setAll(m) {
    if (m.isImmutable()) this.#map.setAll(m);
    else {
      const vals = m.vals();
      for (let i=0; i<vals.size(); ++i) { this.#checkImmutable(vals.get(i)); }
      this.#map.setAll(m);
    }
    return this;
  }

  remove(key) { return this.#map.remove(key); }

  clear() { this.#map.clear(); }

  each(f) { this.#map.each(f); }

  eachWhile(f) { return this.#map.eachWhile(f); }

  containsKey(key) { return this.#map.containsKey(key); }

  keys(of) {
    const array = [];
    this.#map.keys().each((key) => { array.push(key); });
    return sys.List.make(of, array);
  }

  vals(of) {
    const array = [];
    this.#map.vals().each((val) => { array.push(val); });
    return sys.List.make(of, array);
  }

  #checkImmutable(val) {
    if (sys.ObjUtil.isImmutable(val)) return val;
    throw sys.NotImmutableErr.make();
  }
}