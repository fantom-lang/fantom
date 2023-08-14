//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 2009  Andy Frank  Creation
//   04 Apr 2023  Matthew Giannini - refactor for ES
//

class ObjUtil {
  static hash(obj) {
    if (obj instanceof Obj) return obj.hash();

    const t = typeof obj;
    if (t === "number") return parseInt(obj);//Int.hash(obj);
    if (t === "string") return Str.hash(obj);
    if (t === "boolean") return Bool.hash(obj);

    // TODO: FIXIT
    return 0; 
  }

  static equals(a, b) {
    if (a == null) return b == null;
    if (a instanceof Obj) return a.equals(b);

    const t = typeof a;
    if (t === "number") return Int.equals(a, b);
    if (t === "string") return a === b;

    const f = a.fanType$;
    if (f === Float.type$) return Float.equals(a, b);
    if (f === Decimal.type$) return Decimal.equals(a, b);

    return a === b;
  }

  static same(a, b) {
    if (a == null) return b == null;
    if (a instanceof Obj || b instanceof Obj) return a === b;
    return ObjUtil.equals(a,b);
  }

  static compare(a, b, op) {
    if (a instanceof Obj) {
      if (b == null) return +1;
      return a.compare(b);
    }
    else if (a != null && a.fanType$ != null) {
      if (op === true && (isNaN(a) || isNaN(b))) return Number.NaN;
      return Float.compare(a, b);
    }
    else {
      if (a == null) {
        if (b != null) return -1;
        return 0;
      }
      if (b == null) return 1;
      if (a < b) return -1;
      if (a > b) return 1;
      return 0;
    }
  }

  static compareNE(a,b) { return !ObjUtil.equals(a,b); }
  static compareLT(a,b) { return ObjUtil.compare(a,b,true) <  0; }
  static compareLE(a,b) { return ObjUtil.compare(a,b,true) <= 0; }
  static compareGE(a,b) { return ObjUtil.compare(a,b,true) >= 0; }
  static compareGT(a,b) { return ObjUtil.compare(a,b,true) >  0; }

//////////////////////////////////////////////////////////////////////////
// Type
//////////////////////////////////////////////////////////////////////////

  static is(obj, type) {
    if (obj == null) return false;
    return ObjUtil.typeof$(obj).is(type);
  }

  static as(obj, type) {
    if (obj == null) return null;
    type = type.toNonNullable();
    // TODO: not sure if this is best way to handle native closures
    if (obj instanceof Function) {
      obj.fanType$ = type;
      return obj;
    }
    const t = ObjUtil.typeof$(obj);
    if (t.is(Func.type$)) return t.as(obj, type);
    if (t.is(List.type$)) return t.as(obj, type);
    if (t.is(Map.type$))  return t.as(obj, type);
    if (t.is(type)) return obj;
    return null;
  }

  static coerce(obj, type) {
    if (obj == null) {
      if (type.isNullable()) return obj;
      throw NullErr.make("Coerce to non-null");
    }

    const v = ObjUtil.as(obj, type);
    if (v == null) {
      const t = ObjUtil.typeof$(obj);
      throw CastErr.make(t + " cannot be cast to " + type);
    }

    return obj;
  }

  static typeof$(obj) {
    if (obj instanceof Obj) return obj.typeof$();
    else return Type.toFanType(obj);
  }

  static trap(obj, name, args) {
    if (obj instanceof Obj) return obj.trap(name, args);
    else return ObjUtil.doTrap(obj, name, args, Type.toFanType(obj));
  }

  static doTrap(obj, name, args, type) {
    const slot = type.slot(name, true);
    if (slot instanceof Method) {
      return slot.invoke(obj, args);
    }
    else
    {
      const argSize = (args == null) ? 0 : args.size();
      if (argSize == 0) return slot.get(obj);
      if (argSize == 1) { // one arg -> setter
        const val = args.get(0);
        slot.set(obj, val);
        return val;
      }
      throw ArgErr.make("Invalid number of args to get or set field '" + name + "'");
    }
  }

  // static invoke(f, ...args) {
  //   if (f instanceof Func) return f.call(...args);
  //   else return f.apply(null, args);
  // }

//////////////////////////////////////////////////////////////////////////
// Const
//////////////////////////////////////////////////////////////////////////

  static isImmutable(obj) {
    if (obj instanceof Obj) return obj.isImmutable();
    else if (obj == null) return true;
    else {
      if ((typeof obj) == "boolean" || obj instanceof Boolean) return true;
      if ((typeof obj) == "number"  || obj instanceof Number) return true;
      if ((typeof obj) == "string"  || obj instanceof String) return true;
      if ((typeof obj) == "function" || obj instanceof Function) return true;
      if (obj.fanType$ != null) return true;
    }
    throw UnknownTypeErr.make("Not a Fantom type: " + obj);
  }

  static toImmutable(obj) {
    if (obj instanceof Obj) return obj.toImmutable();
    else if (obj == null) return null;
    else {
      if ((typeof obj) == "boolean" || obj instanceof Boolean) return obj;
      if ((typeof obj) == "number"  || obj instanceof Number) return obj;
      if ((typeof obj) == "string"  || obj instanceof String) return obj;
      if ((typeof obj) == "function" || obj instanceof Function) return obj;
      if (obj.fanType$ != null) return obj;
    }
    throw UnknownTypeErr.make("Not a Fantom type: " + obj);
  }

//////////////////////////////////////////////////////////////////////////
// with
//////////////////////////////////////////////////////////////////////////

  static with$(self, f) {
    if (self instanceof Obj) {
      return self.with$(f);
    }
    else {
      f(self);
      return self;
    }
  }

//////////////////////////////////////////////////////////////////////////
// toStr
//////////////////////////////////////////////////////////////////////////

  static toStr(obj) {
    if (obj == null) return "null";
    if (typeof obj == "string") return obj;
  //  if (obj.constructor == Array) return fan.sys.List.toStr(obj);

    // TODO - can't for the life of me figure how the
    // heck Error.toString would ever try to call Obj.toStr
    // so trap it for now
  //  if (obj instanceof Error) return Error.prototype.toString.call(obj);

// TEMP
if (obj.fanType$ === Float.type$) return Float.toStr(obj);

    return obj.toString();
  }

  static echo(obj) {
    if (obj === undefined) obj = "";
    let s = ObjUtil.toStr(obj);
    try { console.log(s); }
    catch (e1)
    {
      try { print(s + "\n"); }
      catch (e2) {} //alert(s); }
    }
  }

}