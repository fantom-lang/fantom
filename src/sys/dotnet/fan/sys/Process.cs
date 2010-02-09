//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Feb 08  Andy Frank  Creation
//

using System;
using System.Collections;
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
      this.command(command);
      this.dir(dir);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()
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
      checkRun();
      if (v != null && (!v.exists() || !v.isDir()))
        throw ArgErr.make("Invalid working directory: " + v).val;
      this.m_dir = v;
    }

    public Map env()
    {
      if (m_env == null)
      {
        m_env = new Map(Sys.StrType, Sys.StrType);
        IDictionaryEnumerator en =
         (IDictionaryEnumerator)new System.Diagnostics.Process().
           StartInfo.EnvironmentVariables.GetEnumerator();
        while (en.MoveNext())
        {
          string key = (string)en.Key;
          string val = (string)en.Value;
          m_env.set(key, val);
        }
      }
      return m_env;
    }

    public bool mergeErr() { return m_mergeErr; }
    public void mergeErr(bool v) { checkRun(); m_mergeErr = v;  }

    public OutStream @out() { return m_out; }
    public void @out(OutStream @out) { checkRun(); this.m_out = @out; }

    public OutStream err() { return m_err; }
    public void err(OutStream err) { checkRun(); this.m_err = err; }

    public InStream @in() { return m_in; }
    public void @in(InStream @in) { checkRun(); this.m_in = @in; }

  //////////////////////////////////////////////////////////////////////////
  // Lifecycle
  //////////////////////////////////////////////////////////////////////////

    public Process run()
    {
      checkRun();
      try
      {
        // arguments
        string fileName = m_command.get(0) as string;
        StringBuilder args = new StringBuilder();
          for (int i=1; i<m_command.sz(); i++)
          {
            if (i > 1) args.Append(" ");
            args.Append(m_command.get(i) as string);
          }

        // create process
        m_proc = new System.Diagnostics.Process();
        m_proc.StartInfo.UseShellExecute = false;
        m_proc.StartInfo.FileName = fileName;
        m_proc.StartInfo.Arguments = args.ToString();

        // environment
        if (m_env != null)
        {
          IDictionaryEnumerator en = m_env.pairsIterator();
          while (en.MoveNext())
          {
            string key = (string)en.Key;
            string val = (string)en.Value;
            m_proc.StartInfo.EnvironmentVariables[key] = val;
          }
        }

        // working directory
        if (m_dir != null)
          m_proc.StartInfo.WorkingDirectory = ((LocalFile)m_dir).m_file.FullName;

        // streams
        if (m_in != null) m_proc.StartInfo.RedirectStandardInput = true;
        m_proc.StartInfo.RedirectStandardOutput = true;
        m_proc.StartInfo.RedirectStandardError  = true;
        m_proc.OutputDataReceived += new System.Diagnostics.DataReceivedEventHandler(outHandler);
        m_proc.ErrorDataReceived  += new System.Diagnostics.DataReceivedEventHandler(errHandler);

        // start it
        m_proc.Start();

        // start async read/writes
        if (m_in != null)
        {
          new System.Threading.Thread(
            new System.Threading.ThreadStart(inHandler)).Start();
        }
        m_proc.BeginOutputReadLine();
        m_proc.BeginErrorReadLine();

        return this;
      }
      catch (System.Exception e)
      {
        m_proc = null;
        throw Err.make(e).val;
      }
    }

    public long join()
    {
      if (m_proc == null) throw Err.make("Process not running").val;
      try
      {
        m_proc.WaitForExit();
        return m_proc.ExitCode;
      }
      catch (System.Exception e)
      {
        throw Err.make(e).val;
      }
    }

    private void checkRun()
    {
      if (m_proc != null) throw Err.make("Process already run").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Handlers
  //////////////////////////////////////////////////////////////////////////

    private void inHandler()
    {
      System.IO.Stream input  = SysInStream.dotnet(m_in);
      System.IO.Stream output = m_proc.StandardInput.BaseStream;
      byte[] temp = new byte[256];

      while (!m_proc.HasExited)
      {
        try
        {
          int n = input.Read(temp, 0, temp.Length);
          if (n < 0) break;
          output.Write(temp, 0, n);
          output.Flush();
        }
        catch (System.Exception e)
        {
          Err.dumpStack(e);
        }
      }
    }

    private void outHandler(object sender, System.Diagnostics.DataReceivedEventArgs args)
    {
      if (String.IsNullOrEmpty(args.Data)) return;
      if (m_out != null) m_out.printLine(args.Data);
    }

    private void errHandler(object sender, System.Diagnostics.DataReceivedEventArgs args)
    {
      if (String.IsNullOrEmpty(args.Data)) return;
      if (m_mergeErr)
      {
        if (m_out != null) m_out.printLine(args.Data);
      }
      else
      {
        if (m_err != null) m_err.printLine(args.Data);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private List m_command;
    private File m_dir;
    private Map m_env;
    private bool m_mergeErr = true;
    private OutStream m_out = Env.cur().@out();
    private OutStream m_err = Env.cur().err();
    private InStream m_in   = null;
    private volatile System.Diagnostics.Process m_proc;

  }
}