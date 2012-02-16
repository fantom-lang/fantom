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

  public Type typeof()
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
    checkRun();
    if (v != null && (!v.exists() || !v.isDir()))
      throw ArgErr.make("Invalid working directory: " + v);
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
        env.set(key, val);
      }
    }
    return env;
  }

  public boolean mergeErr() { return mergeErr; }
  public void mergeErr(boolean v) { checkRun(); mergeErr = v;  }

  public OutStream out() { return out; }
  public void out(OutStream out) { checkRun(); this.out = out; }

  public OutStream err() { return err; }
  public void err(OutStream err) { checkRun(); this.err = err; }

  public InStream in() { return in; }
  public void in(InStream in) { checkRun(); this.in = in;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public final Process run()
  {
    checkRun();
    try
    {
      // commands
      String[] strings = new String[command.sz()];
      for (int i=0; i<command.sz(); ++i)
        strings[i] = (String)command.get(i);
      ProcessBuilder builder = new ProcessBuilder(strings);

      // environment
      if (env != null)
      {
        Iterator it = env.pairsIterator();
        while (it.hasNext())
        {
          Entry entry = (Entry)it.next();
          String key = (String)entry.getKey();
          String val = (String)entry.getValue();
          builder.environment().put(key, val);
        }
      }

      // working directory
      if (dir != null)
        builder.directory(((LocalFile)dir).file);

      // mergeErr
      if (mergeErr)
        builder.redirectErrorStream(true);

      // map Fantom streams to Java streams


      // start it
      this.proc = builder.start();

      // now launch threads to pipe std out, in, and err
      new PipeInToOut(this, "out", proc.getInputStream(), out).start();
      if (!mergeErr) new PipeInToOut(this, "err", proc.getErrorStream(), err).start();
      if (in != null) new PipeOutToIn(this, proc.getOutputStream(), in).start();

      return this;
    }
    catch (Throwable e)
    {
      this.proc = null;
      throw Err.make(e);
    }
  }

  public final long join()
  {
    if (proc == null) throw Err.make("Process not running");
    try
    {
      return proc.waitFor();
    }
    catch (Throwable e)
    {
      throw Err.make(e);
    }
  }

  public final Process kill()
  {
    if (proc == null) throw Err.make("Process not running");
    proc.destroy();
    return this;
  }

  private void checkRun()
  {
    if (proc != null) throw Err.make("Process already run");
  }

  boolean isAlive()
  {
    // hacky to use exception for flow control, but there
    // doesn't seem to be any other way to check state
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

//////////////////////////////////////////////////////////////////////////
// PipeInToOut
//////////////////////////////////////////////////////////////////////////

  static class PipeInToOut extends java.lang.Thread
  {
    PipeInToOut(Process proc, String name, InputStream in, OutStream out)
    {
      super("Process." +  name);
      this.proc = proc;
      this.in   = in;
      this.out  = out == null ? null : SysOutStream.java(out);
    }

    public void run()
    {
      byte[] temp = new byte[256];
      while (true)
      {
        try
        {
          int n = in.read(temp, 0, temp.length);
          if (n < 0) { if (out != null) out.flush(); break; }
          if (out != null) out.write(temp, 0, n);
        }
        catch (Throwable e)
        {
          if (proc.isAlive()) e.printStackTrace();
          else return;
        }
      }
    }

    final Process proc;
    final InputStream in;
    final OutputStream out;
  }

//////////////////////////////////////////////////////////////////////////
// PipeOutToIn
//////////////////////////////////////////////////////////////////////////

  static class PipeOutToIn extends java.lang.Thread
  {
    PipeOutToIn(Process proc, OutputStream out, InStream in)
    {
      super("Process.in");
      this.proc = proc;
      this.out = out;
      this.in  = SysInStream.java(in);
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
          out.write(temp, 0, n);
          out.flush();
        }
        catch (Throwable e)
        {
          if (proc.isAlive()) e.printStackTrace();
          else return;
        }
      }
    }

    final Process proc;
    final OutputStream out;
    final InputStream in;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private List command;
  private File dir;
  private Map env;
  private boolean mergeErr = true;
  private OutStream out = Env.cur().out();
  private OutStream err = Env.cur().err();
  private InStream in   = null;
  private volatile java.lang.Process proc;

}