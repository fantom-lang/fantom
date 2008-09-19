//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   7 Jul 07  Brian Frank  Split from Method
//
package fan.sys;

/**
 * Func models an executable subroutine.
 */
public abstract class Func
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Constructor
   */
  public Func(Type returns, List params)
  {
    this.returns = returns;
    this.params  = params;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.FuncType; }

  public Type returns() { return returns; }

  public List params() { return params.ro(); }

  public abstract Bool isImmutable();

  public abstract Method method();

  public abstract Obj call(List args);
  public abstract Obj callOn(Obj target, List args);
  public abstract Obj call0();
  public abstract Obj call1(Obj a);
  public abstract Obj call2(Obj a, Obj b);
  public abstract Obj call3(Obj a, Obj b, Obj c);
  public abstract Obj call4(Obj a, Obj b, Obj c, Obj d);
  public abstract Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e);
  public abstract Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f);
  public abstract Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g);
  public abstract Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h);

//////////////////////////////////////////////////////////////////////////
// Indirect
//////////////////////////////////////////////////////////////////////////

  public static final int MaxIndirectParams = 8;  // max callX()

  /**
   * Constructor used by Indirect.
   */
  protected Func(FuncType funcType)
  {
    this.returns = funcType.ret;
    this.params  = funcType.toMethodParams();
  }

  /**
   * Indirect is the base class for the IndirectX classes, which are
   * used as the common base classes for closures and general purpose
   ** functions.  An Indirect method takes a funcType for it's type,
   * and also extends Func for the call() implementations.
   */
  public static abstract class Indirect extends Func
  {
    protected Indirect(FuncType type) { super(type); this.type = type; }

    public Str  name()  { return Str.make(getClass().getName()); }
    public Type type()  { return type; }
    public Str  toStr() { return type.signature(); }
    public Bool isImmutable() { return Bool.False; }
    public Method method() { return null; }
    public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + type.params.length).val; }

    public final Obj callOn(Obj obj, List args)
    {
      List flat = args.dup();
      flat.insert(Int.Zero, obj);
      return call(flat);
    }

    FuncType type;
  }

  public static abstract class Indirect0 extends Indirect
  {
    protected Indirect0(FuncType type) { super(type); }
    public final Obj call(List args) { return call0(); }
    public abstract Obj call0();
    public final Obj call1(Obj a) { return call0(); }
    public final Obj call2(Obj a, Obj b) { return call0(); }
    public final Obj call3(Obj a, Obj b, Obj c) { return call0(); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { return call0(); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call0(); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call0(); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call0(); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call0(); }
  }

  public static abstract class Indirect1 extends Indirect
  {
    protected Indirect1(FuncType type) { super(type); }
    public final Obj call(List args) { return call1(args.get(0)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public abstract Obj call1(Obj a);
    public final Obj call2(Obj a, Obj b) { return call1(a); }
    public final Obj call3(Obj a, Obj b, Obj c) { return call1(a); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { return call1(a); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call1(a); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call1(a); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call1(a); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call1(a); }
  }

  public static abstract class Indirect2 extends Indirect
  {
    protected Indirect2(FuncType type) { super(type); }
    public final Obj call(List args) { return call2(args.get(0), args.get(1)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public abstract Obj call2(Obj a, Obj b);
    public final Obj call3(Obj a, Obj b, Obj c) { return call2(a, b); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { return call2(a, b); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call2(a, b); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call2(a, b); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call2(a, b); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call2(a, b); }
  }

  public static abstract class Indirect3 extends Indirect
  {
    protected Indirect3(FuncType type) { super(type); }
    public final Obj call(List args) { return call3(args.get(0), args.get(1), args.get(2)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public abstract Obj call3(Obj a, Obj b, Obj c);
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { return call3(a, b, c); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call3(a, b, c); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call3(a, b, c); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call3(a, b, c); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call3(a, b, c); }
  }

  public static abstract class Indirect4 extends Indirect
  {
    protected Indirect4(FuncType type) { super(type); }
    public final Obj call(List args) { return call4(args.get(0), args.get(1), args.get(2), args.get(3)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public abstract Obj call4(Obj a, Obj b, Obj c, Obj d);
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call4(a, b, c, d); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call4(a, b, c, d); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call4(a, b, c, d); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call4(a, b, c, d); }
  }

  public static abstract class Indirect5 extends Indirect
  {
    protected Indirect5(FuncType type) { super(type); }
    public final Obj call(List args) { return call5(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
    public abstract Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e);
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call5(a, b, c, d, e); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call5(a, b, c, d, e); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call5(a, b, c, d, e); }
  }

  public static abstract class Indirect6 extends Indirect
  {
    protected Indirect6(FuncType type) { super(type); }
    public final Obj call(List args) { return call6(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
    public abstract Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f);
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call6(a, b, c, d, e, f); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call6(a, b, c, d, e, f); }
  }

  public static abstract class Indirect7 extends Indirect
  {
    protected Indirect7(FuncType type) { super(type); }
    public final Obj call(List args) { return call7(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
    public abstract Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g);
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call7(a, b, c, d, e, f, g); }
  }

  public static abstract class Indirect8 extends Indirect
  {
    protected Indirect8(FuncType type) { super(type); }
    public final Obj call(List args) { return call8(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { throw tooFewArgs(7); }
    public abstract Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h);
  }

  public static abstract class IndirectX extends Indirect
  {
    protected IndirectX(FuncType type) { super(type); }
    public abstract Obj call(List args);
    public final Obj call0() { throw tooFewArgs(0); }
    public final Obj call1(Obj a) { throw tooFewArgs(1); }
    public final Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
    public final Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { throw tooFewArgs(7); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { throw tooFewArgs(8); }
  }

//////////////////////////////////////////////////////////////////////////
// Curry
//////////////////////////////////////////////////////////////////////////

  public final Func curry(List args)
  {
    if (args.sz() == 0) return this;
    if (args.sz() > params.sz()) throw ArgErr.make("args.size > params.size").val;

    Type[] newParams = new Type[params.sz()-args.sz()];
    for (int i=0; i<newParams.length; ++i)
      newParams[i] = ((Param)params.get(args.sz()+i)).of;

    FuncType newType = new FuncType(newParams, this.returns);
    return new CurryFunc(newType, this, args);
  }

  static class CurryFunc extends Func
  {
    CurryFunc(FuncType type, Func orig, List bound)
    {
      super(type);
      this.type  = type;
      this.orig  = orig;
      this.bound = bound.ro();
    }

    public Str  name()  { return Str.make(getClass().getName()); }
    public Type type()  { return type; }
    public Str  toStr() { return type.signature(); }
    public Bool isImmutable() { return Bool.False; }
    public Method method() { return null; }

    // this isn't a very optimized implementation
    public final Obj call0() { return call(new List(Sys.ObjType, new Obj[] {})); }
    public final Obj call1(Obj a) { return call(new List(Sys.ObjType, new Obj[] {a})); }
    public final Obj call2(Obj a, Obj b) { return call(new List(Sys.ObjType, new Obj[] {a,b})); }
    public final Obj call3(Obj a, Obj b, Obj c) { return call(new List(Sys.ObjType, new Obj[] {a,b,c})); }
    public final Obj call4(Obj a, Obj b, Obj c, Obj d) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d})); }
    public final Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e})); }
    public final Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f})); }
    public final Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f,g})); }
    public final Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f,g,h})); }

    public Obj call(List args)
    {
      int origSize = orig.params.sz();
      if (origSize == bound.sz()) return orig.call(bound);

      Obj[] temp = new Obj[origSize];
      bound.copyInto(temp, 0, bound.sz());
      args.copyInto(temp, bound.sz(), temp.length-bound.sz());
      return orig.call(new List(Sys.ObjType, temp));
    }

    public final Obj callOn(Obj obj, List args)
    {
      int origSize = orig.params.sz();
      Obj[] temp = new Obj[origSize];
      bound.copyInto(temp, 0, bound.sz());
      temp[bound.sz()] = obj;
      args.copyInto(temp, bound.sz()+1, temp.length-bound.sz()-1);
      return orig.call(new List(Sys.ObjType, temp));
    }

    final FuncType type;
    final Func orig;
    final List bound;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Object[] noArgs = new Object[0];

  final Type returns;
  final List params;

}
