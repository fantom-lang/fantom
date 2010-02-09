//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 May 07  Andy Frank  Creation
//

using System.IO;
using System.Collections;
using Fan.Sys;
using Fanx.Emit;
using Fanx.Fcode;
using Fanx.Util;
using ICSharpCode.SharpZipLib.Zip;

namespace Fanx.Tools
{
  /// <summary>
  /// .NET Stub
  /// </summary>
  ///
  public class Nstub : Tool
  {

  //////////////////////////////////////////////////////////////////////////
  // Stub
  //////////////////////////////////////////////////////////////////////////

    public static void stub(string podName, DirectoryInfo outDir, bool verbose)
    {
      writeLine("    .NET Stub [" + podName + "]");

      string fanHome = SysProps.getProperty("fan.home");
      string podPath = fanHome + "\\lib\\fan\\" + podName + ".pod";
      string target = new FileInfo(outDir + "\\" + podName + ".dll").FullName;

      if (verbose)
      {
        writeLine("  <- " + podPath);
        Pod pod = Pod.doFind(podName, true, null);
        List list = pod.types();
        string pre = "Fan." + FanUtil.upper(podName) + ".";
        for (int i=0; i<list.sz(); i++)
          writeLine("  " + pre + (list.get(i) as Type).name());
        writeLine("  -> " + target);
      }

      FStore store = new FStore(new ZipFile(podPath));
      FPod fpod = new FPod(podName, store);
      fpod.read();
      FTypeEmit.emitPod(fpod, false, target);
    }

  //////////////////////////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////////////////////////

    public static int run(string reserved)
    {
      sysInit(reserved);

      try
      {
        ArrayList pods = new ArrayList();
        DirectoryInfo outDir = new DirectoryInfo(".");
        bool verbose = false;

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
          else if (a == "-v")
          {
            verbose = true;
          }
          else if (a == "-d")
          {
            if (i+1 >= args.Length)
            {
              writeLine("ERROR: must specified dir with -d option");
              return -1;
            }
            outDir = new DirectoryInfo(args[++i]);
          }
          else if (a[0] == '-')
          {
            writeLine("WARNING: Unknown option " + a);
          }
          else
          {
            pods.Add(a);
          }
        }

        if (pods.Count == 0) { help(); return -1; }

        for (int i=0; i<pods.Count; i++)
          stub((string)pods[i], outDir, verbose);
        return 0;
      }
      catch (System.Exception e)
      {
        Err.dumpStack(e);
        return -1;
      }
    }

    static void help()
    {
      writeLine(".NET Stub");
      writeLine("Usage:");
      writeLine("  nstub [options] <pod> ...");
      writeLine("Options:");
      writeLine("  -help, -h, -?  print usage help");
      writeLine("  -d             output directory");
      writeLine("  -v             verbose mode");
    }

    static void writeLine(string s)
    {
      System.Console.WriteLine(s);
    }

  }
}