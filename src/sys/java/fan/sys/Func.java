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

  public Type typeof() { return Sys.FuncType; }

  public Type returns() { return returns; }

  public List params() { return params.ro(); }

  public abstract boolean isImmutable();

  public Object toImmutable()
  {
    if (isImmutable()) return this;
    throw NotImmutableErr.make("Func").val;
  }

  public abstract Method method();

  public abstract Object callList(List args);
  public abstract Object callOn(Object target, List args);
  public abstract Object call();
  public abstract Object call(Object a);
  public abstract Object call(Object a, Object b);
  public abstract Object call(Object a, Object b, Object c);
  public abstract Object call(Object a, Object b, Object c, Object d);
  public abstract Object call(Object a, Object b, Object c, Object d, Object e);
  public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f);
  public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g);
  public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h);

  // Hooks used by compiler to generate runtime const field checks for it-blocks
  public void enterCtor(Object o) {}
  public void exitCtor() {}
  public void checkInCtor(Object o) {}

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
   * functions.  An Indirect method takes a funcType for it's type,
   * and also extends Func for the call() implementations.
   */
  public static abstract class Indirect extends Func
  {
    protected Indirect(FuncType type) { super(type); this.type = type; }

    public String  name()  { return getClass().getName(); }
    public Type typeof()  { return type; }
    public String  toStr() { return type.signature(); }
    public boolean isImmutable() { return false; }
    public Method method() { return null; }
    public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + type.params.length).val; }

    public final Object callOn(Object obj, List args)
    {
      Object[] array = new Object[args.sz()+1];
      array[0] = obj;
      args.copyInto(array, 1, args.sz());
      return callList(new List(Sys.ObjType, array));
    }

    FuncType type;
  }

  public static abstract class Indirect0 extends Indirect
  {
    protected Indirect0(FuncType type) { super(type); }
    protected Indirect0() { super(type0); }
    public final Object callList(List args) { return call(); }
    public abstract Object call();
    public final Object call(Object a) { return call(); }
    public final Object call(Object a, Object b) { return call(); }
    public final Object call(Object a, Object b, Object c) { return call(); }
    public final Object call(Object a, Object b, Object c, Object d) { return call(); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return call(); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(); }
  }

  public static abstract class Indirect1 extends Indirect
  {
    protected Indirect1(FuncType type) { super(type); }
    protected Indirect1() { super(type1); }
    public final Object callList(List args) { return call(args.get(0)); }
    public final Object call() { throw tooFewArgs(0); }
    public abstract Object call(Object a);
    public final Object call(Object a, Object b) { return call(a); }
    public final Object call(Object a, Object b, Object c) { return call(a); }
    public final Object call(Object a, Object b, Object c, Object d) { return call(a); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return call(a); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(a); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a); }

    public void enterCtor(Object o) { this.inCtor = o; }
    public void exitCtor() { this.inCtor = null; }
    public void checkInCtor(Object it)
    {
      if (it == inCtor) return;
      String msg = it == null ? "null" : FanObj.typeof(it).qname();
      throw ConstErr.make(msg).val;
    }

    Object inCtor;
  }

  public static abstract class Indirect2 extends Indirect
  {
    protected Indirect2(FuncType type) { super(type); }
    protected Indirect2() { super(type2); }
    public final Object callList(List args) { return call(args.get(0), args.get(1)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public abstract Object call(Object a, Object b);
    public final Object call(Object a, Object b, Object c) { return call(a, b); }
    public final Object call(Object a, Object b, Object c, Object d) { return call(a, b); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return call(a, b); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(a, b); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a, b); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b); }
  }

  public static abstract class Indirect3 extends Indirect
  {
    protected Indirect3(FuncType type) { super(type); }
    protected Indirect3() { super(type3); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public abstract Object call(Object a, Object b, Object c);
    public final Object call(Object a, Object b, Object c, Object d) { return call(a, b, c); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return call(a, b, c); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(a, b, c); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a, b, c); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b, c); }
  }

  public static abstract class Indirect4 extends Indirect
  {
    protected Indirect4(FuncType type) { super(type); }
    protected Indirect4() { super(type4); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public abstract Object call(Object a, Object b, Object c, Object d);
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return call(a, b, c, d); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(a, b, c, d); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a, b, c, d); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b, c, d); }
  }

  public static abstract class Indirect5 extends Indirect
  {
    protected Indirect5(FuncType type) { super(type); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public abstract Object call(Object a, Object b, Object c, Object d, Object e);
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return call(a, b, c, d, e); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a, b, c, d, e); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b, c, d, e); }
  }

  public static abstract class Indirect6 extends Indirect
  {
    protected Indirect6(FuncType type) { super(type); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f);
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return call(a, b, c, d, e, f); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b, c, d, e, f); }
  }

  public static abstract class Indirect7 extends Indirect
  {
    protected Indirect7(FuncType type) { super(type); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g);
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return call(a, b, c, d, e, f, g); }
  }

  public static abstract class Indirect8 extends Indirect
  {
    protected Indirect8(FuncType type) { super(type); }
    public final Object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { throw tooFewArgs(7); }
    public abstract Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h);
  }

  public static abstract class IndirectX extends Indirect
  {
    protected IndirectX(FuncType type) { super(type); }
    public abstract Object callList(List args);
    public final Object call() { throw tooFewArgs(0); }
    public final Object call(Object a) { throw tooFewArgs(1); }
    public final Object call(Object a, Object b)  { throw tooFewArgs(2); }
    public final Object call(Object a, Object b, Object c) { throw tooFewArgs(3); }
    public final Object call(Object a, Object b, Object c, Object d) { throw tooFewArgs(4); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { throw tooFewArgs(5); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { throw tooFewArgs(6); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { throw tooFewArgs(7); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { throw tooFewArgs(8); }
  }

//////////////////////////////////////////////////////////////////////////
// Retype
//////////////////////////////////////////////////////////////////////////

  public final Func retype(Type t)
  {
    try
    {
      return new Wrapper((FuncType)t, this);
    }
    catch (ClassCastException e)
    {
      throw ArgErr.make("Not a Func type: " + t).val;
    }
  }

  static class Wrapper extends Func
  {
    Wrapper(FuncType t, Func orig) { super(t); this.type = t; this.orig = orig; }
    public Type typeof()  { return type; }
    public final boolean isImmutable() { return orig.isImmutable(); }
    public final Method method() { return orig.method(); }
    public final Object callOn(Object target, List args) { return orig.callOn(target, args); }
    public final Object callList(List args) { return orig.callList(args); }
    public final Object call() { return orig.call(); }
    public final Object call(Object a) { return orig.call(a); }
    public final Object call(Object a, Object b)  { return orig.call(a, b); }
    public final Object call(Object a, Object b, Object c) { return orig.call(a, b, c); }
    public final Object call(Object a, Object b, Object c, Object d) { return orig.call(a, b, c, d); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return orig.call(a, b, c, d, e); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return orig.call(a, b, c, d, e, f); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return orig.call(a, b, c, d, e, f, g); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return orig.call(a, b, c, d, e, f, g, h); }
    FuncType type;
    Func orig;
  }

//////////////////////////////////////////////////////////////////////////
// Bind
//////////////////////////////////////////////////////////////////////////

  public final Func bind(List args)
  {
    if (args.sz() == 0) return this;
    if (args.sz() > params.sz()) throw ArgErr.make("args.size > params.size").val;

    Type[] newParams = new Type[params.sz()-args.sz()];
    for (int i=0; i<newParams.length; ++i)
      newParams[i] = ((Param)params.get(args.sz()+i)).type;

    FuncType newType = new FuncType(newParams, this.returns);
    return new BindFunc(newType, this, args);
  }

  static class BindFunc extends Func
  {
    BindFunc(FuncType type, Func orig, List bound)
    {
      super(type);
      this.type  = type;
      this.orig  = orig;
      this.bound = bound.ro();
    }

    public String name()  { return getClass().getName(); }
    public Type typeof()  { return type; }
    public String  toStr() { return type.signature(); }
    public boolean isImmutable() { return false; }
    public Method method() { return null; }

    // this isn't a very optimized implementation
    public final Object call() { return callList(new List(Sys.ObjType, new Object[] {})); }
    public final Object call(Object a) { return callList(new List(Sys.ObjType, new Object[] {a})); }
    public final Object call(Object a, Object b) { return callList(new List(Sys.ObjType, new Object[] {a,b})); }
    public final Object call(Object a, Object b, Object c) { return callList(new List(Sys.ObjType, new Object[] {a,b,c})); }
    public final Object call(Object a, Object b, Object c, Object d) { return callList(new List(Sys.ObjType, new Object[] {a,b,c,d})); }
    public final Object call(Object a, Object b, Object c, Object d, Object e) { return callList(new List(Sys.ObjType, new Object[] {a,b,c,d,e})); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f) { return callList(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f})); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return callList(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f,g})); }
    public final Object call(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return callList(new List(Sys.ObjType, new Object[] {a,b,c,d,e,f,g,h})); }

    public Object callList(List args)
    {
      int origReq  = orig.params.sz();
      int haveSize = bound.sz() + args.sz();
      Method m = orig.method();
      if (m != null)
      {
        origReq = m.minParams();
        if (haveSize > origReq) origReq = haveSize;
      }
      if (origReq <= bound.sz()) return orig.callList(bound);

      Object[] temp = new Object[haveSize];
      bound.copyInto(temp, 0, bound.sz());
      args.copyInto(temp, bound.sz(), temp.length-bound.sz());
      return orig.callList(new List(Sys.ObjType, temp));
    }

    public final Object callOn(Object obj, List args)
    {
      int origSize = orig.params.sz();
      Object[] temp = new Object[origSize];
      bound.copyInto(temp, 0, bound.sz());
      temp[bound.sz()] = obj;
      args.copyInto(temp, bound.sz()+1, temp.length-bound.sz()-1);
      return orig.callList(new List(Sys.ObjType, temp));
    }

    final FuncType type;
    final Func orig;
    final List bound;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Object[] noArgs = new Object[0];
  static final FuncType type0 = new FuncType(new Type[] {}, Sys.ObjType);
  static final FuncType type1 = new FuncType(new Type[] { Sys.ObjType }, Sys.ObjType);
  static final FuncType type2 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType }, Sys.ObjType);
  static final FuncType type3 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType);
  static final FuncType type4 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType);

  final Type returns;
  final List params;
}