//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Func models an executable subroutine.
  /// </summary>
  public abstract class Func : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Constructor.
    /// </summary>
    public Func(Type returns, List pars)
    {
      this.m_returns = returns;
      this.m_params  = pars;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.FuncType; }

    public Type returns() { return m_returns; }

    public List @params() { return m_params.ro(); }

    public override abstract Bool isImmutable();

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

    public static readonly int MaxIndirectParams = 8;  // max callX()

    /// <summary>
    /// Constructor used by Indirect.
    /// </summary>
    protected Func(FuncType funcType)
    {
      this.m_returns = funcType.m_ret;
      this.m_params  = funcType.toMethodParams();
    }

    /// <summary>
    /// Indirect is the base class for the IndirectX classes, which are
    /// used as the common base classes for closures and general purpose
    /// functions.  An Indirect method takes a funcType for it's type,
    /// and also extends Func for the call() implementations.
    /// </summary>
    public abstract class Indirect : Func
    {
      protected Indirect(FuncType type) : base(type) { this.m_type = type; }

      public Str name() { return Str.make(GetType().Name); }
      public override Type type()  { return m_type; }
      public override Str  toStr() { return m_type.signature(); }
      public override Bool isImmutable() { return Bool.False; }
      public override Method method() { return null; }
      public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + m_type.m_params.Length).val; }

      public override Obj callOn(Obj obj, List args)
      {
        List flat = args.dup();
        flat.insert(Int.Zero, obj);
        return call(flat);
      }

      FuncType m_type;
    }

    public abstract class Indirect0 : Indirect
    {
      protected Indirect0(FuncType type) : base(type) {}
      public override Obj call(List args) { return call0(); }
      public override abstract Obj call0();
      public override Obj call1(Obj a) { return call0(); }
      public override Obj call2(Obj a, Obj b) { return call0(); }
      public override Obj call3(Obj a, Obj b, Obj c) { return call0(); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { return call0(); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call0(); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call0(); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call0(); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call0(); }
    }

    public abstract class Indirect1 : Indirect
    {
      protected Indirect1(FuncType type) : base(type) {}
      public override Obj call(List args) { return call1(args.get(0)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override abstract Obj call1(Obj a);
      public override Obj call2(Obj a, Obj b) { return call1(a); }
      public override Obj call3(Obj a, Obj b, Obj c) { return call1(a); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { return call1(a); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call1(a); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call1(a); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call1(a); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call1(a); }
    }

    public abstract class Indirect2 : Indirect
    {
      protected Indirect2(FuncType type) : base(type) {}
      public override Obj call(List args) { return call2(args.get(0), args.get(1)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override abstract Obj call2(Obj a, Obj b);
      public override Obj call3(Obj a, Obj b, Obj c) { return call2(a, b); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { return call2(a, b); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call2(a, b); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call2(a, b); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call2(a, b); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call2(a, b); }
    }

    public abstract class Indirect3 : Indirect
    {
      protected Indirect3(FuncType type) : base(type) {}
      public override Obj call(List args) { return call3(args.get(0), args.get(1), args.get(2)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override abstract Obj call3(Obj a, Obj b, Obj c);
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { return call3(a, b, c); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call3(a, b, c); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call3(a, b, c); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call3(a, b, c); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call3(a, b, c); }
    }

    public abstract class Indirect4 : Indirect
    {
      protected Indirect4(FuncType type) : base(type) {}
      public override Obj call(List args) { return call4(args.get(0), args.get(1), args.get(2), args.get(3)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override abstract Obj call4(Obj a, Obj b, Obj c, Obj d);
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call4(a, b, c, d); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call4(a, b, c, d); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call4(a, b, c, d); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call4(a, b, c, d); }
    }

    public abstract class Indirect5 : Indirect
    {
      protected Indirect5(FuncType type) : base(type) {}
      public override Obj call(List args) { return call5(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
      public override abstract Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e);
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call5(a, b, c, d, e); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call5(a, b, c, d, e); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call5(a, b, c, d, e); }
    }

    public abstract class Indirect6 : Indirect
    {
      protected Indirect6(FuncType type) : base(type) {}
      public override Obj call(List args) { return call6(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
      public override abstract Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f);
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call6(a, b, c, d, e, f); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call6(a, b, c, d, e, f); }
    }

    public abstract class Indirect7 : Indirect
    {
      protected Indirect7(FuncType type) : base(type) {}
      public override Obj call(List args) { return call7(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
      public override abstract Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g);
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call7(a, b, c, d, e, f, g); }
    }

    public abstract class Indirect8 : Indirect
    {
      protected Indirect8(FuncType type) : base(type) {}
      public override Obj call(List args) { return call8(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { throw tooFewArgs(7); }
      public override abstract Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h);
    }

    public abstract class IndirectX : Indirect
    {
      protected IndirectX(FuncType type) : base(type) {}
      public override abstract Obj call(List args);
      public override Obj call0() { throw tooFewArgs(0); }
      public override Obj call1(Obj a) { throw tooFewArgs(1); }
      public override Obj call2(Obj a, Obj b)  { throw tooFewArgs(2); }
      public override Obj call3(Obj a, Obj b, Obj c) { throw tooFewArgs(3); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { throw tooFewArgs(4); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { throw tooFewArgs(5); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { throw tooFewArgs(6); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { throw tooFewArgs(7); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { throw tooFewArgs(8); }
    }

  //////////////////////////////////////////////////////////////////////////
  // Curry
  //////////////////////////////////////////////////////////////////////////

    public Func curry(List args)
    {
      if (args.sz() == 0) return this;
      if (args.sz() > m_params.sz()) throw ArgErr.make("args.size > params.size").val;

      Type[] newParams = new Type[m_params.sz()-args.sz()];
      for (int i=0; i<newParams.Length; ++i)
        newParams[i] = ((Param)m_params.get(args.sz()+i)).m_of;

      FuncType newType = new FuncType(newParams, this.m_returns);
      return new CurryFunc(newType, this, args);
    }

    internal class CurryFunc : Func
    {
      internal CurryFunc(FuncType type, Func orig, List bound)
        : base(type)
      {
        this.m_type  = type;
        this.m_orig  = orig;
        this.m_bound = bound.ro();
      }

      public Str  name()  { return Str.make(GetType().Name); }
      public override Type type()  { return m_type; }
      public override Str  toStr() { return m_type.signature(); }
      public override Bool isImmutable() { return Bool.False; }
      public override Method method() { return null; }

      // this isn't a very optimized implementation
      public override Obj call0() { return call(new List(Sys.ObjType, new Obj[] {})); }
      public override Obj call1(Obj a) { return call(new List(Sys.ObjType, new Obj[] {a})); }
      public override Obj call2(Obj a, Obj b) { return call(new List(Sys.ObjType, new Obj[] {a,b})); }
      public override Obj call3(Obj a, Obj b, Obj c) { return call(new List(Sys.ObjType, new Obj[] {a,b,c})); }
      public override Obj call4(Obj a, Obj b, Obj c, Obj d) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d})); }
      public override Obj call5(Obj a, Obj b, Obj c, Obj d, Obj e) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e})); }
      public override Obj call6(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f})); }
      public override Obj call7(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f,g})); }
      public override Obj call8(Obj a, Obj b, Obj c, Obj d, Obj e, Obj f, Obj g, Obj h) { return call(new List(Sys.ObjType, new Obj[] {a,b,c,d,e,f,g,h})); }

      public override Obj call(List args)
      {
        int origSize = m_orig.m_params.sz();
        if (origSize == m_bound.sz()) return m_orig.call(m_bound);

        Obj[] temp = new Obj[origSize];
        m_bound.copyInto(temp, 0, m_bound.sz());
        args.copyInto(temp, m_bound.sz(), temp.Length-m_bound.sz());
        return m_orig.call(new List(Sys.ObjType, temp));
      }

      public override Obj callOn(Obj obj, List args)
      {
        int origSize = m_orig.m_params.sz();
        Obj[] temp = new Obj[origSize];
        m_bound.copyInto(temp, 0, m_bound.sz());
        temp[m_bound.sz()] = obj;
        args.copyInto(temp, m_bound.sz()+1, temp.Length-m_bound.sz()-1);
        return m_orig.call(new List(Sys.ObjType, temp));
      }

      readonly FuncType m_type;
      readonly Func m_orig;
      readonly List m_bound;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly object[] noArgs = new object[0];

    internal readonly Type m_returns;
    internal readonly List m_params;

  }
}