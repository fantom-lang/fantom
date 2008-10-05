//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//   9 Jul 07  Brian Frank  Split into Func
//
package fan.sys;

import java.lang.reflect.*;
import fanx.fcode.*;

/**
 * Method is an invocable operation on a Type.
 */
public class Method
  extends Slot
{

//////////////////////////////////////////////////////////////////////////
// Fan Constructor
//////////////////////////////////////////////////////////////////////////

  public static Method make(Str name, Func func) { return make(name, func, null); }
  public static Method make(Str name, Func func, Map facets)
  {
    Method m = new Method();
    make$(m, name, func, facets);
    return m;
  }

  public static void make$(Method self, Str name, Func func) { make$(self, name, func, null); }
  public static void make$(Method self, Str name, Func func, Map facets)
  {
    if (name == null) throw NullErr.make("name is null").val;
    if (func == null) throw NullErr.make("func is null").val;

    self.flags  = FConst.Public;
    self.name   = name;
    self.qname  = name;
    self.func   = func;
    self.params = func.params;
    self.facets = Facets.make(facets);
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Constructor used by Type.reflect.
   */
  public Method(Type parent, Str name, int flags, Facets facets, int lineNum, Type returns, Type inheritedReturns, List params)
  {
    this(parent, name, flags, facets, lineNum, returns, inheritedReturns, params, null);
  }

  /**
   * Constructor used by GenericType and we are given the generic
   * method that is being parameterized.
   */
  public Method(Type parent, Str name, int flags, Facets facets, int lineNum, Type returns, Type inheritedReturns, List params, Method generic)
  {
    super(parent, name, flags, facets, lineNum);

    List fparams = params.ro();
    if ((flags & (FConst.Static|FConst.Ctor)) == 0)
    {
      Object[] temp = new Object[params.sz()+1];
      temp[0] = new Param(Str.thisStr, parent, 0);
      params.copyInto(temp, 1, params.sz());
      fparams = new List(Sys.ParamType, temp);
    }

    this.func = new MethodFunc(returns, fparams);
    this.params = params;
    this.inheritedReturns = inheritedReturns;
    this.mask = (generic != null) ? 0 : toMask(parent, returns, params);
    this.generic = generic;
  }

  /**
   * Default constructor used by make
   */
  public Method() {}

  /**
   * Compute if the method signature contains generic parameter types.
   */
  private static int toMask(Type parent, Type returns, List params)
  {
    // we only use generics in Sys
    if (parent.pod() != Sys.SysPod) return 0;

    int p = returns.isGenericParameter() ? 1 : 0;
    for (int i=0; i<params.sz(); ++i)
      p |= ((Param)params.get(i)).of.isGenericParameter() ? 1 : 0;

    int mask = 0;
    if (p != 0) mask |= GENERIC;
    return mask;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.MethodType; }

  public Type returns() { return func.returns(); }

  public Type inheritedReturns() { return inheritedReturns; }

  public List params() { return params.ro(); }

  public Func func() { return func; }

  public Str signature()
  {
    StringBuilder s = new StringBuilder();
    s.append(func.returns).append(' ').append(name).append('(');
    for (int i=0; i<params.sz(); ++i)
    {
      if (i > 0) s.append(", ");
      Param p = (Param)params.get(i);
      s.append(p.of).append(' ').append(p.name);
    }
    s.append(')');
    return Str.make(s.toString());
  }

  public Object trap(Str name, List args)
  {
    // private undocumented access
    if (name.val.equals("inheritedReturnType"))
      return inheritedReturns;
    else
      return super.trap(name, args);
  }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  /**
   * Return if this method contains generic parameters in it's signature.
   */
  public boolean isGenericMethod()
  {
    return (mask & GENERIC) != 0;
  }

  /**
   * Return if this method is the parameterization of a generic method,
   * with all the generic parameters filled in with real types.
   */
  public boolean isGenericInstance()
  {
    return generic != null;
  }

  /**
   * If isGenericInstance is true, then return the generic method which
   * this method instantiates.  The generic method may be used to access
   * the actual signatures used in the Java code (via getRawType).  If
   * this method is not a generic instance, return null.
   */
  public Method getGenericMethod()
  {
    return generic;
  }

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

  public final Object call(List args) { return func.call(args); }
  public final Object callOn(Object target, List args) { return func.callOn(target, args); }
  public final Object call0() { return func.call0(); }
  public final Object call1(Object a) { return func.call1(a); }
  public final Object call2(Object a, Object b) { return func.call2(a,b); }
  public final Object call3(Object a, Object b, Object c) { return func.call3(a,b,c); }
  public final Object call4(Object a, Object b, Object c, Object d) { return func.call4(a,b,c,d); }
  public final Object call5(Object a, Object b, Object c, Object d, Object e) { return func.call5(a,b,c,d,e); }
  public final Object call6(Object a, Object b, Object c, Object d, Object e, Object f) { return func.call6(a,b,c,d,e,f); }
  public final Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g) { return func.call7(a,b,c,d,e,f,g); }
  public final Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h) { return func.call8(a,b,c,d,e,f,g,h); }

//////////////////////////////////////////////////////////////////////////
// MethodFunc
//////////////////////////////////////////////////////////////////////////

  class MethodFunc extends Func
  {
    MethodFunc(Type returns, List params) { super(returns, params); }

    public Method method() { return Method.this; }

    public Boolean isImmutable()
    {
      return Method.this.isStatic() || parent.isConst();
    }

    public Object call(List args)
    {
      int argsSize = args == null ? 0 : args.sz();

      boolean isStatic = isStatic();
      int p = checkArgs(argsSize, isStatic, false);
      Object[] a = new Object[p];

      if (isStatic)
      {
        if (args != null && a.length > 0) args.toArray(a, 0, a.length);
        return invoke(null, a);
      }
      else
      {
        Object i = args.get(0);
        if (a.length > 0) args.toArray(a, 1, a.length);
        return invoke(i, a);
      }
    }

    public Object callOn(Object target, List args)
    {
      int argsSize = args == null ? 0 : args.sz();
      boolean javaStatic = isStatic();
      boolean fanStatic = ((flags & (FConst.Static|FConst.Ctor)) != 0);

      if (javaStatic && !fanStatic)
      {
        // if Java static doesn't match Fan static, then this is
        // a FanXXX method which we need to call as Java static
        int p = checkArgs(argsSize, false, true);
        Object[] a = new Object[p+1];
        a[0] = target;
        if (args != null && a.length > 0) args.copyInto(a, 1, a.length-1);
        return invoke(null, a);
      }
      else
      {
        // we don't include target as part of arguments
        int p = checkArgs(argsSize, javaStatic, true);
        Object[] a = new Object[p];
        if (args != null && a.length > 0) args.toArray(a, 0, a.length);
        return invoke(target, a);
      }
    }

    public Object call0()
    {
      boolean isStatic = isStatic();
      checkArgs(0, isStatic, false);
      return invoke(null, noArgs);
    }

    public Object call1(Object a)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(1, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        return invoke(a, args);
      }
    }

    public Object call2(Object a, Object b)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(2, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call3(Object a, Object b, Object c)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(3, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call4(Object a, Object b, Object c, Object d)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(4, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 4: args[3] = d;
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 3: args[2] = d;
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call5(Object a, Object b, Object c, Object d, Object e)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(5, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 5: args[4] = e;
          case 4: args[3] = d;
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 4: args[3] = e;
          case 3: args[2] = d;
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call6(Object a, Object b, Object c, Object d, Object e, Object f)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(6, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 6: args[5] = f;
          case 5: args[4] = e;
          case 4: args[3] = d;
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 5: args[4] = f;
          case 4: args[3] = e;
          case 3: args[2] = d;
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call7(Object a, Object b, Object c, Object d, Object e, Object f, Object g)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(7, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 7: args[6] = g;
          case 6: args[5] = f;
          case 5: args[4] = e;
          case 4: args[3] = d;
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 6: args[5] = g;
          case 5: args[4] = f;
          case 4: args[3] = e;
          case 3: args[2] = d;
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    public Object call8(Object a, Object b, Object c, Object d, Object e, Object f, Object g, Object h)
    {
      boolean isStatic = isStatic();
      int p = checkArgs(8, isStatic, false);
      Object[] args = new Object[p];
      if (isStatic)
      {
        switch (p)
        {
          case 8: args[7] = h;
          case 7: args[6] = g;
          case 6: args[5] = f;
          case 5: args[4] = e;
          case 4: args[3] = d;
          case 3: args[2] = c;
          case 2: args[1] = b;
          case 1: args[0] = a;
        }
        return invoke(null, args);
      }
      else
      {
        switch (p)
        {
          case 7: args[6] = h;
          case 6: args[5] = g;
          case 5: args[4] = f;
          case 4: args[3] = e;
          case 3: args[2] = d;
          case 2: args[1] = c;
          case 1: args[0] = b;
        }
        return invoke(a, args);
      }
    }

    private boolean isStatic()
    {
      try
      {
        // ensure parent has finished emitting so that reflect is populated
        parent.finish();

        // return if Java method(s) is static
        return Modifier.isStatic(reflect[0].getModifiers());
      }
      catch (Exception e)
      {
        throw Err.make("Method not mapped to java.lang.reflect correctly " + qname()).val;
      }
    }

    private int checkArgs(int args, boolean isStatic, boolean isCallOn)
    {
      // compuate min/max parameters - reflect contains all the method versions
      // with full params at index zero, and full defaults at reflect.length-1
      int max = params.sz();
      if (!isStatic) max--;
      int min = max-reflect.length+1;

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

  public Object invoke(Object instance, Object[] args)
  {
    if (reflect == null) parent.finish();

    try
    {
      // zero index is full signature up to using max defaults
      int index = params.sz()-args.length;
      if (index < 0) index = 0;
      return reflect[index].invoke(instance, args);
    }
    catch (IllegalArgumentException e)
    {
      throw ArgErr.make(e).val;
    }
    catch (InvocationTargetException e)
    {
      if (e.getCause() instanceof Err.Val)
        throw (Err.Val)e.getCause();
      else
        throw Err.make(e.getCause()).val;
    }
    catch (Exception e)
    {
      if (reflect == null)
        throw Err.make("Method not mapped to java.lang.reflect correctly " + qname()).val;

      //System.out.println("ERROR:      " + signature());
      //System.out.println("  instance: " + instance);
      //System.out.println("  args:     " + (args == null ? "null" : ""+args.length));
      //for (int i=0; args != null && i<args.length; ++i)
      //  System.out.println("    args[" + i + "] = " + args[i]);
      //e.printStackTrace();


      throw Err.make("Cannot call '" + this + "': " + e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final int GENERIC = 0x01;  // is this a generic method
  static final Object[] noArgs = new Object[0];

  Func func;
  List params;             // might be different from func.params is instance method
  Type inheritedReturns;   // for covariance
  int mask;
  Method generic;
  java.lang.reflect.Method[] reflect;

}