//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    15 Nov 08  Brian Frank  Creation
//

**
** ClassPath models a Java classpath to resolve package
** names to types.  Since the standard Java APIs don't expose
** this, we have go thru a lot of pain.
**
class ClassPath
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Attempt to derive the current classpath by looking at
  ** system properties.
  **
  static ClassPath makeForCurrent()
  {
    entries := File[,]

    // System.property "sun.boot.class.path"; this is preferable
    // to trying to figure out rt.jar - on platforms like Mac OS X
    // the classes are in very non-standard locations
    Env.cur.vars.get("sun.boot.class.path", "").split(File.pathSep[0]).each |Str path|
    {
      f := File.os(path)
      // skip big jar files we can probably safely ignore
      if (!f.isDir && f.ext != "jar") return
      if (f.name == "deploy.jar") return
      if (f.name == "charsets.jar") return
      if (f.name == "javaws.jar") return
      entries.add(f)
    }

    // {java}lib/rt.jar (only if sun.boot.class.path failed)
    lib := File.os(Env.cur.vars.get("java.home", "") + File.sep + "lib")
    if (entries.isEmpty)
    {
      rt := lib + `rt.jar`
      if (rt.exists) entries.add(rt)
    }

    // {java}lib/ext
    // {fan}lib/java/ext
    // {fan}lib/java/ext/{plat}
    addJars(entries, lib + `ext/`)
    addJars(entries, Env.cur.homeDir + `lib/java/ext/`)
    addJars(entries, Env.cur.homeDir + `lib/java/ext/${Env.cur.platform}/`)

    // -classpath
    Env.cur.vars.get("java.class.path", "").split(File.pathSep[0]).each |Str path|
    {
      f := File.os(path)
      if (f.exists) entries.add(f)
    }

    return make(entries)
  }

  private static Void addJars(File[] entries, File dir)
  {
    dir.list.each |f| { if (f.ext == "jar") entries.add(f) }
  }

  **
  ** Make for current set of jars.
  **
  new make(File[] entries)
  {
    this.entries = entries
    this.classes = loadClasses
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Class path entries to search
  **
  const File[] entries

  **
  ** List of classes keyed by package name in class path
  **
  const Str:Str[] classes

  **
  ** Return list of jar files.
  **
  override Str toStr()
  {
    return entries.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Loading
//////////////////////////////////////////////////////////////////////////

  **
  ** Load the map of package:class[] by walking every entry
  **
  protected virtual Str:Str[] loadClasses()
  {
    acc := Str:Str[][:]
    entries.each |File f|  { loadEntry(acc, f) }
    return acc
  }

  **
  ** Load the map of package:class[] by walking class path entry
  **
  private Void loadEntry(Str:Str[] acc, File f)
  {
    if(f.isDir)
    {
      f.walk |File x| { accept(acc, x.uri.relTo(f.uri)) }
    }
    else
    {
      Zip? zip := null
      try
      {
        zip = Zip.open(f)
        zip.contents.each |File x, Uri uri| { accept(acc, uri) }
      }
      catch {}
      finally { if (zip != null) zip.close }
    }
  }

  private Void accept(Str:Str[] acc, Uri uri)
  {
    if (uri.ext != "class") return
    package := uri.path[0..-2].join(".")
    if (package.startsWith("com.sun") || package.startsWith("sun")) return
    name := uri.basename
    if (name == "Void") return
    classes := acc[package]
    if (classes == null) acc[package] = classes = Str[,]
    if (!classes.contains(name)) classes.add(name)
  }

  static Void main()
  {
    t1 := Duration.now
    cp := makeForCurrent
    t2:= Duration.now
    echo("ClassPath.makeForCurrent: ${(t2-t1).toMillis}ms")

    echo("Entries Found:")
    cp.entries.each |File f| { echo("  $f") }

    echo("Packages Found:")
    cp.classes.keys.sort.each |Str p| { echo("  $p [" + cp.classes[p].size + "]") }
  }

}