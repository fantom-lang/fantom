//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Reflection;
using System.Text;
using Fanx.Fcode;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// Method is an invocable operation on a Type.
  /// </summary>
  public class Method : Slot
  {

  //////////////////////////////////////////////////////////////////////////
  // C# Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Constructor used by Type.reflect.
    /// </summary>
    public Method(Type parent, string name, int flags, Facets facets, int lineNum, Type returns, Type inheritedReturns, List pars)
     : this(parent, name, flags, facets, lineNum, returns, inheritedReturns, pars, null)
    {
    }

    /// <summary>
    /// Constructor used by GenericType and we are given the generic
    /// method that is being parameterized.
    /// </summary>
    public Method(Type parent, string name, int flags, Facets facets, int lineNum, Type returns, Type inheritedReturns, List pars, Method generic)
      : base(parent, name, flags, facets, lineNum)
    {
      List fparams = pars.ro();
      if ((flags & (FConst.Static|FConst.Ctor)) == 0)
      {
        object[] temp = new object[pars.sz()+1];
        temp[0] = new Param("this", parent, 0);
        pars.copyInto(temp, 1, pars.sz());
        fparams = new List(Sys.ParamType, temp);
      }

      this.m_func = new MethodFunc(this, returns, fparams);
      this.m_params = pars;
      this.m_inheritedReturns = inheritedReturns;
      this.m_mask = (generic != null) ? 0 : toMask(parent, returns, pars);
      this.m_generic = generic;
    }

    /// <summary>
    /// Compute if the method signature contains generic parameter types.
    /// </summary>
    private static int toMask(Type parent, Type returns, List pars)
    {
      // we only use generics in Sys
      if (parent.pod() != Sys.m_sysPod) return 0;

      int p = returns.isGenericParameter() ? 1 : 0;
      for (int i=0; i<pars.sz(); ++i)
        p |= ((Param)pars.get(i)).m_type.isGenericParameter() ? 1 : 0;

      int mask = 0;
      if (p != 0) mask |= GENERIC;
      return mask;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.MethodType; }

    public Type returns() { return m_func.returns(); }

    public Type inheritedReturns() { return m_inheritedReturns; }

    public List @params() { return m_params.ro(); }

    public Func func() { return m_func; }

    public override string signature()
    {
      StringBuilder s = new StringBuilder();
      s.Append(m_func.m_returns).Append(' ').Append(m_name).Append('(');
      for (int i=0; i<m_params.sz(); ++i)
      {
        if (i > 0) s.Append(", ");
        Param p = (Param)m_params.get(i);
        s.Append(p.m_type).Append(' ').Append(p.m_name);
      }
      s.Append(')');
      return s.ToString();
    }

    public override object trap(string name, List args)
    {
      // private undocumented access
      if (name == "inheritedReturnType")
        return m_inheritedReturns;
      else
        return base.trap(name, args);
    }

  //////////////////////////////////////////////////////////////////////////
  // Generics
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Return if this method contains generic parameters in it's signature.
    /// </summary>
    public bool isGenericMethod()
    {
      return (m_mask & GENERIC) != 0;
    }

    /// <summary>
    /// Return if this method is the parameterization of a generic method,
    /// with all the generic parameters filled in with real types.
    /// </summary>
    public bool isGenericInstance()
    {
      return m_generic != null;
    }

    /// <summary>
    /// If isGenericInstance is true, then return the generic method which
    /// this method instantiates.  The generic method may be used to access
    /// the actual signatures used in the Java code (via getRawType).  If
    /// this method is not a generic instance, return null.
    /// </summary>
    public Method getGenericMethod()
    {
      return m_generic;
    }

  //////////////////////////////////////////////////////////////////////////
  // Call Conveniences
  //////////////////////////////////////////////////////////////////////////

    public object callList(List args) { return m_func.callList(args); }
    public object callOn(object target, List args) { return m_func.callOn(target, args); }
    public object call() { return m_func.call(); }
    public object call(object a) { return m_func.call(a); }
    public object call(object a, object b) { return m_func.call(a,b); }
    public object call(object a, object b, object c) { return m_func.call(a,b,c); }
    public object call(object a, object b, object c, object d) { return m_func.call(a,b,c,d); }
    public object call(object a, object b, object c, object d, object e) { return m_func.call(a,b,c,d,e); }
    public object call(object a, object b, object c, object d, object e, object f) { return m_func.call(a,b,c,d,e,f); }
    public object call(object a, object b, object c, object d, object e, object f, object g) { return m_func.call(a,b,c,d,e,f,g); }
    public object call(object a, object b, object c, object d, object e, object f, object g, object h) { return m_func.call(a,b,c,d,e,f,g,h); }

  //////////////////////////////////////////////////////////////////////////
  // MethodFunc
  //////////////////////////////////////////////////////////////////////////

    internal class MethodFunc : Func
    {
      internal MethodFunc(Method method, Type returns, List pars)
        : base (returns, pars)
      {
        this.m = method;
      }
      private Method m;

      public override Method method() { return m; }

      public override bool isImmutable() { return true; }

      public override object callList(List args)
      {
        int argsSize = args == null ? 0 : args.sz();

        bool isStatic = _isStatic();
        int p = checkArgs(argsSize, isStatic, false);
        object[] a = new object[p];

        if (isStatic)
        {
          if (args != null && a.Length > 0) args.toArray(a, 0, a.Length);
          return m.invoke(null, a);
        }
        else
        {
          object i = args.get(0);
          if (a.Length > 0) args.toArray(a, 1, a.Length);
          return m.invoke(i, a);
        }
      }

      public override object callOn(object target, List args)
      {
        int argsSize = args == null ? 0 : args.sz();
        bool dotnetStatic = _isStatic();
        bool fanStatic = ((m.m_flags & (FConst.Static|FConst.Ctor)) != 0);

        if (dotnetStatic && !fanStatic)
        {
          // if Java static doesn't match Fantom static, then this is
          // a FanXXX method which we need to call as Java static
          int p = checkArgs(argsSize, false, true);
          object[] a = new object[p+1];
          a[0] = target;
          if (args != null && a.Length > 0) args.copyInto(a, 1, a.Length-1);
          return m.invoke(null, a);
        }
        else
        {
          // we don't include target as part of arguments
          int p = checkArgs(argsSize, dotnetStatic, true);
          object[] a = new object[p];
          if (args != null && a.Length > 0) args.toArray(a, 0, a.Length);
          return m.invoke(target, a);
        }
      }

      public override object call()
      {
        bool isStatic = _isStatic();
        checkArgs(0, isStatic, false);
        return m.invoke(null, noArgs);
      }

      public override object call(object a)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(1, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(2, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(3, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c, object d)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(4, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          if (p > 3) args[3] = d;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          if (p > 2) args[2] = d;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c, object d, object e)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(5, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          if (p > 3) args[3] = d;
          if (p > 4) args[4] = e;
          return m.invoke(null, args);
        }


        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          if (p > 2) args[2] = d;
          if (p > 3) args[3] = e;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c, object d, object e, object f)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(6, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          if (p > 3) args[3] = d;
          if (p > 4) args[4] = e;
          if (p > 5) args[5] = f;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          if (p > 2) args[2] = d;
          if (p > 3) args[3] = e;
          if (p > 4) args[4] = f;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c, object d, object e, object f, object g)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(7, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          if (p > 3) args[3] = d;
          if (p > 4) args[4] = e;
          if (p > 5) args[5] = f;
          if (p > 6) args[6] = g;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          if (p > 2) args[2] = d;
          if (p > 3) args[3] = e;
          if (p > 4) args[4] = f;
          if (p > 5) args[5] = g;
          return m.invoke(a, args);
        }
      }

      public override object call(object a, object b, object c, object d, object e, object f, object g, object h)
      {
        bool isStatic = _isStatic();
        int p = checkArgs(8, isStatic, false);
        object[] args;
        if (isStatic)
        {
          args = new object[p];
          if (p > 0) args[0] = a;
          if (p > 1) args[1] = b;
          if (p > 2) args[2] = c;
          if (p > 3) args[3] = d;
          if (p > 4) args[4] = e;
          if (p > 5) args[5] = f;
          if (p > 6) args[6] = g;
          if (p > 7) args[7] = h;
          return m.invoke(null, args);
        }
        else
        {
          args = new object[p];
          if (p > 0) args[0] = b;
          if (p > 1) args[1] = c;
          if (p > 2) args[2] = d;
          if (p > 3) args[3] = e;
          if (p > 4) args[4] = f;
          if (p > 5) args[5] = g;
          if (p > 6) args[6] = h;
          return m.invoke(a, args);
        }
      }

      private bool _isStatic()
      {
        try
        {
          // ensure parent has finished emitting so that reflect is populated
          m.m_parent.finish();

          // return if .NET method(s) is static
          return m.m_reflect[0].IsStatic;
        }
        catch (Exception)
        {
          throw Err.make("Method not mapped to System.Reflection correctly " + m.qname()).val;
        }
      }

      private int checkArgs(int args, bool isStatic, bool isCallOn)
      {
        // compuate min/max parameters - reflect contains all the method versions
        // with full pars at index zero, and full defaults at reflect.Length-1
        int max = m_params.sz();
        if (!isStatic) max--;
        int min = max-m.m_reflect.Length+1;

        // do checking
        if (isStatic || isCallOn)
        {
          if (args < min) throw ArgErr.make("Too few arguments: " + args + " < " + min+".."+max).val;
        }
        else
        {
          if (args < min+1) throw ArgErr.make("Too few arguments: " + args + " < instance+" + min+".."+max).val;
          args--;
        }

        // return size of arguments to pass to java method
        return args <= max ? args : max;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Reflection
  //////////////////////////////////////////////////////////////////////////

    public int minParams()
    {
      if (m_minParams < 0)
      {
        int min = 0;
        for (; min<m_params.sz(); ++min)
          if (((Param)m_params.get(min)).hasDefault()) break;
        m_minParams = min;
      }
      return m_minParams;
    }

    private bool isInstance() { return (m_flags & (FConst.Static|FConst.Ctor)) == 0; }

    internal object invoke(object instance, object[] args)
    {
      if (m_reflect == null) m_parent.finish();

      try
      {
        // zero index is full signature up to using max defaults
        int index = m_params.sz()-args.Length;
        if (m_parent.dotnetRepr() && isInstance()) index++;
        if (index < 0) index = 0;
        MethodInfo m = m_reflect[index];

        //System.Console.WriteLine(">>> " + m_reflect.Length + "/" + index);
        //System.Console.WriteLine(m_reflect[index]);
        //System.Console.WriteLine("---");
        //for (int i=0; i<m_reflect.Length; i++)
        //  System.Console.WriteLine(m_reflect[i]);

        // TODO - not sure how this should work entirely yet, but we need
        // to be responsible for "boxing" Fantom wrappers and primitives

        // box the parameters
        ParameterInfo[] pars = m.GetParameters();
        for (int i=0; i<args.Length; i++)
        {
          System.Type pt = pars[i].ParameterType;
          if (pt == boolPrimitive && args[i] is Fan.Sys.Boolean)
          {
            args[i] = (args[i] as Fan.Sys.Boolean).booleanValue();
          }
          else if (pt == doublePrimitive && args[i] is Fan.Sys.Double)
          {
            args[i] = (args[i] as Fan.Sys.Double).doubleValue();
          }
          else if (pt == longPrimitive && args[i] is Fan.Sys.Long)
          {
            args[i] = (args[i] as Fan.Sys.Long).longValue();
          }
        }

        // invoke method
        object ret = m.Invoke(instance, args);

        // box the return value
        return FanUtil.box(ret);
      }
      catch (ArgumentException e)
      {
        throw ArgErr.make(e).val;
      }
      catch (TargetInvocationException e)
      {
        Err err = Err.make(e.InnerException);
        err.m_stack = e.InnerException.StackTrace;
        throw err.val;
      }
      catch (Exception e)
      {
        if (m_reflect == null)
          throw Err.make("Method not mapped to System.Reflection.MethodInfo correctly " + m_qname).val;

        /*
        System.Console.WriteLine("ERROR:      " + signature());
        System.Console.WriteLine("  instance: " + instance);
        System.Console.WriteLine("  args:     " + (args == null ? "null" : ""+args.Length));
        for (int i=0; args != null && i<args.Length; ++i)
          System.Console.WriteLine("    args[" + i + "] = " + args[i]);
        Err.dumpStack(e);
        */

        throw Err.make("Cannot call '" + this + "': " + e).val;
      }
    }

    private static System.Type boolPrimitive = System.Type.GetType("System.Boolean");
    private static System.Type doublePrimitive = System.Type.GetType("System.Double");
    private static System.Type longPrimitive = System.Type.GetType("System.Int64");

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly int GENERIC = 0x01;  // is this a generic method
    internal static readonly object[] noArgs = new object[0];

    internal Func m_func;
    internal List m_params;           // might be different from func.params is instance method
    internal Type m_inheritedReturns; // for covariance
    internal int m_mask;
    internal Method m_generic;
    internal MethodInfo[] m_reflect;
    private int m_minParams = -1;

  }
}