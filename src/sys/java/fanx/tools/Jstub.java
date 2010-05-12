//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Mar 06  Brian Frank  Creation
//
package fanx.tools;

import java.io.File;
import java.io.FileOutputStream;
import java.util.*;
import java.util.zip.*;
import fan.sys.*;
import fan.sys.List;
import fanx.fcode.*;
import fanx.emit.*;
import fanx.util.*;

/**
 * Jstub loads an fcode pod and emits to a jar file
 */
public class Jstub
{

//////////////////////////////////////////////////////////////////////////
// Stub
//////////////////////////////////////////////////////////////////////////

  /**
   * Stub the specified pod
   */
  public void stub(String podName, File outDir)
    throws Exception
  {
    System.out.println("    Java Stub [" + podName + "]");

    // read fcode into memory
    Pod pod = Pod.find(podName, true);
    ClassType[] types = (ClassType[])pod.types().toArray(new ClassType[pod.types().sz()]);

    // open jar file
    ZipOutputStream out = new ZipOutputStream(new FileOutputStream(new File(outDir, podName + ".jar")));
    try
    {
      // emit pod - we have to read back the pod here because normal
      // pod loading clears all these tables as soon as Pod$ is emitted
      FPodEmit podEmit = FPodEmit.emit(Pod.readFPod(podName));
      add(out, podEmit.className, podEmit.classFile);

      // write out each type to one or more .class files
      for (int i=0; i<types.length; ++i)
      {
        ClassType type = types[i];
        if (type.isNative()) continue;

        FTypeEmit[] emitted = type.emitToClassFiles();

        // write to jar
        for (int j=0; j<emitted.length; ++j)
        {
          FTypeEmit emit = emitted[j];
          add(out, emit.className, emit.classFile);
        }
      }

      // write manifest
      out.putNextEntry(new ZipEntry("meta-inf/Manifest.mf"));
      out.write("Manifest-Version: 1.0\n".getBytes());
      out.write("Created-By: Fantom Java Stub\n".getBytes());
      out.closeEntry();
    }
    finally
    {
      try { out.close(); } catch (Exception e) {}
    }
  }

  private void add(ZipOutputStream out, String className, Box classFile)
    throws Exception
  {
    String path = className + ".class";
    if (verbose) System.out.println("  " + path);
    out.putNextEntry(new ZipEntry(path));
    out.write(classFile.buf, 0, classFile.len);
    out.closeEntry();
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  /**
   * Main entry point for compiler.
   */
  public int run(String[] args)
    throws Exception
  {
    ArrayList pods = new ArrayList();
    File outDir = new File(".");

    if (args.length == 0) { help(); return -1; }

    // process args
    for (int i=0; i<args.length; ++i)
    {
      String a = args[i].intern();
      if (a.length() == 0) continue;
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
        if (i+1 >= args.length)
        {
          System.out.println("ERROR: must specified dir with -d option");
          return -1;
        }
        outDir = new File(args[++i]);
      }
      else if (a.charAt(0) == '-')
      {
        System.out.println("WARNING: Unknown option " + a);
      }
      else
      {
        pods.add(a);
      }
    }

    if (pods.size() == 0) { help(); return -1; }

    for (int i=0; i<pods.size(); ++i)
      stub((String)pods.get(i), outDir);
    return 0;
  }

  /**
   * Dump help usage.
   */
  void help()
  {
    System.out.println("Java Stub");
    System.out.println("Usage:");
    System.out.println("  jstub [options] <pod> ...");
    System.out.println("Options:");
    System.out.println("  -help, -h, -?  print usage help");
    System.out.println("  -d             output directory");
    System.out.println("  -v             verbose mode");
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public static void main(String[] args)
    throws Exception
  {
    System.exit(new Jstub().run(args));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  boolean verbose;

}