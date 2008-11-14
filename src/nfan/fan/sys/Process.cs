//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Feb 08  Andy Frank  Creation
//

using System;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Process
  /// </summary>
  public class Process : FanObj
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
      this.command(command);
      this.dir(dir);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type()
    {
      return Sys.ProcessType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Configuration
  //////////////////////////////////////////////////////////////////////////

    public List command() { return m_command; }
    public void command(List v) { this.m_command = v; }

    public File dir() { return m_dir; }
    public void dir(File v)
    {
      if (v != null && (!v.exists().booleanValue() || !v.isDir().booleanValue()))
        throw ArgErr.make("Invalid working directory: " + v).val;
      this.m_dir = v;
    }

  //////////////////////////////////////////////////////////////////////////
  // Lifecycle
  //////////////////////////////////////////////////////////////////////////

    public long run()
    {
      try
      {
        // get arguments
        string fileName = m_command.get(0) as string;
        StringBuilder args = new StringBuilder();
          for (int i=1; i<m_command.sz(); ++i)
          {
            if (i > 1) args.Append(" ");
            args.Append(m_command.get(i) as string);
          }

        // config and run process
        System.Diagnostics.Process p = new System.Diagnostics.Process();
        p.StartInfo.UseShellExecute = false;
        p.StartInfo.FileName = fileName;
        p.StartInfo.Arguments = args.ToString();
        if (m_dir != null)
          p.StartInfo.WorkingDirectory = ((LocalFile)m_dir).m_file.FullName;
        p.Start();
        p.WaitForExit();

        // return exit code
        return p.ExitCode;
      }
      catch (Exception e)
      {
        throw Err.make(e).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private List m_command;
    private File m_dir;

  }
}