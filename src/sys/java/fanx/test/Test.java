//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Sep 05  Brian Frank  Creation
//
package fanx.test;

import java.io.File;
import java.io.IOException;
import fanx.util.*;
import fan.sys.*;

/**
 * Test is the base class of test cases as well as the
 * main entry for test harness.
 */
public abstract class Test
{

//////////////////////////////////////////////////////////////////////////
// Test Case List
//////////////////////////////////////////////////////////////////////////

  public static String[] tests =
  {
    "CharsetTest",
    "EmitTest",
    "FileUtilTest",
    "StrBufTest",
    "StrUtilTest",
    "TokenizerTest",
    "DateTimeTest",
  };

//////////////////////////////////////////////////////////////////////////
// Test Cases
//////////////////////////////////////////////////////////////////////////

  /**
   * Get the test name.
   */
  public final String testName()
  {
    return testName;
  }

  /**
   * Return true if we should skip this test.
   */
  public boolean skip()
  {
    return false;
  }

  /**
   * Run the test case - any exception thrown
   * is considered a failed test.
   */
  public abstract void run()
    throws Exception;

//////////////////////////////////////////////////////////////////////////
// Reflection Utils
//////////////////////////////////////////////////////////////////////////

  public Object newInstance(Class cls, Object[] args) throws Exception
  {
    return cls.getConstructor(argsToParams(args)).newInstance(args);
  }

  public Object make(Class cls) throws Exception { return make(cls, new Object[0]); }
  public Object make(Class cls, Object[] args) throws Exception
  {
    return findMethod(cls, "make", args.length).invoke(null, args);
  }

  public Object invoke(Class cls, String name) throws Exception { return invoke(cls, name, new Object[0]); }
  public Object invoke(Class cls, String name, Object[] args) throws Exception
  {
    try
    {
      int paramCount = (args == null) ? 0 : args.length;
      return findMethod(cls, name, paramCount).invoke(null, args);
    }
    catch (java.lang.reflect.InvocationTargetException e)
    {
      throw (Exception)e.getCause();
    }
  }

  public Object invoke(Object instance, String name) throws Exception { return invoke(instance, name, new Object[0]); }
  public Object invoke(Object instance, String name, Object[] args) throws Exception
  {
    try
    {
      int paramCount = (args == null) ? 0 : args.length;
      return findMethod(instance.getClass(), name, paramCount).invoke(instance, args);
    }
    catch (java.lang.reflect.InvocationTargetException e)
    {
      throw (Exception)e.getCause();
    }
  }

  public java.lang.reflect.Method findMethod(Class cls, String name) throws Exception
  {
    return findMethod(cls, name, -1);
  }

  public java.lang.reflect.Method findMethod(Class cls, String name, int paramCount) throws Exception
  {
    java.lang.reflect.Method method;
    method = findMethod(cls, name, paramCount, cls.getMethods()); if (method != null) return method;
    method = findMethod(cls, name, paramCount, cls.getDeclaredMethods()); if (method != null) return method;
    throw new IllegalStateException("No method " + name);
  }

  public java.lang.reflect.Method findMethod(Class cls, String name, int paramCount, java.lang.reflect.Method[] methods) throws Exception
  {
    for (int i=0; i<methods.length; ++i)
      if (methods[i].getName().equals(name))
      {
        if (paramCount != -1 && methods[i].getParameterTypes().length != paramCount) continue;
        return methods[i];
      }
    return null;
  }

  public Object get(Class cls, String name) throws Exception
  {
    return cls.getField(name).get(null);
  }

  public Object get(Object instance, String name) throws Exception
  {
    if (instance instanceof Class)
      return ((Class)instance).getField(name).get(null);
    else
      return instance.getClass().getField(name).get(instance);
  }

  public void set(Class cls, String name, Object val) throws Exception
  {
    cls.getField(name).set(null, val);
  }

  public void set(Object instance, String name, Object val) throws Exception
  {
    if (instance instanceof Class)
      ((Class)instance).getField(name).set(null, val);
    else
      instance.getClass().getField(name).set(instance, val);
  }

  public Class[] argsToParams(Object[] args)
  {
    Class[] params = new Class[args.length];
    for (int i=0; i<params.length; ++i)
      params[i] = argToParam(args[i]);
    return params;
  }

  public Class argToParam(Object arg)
  {
    Class cls = arg.getClass();
    if (cls == Boolean.class) return boolean.class;
    if (cls == Integer.class) return int.class;
    if (cls == Long.class)    return long.class;
    if (cls == Float.class)   return float.class;
    if (cls == Double.class)  return double.class;
    return cls;
  }

//////////////////////////////////////////////////////////////////////////
// Verify Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Verify the condition is true, otherwise throw an exception.
   */
  public void verify(boolean b)
  {
    if (!b) throw new RuntimeException("Test failed");
    verified++;
    totalVerified++;
  }

  /**
   * Verify a and b are equal.
   */
  public void verifyEq(boolean a, boolean b)
  {
    if (a != b) throw new RuntimeException("Test failed " + a + " != " + b);
    verified++;
    totalVerified++;
  }

  /**
   * Verify a and b are equal.
   */
  public void verifyEq(long a, long b)
  {
    if (a != b) throw new RuntimeException("Test failed " + a + " != " + b);
    verified++;
    totalVerified++;
  }

  /**
   * Verify a and b are equal taking into account nulls.
   */
  public void verify(Object a, Object b)
  {
    try
    {
      verify(equals(a, b));
    }
    catch (RuntimeException e)
    {
      if (!e.getMessage().equals("Test failed")) throw e;
      throw new RuntimeException("Test failed " + a  + " != " + b);
    }
  }

  /**
   * Equals taking into account nulls.
   */
  public static boolean equals(Object a, Object b)
  {
    if (a == null) return b == null;
    else if (b == null) return false;
    else return a.equals(b);
  }

  /**
   * Force test failure
   */
  public void fail()
  {
    verify(false);
  }

//////////////////////////////////////////////////////////////////////////
// Misc Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Print a line to standard out.
   */
  public static void println(Object s)
  {
    System.out.println(s);
  }

  /**
   * Print a line to standard out if in verbose mode.
   */
  public static void verbose(Object s)
  {
    if (verbose) System.out.println(s);
  }

  /**
   * Get the temporary directory to use for tests.
   */
  public static File temp()
  {
    temp.mkdirs();
    return temp;
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static boolean runTest(String testName)
  {
    try
    {
      Class cls = Class.forName("fanx.test." + testName);
      Test test = (Test)cls.newInstance();
      test.testName = testName;
      if (test.skip())
      {
        println("-- Skip: sys::" + testName + " [skip]");
      }
      else
      {
        println("-- Run:  sys::" + testName + "...");
        test.run();
        println("   Pass: sys::" + testName + " [" + test.verified + "]");
      }
      return true;
    }
    catch (Throwable e)
    {
      println("### Failed: " + testName);
      e.printStackTrace();
      return false;
    }
  }

  public static boolean test(String pattern)
  {
    temp = new File("temp");

    if (pattern == null) pattern = "";

    boolean allPassed = true;
    int testCount = 0;

    for (int i=0; i<tests.length; ++i)
    {
      if (tests[i].startsWith(pattern))
      {
        testCount++;
        if (!runTest(tests[i]))
          allPassed = false;
      }
    }

    try { FileUtil.delete(temp); } catch (IOException e) { e.printStackTrace(); }

    return allPassed;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static boolean verbose;
  public static int totalVerified;
  private static File temp;
  private int verified;
  private String testName;

}
