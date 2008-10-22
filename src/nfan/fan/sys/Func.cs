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

    public override abstract Boolean isImmutable();

    public abstract Method method();

    public abstract object call(List args);
    public abstract object callOn(object target, List args);
    public abstract object call0();
    public abstract object call1(object a);
    public abstract object call2(object a, object b);
    public abstract object call3(object a, object b, object c);
    public abstract object call4(object a, object b, object c, object d);
    public abstract object call5(object a, object b, object c, object d, object e);
    public abstract object call6(object a, object b, object c, object d, object e, object f);
    public abstract object call7(object a, object b, object c, object d, object e, object f, object g);
    public abstract object call8(object a, object b, object c, object d, object e, object f, object g, object h);

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

      public string name() { return GetType().Name; }
      public override Type type()  { return m_type; }
      public override string  toStr() { return m_type.signature(); }
      public override Boolean isImmutable() { return Boolean.False; }
      public override Method method() { return null; }
      public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + m_type.m_params.Length).val; }

      public override object callOn(object obj, List args)
      {
        List flat = args.dup();
        flat.insert(FanInt.Zero, obj);
        return call(flat);
      }

      FuncType m_type;
    }

    public abstract class Indirect0 : Indirect
    {
      protected Indirect0(FuncType type) : base(type) {}
      public override object call(List args) { return call0(); }
      public override abstract object call0();
      public override object call1(object a) { return call0(); }
      public override object call2(object a, object b) { return call0(); }
      public override object call3(object a, object b, object c) { return call0(); }
      public override object call4(object a, object b, object c, object d) { return call0(); }
      public override object call5(object a, object b, object c, object d, object e) { return call0(); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call0(); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call0(); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call0(); }
    }

    public abstract class Indirect1 : Indirect
    {
      protected Indirect1(FuncType type) : base(type) {}
      public override object call(List args) { return call1(args.get(0)); }
      public override object call0() { throw tooFewArgs(0); }
      public override abstract object call1(object a);
      public override object call2(object a, object b) { return call1(a); }
      public override object call3(object a, object b, object c) { return call1(a); }
      public override object call4(object a, object b, object c, object d) { return call1(a); }
      public override object call5(object a, object b, object c, object d, object e) { return call1(a); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call1(a); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call1(a); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call1(a); }
    }

    public abstract class Indirect2 : Indirect
    {
      protected Indirect2(FuncType type) : base(type) {}
      public override object call(List args) { return call2(args.get(0), args.get(1)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override abstract object call2(object a, object b);
      public override object call3(object a, object b, object c) { return call2(a, b); }
      public override object call4(object a, object b, object c, object d) { return call2(a, b); }
      public override object call5(object a, object b, object c, object d, object e) { return call2(a, b); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call2(a, b); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call2(a, b); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call2(a, b); }
    }

    public abstract class Indirect3 : Indirect
    {
      protected Indirect3(FuncType type) : base(type) {}
      public override object call(List args) { return call3(args.get(0), args.get(1), args.get(2)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override abstract object call3(object a, object b, object c);
      public override object call4(object a, object b, object c, object d) { return call3(a, b, c); }
      public override object call5(object a, object b, object c, object d, object e) { return call3(a, b, c); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call3(a, b, c); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call3(a, b, c); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call3(a, b, c); }
    }

    public abstract class Indirect4 : Indirect
    {
      protected Indirect4(FuncType type) : base(type) {}
      public override object call(List args) { return call4(args.get(0), args.get(1), args.get(2), args.get(3)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override abstract object call4(object a, object b, object c, object d);
      public override object call5(object a, object b, object c, object d, object e) { return call4(a, b, c, d); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call4(a, b, c, d); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call4(a, b, c, d); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call4(a, b, c, d); }
    }

    public abstract class Indirect5 : Indirect
    {
      protected Indirect5(FuncType type) : base(type) {}
      public override object call(List args) { return call5(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call4(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override abstract object call5(object a, object b, object c, object d, object e);
      public override object call6(object a, object b, object c, object d, object e, object f) { return call5(a, b, c, d, e); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call5(a, b, c, d, e); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call5(a, b, c, d, e); }
    }

    public abstract class Indirect6 : Indirect
    {
      protected Indirect6(FuncType type) : base(type) {}
      public override object call(List args) { return call6(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call4(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call5(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override abstract object call6(object a, object b, object c, object d, object e, object f);
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call6(a, b, c, d, e, f); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call6(a, b, c, d, e, f); }
    }

    public abstract class Indirect7 : Indirect
    {
      protected Indirect7(FuncType type) : base(type) {}
      public override object call(List args) { return call7(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call4(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call5(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call6(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override abstract object call7(object a, object b, object c, object d, object e, object f, object g);
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call7(a, b, c, d, e, f, g); }
    }

    public abstract class Indirect8 : Indirect
    {
      protected Indirect8(FuncType type) : base(type) {}
      public override object call(List args) { return call8(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call4(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call5(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call6(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { throw tooFewArgs(7); }
      public override abstract object call8(object a, object b, object c, object d, object e, object f, object g, object h);
    }

    public abstract class IndirectX : Indirect
    {
      protected IndirectX(FuncType type) : base(type) {}
      public override abstract object call(List args);
      public override object call0() { throw tooFewArgs(0); }
      public override object call1(object a) { throw tooFewArgs(1); }
      public override object call2(object a, object b)  { throw tooFewArgs(2); }
      public override object call3(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call4(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call5(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call6(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { throw tooFewArgs(7); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { throw tooFewArgs(8); }
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

      public string  name()  { return GetType().Name; }
      public override Type type()  { return m_type; }
      public override string  toStr() { return m_type.signature(); }
      public override Boolean isImmutable() { return Boolean.False; }
      public override Method method() { return null; }

      // this isn't a very optimized implementation
      public override object call0() { return call(new List(Sys.ObjType, new object[] {})); }
      public override object call1(object a) { return call(new List(Sys.ObjType, new object[] {a})); }
      public override object call2(object a, object b) { return call(new List(Sys.ObjType, new object[] {a,b})); }
      public override object call3(object a, object b, object c) { return call(new List(Sys.ObjType, new object[] {a,b,c})); }
      public override object call4(object a, object b, object c, object d) { return call(new List(Sys.ObjType, new object[] {a,b,c,d})); }
      public override object call5(object a, object b, object c, object d, object e) { return call(new List(Sys.ObjType, new object[] {a,b,c,d,e})); }
      public override object call6(object a, object b, object c, object d, object e, object f) { return call(new List(Sys.ObjType, new object[] {a,b,c,d,e,f})); }
      public override object call7(object a, object b, object c, object d, object e, object f, object g) { return call(new List(Sys.ObjType, new object[] {a,b,c,d,e,f,g})); }
      public override object call8(object a, object b, object c, object d, object e, object f, object g, object h) { return call(new List(Sys.ObjType, new object[] {a,b,c,d,e,f,g,h})); }

      public override object call(List args)
      {
        int origSize = m_orig.m_params.sz();
        if (origSize == m_bound.sz()) return m_orig.call(m_bound);

        object[] temp = new object[origSize];
        m_bound.copyInto(temp, 0, m_bound.sz());
        args.copyInto(temp, m_bound.sz(), temp.Length-m_bound.sz());
        return m_orig.call(new List(Sys.ObjType, temp));
      }

      public override object callOn(object obj, List args)
      {
        int origSize = m_orig.m_params.sz();
        object[] temp = new object[origSize];
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