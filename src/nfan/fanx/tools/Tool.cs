//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using System.Reflection;
using System.Text;
using Depend = Fan.Sys.Depend;
using Err    = Fan.Sys.Err;
using List   = Fan.Sys.List;
using Pod    = Fan.Sys.Pod;
using Sys    = Fan.Sys.Sys;
using SysProps = Fan.Sys.SysProps;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Tools
{
  public abstract class Tool
  {

  //////////////////////////////////////////////////////////////////////////
  // Fan Assembly Loading
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Register the assembly resolver.
    /// </summary>
    protected Tool()
    {
      AppDomain domain = AppDomain.CurrentDomain;
      domain.AssemblyResolve += new ResolveEventHandler(resolveAssembly);
    }

    /// <summary>
    /// Get the assembly name from the specified fullName.  The fullName
    /// has the following format:
    ///
    /// <name>, Version=<major.minor.build.patch>, Culture=<...>, PublicKeyToken=<...>
    ///
    /// </summary>
    public static string getAssemblyName(string fullName)
    {
      int sep = fullName.IndexOf(',');
      if (sep == -1)
        return fullName;
      else
        return fullName.Substring(0, sep);
    }

    /// <summary>
    /// Resolve an assembly that cannot be found in
    /// the current AppDomain.
    /// </summary>
    public static Assembly resolveAssembly(object sender, ResolveEventArgs args)
    {
      string asmName = getAssemblyName(args.Name);
      AppDomain domain = AppDomain.CurrentDomain;

      // check if already loaded
      Assembly[] current = domain.GetAssemblies();
      for (int i=0; i<current.Length; i++)
        if (asmName == current[i].GetName().Name)
          return current[i];

      // otherwise load it from disk
      string libDir = FileUtil.combine(Sys.HomeDir, "lib", "net");
      string dll = FileUtil.combine(libDir, asmName + ".dll");

      FileInfo f = new FileInfo(dll);
      if (!f.Exists)
      {
        // check tmp dir
        string tmpDir = FileUtil.combine(Sys.HomeDir, "lib", "tmp");
        dll = FileUtil.combine(tmpDir, asmName + ".dll");
        f = new FileInfo(dll);
      }
      if (!f.Exists)
      {
        // not emitted yet, emit
        Pod pod = Pod.find(asmName, true);
        return FTypeEmit.emitPod(pod.fpod, true, null);
      }

      // the file may have been generated by another process, so
      // check if we need to emit to flush out things this process
      // will need from FTypeEmit
      if (!asmName.EndsWith("Native_") && !FTypeEmit.isEmitted(asmName))
      {
        Pod pod = Pod.find(asmName, true);
        return FTypeEmit.emitPod(pod.fpod, true, null);
      }

      BinaryReader fIn = new BinaryReader(f.OpenRead());
      byte[] asm = fIn.ReadBytes((int)f.Length);
      fIn.Close();
      if (asm.Length != f.Length)
        throw new Exception("Could not read " + dll + ": " + asm.Length + " != " + f.Length);

      Assembly result = domain.Load(asm);
      return result;
    }

    /// <summary>
    /// Return the cmd line arguments passed for the
    /// Fan launcher code.
    /// </summary>
    public static string[] getArgv()
    {
      return argv;
    }

    /// <summary>
    /// Initialize the .NET enviornement.
    /// </summary>
    public static void sysInit(string reserved)
    {
      if (isInit) return;
      try
      {
        string[] s = reserved.Split('\n');

        // get fan.home
        string fanHome = s[0];
        SysProps.putProperty("fan.home", fanHome);

        // get correct cmd line args
        argv = new string[s.Length-1];
        Array.Copy(s, 1, argv, 0, argv.Length);

        // check for dll reuse
        verifyDlls();
      }
      catch (Exception e)
      {
        Err.dumpStack(e);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Verify Dlls
  //////////////////////////////////////////////////////////////////////////

    static void verifyDlls()
    {
      // get dirs
      string podDir = FileUtil.combine(Sys.HomeDir, "lib", "fan");
      string tmpDir = FileUtil.combine(Sys.HomeDir, "lib", "tmp");

      // check our tmp dir - cleaning up out-of-date DLL and PDB files
      if (Directory.Exists(tmpDir))
      {
        string[] tmp = Directory.GetFiles(tmpDir, "*.dll");
        Hashtable keep = new Hashtable();

        string sysDll = FileUtil.combine(Sys.HomeDir, "lib", "net", "sys.dll");
        DateTime sysModified = File.GetLastWriteTime(sysDll);

        if (debug)
        {
          System.Console.WriteLine("\n sys  " + sysModified + "\n");
          System.Console.WriteLine(pad(" pod", 15) + pad("action", 10) + pad("podTime", 25) + pad("dllTime", 25));
          System.Console.WriteLine(pad(" ---", 15) + pad("------", 10) + pad("-------", 25) + pad("-------", 25));
        }

        for (int i=0; i<tmp.Length; i++)
        {
          string dll  = tmp[i];
          int start   = dll.LastIndexOf("\\")+1;
          int end     = dll.IndexOf(".");
          string name = dll.Substring(start, end-start);
          DateTime podModified = DateTime.MinValue;
          DateTime dllModified = DateTime.MinValue;

          // native get handled by pod
          if (name.EndsWith("Native_")) continue;

          // check for pod
          string pod  = FileUtil.combine(podDir, name+".pod");
          if (File.Exists(pod))
          {
            // if the DLL is still up-to-date, just reuse it
            podModified = File.GetLastWriteTime(pod);
            dllModified = File.GetLastWriteTime(dll);
            if (podModified < dllModified)
              keep[name] = new PodInfo(Pod.find(name, false), dllModified);
          }

          if (debug)
          {
            PodInfo info = keep[name] as PodInfo;
            StringBuilder b = new StringBuilder(pad(" "+name, 15));
            b.Append(pad(keep[name] != null ? "[keep]" : "[delete]", 10));
            if (podModified != DateTime.MinValue) b.Append(pad(podModified.ToString(), 25));
            if (dllModified != DateTime.MinValue) b.Append(pad(dllModified.ToString(), 25));
            System.Console.WriteLine(b);
          }
        }

        if (debug) System.Console.WriteLine("");

        // check pod dependencies
        string[] keys = new string[keep.Count];
        keep.Keys.CopyTo(keys, 0);
        for (int k=0; k<keys.Length; k++)
        {
          string name = keys[k];
          PodInfo info = keep[name] as PodInfo;

          // check sys first
          if (info.modified < sysModified)
          {
            keep.Remove(name);
            if (debug) System.Console.WriteLine(pad(" "+name,15)+"[delete] due to sys");
            continue;
          }

          // check for out-of-date depends
          List depends = info.pod.depends();
          for (int i=0; i<depends.sz(); i++)
          {
            Depend d = depends.get(i) as Depend;
            string n = d.name();
            if (n == "sys") continue; // skip sys
            if (keep[n] == null)
            {
              keep.Remove(name);
              if (debug) System.Console.WriteLine(pad(" "+name,15)+"[delete] due to " + n);
              break;
            }
          }
        }

        if (debug)
        {
          if (keep.Count > 0)
          {
            System.Console.WriteLine("");
            foreach (string key in keep.Keys)
              System.Console.WriteLine(" [keep]  " + key);
          }
          System.Console.WriteLine("");
        }

        // delete out-of-date
        for (int i=0; i<tmp.Length; i++)
        {
          string dll  = tmp[i];
          int start   = dll.LastIndexOf("\\")+1;
          int end     = dll.IndexOf(".");
          string name = dll.Substring(start, end-start);
          string pdb  = FileUtil.combine(tmpDir, name+".pdb");

          // native get handled by pod
          if (name.EndsWith("Native_"))
            name = name.Substring(0, name.Length-"Native_".Length);

          // if keep, skip
          if (keep[name] != null) continue;

          // nuke it!
          if (debug)
          {
            System.Console.WriteLine(" [delete]  " + tmp[i]);
            if (File.Exists(pdb)) System.Console.WriteLine(" [delete]  " + pdb);
          }
          File.Delete(dll);
          File.Delete(pdb);
        }

        if (debug) System.Console.WriteLine("");
      }

      // mark env as initialized
      isInit = true;
    }

    static string pad(string str, int pad)
    {
      int sp = pad-str.Length;
      if (sp <= 0) return str;
      StringBuilder b = new StringBuilder(str);
      for (int i=0; i<sp; i++) b.Append(" ");
      return b.ToString();
    }

    class PodInfo
    {
      public PodInfo(Pod pod, DateTime modified)
      {
        this.pod = pod;
        this.modified = modified;
      }
      public Pod pod;
      public DateTime modified;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static bool isInit = false;
    static string[] argv = new string[0];
    static bool debug = false;

  }
}