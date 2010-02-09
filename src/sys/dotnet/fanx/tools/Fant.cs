//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;
using FanSysTest = Fan.Sys.Test;

namespace Fanx.Tools
{
  /// <summary>
  /// Fant .NET runtime.
  /// </summary>
  ///
  public class Fant : Tool
  {

  //////////////////////////////////////////////////////////////////////////
  // Test
  //////////////////////////////////////////////////////////////////////////

    public int test(string[] patterns, bool verbose)
    {
      long t1 = System.Environment.TickCount;
      for (int i=0; i<patterns.Length; i++)
        test(patterns[i], verbose);
      long t2 = System.Environment.TickCount;

      writeLine("");
      writeLine("Time: " + (t2-t1) + "ms");
      writeLine("");
      foreach (Method m in failedMethods)
        writeLine(" -- failed: " + m.qname());
      writeLine("");
      writeLine("***");
      writeLine("*** " + (failures == 0 ? "All tests passed!" : failures + " FAILURES") + " [" + testCount + " tests, " + methodCount  + " methods, " + totalVerifyCount + " verifies] ");
      writeLine("***");
      return failures;
    }

    public void test(string pattern, bool verbose)
    {
      if (pattern == "*")
      {
        List pods = Pod.list();
        for (int i=0; i<pods.sz(); i++)
        {
          Pod p = (Pod)pods.get(i);
          test(p.name(), verbose);
        }
        return;
      }

      if (pattern == "sys" || pattern.StartsWith("sys::"))
      {
        writeLine("");
        //if (pattern == "sys")
        //  pattern = "";
        //else
        //  pattern = pattern.Substring(5);
        if (!Fanx.Test.Test.RunTests(null)) failures++;
        totalVerifyCount += Fanx.Test.Test.totalVerified;
        return;
      }

      string[] s = pattern.Split(new char[] { ':', '.' });
      string podName = s[0];
      string testName = (s.Length > 2) ? s[2] : "*";
      string methodName = (s.Length > 3) ? s[3] : "*";

      writeLine("");

      Pod pod = Pod.doFind(podName, true, null);
      Type[] t = tests(pod, testName);
      for (int i=0; i<t.Length; i++)
      {
        Method[] m = methods(t[i], methodName);
        for (int j=0; j<m.Length; j++)
        {
          writeLine("-- Run:  " + m[j] + "...");
          int verifyCount = runTest(t[i], m[j]);
          if (verifyCount < 0) { failures++; failedMethods.Add(m[j]); continue; }
          writeLine("   Pass: " + m[j] + " [" + verifyCount + "]");
          methodCount++;
          totalVerifyCount += verifyCount;
        }
        testCount++;
      }
    }

    private Type[] tests(Pod pod, string testName)
    {
      // named test
      if (testName != "*") return new Type[] { pod.type(testName, true) };

      // all types which subclass Test
      List all = pod.types();
      ArrayList acc = new ArrayList();
      for (int i=0; i<all.sz(); i++)
      {
        Type x = (Type)all.get(i);
        if (x.@is(Sys.TestType) && !x.isAbstract()) acc.Add(x);
      }
      return (Type[])acc.ToArray(System.Type.GetType("Fan.Sys.Type"));
    }

    private Method[] methods(Type type, string methodName)
    {
      // named test
      if (methodName != "*") return new Method[] { type.method(methodName, true) };

      // all methods which start with "test"
      List all = type.methods();
      ArrayList acc = new ArrayList();
      for (int i=0; i<all.sz(); i++)
      {
        Method m = (Method)all.get(i);
        if (m.name().StartsWith("test") && !m.isAbstract()) acc.Add(m);
      }
      return (Method[])acc.ToArray(System.Type.GetType("Fan.Sys.Method"));
    }

    private int runTest(Type type, Method method)
    {
      Method setup    = type.method("setup", true);
      Method teardown = type.method("teardown", true);

      FanSysTest test = null;
      List args = null;
      try
      {
        test = (FanSysTest)type.make();
        args = new List(Sys.ObjType, new object[] {test});
      }
      catch (System.Exception e)
      {
        System.Console.WriteLine();
        System.Console.WriteLine("ERROR: Cannot make test " + type);
        if (e is Err.Val)
          ((Err.Val)e).err().trace();
        else
          Err.dumpStack(e);
        return -1;
      }

      try
      {
        test.m_curTestMethod = method;
        setup.callList(args);
        method.callList(args);
        return test.verifyCount;
      }
      catch (System.Exception e)
      {
//System.Console.WriteLine(" -- " + e.GetType() + " -- ");
        System.Console.WriteLine();
        System.Console.WriteLine("TEST FAILED");
        if (e is Err.Val)
          ((Err.Val)e).err().trace();
        else
          Err.dumpStack(e);
        return -1;
      }
      finally
      {
        try
        {
          if (args != null) teardown.callList(args);
        }
        catch (System.Exception e)
        {
          Err.dumpStack(e);
        }
        test.m_curTestMethod = null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Run Methods
  //////////////////////////////////////////////////////////////////////////

    public static int run(string reserved)
    {
      try
      {
        sysInit(reserved);
        SysProps.putProperty("fan.appDir", "$home/tmp/test/");

        //bool self = false;
        bool verbose = false;
        ArrayList targets = new ArrayList();

        string[] args = Tool.getArgv();
        if (args.Length == 0) { help(); return -1; }

        // process args
        for (int i=0; i<args.Length; i++)
        {
          string a = args[i];
          if (a.Length == 0) continue;
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
            FanSysTest.verbose =  true;
            //fanx.test.Test.verbose = true;
          }
          else if (a == "-all")
          {
            targets.Add("*");
          }
          else if (a[0] == '-')
          {
            writeLine("WARNING: Unknown option " + a);
          }
          else
          {
            targets.Add(a);
          }
        }

        if (targets.Count == 0) { help(); return -1; }

        string[] t = (string[])targets.ToArray(System.Type.GetType("System.String"));
        return new Fant().test(t, verbose);
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
        return -1;
      }
    }

    static void help()
    {
      writeLine("Fantom Test");
      writeLine("Usage:");
      writeLine("  fant [options] -all");
      writeLine("  fant [options] <pod> [pod]*");
      writeLine("  fant [options] <pod>::<test>");
      writeLine("  fant [options] <pod>::<test>.<method>");
      writeLine("Note:");
      writeLine("  You can use * to indicate wildcard for all pods");
      writeLine("Options:");
      writeLine("  -help, -h, -?  print usage help");
      writeLine("  -version       print version");
      writeLine("  -v             verbose mode");
      writeLine("  -all           test all pods");
    }

    static void writeLine(string s)
    {
      System.Console.WriteLine(s);
    }

    static Fant()
    {
      // .NET will only create one new thread every 500ms, which will
      // throw off all the timing in testSys, so if we're running under
      // fant, create a larger initial thread pool to work around that.
      System.Threading.ThreadPool.SetMinThreads(10, 10);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    int testCount = 0;
    int methodCount = 0;
    int totalVerifyCount = 0;
    int failures = 0;
    ArrayList failedMethods = new ArrayList();
  }
}