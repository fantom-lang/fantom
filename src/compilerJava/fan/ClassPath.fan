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
    jars := File[,]

    // System.property "sun.boot.class.path"; this is preferable
    // to trying to figure out rt.jar - on platforms like Mac OS X
    // the classes are in very non-standard locations
    Sys.env.get("sun.boot.class.path", "").split(File.pathSep[0]).each |Str path|
    {
      f := File.os(path)
      // skip big jar files we can probably safely ignore
      if (f.ext != "jar") return
      if (f.name == "deploy.jar") return
      if (f.name == "charsets.jar") return
      if (f.name == "javaws.jar") return
      jars.add(f)
    }

    // {java}lib/rt.jar (only if sun.boot.class.path failed)
    lib := File.os(Sys.env.get("java.home", "") + File.sep + "lib")
    if (jars.isEmpty)
    {
      rt := lib + `rt.jar`
      if (rt.exists) jars.add(rt)
    }

    // {java}lib/ext
    ext := lib + `ext/`
    ext.list.each |File extJar| { if (extJar.ext == "jar") jars.add(extJar) }


    // -classpath
    Sys.env.get("java.class.path", "").split(File.pathSep[0]).each |Str path|
    {
      f := File.os(path)
      if (f.exists) jars.add(f)
    }

    return make(jars)
  }

  **
  ** Make for current set of jars.
  **
  new make(File[] jars)
  {
    this.jars = jars
    this.classes = loadClasses
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  **
  ** Jar files to search
  **
  const File[] jars

  **
  ** List of classes keyed by package name in class path
  **
  const Str:Str[] classes

  **
  ** Return list of jar files.
  **
  override Str toStr()
  {
    return jars.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Loading
//////////////////////////////////////////////////////////////////////////

  **
  ** Load the map of package:class[] by walking every jar file
  **
  private Str:Str[] loadClasses()
  {
    acc := Str:Str[][:]
    jars.each |File f|  { loadJar(acc, f) }
    return acc
  }

  **
  ** Load the map of package:class[] by walking entries in jar file
  **
  private Void loadJar(Str:Str[] acc, File f)
  {
    Zip? zip := null
    try
    {
      zip = Zip.open(f)
      zip.contents.each |File x, Uri uri|
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
    }
    catch {}
    finally { if (zip != null) zip.close }
  }

  static Void main()
  {
    t1 := Duration.now
    cp := makeForCurrent
    t2:= Duration.now
    echo("ClassPath.makeForCurrent: ${(t2-t1).toMillis}ms")

    echo("Jars Found:")
    cp.jars.each |File f| { echo("  $f") }

    echo("Packages Found:")
    cp.classes.keys.sort.each |Str p| { echo("  $p [" + cp.classes[p].size + "]") }
  }

}