//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.io.File;
import java.io.FileOutputStream;
import java.net.*;
import java.security.*;
import java.util.*;
import fanx.emit.*;
import fanx.util.*;

/**
 * FanClassLoader is used to emit fcode to Java bytecode.  It manages
 * the "fan." namespace to map to dynamically loaded Fantom classes.
 */
public class FanClassLoader
  extends URLClassLoader
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FanClassLoader(Pod  pod)
  {
    super(new URL[0], extClassLoader);
    try
    {
      this.pod = pod;
      this.allPermissions = new AllPermission().newPermissionCollection();
      this.codeSource = new CodeSource(new java.net.URL("file://"), (CodeSigner[])null);
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Load Fan
//////////////////////////////////////////////////////////////////////////

  public Class loadFan(String name, Box classfile)
  {
    try
    {
      synchronized(pendingClasses)
      {
        pendingClasses.put(name, classfile);
      }
      return loadClass(name);
    }
    catch (ClassNotFoundException e)
    {
      e.printStackTrace();
      throw Err.make("Cannot load class: " + name, e).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// ClassLoader
//////////////////////////////////////////////////////////////////////////

  public String toString()
  {
    return "FanClassLoader[" + pod.name() + "]";
  }

  protected PermissionCollection getPermissions(CodeSource src)
  {
    return allPermissions;
  }

  protected Class findClass(String name)
    throws ClassNotFoundException
  {
    try
    {
      Class cls;

      // first check if the classfile in my pending queue
      cls = findPendingClass(name);
      if (cls != null) return cls;

      // anything starting with "fan." maps to a Fantom Type (or native peer code)
      cls = findFanClass(name);
      if (cls != null) return cls;

      // fallback to default URLClassLoader loader
      // implementation which searches my ext jars
      return super.findClass(name);
    }
    catch (NoClassDefFoundError e)
    {
      String s = e.toString();
      if (s.contains("eclipse") && s.contains("swt"))
        System.out.println("ERROR: cannot load SWT library - see `http://fantom.org/doc/docTools/Setup.html#swt`");
      throw e;
    }
  }

  private Class findPendingClass(String name)
  {
    Box pending = null;
    synchronized(pendingClasses)
    {
      pending = (Box)pendingClasses.get(name);
      if (pending != null) pendingClasses.remove(name);
    }
    if (pending == null) return null;
    // if (name.indexOf("Foo") > 0) dumpToFile(name, pending);
    return defineClass(name, pending.buf, 0, pending.len, codeSource);
  }

  private Class findFanClass(String name)
    throws ClassNotFoundException
  {
    // anything starting with "fan." maps to a Fantom Type (or native peer code)
    if (!name.startsWith("fan.")) return null;

    // fan.{pod}.{type}
    int dot = name.indexOf('.', 4);
    String podName  = name.substring(4, dot);
    String typeName = name.substring(dot+1);

    // check if this is my pod
    if (!pod.name().equals(podName))
    {
      Pod pod = Pod.doFind(podName, true, null, null);
      return pod.classLoader.loadClass(name);
    }

    // see if we can find a precompiled class
    Class cls = findPrecompiledClass(name, podName, typeName);
    if (cls != null) return cls;

    // ensure pod is emitted with our constant pool before
    // loading any classes inside of it (if this was the
    // actual class to load, then we are done)
    pod.emit();
    if (typeName.equals("$Pod")) return pod.emit();

    // if the type name ends with $ then this is a mixin body
    // class being used before we have loaded the mixin interface,
    // so load them both, then we should it registered by name;
    // same goes for $Val for Err value types
    if (typeName.endsWith("$") || typeName.endsWith("$Val"))
    {
      int strip = typeName.endsWith("$") ? 1 : 4;
      ClassType t = (ClassType)pod.type(typeName.substring(0, typeName.length()-strip), true);
      cls = t.emit();
      return loadClass(name);
    }

    // if there wasn't a precompiled class, then this must
    // be a normal fcode type which we need to emit
    ClassType t = (ClassType)pod.type(typeName, true);
    return t.emit();
  }

  private Class findPrecompiledClass(String name, String podName, String typeName)
  {
    if (pod.fpod.store == null) return null;
    try
    {
      String path = "fan/" + podName + "/" + typeName + ".class";
      Box precompiled = pod.fpod.store.readToBox(path);
      if (precompiled == null) return null;

      Class cls = defineClass(name, precompiled.buf, 0, precompiled.len, codeSource);

      // if the precompiled class is a fan type, then we need
      // to finish the emit process since we skipped the normal
      // code path thru Type.emit() for fcode to bytecode generation
      ClassType type = (ClassType)pod.type(typeName, false);
      if (type != null) type.precompiled(cls);

      // if the class is a precompiled Pod type
      else if (typeName.equals("$Pod")) pod.precompiled(cls);

      return cls;
    }
    catch (Exception e)
    {
      e.printStackTrace();
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  static void dumpToFile(String name, Box classfile)
  {
    try
    {
      File f = new File(name.substring(name.lastIndexOf('.')+1) + ".class");
      System.out.println("Dump: " + f);
      FileOutputStream out = new FileOutputStream(f);
      out.write(classfile.buf, 0, classfile.len);
      out.close();
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// ExtClassLoader
//////////////////////////////////////////////////////////////////////////

  static final ExtClassLoader extClassLoader = new ExtClassLoader();

  static class ExtClassLoader extends URLClassLoader
  {
    public ExtClassLoader()
    {
      super(new URL[0], FanClassLoader.class.getClassLoader());
      try
      {
        String sep = java.io.File.separator;
        java.io.File extDir = new java.io.File(Sys.homeDir, "lib" + sep + "java" + sep + "ext");
        java.io.File platDir = new java.io.File(extDir, Sys.platform);
        addExtJars(extDir);
        addExtJars(platDir);
      }
      catch (Exception e)
      {
        e.printStackTrace();
      }
    }

    private void addExtJars(java.io.File extDir) throws Exception
    {
      java.io.File[] list = extDir.listFiles();
      for (int i=0; list != null && i<list.length; ++i)
      {
        if (list[i].getName().endsWith(".jar"))
          addURL(list[i].toURL());
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Pod pod;
  private PermissionCollection allPermissions;
  private CodeSource codeSource;
  private HashMap pendingClasses = new HashMap(); // name -> Box
}