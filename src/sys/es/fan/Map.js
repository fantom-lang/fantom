//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jan 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   14 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Map.
 */
class Map extends Obj {
  // Known Issues:
  // - ro() does not behave the same as the java impl. Java creates
  //   a shallow copy initially and saves it in #readOnlyMap field of the
  //   mutable version. Then if the mutable one gets modified, it detaches the
  //   shallow copy and does a deep clone transfer to the readOnlyMap.
  //      - So we are currently excluding verifySame() tests in the MapTest.testReadonly()

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(mt) { 
    super(); 
    this.#vals = [];
    this.#keys = null; // only used for ordered
    this.#size = 0;
    this.#readonly = false;
    this.#immutable = false;
    this.#type = mt;
    this.#def = null;
    this.#caseInsensitive = false;
    this.#ordered = false;
  }

  #vals;
  #keys;
  #size;
  #readonly;
  #immutable;
  #type;
  #def;
  #caseInsensitive;
  #ordered;

  static make(k, v) {
    let mt = null;
    if (k !== undefined && v === undefined) mt = k;
    else {
      if (k === undefined) k = Obj.type$;
      if (v === undefined) v = Obj.type$.toNullable();
      mt = new MapType(k, v);
    }
    if (mt.k.isNullable()) throw ArgErr.make(`map key type cannot be nullable: ${mt.k}`);
    return new Map(mt);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  typeof$() { return this.#type; }
  __type(it) { 
    if (!(it instanceof MapType)) throw ArgErr.make(`Must be MapType: ${it} ${it.constructor.name}`);
    this.#type = it;
  }

//////////////////////////////////////////////////////////////////////////
// Iterator
//////////////////////////////////////////////////////////////////////////

  [Symbol.iterator]() {
    const keys = this.keys();
    const sz = keys.size();
    let i = 0;
    return {
      next: () => {
        if (i < sz) {
          let k = keys.get(i);1
          const result = {value:[k, this.get(k)], done:false};
          ++i;
          return result;
        }
        return {done:true};
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  isEmpty() { return this.#size == 0; }

  size() { return this.#size; }

  get(key, defVal=this.#def) {
    let val = this.#get(key);
    if (val === undefined) {
      val = defVal;
      if (val === undefined) val = this.#def;
    }
    return val;
  }

  getChecked(key, checked=true) {
    const val = this.#get(key);
    if (val === undefined) {
      if (checked) throw UnknownKeyErr.make("" + key);
      return null;
    }
    return val;
  }

  getOrThrow(key) {
    const val = this.#get(key);
    if (val === undefined)
      throw UnknownKeyErr.make("" + key);
    return val;
  }

  containsKey(key) {
    return this.#get(key) !== undefined;
  }

  keys() {
    const array = [];
    this.#each((b) => { array.push(b.key); });
    return List.make(this.#type.k, array);
  }

  vals() {
    const array = [];
    this.#each((b) => { array.push(b.val); });
    return List.make(this.#type.v, array);
  }

  set(key, val) {
    this.#modify();
    if (key == null) 
      throw NullErr.make("key is null");
    if (!ObjUtil.isImmutable(key))
      throw NotImmutableErr.make("key is not immutable: " + ObjUtil.typeof$(key));
    this.#set(key, val);
    return this;
  }

  add(key, val) {
    this.#modify();
    if (key == null)
      throw NullErr.make("key is null");
    if (!ObjUtil.isImmutable(key))
      throw NotImmutableErr.make("key is not immutable: " + ObjUtil.typeof$(key));
    this.#set(key, val, true);
    return this;
  }

  addIfNotNull(key, val) {
    return this.addNotNull(key, val);
  }

  addNotNull(key, val) {
    if (val == null) return this;
    return this.add(key, val);
  }

  getOrAdd(key, valFunc) {
    let val = this.#get(key);
    if (val !== undefined) return val;
    val = valFunc(key);
    this.add(key, val);
    return val;
  }

  setAll(m) {
    this.#modify();
    const keys = m.keys();
    const len = keys.size();
    for (let i=0; i<len; i++) {
      const key = keys.get(i);
      this.set(key, m.get(key));
    }
    return this;
  }

  addAll(m) {
    this.#modify();
    const keys = m.keys();
    const len = keys.size();
    for (let i=0; i<len; i++) {
      const key = keys.get(i);
      this.add(key, m.get(key));
    }
    return this;
  }

  setList(list, f=null) {
    this.#modify();
    if (f == null) {
      for (let i=0; i<list.size(); ++i)
        this.set(list.get(i), list.get(i));
    }
    else {
      for (let i=0; i<list.size(); ++i)
        this.set(f(list.get(i), i), list.get(i));
    }
    return this;
  }

  addList(list, f=null) {
    this.#modify();
    if (f == null) {
      for (let i=0; i<list.size(); ++i)
        this.add(list.get(i), list.get(i));
    }
    else {
      for (let i=0; i<list.size(); ++i)
        this.add(f(list.get(i), i), list.get(i));
    }
    return this;
  }

  remove(key) {
    this.#modify();
    return this.#remove(key);
  }

  dup() {
    const dup = Map.make(this.#type.k, this.#type.v);
    if (this.#ordered) dup.ordered(true);
    if (this.#caseInsensitive) dup.caseInsensitive(true);
    dup.#def = this.#def;
    this.#each((b) => { dup.set(b.key, b.val); });
    return dup;
  }

  clear() {
    this.#modify();
    if (this.#ordered) this.#keys = [];
    this.#vals = [];
    this.#size = 0;
    return this;
  }

  caseInsensitive(it=undefined) {
    if (it === undefined) return this.#caseInsensitive;
    this.#modify();

    if (this.#type.k != Str.type$)
      throw UnsupportedErr.make("Map not keyed by Str: " + this.m_type);

    if (this.#size != 0)
      throw UnsupportedErr.make("Map not empty");

    if (it && this.ordered())
      throw UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

    this.#caseInsensitive = it;
  }

  ordered(it=undefined) {
    if (it === undefined) return this.#ordered;
    this.#modify();

    if (this.#size != 0)
      throw UnsupportedErr.make("Map not empty");

    if (it && this.caseInsensitive())
      throw UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

    this.#ordered = it;
    this.#keys = [];
  }

  def(it=undefined) {
    if (it === undefined) return this.#def;
    this.#modify();
    if (it != null && !ObjUtil.isImmutable(it))
      throw NotImmutableErr.make("def must be immutable: " + ObjUtil.typeof$(it));
    this.#def = it;
  }

  equals(that) {
    if (that != null && that instanceof Map) {
      if (!this.#type.equals(that.#type)) return false;
      if (this.#size != that.#size) return false;
      let eq = true;
      this.#each((b) => {
        eq = ObjUtil.equals(b.val, that.get(b.key));
        return eq;
      });
      return eq;
    }
    return false;
  }

  hash() {
    // TODO FIXIT
    return 0;
  }

  toStr() {
    if (this.#size == 0) return "[:]";
    let s = "";
    this.#each((b) => {
      if (s.length > 0) s += ", ";
      s += b.key + ":" + b.val;
    });
    return "[" + s + "]";
  }

  literalEncode$(out) {
    // route back to obj encoder
    out.writeMap(this);
  }

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  each(f) {
    this.#each((b) => { f(b.val, b.key); });
  }

  eachWhile(f) {
    let result = null;
    this.#each((b) => {
      let r = f(b.val, b.key);
      if (r != null) { result=r; return false; }
    });
    return result;
  }

  find(f) {
    let result = null;
    this.#each((b) => {
      if (f(b.val, b.key)) {
        result = b.val;
        return false;
      }
    });
    return result;
  }

  findAll(f) {
    const acc = Map.make(this.#type.k, this.#type.v);
    if (this.#ordered) acc.ordered(true);
    if (this.#caseInsensitive) acc.caseInsensitive(true);
    this.#each((b) => {
      if (f(b.val, b.key))
        acc.set(b.key, b.val);
    });
    return acc;
  }

  findNotNull() {
    const acc = Map.make(this.#type.k, this.#type.v.toNonNullable());
    if (this.#ordered) acc.ordered(true);
    if (this.#caseInsensitive) acc.caseInsensitive(true);
    this.#each((b) => {
      if (b.val != null)
        acc.set(b.key, b.val);
    });
    return acc;
  }

  exclude(f) {
    const acc = Map.make(this.#type.k, this.#type.v);
    if (this.#ordered) acc.ordered(true);
    if (this.#caseInsensitive) acc.caseInsensitive(true);
    this.#each((b) => {
      if (!f(b.val, b.key))
        acc.set(b.key, b.val);
    });
    return acc;
  }

  any(f) {
    if (this.#size == 0) return false;
    let any = false;
    this.#each((b) => {
      if (f(b.val, b.key)) {
        any = true;
        return false;
      }
    });
    return any;
  }

  all(f) {
    if (this.#size == 0) return true;
    let all = true;
    this.#each((b) => {
      if (!f(b.val, b.key)) {
        all = false
        return false;
      }
    });
    return all;
  }

  reduce(reduction, f) {
    this.#each((b) => { reduction = f(reduction, b.val, b.key); });
    return reduction;
  }

  map(f) {
    let r = arguments[arguments.length-1]
    if (r == null || r == Void.type$ || !(r instanceof Type)) r = Obj.type$.toNullable();

    const acc = Map.make(this.#type.k, r);
    if (this.#ordered) acc.ordered(true);
    if (this.#caseInsensitive) acc.caseInsensitive(true);
    this.#each((b) => { acc.add(b.key, f(b.val, b.key)); });
    return acc;
  }

  mapNotNull(f) {
    let r = arguments[arguments.length-1]
    if (r == null || r == Void.type$ || !(r instanceof Type)) r = Obj.type$.toNullable();

    const acc = Map.make(this.#type.k, r.toNonNullable());
    if (this.#ordered) acc.ordered(true);
    if (this.#caseInsensitive) acc.caseInsensitive(true);
    this.#each((b) => { acc.addNotNull(b.key, f(b.val, b.key)); });
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  join(sep, f=null) {
    if (this.#size == 0) return "";
    let s = "";
    this.#each((b) => {
      if (s.length > 0) s += sep;
      if (f == null)
        s += b.key + ": " + b.val;
      else
        s += f(b.val, b.key);
    });
    return s;
  }

  toCode() {
    const size = this.#size;
    let s = '';
    s += this.#type.signature();
    s += '[';
    if (size == 0) s += ':';
    let first = true;
    this.#each((b) => {
      if (first) first = false;
      else s += ', ';
      s += ObjUtil.trap(b.key, "toCode", null)
        + ':'
        + ObjUtil.trap(b.val, "toCode", null);
    });
    s += ']';
    return s;
  }

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  isRW() { return !this.#readonly; }

  isRO() { return this.#readonly; }

  rw() {
    if (!this.#readonly) return this;
    const rw = this.dup();
    rw.#readonly = false;
    return rw;
  }

  ro() {
    if (this.#readonly) return this;
    const ro = this.dup();
    ro.#readonly = true;
    return ro;
  }

  isImmutable() { return this.#immutable; }

  toImmutable() {
    if (this.#immutable) return this;
    const ro = Map.make(this.#type.k, this.#type.v);
    if (this.#ordered) ro.ordered(true);
    if (this.#caseInsensitive) ro.caseInsensitive(true);
    this.#each((b) => {
      ro.set(b.key, ObjUtil.toImmutable(b.val));
    });
    ro.#readonly = true;
    ro.#immutable = true;
    ro.#def = this.#def;
    return ro;
  }

  #modify() {
    // if readonly then throw readonly exception
    if (this.#readonly)
      throw ReadonlyErr.make("Map is readonly");
  }

//////////////////////////////////////////////////////////////////////////
// Internal
//////////////////////////////////////////////////////////////////////////

  static fromLiteral$(keys, vals, k, v) {
    const map = Map.make(k,v);
    for (let i=0; i<keys.length; i++)
      map.set(keys[i], vals[i]);
    return map;
  }

  #hashKey(key) {
    if (this.#caseInsensitive) key = Str.lower(key);
    return ObjUtil.hash(key);
  }

  #keysEqual(a, b) {
    return (this.#caseInsensitive)
      ? Str.equalsIgnoreCase(a, b)
      : ObjUtil.equals(a, b);
  }

  #get(key) {
    let b = this.#vals[this.#hashKey(key)];
    while (b !== undefined) {
      if (this.#keysEqual(b.key, key)) return b.val;
      b = b.next;
    }
    return undefined;
  }

  #set(key, val, add) {
    const n = { key:key, val:val };
    const h = this.#hashKey(key);
    let b = this.#vals[h];
    if (b === undefined) {
      if (this.#ordered) {
        n.ki = this.#keys.length;
        this.#keys.push(key);
      }
      this.#vals[h] = n;
      this.#size++;
      return
    }
    while (true) {
      if (this.#keysEqual(b.key, key)) {
        if (add) throw ArgErr.make("Key already mapped: " + key);
        b.val = val;
        return;
      }
      if (b.next === undefined) {
        if (this.#ordered) {
          n.ki = this.#keys.length;
          this.#keys.push(key);
        }
        b.next = n;
        this.#size++;
        return;
      }
      b = b.next;
    }
  }

  #remove(key) {
    const h = this.#hashKey(key);
    let b = this.#vals[h];
    if (b === undefined) return null;
    if (b.next === undefined) {
      if (this.#ordered) this.#keys[b.ki] = undefined;
      this.#vals[h] = undefined;
      this.#size--;
      const v = b.val;
      delete this.#vals[h];
      return v;
    }
    let prev = undefined;
    while (b !== undefined) {
      if (this.#keysEqual(b.key, key)) {
        const v = b.val;
        if (prev !== undefined && b.next !== undefined) prev.next = b.next;
        else if (prev === undefined) this.#vals[h] = b.next;
        else if (b.next === undefined) prev.next = undefined;
        if (this.#ordered) this.#keys[b.ki] = undefined;
        this.#size--;
        delete b.key; delete b.val; delete b.next;
        return v;
      }
      prev = b;
      b = b.next;
    }
    return null;
  }

  #each(func) {
    if (this.#ordered) {
      for (let i=0; i<this.#keys.length; i++) {
        const k = this.#keys[i];
        if (k === undefined) continue;
        const v = this.#get(k);
        if (func({key:k, ki:i, val:v }) === false) return;
      }
    }
    else {
      for (let h in this.#vals) {
        let b = this.#vals[h];
        while (b !== undefined) {
          if (func(b) === false) return;
          b = b.next;
        }
      }
    }
  }
}