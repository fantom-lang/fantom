//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Repo
 */
public final class Repo
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  public static Repo working() { return working; }

  public static Repo boot() { return boot; }

  public static List list() { return list; }

//////////////////////////////////////////////////////////////////////////
// Java Constructor
//////////////////////////////////////////////////////////////////////////

  private Repo(String n, File d) { this.name = n; this.dir = d; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String name() { return name; }

  public File dir() { return dir; }

  public long hash()  { return super.hashCode(); }

  public boolean equals(Object that)  { return this == that; }

  public String toStr()  { return name + " [" + dir + "]";  }

  public Type type()  { return Sys.RepoType;  }

//////////////////////////////////////////////////////////////////////////
// Boostrap
//////////////////////////////////////////////////////////////////////////

  public static final Repo working;
  public static final Repo boot;
  public static final List list;

  static
  {
    Repo b = null, w = null;
    List a = null;
    try
    {
      // boot repo
      b = new Repo("boot", Sys.homeDir.normalize());

      // working repo
      File wd = resolveWorking();
      if (wd != null) w = new Repo("working", wd);

      // list of all repos
      Repo[] array = (w == null) ? new Repo[] { b } : new Repo[] { w, b };
      a = new List(Sys.RepoType, array).toImmutable();
    }
    catch (Exception e) { e.printStackTrace(); }

    // assign to static fields exactly once to please javac
    working = w;
    boot = b;
    list = a;
  }

  static File resolveWorking()
  {
    String env = System.getenv("FAN_REPO");
    if (env == null) return null;
    try
    {
      File f = File.os(env).normalize();
      if (!f.exists()) f = File.make(Uri.fromStr(env).plusSlash(), false).normalize();
      if (!f.isDir()) throw new IllegalStateException("Repo must be dir: " + f);
      return f;
    }
    catch (Throwable e)
    {
      System.out.println("ERROR: cannot resolve working dir: " + env);
      e.printStackTrace();
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////


  final String name;
  final File dir;

}