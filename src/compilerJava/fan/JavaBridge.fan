//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaBridge is the compiler plugin for bringing Java
** classes into the Fan type system.
**
@compilerBridge="java"
class JavaBridge : CBridge
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a JavaBridge for current environment
  **
  new make(CNamespace ns)
  {
    this.ns = ns
    this.cp = ClassPath.makeForCurrent
  }

//////////////////////////////////////////////////////////////////////////
// CBridge
//////////////////////////////////////////////////////////////////////////

  **
  ** Map a FFI "podName" to a Java package.
  **
  override CPod resolvePod(Str name, Location? loc)
  {
    // look for package name in classpatch
    classes := cp.classes[name]
    if (classes == null)
      throw CompilerErr("Java package '$name' not found", loc)

    // map package to JavaPod
    return JavaPod(ns, name, classes)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  readonly CNamespace ns
  readonly ClassPath cp

}