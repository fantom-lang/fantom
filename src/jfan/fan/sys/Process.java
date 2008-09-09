//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;

/**
 * Process
 */
public class Process
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

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
    if (v != null && (!v.exists().val || !v.isDir().val))
      throw ArgErr.make("Invalid working directory: " + v).val;
    this.dir = v;
  }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  public final Int run()
  {
    try
    {
      // start process
      java.lang.Process p = toProcessBuilder().start();

      // read from input stream until terminated
      InputStream in = p.getInputStream();
      int ch;
      while ((ch = in.read()) >= 0)
      {
        System.out.write(ch);
        System.out.flush();
      }

      // return exit code
      return Int.make(p.waitFor());
    }
    catch (Throwable e)
    {
      throw Err.make(e).val;
    }
  }

  private ProcessBuilder toProcessBuilder()
  {
    String[] strings = new String[command.sz()];
    for (int i=0; i<command.sz(); ++i)
      strings[i] = ((Str)command.get(i)).val;

    ProcessBuilder builder = new ProcessBuilder(strings);
    builder.redirectErrorStream(true);
    if (dir != null) builder.directory(((LocalFile)dir).file);
    return builder;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private List command;
  private File dir;

}