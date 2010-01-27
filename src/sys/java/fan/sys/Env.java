//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jan 10  Brian Frank  Creation
//
package fan.sys;

/**
 * Env
 */
public abstract class Env
  extends FanObj
{


//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Env cur() { return Sys.curEnv; }

  public static void make$(Env self) { make$(self, cur()); }
  public static void make$(Env self, Env parent) { self.parent = parent; }

  public Env() {}
  public Env(Env parent) { this.parent = parent; }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.EnvType; }

  public String toStr() { return typeof().toString(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  public final Env parent() { return parent; }

  public final String os() { return Sys.os; }

  public final String arch() { return Sys.arch; }

  public final String platform() { return Sys.platform; }

  public final String runtime() { return "java"; }

  public final long idHash(Object obj) { return System.identityHashCode(obj); }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  public List args() { return parent.args(); }

  public Map vars()  { return parent.vars(); }

  public Map diagnostics() { return parent.diagnostics(); }

  public void gc() { parent.gc(); }

  public String host() { return parent.host(); }

  public String user() { return parent.user(); }

  public void exit() { this.exit(0); }
  public void exit(long status) { parent.exit(status); }

  public InStream in() { return parent.in(); }

  public OutStream out() { return parent.out(); }

  public OutStream err() { return parent.err(); }

//////////////////////////////////////////////////////////////////////////
// Compile Hooks
//////////////////////////////////////////////////////////////////////////

  public Type compileScript(fan.sys.File file) { return this.compileScript(file, null); }
  public Type compileScript(fan.sys.File file, Map options) { return parent.compileScript(file, options); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Env parent;

}