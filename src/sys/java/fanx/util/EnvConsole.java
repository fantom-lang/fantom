//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Apr 24  Brian Frank  Creation
//
package fanx.util;

import java.io.*;
import java.lang.reflect.Method;
import fan.sys.*;


/**
 * EnvConsole tries to tame the mess of Java console input using a
 * series of different implementations and fallbacks:
 *   1. jline 3
 *   2. jline 2
 *   3. java.io.Console
 *   4. stdin
 */
public abstract class EnvConsole
{
  public static EnvConsole init()
  {
    try { return new Jline3Console(); } catch (Exception e) {}
    try { return new Jline2Console(); } catch (Exception e) {}
    if (System.console() != null) return new JavaConsole(System.console());
    return new StdinConsole();
  }

  /*
  // java -Dfan.home=/work/fan -cp ../lib/java/sys.jar:../lib/java/ext/jline-2.9.jar fanx.util.EnvConsole

  public static void main(String[] args) throws Exception
  {
    test(new Jline3Console());
    test(new Jline2Console());
    test(new JavaConsole(System.console()));
    test(new StdinConsole());
 }

  private static void test(EnvConsole c)
  {
    System.out.println();
    System.out.println("### Test: " + c.getClass());
    String s1 = c.prompt("prompt 1> ");
    System.out.println("=>" + s1);
    String s2 = c.prompt("prompt 2> ");
    System.out.println("=>" + s2);
    String p = c.promptPassword("password> ");
    System.out.println("=>" + p);
  }
  */

  public abstract String prompt(String msg);

  public abstract String promptPassword(String msg);

//////////////////////////////////////////////////////////////////////////
// StdinConsole
//////////////////////////////////////////////////////////////////////////

  static class StdinConsole extends EnvConsole
  {
    public String prompt(String msg)
    {
      try
      {
        System.out.print(msg);
        System.out.flush();
        return new java.io.BufferedReader(new java.io.InputStreamReader(System.in)).readLine();
      }
      catch (Exception e)
      {
        throw Err.make(e);
      }
    }

    public String promptPassword(String msg)
    {
      return prompt(msg);
    }
  }

//////////////////////////////////////////////////////////////////////////
// JavaConsole
//////////////////////////////////////////////////////////////////////////

  static class JavaConsole extends EnvConsole
  {
    JavaConsole(java.io.Console c) { this.console = c; }

    public String prompt(String msg)
    {
      return console.readLine(msg);
    }

    public String promptPassword(String msg)
    {
      return new String(console.readPassword(msg));
    }

    private java.io.Console console;
  }

//////////////////////////////////////////////////////////////////////////
// Jline3Console
//////////////////////////////////////////////////////////////////////////

  static class Jline3Console extends EnvConsole
  {
    Jline3Console() throws Exception
    {
      // reader = LineReaderBuilder.builder().build()
      Class builderClass  = Class.forName("org.jline.reader.LineReaderBuilder");
      Class readerClass   = Class.forName("org.jline.reader.LineReader");
      Method builderCtor  = builderClass.getMethod("builder", new Class[] {});
      Method builderBuild = builderClass.getMethod("build", new Class[] {});
      this.reader         = builderBuild.invoke(builderCtor.invoke(null));
      this.readLine       = readerClass.getMethod("readLine", new Class[] { String.class });
      this.readLineMask   = readerClass.getMethod("readLine", new Class[] { String.class, Character.class });
    }

    public String prompt(String msg)
    {
      try
      {
        return (String)readLine.invoke(reader, new Object[] { msg });
      }
      catch (Exception e)
      {
        throw Err.make(e);
      }
    }

    public String promptPassword(String msg)
    {
      try
      {
        return (String)readLineMask.invoke(reader, new Object[] { msg, new Character('#') });
      }
      catch (Exception e)
      {
        throw Err.make(e);
      }
    }

    private Object reader;        // org.jline.reader.LineReader
    private Method readLine;      // readLine(String)
    private Method readLineMask;  // readLine(String,Character)
  }

//////////////////////////////////////////////////////////////////////////
// Jline3Console
//////////////////////////////////////////////////////////////////////////

  static class Jline2Console extends EnvConsole
  {
    Jline2Console() throws Exception
    {
      // reader = new ConsoleReader()
      Class cls  = Class.forName("jline.console.ConsoleReader");
      this.reader       = cls.getConstructor(new Class[] {}).newInstance();
      this.readLine     = cls.getMethod("readLine", new Class[] { String.class });
      this.readLineMask = cls.getMethod("readLine", new Class[] { String.class, Character.class });
    }

    public String prompt(String msg)
    {
      try
      {
        return (String)readLine.invoke(reader, new Object[] { msg });
      }
      catch (Exception e)
      {
        throw Err.make(e);
      }
    }

    public String promptPassword(String msg)
    {
      try
      {
        return (String)readLineMask.invoke(reader, new Object[] { msg, new Character('#') });
      }
      catch (Exception e)
      {
        throw Err.make(e);
      }
    }

    private Object reader;        // jline.console.ConsoleReader
    private Method readLine;      // readLine(String)
    private Method readLineMask;  // readLine(String,Character)
  }
}

