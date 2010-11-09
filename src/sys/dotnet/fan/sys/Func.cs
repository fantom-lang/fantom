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

    public override Type @typeof() { return Sys.FuncType; }

    public Type returns() { return m_returns; }

    public long arity() { return m_params.size(); }

    public List @params() { return m_params.ro(); }

    public override abstract bool isImmutable();

    public abstract Method method();

    public abstract object callList(List args);
    public abstract object callOn(object target, List args);
    public abstract object call();
    public abstract object call(object a);
    public abstract object call(object a, object b);
    public abstract object call(object a, object b, object c);
    public abstract object call(object a, object b, object c, object d);
    public abstract object call(object a, object b, object c, object d, object e);
    public abstract object call(object a, object b, object c, object d, object e, object f);
    public abstract object call(object a, object b, object c, object d, object e, object f, object g);
    public abstract object call(object a, object b, object c, object d, object e, object f, object g, object h);

    public override object toImmutable()
    {
      if (isImmutable()) return this;
      throw NotImmutableErr.make().val;
    }

    // Hooks used by compiler to generate runtime const field checks for it-blocks
    public virtual void enterCtor(object o) {}
    public virtual void exitCtor() {}
    public virtual void checkInCtor(object o) {}

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
    /// and also extends Func for the callList() implementations.
    /// </summary>
    public abstract class Indirect : Func
    {
      protected Indirect(FuncType type) : base(type) { this.m_type = type; }

      public string name() { return GetType().Name; }
      public override Type @typeof()  { return m_type; }
      public override string  toStr() { return m_type.signature(); }
      public override bool isImmutable() { return false; }
      public override Method method() { return null; }
      public Err.Val tooFewArgs(int given) { return Err.make("Too few arguments: " + given + " < " + m_type.m_params.Length).val; }

      public override object callOn(object obj, List args)
      {
        List flat = args.dup();
        flat.insert(0, obj);
        return callList(flat);
      }

      FuncType m_type;
    }

    public abstract class Indirect0 : Indirect
    {
      protected Indirect0(FuncType type) : base(type) {}
      protected Indirect0() : base(type0) {}
      public override object callList(List args) { return call(); }
      public override abstract object call();
      public override object call(object a) { return call(); }
      public override object call(object a, object b) { return call(); }
      public override object call(object a, object b, object c) { return call(); }
      public override object call(object a, object b, object c, object d) { return call(); }
      public override object call(object a, object b, object c, object d, object e) { return call(); }
      public override object call(object a, object b, object c, object d, object e, object f) { return call(); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(); }
    }

    public abstract class Indirect1 : Indirect
    {
      protected Indirect1(FuncType type) : base(type) {}
      protected Indirect1() : base(type1) {}
      public override object callList(List args) { return call(args.get(0)); }
      public override object call() { throw tooFewArgs(0); }
      public override abstract object call(object a);
      public override object call(object a, object b) { return call(a); }
      public override object call(object a, object b, object c) { return call(a); }
      public override object call(object a, object b, object c, object d) { return call(a); }
      public override object call(object a, object b, object c, object d, object e) { return call(a); }
      public override object call(object a, object b, object c, object d, object e, object f) { return call(a); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a); }

      public override void enterCtor(object o) { this.m_inCtor = o; }
      public override void exitCtor() { this.m_inCtor = null; }
      public override void checkInCtor(object it)
      {
        if (it == m_inCtor) return;
        string msg = it == null ? "null" : FanObj.@typeof(it).qname();
        throw ConstErr.make(msg).val;
      }

      internal object m_inCtor;
    }

    public abstract class Indirect2 : Indirect
    {
      protected Indirect2(FuncType type) : base(type) {}
      protected Indirect2() : base(type2) {}
      public override object callList(List args) { return call(args.get(0), args.get(1)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override abstract object call(object a, object b);
      public override object call(object a, object b, object c) { return call(a, b); }
      public override object call(object a, object b, object c, object d) { return call(a, b); }
      public override object call(object a, object b, object c, object d, object e) { return call(a, b); }
      public override object call(object a, object b, object c, object d, object e, object f) { return call(a, b); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a, b); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b); }
    }

    public abstract class Indirect3 : Indirect
    {
      protected Indirect3(FuncType type) : base(type) {}
      protected Indirect3() : base(type3) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override abstract object call(object a, object b, object c);
      public override object call(object a, object b, object c, object d) { return call(a, b, c); }
      public override object call(object a, object b, object c, object d, object e) { return call(a, b, c); }
      public override object call(object a, object b, object c, object d, object e, object f) { return call(a, b, c); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a, b, c); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b, c); }
    }

    public abstract class Indirect4 : Indirect
    {
      protected Indirect4(FuncType type) : base(type) {}
      protected Indirect4() : base(type4) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override abstract object call(object a, object b, object c, object d);
      public override object call(object a, object b, object c, object d, object e) { return call(a, b, c, d); }
      public override object call(object a, object b, object c, object d, object e, object f) { return call(a, b, c, d); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a, b, c, d); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b, c, d); }
    }

    public abstract class Indirect5 : Indirect
    {
      protected Indirect5(FuncType type) : base(type) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override abstract object call(object a, object b, object c, object d, object e);
      public override object call(object a, object b, object c, object d, object e, object f) { return call(a, b, c, d, e); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a, b, c, d, e); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b, c, d, e); }
    }

    public abstract class Indirect6 : Indirect
    {
      protected Indirect6(FuncType type) : base(type) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override abstract object call(object a, object b, object c, object d, object e, object f);
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return call(a, b, c, d, e, f); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b, c, d, e, f); }
    }

    public abstract class Indirect7 : Indirect
    {
      protected Indirect7(FuncType type) : base(type) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override abstract object call(object a, object b, object c, object d, object e, object f, object g);
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return call(a, b, c, d, e, f, g); }
    }

    public abstract class Indirect8 : Indirect
    {
      protected Indirect8(FuncType type) : base(type) {}
      public override object callList(List args) { return call(args.get(0), args.get(1), args.get(2), args.get(3), args.get(4), args.get(5), args.get(6), args.get(7)); }
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { throw tooFewArgs(7); }
      public override abstract object call(object a, object b, object c, object d, object e, object f, object g, object h);
    }

    public abstract class IndirectX : Indirect
    {
      protected IndirectX(FuncType type) : base(type) {}
      public override abstract object callList(List args);
      public override object call() { throw tooFewArgs(0); }
      public override object call(object a) { throw tooFewArgs(1); }
      public override object call(object a, object b)  { throw tooFewArgs(2); }
      public override object call(object a, object b, object c) { throw tooFewArgs(3); }
      public override object call(object a, object b, object c, object d) { throw tooFewArgs(4); }
      public override object call(object a, object b, object c, object d, object e) { throw tooFewArgs(5); }
      public override object call(object a, object b, object c, object d, object e, object f) { throw tooFewArgs(6); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { throw tooFewArgs(7); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { throw tooFewArgs(8); }
    }

  //////////////////////////////////////////////////////////////////////////
  // Retype
  //////////////////////////////////////////////////////////////////////////

    public Func retype(Type t)
    {
      try
      {
        return new Wrapper((FuncType)t, this);
      }
      catch (System.InvalidCastException)
      {
        throw ArgErr.make("Not a Func type: " + t).val;
      }
    }

    internal class Wrapper : Func
    {
      internal Wrapper(FuncType t, Func orig) : base(t) { m_type = t; m_orig = orig; }
      public override Type @typeof()  { return m_type; }
      public override bool isImmutable() { return m_orig.isImmutable(); }
      public override Method method() { return m_orig.method(); }
      public override object callOn(object target, List args) { return m_orig.callOn(target, args); }
      public override object callList(List args) { return m_orig.callList(args); }
      public override object call() { return m_orig.call(); }
      public override object call(object a) { return m_orig.call(a); }
      public override object call(object a, object b)  { return m_orig.call(a, b); }
      public override object call(object a, object b, object c) { return m_orig.call(a, b, c); }
      public override object call(object a, object b, object c, object d) { return m_orig.call(a, b, c, d); }
      public override object call(object a, object b, object c, object d, object e) { return m_orig.call(a, b, c, d, e); }
      public override object call(object a, object b, object c, object d, object e, object f) { return m_orig.call(a, b, c, d, e, f); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return m_orig.call(a, b, c, d, e, f, g); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return m_orig.call(a, b, c, d, e, f, g, h); }
      FuncType m_type;
      Func m_orig;
    }

  //////////////////////////////////////////////////////////////////////////
  // Bind
  //////////////////////////////////////////////////////////////////////////

    public Func bind(List args)
    {
      if (args.sz() == 0) return this;
      if (args.sz() > m_params.sz()) throw ArgErr.make("args.size > params.size").val;

      Type[] newParams = new Type[m_params.sz()-args.sz()];
      for (int i=0; i<newParams.Length; ++i)
        newParams[i] = ((Param)m_params.get(args.sz()+i)).m_type;

      FuncType newType = new FuncType(newParams, this.m_returns);
      return new BindFunc(newType, this, args);
    }

    internal class BindFunc : Func
    {
      internal BindFunc (FuncType type, Func orig, List bound)
        : base(type)
      {
        this.m_type  = type;
        this.m_orig  = orig;
        this.m_bound = bound.ro();
      }

      public string  name()  { return GetType().Name; }
      public override Type @typeof()  { return m_type; }
      public override string  toStr() { return m_type.signature(); }
      public override Method method() { return null; }

      public override bool isImmutable()
      {
        if (this.m_isImmutable == null)
        {
          bool isImmutable = false;
          if (m_orig.isImmutable())
          {
            isImmutable = true;
            for (int i=0; i<m_bound.sz(); ++i)
            {
              object obj = m_bound.get(i);
              if (obj != null && !FanObj.isImmutable(obj))
                { isImmutable = false; break; }
            }
          }
          this.m_isImmutable = Boolean.valueOf(isImmutable);
        }
        return this.m_isImmutable.booleanValue();
      }

      // this isn't a very optimized implementation
      public override object call() { return callList(new List(Sys.ObjType, new object[] {})); }
      public override object call(object a) { return callList(new List(Sys.ObjType, new object[] {a})); }
      public override object call(object a, object b) { return callList(new List(Sys.ObjType, new object[] {a,b})); }
      public override object call(object a, object b, object c) { return callList(new List(Sys.ObjType, new object[] {a,b,c})); }
      public override object call(object a, object b, object c, object d) { return callList(new List(Sys.ObjType, new object[] {a,b,c,d})); }
      public override object call(object a, object b, object c, object d, object e) { return callList(new List(Sys.ObjType, new object[] {a,b,c,d,e})); }
      public override object call(object a, object b, object c, object d, object e, object f) { return callList(new List(Sys.ObjType, new object[] {a,b,c,d,e,f})); }
      public override object call(object a, object b, object c, object d, object e, object f, object g) { return callList(new List(Sys.ObjType, new object[] {a,b,c,d,e,f,g})); }
      public override object call(object a, object b, object c, object d, object e, object f, object g, object h) { return callList(new List(Sys.ObjType, new object[] {a,b,c,d,e,f,g,h})); }

      public override object callList(List args)
      {
        int origReq  = m_orig.m_params.sz();
        int haveSize = m_bound.sz() + args.sz();
        Method m = m_orig.method();
        if (m != null)
        {
          origReq = m.minParams();
          if (haveSize > origReq) origReq = haveSize;
        }
        if (origReq <= m_bound.sz()) return m_orig.callList(m_bound);

        object[] temp = new object[haveSize];
        m_bound.copyInto(temp, 0, m_bound.sz());
        args.copyInto(temp, m_bound.sz(), temp.Length-m_bound.sz());
        return m_orig.callList(new List(Sys.ObjType, temp));
      }

      public override object callOn(object obj, List args)
      {
        int origSize = m_orig.m_params.sz();
        object[] temp = new object[origSize];
        m_bound.copyInto(temp, 0, m_bound.sz());
        temp[m_bound.sz()] = obj;
        args.copyInto(temp, m_bound.sz()+1, temp.Length-m_bound.sz()-1);
        return m_orig.callList(new List(Sys.ObjType, temp));
      }

      private readonly FuncType m_type;
      private readonly Func m_orig;
      private readonly List m_bound;
      private Boolean m_isImmutable;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly object[] noArgs = new object[0];
    internal static readonly FuncType type0 = new FuncType(new Type[] {}, Sys.ObjType);
    internal static readonly FuncType type1 = new FuncType(new Type[] { Sys.ObjType }, Sys.ObjType);
    internal static readonly FuncType type2 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType }, Sys.ObjType);
    internal static readonly FuncType type3 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType);
    internal static readonly FuncType type4 = new FuncType(new Type[] { Sys.ObjType, Sys.ObjType, Sys.ObjType, Sys.ObjType }, Sys.ObjType);

    internal readonly Type m_returns;
    internal readonly List m_params;

  }
}