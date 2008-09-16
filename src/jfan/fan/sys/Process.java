//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.util.Iterator;
import java.util.Map.Entry;

/**
 * Process
 */
public class Process
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Process make()
  {
    return new Process(new List(Sys.StrType), null);
  }

  public static Process make(List command)
  {
    return new Process(command, null);
  }

  public static Process make(List command, File dir)
  {
    return new Process(command, dir);
  }

  private Process(List command, File dir)
  {
    command(command);
    dir(dir);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type()
  {
    return Sys.ProcessType;
  }

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  public List command() { return command; }
  public void command(List v) { this.command = v; }

  public File dir() { return dir; }
  public void dir(File v)
  {
    if (proc != null) throw Err.make("Cannot set Process.dir while running").val;
    if (v != null && (!v.exists().val || !v.isDir().val))
      throw ArgErr.make("Invalid working directory: " + v).val;
    this.dir = v;
  }

  public Map env()
  {
    if (env == null)
    {
      env = new Map(Sys.StrType, Sys.StrType);
      Iterator it = new ProcessBuilder().environment().entrySet().iterator();
      while (it.hasNext())
      {
        Entry entry = (Entry)it.next();
        String key = (String)entry.getKey();
        String val = (String)entry.getValue();
        env.set(Str.make(key), Str.make(val));
      }
    }
    return env;
  }

  public Bool mergeErr() { return Bool.make(mergeErr); }
  public void mergeErr(Bool v) { mergeErr = v.val;  }

  public OutStream out() { return out; }
  public void out(OutStream out)
  {
    if (proc != null) throw Err.make("Cannot set Process.out while running").val;
    this.out = out;
  }

  public OutStream err() { return err; }
  public void err(OutStream err)
  {
    if (proc != null) throw Err.make("Cannot set Process.err while running").val;
    this.err = err;
  }

  public InStream in() { return in; }
  public void in(InStream in)
  {
    if (proc != null)  throw Err.make("Cannot set Process.in while running").val;
    this.in = in;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public final Process run()
  {
    if (proc != null) throw Err.make("Process already running").val;
    try
    {
      // commands
      String[] strings = new String[command.sz()];
      for (int i=0; i<command.sz(); ++i)
        strings[i] = ((Str)command.get(i)).val;
      ProcessBuilder builder = new ProcessBuilder(strings);

      // environment
      if (env != null)
      {
        Iterator it = env.pairsIterator();
        while (it.hasNext())
        {
          Entry entry = (Entry)it.next();
          Str key = (Str)entry.getKey();
          Str val = (Str)entry.getValue();
          builder.environment().put(key.val, val.val);
        }
      }

      // working directory
      if (dir != null)
        builder.directory(((LocalFile)dir).file);

      // mergeErr
      if (mergeErr)
        builder.redirectErrorStream(true);

      // map Fan streams to Java streams


      // start it
      this.proc = builder.start();

      // now launch threads to pipe std out, in, and err
      new PipeInToOut("out", proc.getInputStream(), out).start();
      if (!mergeErr) new PipeInToOut("err", proc.getErrorStream(), err).start();
      if (in != null) new PipeOutToIn(proc, proc.getOutputStream(), in).start();

      return this;
    }
    catch (Throwable e)
    {
      this.proc = null;
      throw Err.make(e).val;
    }
  }

  public final Int join()
  {
    if (proc == null) throw Err.make("Process not running").val;
    try
    {
      return Int.make(proc.waitFor());
    }
    catch (Throwable e)
    {
      throw Err.make(e).val;
    }
    finally
    {
      proc = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// PipeInToOut
//////////////////////////////////////////////////////////////////////////

  static class PipeInToOut extends java.lang.Thread
  {
    PipeInToOut(String name, InputStream in, OutStream out)
    {
      super("Process." +  name);
      this.in = in;
      if (out != null)
        this.out = SysOutStream.java(out);
    }

    public void run()
    {
      byte[] temp = new byte[256];
      while (true)
      {
        try
        {
          int n = in.read(temp, 0, temp.length);
          if (n < 0) break;
          if (out != null) out.write(temp, 0, n);
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
    }

    InputStream in;
    OutputStream out;
  }

//////////////////////////////////////////////////////////////////////////
// PipeOutToIn
//////////////////////////////////////////////////////////////////////////

  static class PipeOutToIn extends java.lang.Thread
  {
    PipeOutToIn(java.lang.Process proc, OutputStream out, InStream in)
    {
      super("Process.in");
      this.proc = proc;
      this.out = out;
      this.in  = SysInStream.java(in);
    }

    public void run()
    {
      byte[] temp = new byte[256];
      while (procIsAlive())
      {
        try
        {
          int n = in.read(temp, 0, temp.length);
          if (n < 0) break;
          out.write(temp, 0, n);
          out.flush();
        }
        catch (Throwable e)
        {
          e.printStackTrace();
        }
      }
    }

    boolean procIsAlive()
    {
       try
       {
         proc.exitValue();
         return false;
       }
       catch (IllegalThreadStateException e)
       {
         return true;
       }
    }

    java.lang.Process proc;
    OutputStream out;
    InputStream in;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private List command;
  private File dir;
  private Map env;
  private boolean mergeErr = true;
  private OutStream out = Sys.out();
  private OutStream err = Sys.err();
  private InStream in   = null;
  private volatile java.lang.Process proc;

}