//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Feb 10  Brian Frank  Creation
//
package fan.sys;

import java.io.InputStream;
import java.util.HashMap;

/**
 * JarDistEnv
 */
public class JarDistEnv
  extends Env
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static JarDistEnv make() { return new JarDistEnv(Env.cur()); }

  public JarDistEnv(Env parent) { super(parent); }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.JarDistEnvType; }

//////////////////////////////////////////////////////////////////////////
// Find Files
//////////////////////////////////////////////////////////////////////////

  public Map props(Pod pod, Uri uri, Duration maxAge)
  {
    String path = "res/" + pod.name() + "/" + uri;
    Map props = (Map)propsCache.get(path);
    if (props == null)
    {
      InputStream in = JarDistEnv.class.getClassLoader().getResourceAsStream(path);
      if (in != null)
      {
        InStream sysIn = new SysInStream(in);
        props = sysIn.readProps();
        sysIn.close();
      }
      props = (props == null) ? Sys.emptyStrStrMap : (Map)props.toImmutable();
      propsCache.put(path, props);
    }
    return props;
  }

  public File findFile(Uri uri, boolean checked)
  {
    System.out.println("WARN: JarDistEnv.findFile not implemented: " + uri);
    if (!checked) return null;
    throw UnresolvedErr.make("File not found in Env: " + uri);
  }

  public List findAllFiles(Uri uri)
  {
    File f = findFile(uri, false);
    if (f == null) return Sys.FileType.emptyList();
    return new List(Sys.FileType, new File[] { f });
  }

//////////////////////////////////////////////////////////////////////////
// Java Env
//////////////////////////////////////////////////////////////////////////

  public Class loadPodClass(Pod pod)
  {
    try
    {
      String classname = "fan." + pod.name() + ".$Pod";
      Class cls = getClass().getClassLoader().loadClass(classname);
      pod.precompiled(cls);
      return cls;
    }
    catch (Exception e)
    {
      return super.loadPodClass(pod);
    }
  }

  /**
   * Given a pod and a Fantom class formatted as its Java
   * dotted classname, emit to a Java classfile.
   */
  public Class[] loadTypeClasses(ClassType t)
  {
    try
    {
      String classname = "fan." + t.pod().name() + "." + t.name();
      Class cls = getClass().getClassLoader().loadClass(classname);
      t.precompiled(cls);
      return new Class[] { cls };
    }
    catch (Exception e)
    {
      return super.loadTypeClasses(t);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private HashMap propsCache = new HashMap();
}

