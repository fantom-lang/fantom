//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//

using System;
using System.Collections;
using System.IO;

namespace Fan.Sys
{
  public class BootEnv : Env
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public BootEnv()
    {
      this.m_args    = initArgs();
      this.m_vars    = initVars();
      this.m_host    = initHost();
      this.m_user    = initUser();
      this.m_in      = new SysInStream(Console.OpenStandardInput());
      this.m_out     = new SysOutStream(Console.OpenStandardOutput());
      this.m_err     = new SysOutStream(Console.OpenStandardError());
      this.m_homeDir = new LocalFile(new DirectoryInfo(Sys.m_homeDir), true).normalize();
      this.m_tempDir = m_homeDir.plus(Uri.fromStr("temp/"), false);
    }

    private static List initArgs()
    {
      return (List)new List(Sys.StrType).toImmutable();
    }

    private static Map initVars()
    {
      Map vars = new Map(Sys.StrType, Sys.StrType);
      try
      {
        vars.caseInsensitive(true);

        // predefined
        vars.set("os.name", Environment.OSVersion.Platform.ToString());
        vars.set("os.version", Environment.OSVersion.Version.ToString());

        // environment variables
        IDictionary getenv = Environment.GetEnvironmentVariables();
        foreach (DictionaryEntry de in getenv)
        {
          string key = (string)de.Key;
          string val = (string)de.Value;
          vars.set(key, val);
        }
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
      return (Map)vars.toImmutable();
    }

    private static string initHost()
    {
      return Environment.MachineName;
    }

    private static string initUser()
    {
      return Environment.UserName;
    }

  //////////////////////////////////////////////////////////////////////////
  // BootEnv
  //////////////////////////////////////////////////////////////////////////

    public void setArgs(string[] args)
    {
      this.m_args = (List)new List(Sys.StrType, args).toImmutable();
    }

  //////////////////////////////////////////////////////////////////////////
  // Obj
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.BootEnvType; }

  //////////////////////////////////////////////////////////////////////////
  // Virtuals
  //////////////////////////////////////////////////////////////////////////

    public override List args() { return m_args; }

    public override Map vars()  { return m_vars; }

    public override string host() { return m_host; }

    public override string user() { return m_user; }

    public override void gc() { GC.Collect(); }

    public override void exit(long status) { System.Environment.Exit((int)status); }

    public override InStream @in() { return m_in; }

    public override OutStream @out() { return m_out; }

    public override OutStream err() { return m_err; }

    public override File homeDir() { return m_homeDir; }

    public override File workDir() { return m_homeDir; }

    public override File tempDir() { return m_tempDir; }

  //////////////////////////////////////////////////////////////////////////
  // Diagnostics
  //////////////////////////////////////////////////////////////////////////

    public override Map diagnostics()
    {
      // TODO: return empty map for now
      Map d = new Map(Sys.StrType, Sys.ObjType);
      return d;
    }

  //////////////////////////////////////////////////////////////////////////
  // Find Files
  //////////////////////////////////////////////////////////////////////////

    public override File findFile(Uri uri, bool check)
    {
      if (uri.isPathAbs()) throw ArgErr.make("Uri must be relative: " + uri).val;
      File f = m_homeDir.plus(uri, false);
      if (f.exists()) return f;
      if (!check) return null;
      throw UnresolvedErr.make("File not found in Env: " + uri).val;
    }

    public override List findAllFiles(Uri uri)
    {
      File f = findFile(uri, false);
      if (f == null) return Sys.FileType.emptyList();
      return new List(Sys.FileType, new File[] { f });
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private List m_args;
    private Map m_vars;
    private string m_host;
    private string m_user;
    private InStream  m_in;
    private OutStream m_out;
    private OutStream m_err;
    private File m_homeDir;
    private File m_tempDir;

  }
}

