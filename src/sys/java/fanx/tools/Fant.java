//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Dec 05  Brian Frank  Creation
//
package fanx.tools;

import java.util.*;
import fan.sys.*;
import fan.sys.List;

/**
 * Fant is the command line used to run Fantom unit tests.
 */
public class Fant
{

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  public int test(String[] patterns, boolean verbose)
  {
    Sys.boot();

    long t1 = System.currentTimeMillis();
    for (int i=0; i<patterns.length; ++i)
      test(patterns[i], verbose);
    long t2 = System.currentTimeMillis();

    System.out.println();
    System.out.println("Time: " + (t2-t1) + "ms");
    System.out.println();

    if (failureNames.size() > 0)
    {
      System.out.println("Failed:");
      for (int i=0; i<failureNames.size(); ++i)
        System.out.println("  " + failureNames.get(i));
      System.out.println();
    }

    System.out.println("***");
    System.out.println("*** " + (failures == 0 ? "All tests passed!" : failures + " FAILURES") + " [" + testCount + " tests, " + methodCount  + " methods, " + totalVerifyCount + " verifies] ");
    System.out.println("***");
    return failures;
  }

  public void test(String pattern, boolean verbose)
  {
    if (pattern.equals("*"))
    {
      List pods = Pod.list();
      for (int i=0; i<pods.sz(); ++i)
      {
        Pod pod = (Pod)pods.get(i);
        test(pod.name(), verbose);
      }
      return;
    }

    if (pattern.equals("sys") || pattern.startsWith("sys::"))
    {
      System.out.println();
      if (pattern.equals("sys"))
        pattern = "";
      else
        pattern = pattern.substring(5);
      if (!fanx.test.Test.test(pattern)) failures++;
      totalVerifyCount += fanx.test.Test.totalVerified;
      return;
    }

    StringTokenizer st = new StringTokenizer(pattern, ":.");
    String podName    = st.nextToken();
    String testName   = st.hasMoreTokens() ? st.nextToken() : "*";
    String methodName = st.hasMoreTokens() ? st.nextToken() : "*";

    System.out.println();

    Pod pod = Pod.find(podName, true);
    Type[] tests = tests(pod, testName);
    for (int i=0; i<tests.length; ++i)
    {
      Type testType = tests[i];
      Method[] methods = methods(testType, methodName);
      for (int j=0; j<methods.length; ++j)
      {
        String name = testType.qname() + "." + methods[j].name();
        System.out.println("-- Run:  " + name + "...");
        System.out.flush();
        int verifyCount = runTest(tests[i], methods[j]);
        if (verifyCount < 0)
        {
          failures++;
          failureNames.add(name);
        }
        else
        {
          System.out.println("   Pass: " + name + " [" + verifyCount + "]");
          methodCount++;
          totalVerifyCount += verifyCount;
        }
      }
      testCount++;
    }
  }

  private Type[] tests(Pod pod, String testName)
  {
    // named test
    if (!testName.equals("*")) return new Type[] { pod.type(testName, true) };

    // all types which subclass Test
    List all = pod.types();
    ArrayList acc = new ArrayList();
    for (int i=0; i<all.sz(); ++i)
    {
      Type x = (Type)all.get(i);
      if (x.is(Sys.TestType) && !x.isAbstract()) acc.add(x);
    }
    return (Type[])acc.toArray(new Type[acc.size()]);
  }

  private Method[] methods(Type type, String methodName)
  {
    // named test
    if (!methodName.equals("*")) return new Method[] { type.method(methodName, true) };

    // all methods which start with "test"
    List all = type.methods();
    ArrayList acc = new ArrayList();
    for (int i=0; i<all.sz(); ++i)
    {
      Method m = (Method)all.get(i);
      if (m.name().startsWith("test") && !m.isAbstract()) acc.add(m);
    }
    return (Method[])acc.toArray(new Method[acc.size()]);

    // what would this look like in Fan?
    //  if (methodName == "*") return [ type.slot(testMethod, true) ]
    //  return type.methods.filter {|m| return m.name.startsWith("test") && !m.isAbstract }
  }

  private int runTest(Type type, Method method)
  {
    Method setup    = type.method("setup", true);
    Method teardown = type.method("teardown", true);

    Test test = null;
    List args = null;
    try
    {
      test = (Test)type.make();
      args = new List(Sys.ObjType, new Object[] {test});
    }
    catch (Throwable e)
    {
      System.out.println();
      System.out.println("ERROR: Cannot make test " + type);
      if (e instanceof Err)
        ((Err)e).trace();
      else
        e.printStackTrace();
      return -1;
    }

    try
    {
      test.curTestMethod = method;
      setup.callList(args);
      method.callList(args);
      return test.verifyCount;
    }
    catch (Throwable e)
    {
      System.out.println();
      System.out.println("TEST FAILED");
      if (e instanceof Err)
        ((Err)e).trace();
      else
        e.printStackTrace();
      return -1;
    }
    finally
    {
      try
      {
        if (args != null) teardown.callList(args);
      }
      catch (Throwable e)
      {
        if (e instanceof Err)
          ((Err)e).trace();
        else
          e.printStackTrace();
      }
      test.curTestMethod = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  /**
   * Main entry point for compiler.
   */
  public int run(String[] args)
  {
    try
    {
      boolean self = false;
      boolean verbose = false;
      ArrayList targets = new ArrayList();

      if (args.length == 0) { help(); return -1; }

      // process args
      for (int i=0; i<args.length; ++i)
      {
        String a = args[i].intern();
        if (a.length() == 0) continue;
        if (a == "-help" || a == "-h" || a == "-?")
        {
          help();
          return -1;
        }
        if (a == "-version")
        {
          Fan.version("Fantom Test");
          return -1;
        }
        else if (a == "-v")
        {
          verbose = true;
          fan.sys.Test.verbose =  true;
          fanx.test.Test.verbose = true;
        }
        else if (a == "-all")
        {
          targets.add("*");
        }
        else if (a.charAt(0) == '-')
        {
          System.out.println("WARNING: Unknown option " + a);
        }
        else
        {
          targets.add(a);
        }
      }

      if (targets.size() == 0) { help(); return -1; }

      String[] t = (String[])targets.toArray(new String[targets.size()]);
      return test(t, verbose);
    }
    catch (Throwable e)
    {
      e.printStackTrace();
      return -1;
    }
  }

  /**
   * Dump help usage.
   */
  void help()
  {
    System.out.println("Fantom Test");
    System.out.println("Usage:");
    System.out.println("  fant [options] -all");
    System.out.println("  fant [options] <pod> [pod]*");
    System.out.println("  fant [options] <pod>::<test>");
    System.out.println("  fant [options] <pod>::<test>.<method>");
    System.out.println("Note:");
    System.out.println("  You can use * to indicate wildcard for all pods");
    System.out.println("Options:");
    System.out.println("  -help, -h, -?  print usage help");
    System.out.println("  -version       print version");
    System.out.println("  -v             verbose mode");
    System.out.println("  -all           test all pods");
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  /** Used by fan "[java]fanx.tools::Fant.fanMain" */
  public static void fanMain() throws Exception
  {
    List args = Env.cur().args();
    main((String[])args.toArray(new String[args.sz()]));
  }

  public static void main(final String[] args)
    throws Exception
  {
    System.exit(new Fant().run(args));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  int testCount = 0;
  int methodCount = 0;
  int totalVerifyCount = 0;
  int failures = 0;
  ArrayList failureNames = new ArrayList();

}