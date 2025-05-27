//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Jun 24  Brian Frank  Creation
//
package fan.util;

import java.io.PrintStream;
import java.lang.reflect.Method;
import fan.sys.*;

public abstract class NativeConsole extends Console
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public static NativeConsole curNative()
  {
    if (cur == null) cur = create();
    return cur;
  }
  private static NativeConsole cur;

  /*
   * To test jline2:
   * java -Dfan.home=/work/fan -cp /work/fan/lib/java/sys.jar:/work/stuff/jline/jline-2.9.jar fanx.tools.Fan util::ConsoleTest
   */

  private static NativeConsole create()
  {
    try { return new Jline3Console(); } catch (Exception e) {}
    try { return new Jline2Console(); } catch (Exception e) {}
    if (System.console() != null) return new JavaConsole(System.console());
    return new StdinConsole();
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Long width()
  {
    return null;
  }

  public Long height()
  {
    return null;
  }

  public Console debug(Object msg) { return debug(msg, null); }
  public Console debug(Object msg, Err err)
  {
    return log("DEBUG", msg, err);
  }

  public Console info(Object msg) { return info(msg, null); }
  public Console info(Object msg, Err err)
  {
    return log("", msg, err);
  }

  public Console warn(Object msg) { return warn(msg, null); }
  public Console warn(Object msg, Err err)
  {
    return log("WARN", msg, err);
  }

  public Console err(Object msg) { return err(msg, null); }
  public Console err(Object msg, Err err)
  {
    return log("ERR", msg, err);
  }

  private Console log(String level, Object msg, Err err)
  {
    if (indent > 0)
    {
      out().print(FanStr.spaces(indent*2));
    }
    if (!level.isEmpty())
    {
      out().print(level);
      out().print(": ");
    }
    out().println(msg);
    if (err != null)
    {
      List lines = FanStr.splitLines(err.traceToStr());
      for (int i=0; i<lines.sz(); ++i)
      {
        out().print(FanStr.spaces(indent*2));
        out().println(lines.get(i));
      }
    }
    return this;
  }

  public Console table(Object obj)
  {
    ConsoleTable.make(obj).dump(this);
    return this;
  }

  public Console group(Object obj) { return group(obj, false); }
  public Console group(Object obj, boolean collapse)
  {
    info(obj);
    indent++;
    return this;
  }
  private int indent;

  public Console groupEnd()
  {
    indent--;
    if (indent < 0) indent = 0;
    return this;
  }

  public Console clear()
  {
    return this;
  }

  public String prompt() { return prompt(""); }
  public abstract String prompt(String msg);

  public String promptPassword() { return promptPassword(""); }
  public abstract String promptPassword(String msg);

  public Type typeof() { return typeof$(); }

  public static Type typeof$()
  {
    if (type == null) type = Type.find("util::NativeConsole");
    return type;
  }
  private static Type type;

  public String toStr()
  {
    return getClass().getName();
  }

  private PrintStream out()
  {
    return System.out;
  }

//////////////////////////////////////////////////////////////////////////
// StdinConsole
//////////////////////////////////////////////////////////////////////////

  static class StdinConsole extends NativeConsole
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

  static class JavaConsole extends NativeConsole
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

  static class Jline3Console extends NativeConsole
  {
    Jline3Console() throws Exception
    {
      // TerminalBuilder.terminal()
      Class terminalBuilder = Class.forName("org.jline.terminal.TerminalBuilder");
      this.terminal  = terminalBuilder.getMethod("terminal", new Class[] {}).invoke(null);

      // reader = LineReaderBuilder.builder().build()
      Class builderClass  = Class.forName("org.jline.reader.LineReaderBuilder");
      Class readerClass   = Class.forName("org.jline.reader.LineReader");
      Method builderCtor  = builderClass.getMethod("builder", new Class[] {});
      Method builderBuild = builderClass.getMethod("build", new Class[] {});
      this.reader         = builderBuild.invoke(builderCtor.invoke(null));
      this.readLine       = readerClass.getMethod("readLine", new Class[] { String.class });
      this.readLineMask   = readerClass.getMethod("readLine", new Class[] { String.class, Character.class });
    }

    public Long width()
    {
      try
      {
        return ((Integer)terminal.getClass().getMethod("getWidth").invoke(terminal)).longValue();
      }
      catch (Exception e) {} // ignore
      return null;
    }

    public Long height()
    {
      try
      {
        return ((Integer)terminal.getClass().getMethod("getHeight").invoke(terminal)).longValue();
      }
      catch (Exception e) {} // ignore
      return null;
    }

    public Console clear()
    {
      try
      {
        // terminal.puts(InfoCmp$Capability.clear_screen)
        Class capabilityClass = Class.forName("org.jline.utils.InfoCmp$Capability");
        Object clear = capabilityClass.getField("clear_screen").get(null);
        Method puts = terminal.getClass().getMethod("puts", new Class[] { capabilityClass, Object[].class });
        puts.invoke(terminal, clear, new Object[0]);

        // terminal.flush()
        terminal.getClass().getMethod("flush").invoke(terminal);
      }
      catch (Exception e) {} // ignore
      return this;
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

    private Object terminal;      // org.jline.terminal.Terminal
    private Object reader;        // org.jline.reader.LineReader
    private Method readLine;      // readLine(String)
    private Method readLineMask;  // readLine(String,Character)
  }

//////////////////////////////////////////////////////////////////////////
// Jline3Console
//////////////////////////////////////////////////////////////////////////

  static class Jline2Console extends NativeConsole
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

