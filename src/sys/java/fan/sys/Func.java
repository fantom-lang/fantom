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

  public abstract boolean isImmutable();

  public abstract Method method();

  public abstract Object call(List args);
  public abstract Object callOn(Object target, List args);
  public abstract Object call0();
  public abstract Object call1(Object a);
  public abstract Object call2(Object a, Object b);
  public abstract Object call3(Object a, Object b, Object c);
  public abstract Object call4(Object a, Object b, Object c, Object d);
  public abstract Object call5(Object a, Object b, Object c, Object d, Object e);
  public abstract Object call6(Object a, Object b, Object c, Object d, Object e, Object f);
  public abstract Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g);
  public abstract Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h);

  public final Func toImmutable()
  {
    if (isImmutable()) return this;
    throw NotImmutableErr.make().val;
  }

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

    public String  name()  { return getClass().getName(); }
    public Type type()  { return type; }
    public String  toStr() { return type.signature(); }
    public boolean isImmutable() { return false; }
    public Method method() { return null; }
    public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + type.params.length).val; }

    public final Object callOn(Object obj, List args)
    {
      List flat = args.dup();
      flat.insert(0L, obj);
      return call(flat);
    }

    FuncType type;
  }

  public static abstract class Indirect0 extends Indirect
  {
    protected Indirect0(FuncType type) { super(type); }
    protected Indirect0() { super(new FuncType(new Type[] {}, Sys.ObjType)); }
    public final Object call(List args) { return call0(); }
    public abstract Object call0();
    public final Object call1(Object a) { return call0(); }
    public final Object call2(Object a, Object b) { return call0(); }
    public final Object call3(Object a, Object b, Object c) { return call0(); }
    public final Object call4(Object a, Object b, Object c, Object d) { return call0(); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call0(); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call0(); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call0(); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call0(); }
  }

  public static abstract class Indirect1 extends Indirect
  {
    protected Indirect1(FuncType type) { super(type); }
    protected Indirect1() { super(new FuncType(new Type[] { Sys.ObjType }, Sys.ObjType)); }
    public final Object call(List args) { return call1(args.get(0)); }
    public final Object call0() { throw tooFewArgs(0); }
    public abstract Object call1(Object a);
    public final Object call2(Object a, Object b) { return call1(a); }
    public final Object call3(Object a, Object b, Object c) { return call1(a); }
    public final Object call4(Object a, Object b, Object c, Object d) { return call1(a); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call1(a); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call1(a); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call1(a); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call1(a); }
  }

  public static abstract class Indirect2 extends Indirect
  {
    protected Indirect2(FuncType type) { super(type); }
    protected Indirect2() { super(new FuncType(new Type[] { Sys.ObjType, Sys.ObjType }, Sys.ObjType)); }
    public final Object call(List args) { return call2(args.get(0), args.get(1)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public abstract Object call2(Object a, Object b);
    public final Object call3(Object a, Object b, Object c) { return call2(a, b); }
    public final Object call4(Object a, Object b, Object c, Object d) { return call2(a, b); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call2(a, b); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call2(a, b); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call2(a, b); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call2(a, b); }
  }

  public static abstract class Indirect3 extends Indirect
  {
    protected Indirect3(FuncType type) { super(type); }
    protected Indirect3() { super(new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType)); }
    public final Object call(List args) { return call3(args.get(0), args.get(1), args.get(2)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public abstract Object call3(Object a, Object b, Object c);
    public final Object call4(Object a, Object b, Object c, Object d) { return call3(a, b, c); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call3(a, b, c); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call3(a, b, c); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call3(a, b, c); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call3(a, b, c); }
  }

  public static abstract class Indirect4 extends Indirect
  {
    protected Indirect4(FuncType type) { super(type); }
    protected Indirect4() { super(new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType)); }
    public final Object call(List args) { return call4(args.get(0), args.get(1), args.get(2), args.get(3)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public abstract Object call4(Object a, Object b, Object c, Object d);
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call4(a, b, c, d); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call4(a, b, c, d); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call4(a, b, c, d); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call4(a, b, c, d); }
  }

  public static abstract class Indirect5 extends Indirect
  {
    protected Indirect5(FuncType type) { super(type); }
    public final Object call(List args) { return call5(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call4(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public abstract Object call5(Object a, Object b, Object c, Object d, Object e);
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call5(a, b, c, d, e); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call5(a, b, c, d, e); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call5(a, b, c, d, e); }
  }

  public static abstract class Indirect6 extends Indirect
  {
    protected Indirect6(FuncType type) { super(type); }
    public final Object call(List args) { return call6(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call4(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public abstract Object call6(Object a, Object b, Object c, Object d, Object e, Object f);
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call6(a, b, c, d, e, f); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call6(a, b, c, d, e, f); }
  }

  public static abstract class Indirect7 extends Indirect
  {
    protected Indirect7(FuncType type) { super(type); }
    public final Object call(List args) { return call7(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call4(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public abstract Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g);
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call7(a, b, c, d, e, f, g); }
  }

  public static abstract class Indirect8 extends Indirect
  {
    protected Indirect8(FuncType type) { super(type); }
    public final Object call(List args) { return call8(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call4(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { throw tooFewArgs(7); }
    public abstract Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h);
  }

  public static abstract class IndirectX extends Indirect
  {
    protected IndirectX(FuncType type) { super(type); }
    public abstract Object call(List args);
    public final Object call0() { throw tooFewArgs(0); }
    public final Object call1(Object a) { throw tooFewArgs(1); }
    public final Object call2(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call3(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call4(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { throw tooFewArgs(7); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { throw tooFewArgs(8); }
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

    public String name()  { return getClass().getName(); }
    public Type type()  { return type; }
    public String  toStr() { return type.signature(); }
    public boolean isImmutable() { return false; }
    public Method method() { return null; }

    // this isn't a very optimized implementation
    public final Object call0() { return call(new List(Sys.ObjType, new Object[] {})); }
    public final Object call1(Object a) { return call(new List(Sys.ObjType, new Object[] {a})); }
    public final Object call2(Object a, Object b) { return call(new List(Sys.ObjType, new Object[] {a,b})); }
    public final Object call3(Object a, Object b, Object c) { return call(new List(Sys.ObjType, new Object[] {a,b,c})); }
    public final Object call4(Object a, Object b, Object c, Object d) { return call(new List(Sys.ObjType, new Object[] {a,b,c,d})); }
    public final Object call5(Object a, Object b, Object c, Object d, Object e) { return call(new List(Sys.ObjType, new Object[] {a,b,c,d,e})); }
    public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return call(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f})); }
    public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f,g})); }
    public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f,g,h})); }

    public Object call(List args)
    {
      int origSize = orig.params.sz();
      if (origSize == bound.sz()) return orig.call(bound);

      Object[] temp = new Object[origSize];
      bound.copyInto(temp, 0, bound.sz());
      args.copyInto(temp, bound.sz(), temp.length-bound.sz());
      return orig.call(new List(Sys.ObjType, temp));
    }

    public final Object callOn(Object obj, List args)
    {
      int origSize = orig.params.sz();
      Object[] temp = new Object[origSize];
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