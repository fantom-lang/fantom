//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jun 06  Brian Frank  Creation
//

**
** CPod is a "compiler pod" used for representing a Pod in the compiler.
**
mixin CPod
{

  **
  ** Associated namespace for this pod representation
  **
  abstract CNamespace ns()

  **
  ** Get the pod name
  **
  abstract Str name()

  **
  ** Get the pod version or null if unknown.
  **
  abstract Version version()

  **
  ** Get the pod dependencies
  **
  abstract CDepend[] depends()

  **
  ** List of the all defined types.
  **
  abstract CType[] types()

  **
  ** Pod zip file.  Not all implementations have a backing
  ** file in which case they will throw UnsupportedErr
  **
  abstract File file()

  **
  ** Pod meta data
  **
  abstract Str:Str meta()

  **
  ** Return if this pod has client side JavaScript
  **
  Bool hasJs() { meta["pod.js"] == "true" || name == "sys" }

  **
  ** Lookup a type by its simple name.  If the type doesn't
  ** exist and checked is true then throw UnknownTypeErr
  ** otherwise return null.
  **
  abstract CType? resolveType(Str name, Bool checked)

  **
  ** If this a foreign function interface pod.
  **
  virtual Bool isForeign() { false }

  **
  ** If this a foreign function interface return the bridge.
  **
  virtual CBridge? bridge() { null }

  **
  ** Hash on name.
  **
  override Int hash()
  {
    return name.hash
  }

  **
  ** Equality based on pod name.
  **
  override Bool equals(Obj? t)
  {
    if (this === t) return true
    that := t as CPod
    if (that == null) return false
    return name == that.name
  }

  **
  ** Return name
  **
  override final Str toStr()
  {
    return name
  }

  **
  ** Expand a set of pods to include all their recursive dependencies.
  ** This method does not order them; see `orderByDepends`.
  **
  static CPod[] flattenDepends(CPod[] pods)
  {
    acc := Str:CPod[:]
    pods.each |pod| { doFlattenDepends(acc, pod) }
    return acc.vals
  }

  private static Void doFlattenDepends([Str:CPod] acc, CPod pod)
  {
    if (acc.containsKey(pod.name)) return
    acc[pod.name] = pod
    pod.depends.each |CDepend depend|
    {
      doFlattenDepends(acc, pod.ns.resolvePod(depend.name, null))
    }
  }

  **
  ** Order a list of pods by their dependencies.
  ** This method does not flatten dependencies - see `flattenDepends`.
  **
  static CPod[] orderByDepends(CPod[] pods)
  {
    left := pods.dup.sort
    ordered := CPod[,]
    while (!left.isEmpty)
    {
      i := 0
      for (i = 0; i<left.size; ++i)
      {
        if (noDependsInLeft(left, left[i])) break
      }
      ordered.add(left.removeAt(i))
    }
    return ordered
  }

  private static Bool noDependsInLeft(CPod[] left, CPod p)
  {
    depends := p.depends
    for (i := 0; i<depends.size; ++i)
    {
      d := depends[i]
      for (j := 0; j<left.size; ++j)
      {
        if (d.name == left[j].name)
          return false
      }
    }
    return true
  }


}

