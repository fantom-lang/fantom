//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   03 Dec 2009  Andy Frank  Wrap Array object
//   04 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * List
 */
class List extends Obj {
  // Known Issues:
  // - capacity/sizing implementation is inconsistent with Java impl so those
  //   tests fail: testSizeCapacity()

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  static make(of, values) {
    if (of == null) throw NullErr.make("of not defined", new Error());
    if (values === undefined || typeof(values) == "number") values = [];
    return new List(of, values);
  }

  static makeObj(capacity) {
    return List.make(Obj.type$);
  }

  constructor(of, values) {
    super();
    this.#of = of;
    this.#size = values.length;
    this.#values = values;
    this.#readonly = false;
    this.#readonlyList= null;
    this.#immutable = false;
  }

  #of;
  #size;
  #values;
  #readonly;
  #readonlyList;
  #immutable;

//////////////////////////////////////////////////////////////////////////
// Internal Access
//////////////////////////////////////////////////////////////////////////

  __values() { return this.#values; }

//////////////////////////////////////////////////////////////////////////
// Iterator
//////////////////////////////////////////////////////////////////////////

  [Symbol.iterator]() {
    let i = 0;
    return {
      next: () => {
        if (i < this.#size) {
          const result = {value: this.#values[i], done: false};
          ++i;
          return result;
        }
        return {done: true}
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  typeof$() { return this.#of.toListOf(); }

  of() { return this.#of;}

  isEmpty() { return  this.#size == 0; }

  size(it=undefined) { 
    if (it === undefined) return this.#size; 
    this.#modify();
    // const oldSize = this.#size;
    const newSize = it;
    for (let i=0; this.#size+i<newSize; i++)
      this.#values.push(null);
    this.#size = newSize;
  }

  capacity(it=undefined) {
    if (it === undefined) return this.#values.length;
    this.#modify();
    if (it < this.#size) throw ArgErr.make("capacity < size");
    // TODO:??? - no-op
    // fill with nulls
    // this.#values = this.#values.concat(new Array(it-this.#values.length).fill(null));
  }

  get(index) {
    if (index < 0) index = this.#size + index;
    if (index >= this.#size || index < 0) throw IndexErr.make(index);
    return this.#values[index];
  }

  getSafe(index, def=null) {
    if (index < 0) index = this.#size + index;
    if (index >= this.#size || index < 0) return def;
    return this.#values[index];
  }

  getRange(range) {
    const s = range.__start(this.#size);
    const e = range.__end(this.#size);
    if (e+1 < s || s < 0) throw IndexErr.make(range);
    return List.make(this.#of, this.#values.slice(s, e+1));
  }

  containsSame(value) {
    const size = this.#size;
    const vals = this.#values;
    for (let i=0; i<size; i++)
      if (value === vals[i])
        return true;
    return false;
  }

  contains(value) { return this.index(value) != null; }

  containsAll(list) {
    for (let i=0; i<list.size(); ++i)
      if (this.index(list.get(i)) == null)
        return false;
    return true;
  }

  containsAny(list) {
    for (let i=0; i<list.size(); ++i)
      if (this.index(list.get(i)) != null)
        return true;
    return false;
  }
  
  index(value, off=0) {
    const size = this.#size;
    const values = this.#values;
    if (size == 0) return null;
    let start = off;
    if (start < 0) start = size + start;
    if (start >= size || start < 0) throw IndexErr.make(off);

    if (value == null) {
      for (let i=start; i<size; ++i)
        if (values[i] == null)
          return i;
    }
    else {
      for (let i=start; i<size; ++i) {
        const obj = values[i];
        if (obj != null && ObjUtil.equals(obj, value))
          return i;
      }
    }
    return null;
  }

  indexr(value, off=-1) {
    const size = this.#size;
    const values = this.#values;
    if (size == 0) return null;
    let start = off;
    if (start < 0) start = size + start;
    if (start >= size || start < 0) throw IndexErr.make(off);

    if (value == null) {
      for (let i=start; i>=0; --i)
        if (values[i] == null)
          return i;
    }
    else {
      for (let i=start; i>=0; --i) {
        const obj = values[i];
        if (obj != null && ObjUtil.equals(obj, value))
          return i;
      }
    }
    return null;
  }

  indexSame(value, off=0) {
    const size = this.#size;
    const values = this.#values;
    if (size == 0) return null;
    let start = off;
    if (start < 0) start = size + start;
    if (start >= size || start < 0) throw IndexErr.make(off);

    for (let i=start; i<size; i++)
      if (value === values[i])
        return i;
    return null;
  }

  first() {
    if (this.#size == 0) return null;
    return this.#values[0];
  }

  last() {
    if (this.#size == 0) return null;
    return this.#values[this.#size-1];
  }

  dup() { return List.make(this.#of, this.#values.slice(0)); }

  hash() {
    let hash = 33;
    const size = this.#size;
    const vals = this.#values;
    for (let i=0; i<size; ++i) {
      const obj = vals[i];
      hash = (31*hash) + (obj == null ? 0 : ObjUtil.hash(obj));
    }
    return hash;
  }

  equals(that) {
    if (that instanceof List) {
      if (!this.#of.equals(that.#of)) return false;
      if (this.#size != that.#size) return false;
      for (let i=0; i<this.#size; ++i)
        if (!ObjUtil.equals(this.#values[i], that.#values[i]))
          return false;
      return true;
    }
    return false;
  }

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  set(index, value) {
    this.#modify();
    //try
    //{
      if (index < 0) index = this.#size + index;
      if (index >= this.#size || index < 0) throw IndexErr.make(index);
      this.#values[index] = value;
      return this;
    //}
    //catch (ArrayIndexOutOfBoundsException e)
    //{
    //  throw IndexErr.make(index).val;
    //}
    //catch (ArrayStoreException e)
    //{
    //  throw CastErr.make("Setting '" + FanObj.type(value) + "' into '" + of + "[]'").val;
    //}
  }

  add(value) {
    // modify in #insert$
    return this.#insert$(this.#size, value);
  }

  addIfNotNull(value) { return this.addNotNull(value); }

  addNotNull(value) {
    if (value == null) return this;
    return this.add(value);
  }

  addAll(list) {
    // modify in #insertAll$
    return this.#insertAll$(this.#size, list);
  }

  insert(index, value) {
    // modify in #insert$
    if (index < 0) index = this.#size + index;
    if (index > this.#size || index < 0) throw IndexErr.make(index);
    return this.#insert$(index, value);
  }

  #insert$(i, value) {
    //try
    //{
      this.#modify();
      this.#values.splice(i, 0, value);
      this.#size++;
      return this;
    //}
    //catch (ArrayStoreException e)
    //{
    //  throw CastErr.make("Adding '" + FanObj.type(value) + "' into '" + of + "[]'").val;
    //}
  }

  insertAll(index, list) {
    // modify in #insertAll$
    if (index < 0) index = this.#size + index;
    if (index > this.#size || index < 0) throw IndexErr.make(index);
    return this.#insertAll$(index, list);
  }

  #insertAll$(i, list) {
    // TODO: worth it to optimze small lists?
    // splice(i, 0, list[0], list[1], list[2])
    this.#modify();
    if (list.#size == 0) return this;
    let vals = list.#values;
    if (this.#values === vals) vals = vals.slice(0);
    for (let j=0; j<list.#size; j++)
      this.#values.splice(i+j, 0, vals[j]);
    this.#size += list.#size;
    return this;
  }

  remove(value) {
    // modify in removeAt
    const index = this.index(value);
    if (index == null) return null;
    return this.removeAt(index);
  }

  removeSame(value) {
    // modify in removeAt
    const index = this.indexSame(value);
    if (index == null) return null;
    return this.removeAt(index);
  }

  removeAt(index) {
    this.#modify();
    if (index < 0) index = this.#size + index;
    if (index >= this.#size || index < 0) throw IndexErr.make(index);
    const old = this.#values.splice(index, 1);
    this.#size--;
    return old[0];
  }

  removeRange(r) {
    this.#modify();
    const s = r.__start(this.#size);
    const e = r.__end(this.#size);
    const n = e - s + 1;
    if (n < 0) throw IndexErr.make(r);
    this.#values.splice(s, n);
    this.#size -= n;
    return this;
  }

  removeAll(toRemove) {
    this.#modify();
    for (let i=0; i<toRemove.#size; i++)
      this.remove(toRemove.get(i));
    return this;
  }

  trim() {
    this.#modify();
    return this;
  }

  clear() {
    this.#modify();
    this.#values.splice(0, this.#size);
    this.#size = 0;
    return this;
  }

  fill(value, times) {
    this.#modify();
    for (let i=0; i<times; i++) this.add(value);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

peek() {
  if (this.#size == 0) return null;
  return this.#values[this.#size-1];
}

pop() {
  // modify in removeAt()
  if (this.#size == 0) return null;
  return this.removeAt(-1);
}

push(obj) {
  // modify in add()
  return this.add(obj);
}

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  each(f) {
    for (let i=0; i<this.#size; ++i)
      f(this.#values[i], i);
  }

  eachr(f) {
    for (let i=this.#size-1; i>=0; --i)
      f(this.#values[i], i)
  }

  eachNotNull(f) {
    for (let i=0; i<this.#size; ++i)
      if (this.#values[i] != null)
        f(this.#values[i], i);
  }

  eachRange(r, f) {
    const s = r.__start(this.#size);
    const e = r.__end(this.#size);
    const n = e - s + 1;
    if (n < 0) throw IndexErr.make(r);

    for (let i=s; i<=e; ++i)
      f(this.#values[i], i);
  }

  eachWhile(f) {
    for (let i=0; i<this.#size; ++i) {
      const r = f(this.#values[i], i);
      if (r != null) return r;
    }
    return null;
  }

  eachrWhile(f) {
    for (let i=this.#size-1; i>=0; --i) {
      const r = f(this.#values[i], i);
      if (r != null) return r;
    }
    return null;
  }

  find(f) {
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) == true)
        return this.#values[i]
    return null;
  }

  findIndex(f) {
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) == true)
        return i;
    return null;
  }

  findAll(f) {
    const acc = List.make(this.#of);
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) == true)
        acc.add(this.#values[i]);
    return acc;
  }

  findType(t) {
    const acc = List.make(t);
    for (let i=0; i<this.#size; ++i) {
      const item = this.#values[i];
      if (item != null && ObjUtil.typeof$(item).is(t))
        acc.add(item);
    }
    return acc;
  }

  findNotNull() {
    const acc = List.make(this.#of.toNonNullable());
    for (let i=0; i<this.#size; ++i) {
      const item = this.#values[i];
      if (item != null)
        acc.add(item);
    }
    return acc;
  }

  exclude(f) {
    const acc = List.make(this.#of);
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) != true)
        acc.add(this.#values[i]);
    return acc;
  }

  any(f) {
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) == true)
        return true;
    return false;
  }

  all(f) {
    for (let i=0; i<this.#size; ++i)
      if (f(this.#values[i], i) != true)
        return false;
    return true;
  }

  reduce(reduction, f) {
    for (let i=0; i<this.#size; ++i)
      reduction = f(reduction, this.#values[i], i)
    return reduction;
  }

  map(f) {
    let r = arguments[arguments.length-1]
    if (r == null || r == Void.type$ || !(r instanceof Type)) r = Obj.type$.toNullable();

    const acc = List.make(r);
    for (let i=0; i<this.#size; ++i)
      acc.add(f(this.#values[i], i));
    return acc;
  }

  mapNotNull(f) {
    let r = arguments[arguments.length-1]
    if (r == null || r == Void.type$ || !(r instanceof Type)) r = Obj.type$.toNullable();

    const acc = List.make(r.toNonNullable());
    for (let i=0; i<this.#size; ++i)
      acc.addNotNull(f(this.#values[i], i))
    return acc;
  }

  flatMap(f) {
    const r = arguments[arguments.length-1]
    let of = (r == null || r == Void.type$ || !(r instanceof Type)) ? null : r.v;
    if (of == null) of = Obj.type$.toNullable();

    const acc = List.make(of);
    for (let i=0; i<this.#size; ++i)
      acc.addAll(f(this.#values[i], i))
    return acc;
  }

  groupBy(f) {
    let r = arguments[arguments.length-1]
    if (r == null || r == Void.type$ || !(r instanceof Type)) r = Obj.type$.toNullable();
    const acc = Map.make(r, this.typeof$());
    return this.groupByInto(acc, f);
  }

  groupByInto(acc, f) {
    const mapValType = acc.typeof$().v;
    const bucketOfType = mapValType.v;
    // const arity1 = f.arity() == 1;
    for (let i=0; i<this.#size; ++i) {
      const val = this.#values[i];
      const key = f(val, i);
      let bucket = acc.get(key);
      if (bucket == null) {
        bucket = List.make(bucketOfType, 8);
        acc.set(key, bucket);
      }
      bucket.add(val);
    }
    return acc;
  }

  max(f=null) {
    if (this.#size == 0) return null;
    let max = this.#values[0];
    for (let i=1; i<this.#size; ++i) {
      const s = this.#values[i];
      if (f == null)
        max = (s != null && s > max) ? s : max;
      else
        max = (s != null && f(s, max) > 0) ? s : max;
    }
    return max;
  }

  min(f=null) {
    if (this.#size == 0) return null;
    let min = this.#values[0];
    for (let i=1; i<this.#size; ++i) {
      const s = this.#values[i];
      if (f == null)
        min = (s == null || s < min) ? s : min;
      else
        min = (s == null || f(s, min) < 0) ? s : min;
    }
    return min;
  }

  unique() {
    const dups = new js.Map();
    const acc = List.make(this.#of);
    for (let i=0; i<this.#size; ++i) {
      const v = this.#values[i];
      const key = v;
      if (dups.get(key) === undefined) {
        dups.set(key, this);
        acc.add(v);
      }
    }
    return acc;
  }

  union(that) {
    const dups = Map.make(Obj.type$, Obj.type$);
    const acc = List.make(this.#of);

    // first me
    for (let i=0; i<this.#size; ++i) {
      const v = this.#values[i];
      let key = v;
      if (key == null) key = "__null_key__";
      if (dups.get(key) == null) {
        dups.set(key, this);
        acc.add(v);
      }
    }

    // then him
    for (let i=0; i<that.#size; ++i) {
      const v = that.#values[i];
      let key = v;
      if (key == null) key = "__null_key__";
      if (dups.get(key) == null) {
        dups.set(key, this);
        acc.add(v);
      }
    }

    return acc;
  }

  intersection(that) {
    // put other list into map
    const dups = Map.make(Obj.type$, Obj.type$);
    for (let i=0; i<that.#size; ++i) {
      const v = that.#values[i];
      let key = v;
      if (key == null) key = "__null_key__";
      dups.set(key, this);
    }

    // now walk this list and accumulate
    // everything found in the dups map
    const acc = List.make(this.#of);
    for (let i=0; i<this.#size; ++i) {
      const v = this.#values[i];
      let key = v;
      if (key == null) key = "__null_key__";
      if (dups.get(key) != null) {
        acc.add(v);
        dups.remove(key);
      }
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  isRW() { return !this.#readonly; }

  isRO() { return this.#readonly; }

  rw() {
    if (!this.#readonly) return this;

    const rw = List.make(this.#of, this.#values.slice(0));
    rw.#readonly = false;
    rw.#readonlyList = this;
    return rw;
  }

  ro() {
    if (this.#readonly) return this;
    if (this.#readonlyList == null)
    {
      const ro = List.make(this.#of, this.#values.slice(0));
      ro.#readonly = true;
      this.#readonlyList = ro;
    }
    return this.#readonlyList;
  }

  isImmutable() {
    return this.#immutable;
  }

  toImmutable() {
    if (this.#immutable) return this;

    // make safe copy
    let temp = [];
    for (let i=0; i<this.#size; ++i)
    {
      let item = this.#values[i];
      if (item != null) {
        if (item instanceof List) item = item.toImmutable();
        else if (item instanceof Map) item = item.toImmutable();
        else if (!ObjUtil.isImmutable(item))
          throw NotImmutableErr.make("Item [" + i + "] not immutable " + Type.of(item));
      }
      temp[i] = item;
    }

    // return new immutable list
    let ro = List.make(this.#of, temp);
    ro.#readonly = true;
    ro.#immutable = true;
    return ro;
  }

  #modify() {
    // if readonly then throw readonly exception
    if (this.#readonly)
      throw ReadonlyErr.make("List is readonly");

    // if we have a cached readonlyList, then detach
    // it so it remains immutable
    if (this.#readonlyList != null)
    {
      this.#readonlyList.#values = this.#values.slice(0);
      this.#readonlyList = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  sort(f=null) {
    this.#modify();
    if (f != null) 
      this.#values.sort(f);
    else 
      this.#values.sort((a,b)  => ObjUtil.compare(a, b, false));
    return this;
  }

  sortr(f=null) {
    this.#modify();
    if (f != null) 
      this.#values.sort((a,b) => f(b, a));
    else
      this.#values.sort((a,b) => ObjUtil.compare(b, a, false));
    return this;
  }

  binarySearch(key, f=null) {
    const c = f != null
      ? (item, index) => { return f(key, item); }
      : (item, index) => { return ObjUtil.compare(key,item,false); }
    return this.#doBinaryFind(c);
  }

  binaryFind(f) { return this.#doBinaryFind(f); }

  #doBinaryFind(f) {
    let low = 0;
    let high = this.#size - 1;
    while (low <= high)
    {
      const mid = Math.floor((low + high) / 2);
      const cmp = f(this.#values[mid], mid);
      if (cmp > 0) low = mid + 1;
      else if (cmp < 0) high = mid - 1;
      else return mid;
    }
    return -(low + 1);
  }


  reverse() {
    this.#modify();
    const mid = this.#size/2;
    for (let i=0; i<mid; ++i) {
      const a = this.#values[i];
      const b = this.#values[this.#size-i-1];
      this.#values[i] = b;
      this.#values[this.#size-i-1] = a;
    }
    return this;
  }

  swap(a, b) {
    // modify in set()
    const temp = this.get(a);
    this.set(a, this.get(b));
    this.set(b, temp);
    return this;
  }

  moveTo(item, toIndex) {
    this.#modify();
    let curIndex = this.index(item);
    if (curIndex == null) return this;
    if (curIndex == toIndex) return this;
    this.removeAt(curIndex);
    if (toIndex == -1) return this.add(item);
    if (toIndex < 0) ++toIndex;
    return this.insert(toIndex, item);
  }

  flatten() {
    const acc = List.make(Obj.type$.toNullable());
    this.#doFlatten(acc);
    return acc;
  }

  #doFlatten(acc) {
    for (let i=0; i<this.#size; ++i) {
      const item = this.#values[i];
      if (item instanceof List)
        item.#doFlatten(acc);
      else
        acc.add(item);
    }
  }

  random() {
    if (this.#size == 0) return null;
    let i = Math.floor(Math.random() * 4294967296);
    if (i < 0) i = -i;
    return this.#values[i % this.#size];
  }

  shuffle() {
    this.#modify();
    for (let i=0; i<this.#size; ++i) {
      const randi = Math.floor(Math.random() * (i+1));
      const temp = this.#values[i];
      this.#values[i] = this.#values[randi];
      this.#values[randi] = temp;
    }
    return this;
  }


//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  join(sep="", f=null) {
    if (this.#size === 0) return "";
    if (this.#size === 1) {
      const v = this.#values[0];
      if (f != null) return f(v, 0);
      if (v == null) return "null";
      return ObjUtil.toStr(v);
    }

    let s = ""
    for (let i=0; i<this.#size; ++i) {
      if (i > 0) s += sep;
      if (f == null)
        s += this.#values[i];
      else
        s += f(this.#values[i], i);
    }
    return s;
  }

  toStr() {
    if (this.#size == 0) return "[,]";
    var s = "[";
    for (let i=0; i<this.#size; i++) {
      if (i > 0) s += ", ";
      s += this.#values[i];
    }
    s += "]";
    return s;
  }

  toCode() {
    let s = '';
    s += this.#of.signature();
    s += '[';
    if (this.#size == 0) s += ',';
    for (let i=0; i<this.#size; ++i) {
      if (i > 0) s += ', ';
      s += ObjUtil.trap(this.#values[i], "toCode", null);
    }
    s += ']';
    return s;
  }

  literalEncode$(out) {
    // route back to obj encoder
    out.writeList(this);
  }

}
