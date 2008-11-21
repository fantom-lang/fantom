//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaPod is the CPod wrapper for a Java package.
**
class JavaPod : CPod
{

  new make(JavaBridge bridge, Str package, Str[]? classes)
  {
    this.bridge = bridge
    this.name = "[java]" + package
    this.packageName = package
    if (classes != null)
      this.types = classes.map(JavaType[,]) |Str n->JavaType| { return JavaType(this, n) }
  }

  override CNamespace ns() { return bridge.ns }

  override readonly Str name

  readonly Str packageName

  override Version version() { return Version("0") }

  override JavaBridge? bridge

  override Bool isForeign() { return true }

  override CType[] types

  override JavaType? resolveType(Str typeName, Bool checked)
  {
    x := types.find |JavaType t->Bool| { return t.name == typeName }
    if (x != null) return x
    if (checked) throw UnknownTypeErr(name + "::" + typeName)
    return null
  }

}