//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//

**
** Pod represents a module of Types.  Pods serve as a type namespace
** as well as unit of deployment and versioning.
**
final const class Pod
{

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the pod of the given instance which is convenience
  ** for 'Type.of(obj).pod'.  See `Type.pod`.
  **
  static Pod? of(Obj obj)

  **
  ** Get a list of all the pods installed.  Note that currently this
  ** method will load all of the pods into memory, so it is an expensive
  ** operation.
  **
  static Pod[] list()

  **
  ** Find a pod by name.  If the pod doesn't exist and checked
  ** is false then return null, otherwise throw UnknownPodErr.
  **
  static Pod? find(Str name, Bool checked := true)

  **
  ** Load a pod into memory from the specified input stream.  The
  ** stream must contain a valid pod zip file with the all the definitions.
  ** The pod is completely loaded into memory and the input stream is
  ** closed.  The pod cannot have resources.  The pod name as defined
  ** by '/pod.def' must be uniquely named or Err is thrown.
  **
  static Pod load(InStream in)

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Private constructor.
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Simple name of the pod such as "sys".
  **
  Str name()

  **
  ** Version number for this pod.
  **
  Version version()

  **
  ** Get the declared list of dependencies for this pod.
  **
  Depend[] depends()

  **
  ** Return the uri for this pod which if "fan:/sys/pod/{name}/".
  **
  Uri uri()

  **
  ** Always return name().
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Repo
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the repo which was used to load this pod or null
  ** if this pod was loaded outside the repository (such as
  ** from a script).
  **
  Repo? repo()

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Return all the facets defined for this pod or an empty map
  ** if no facets are defined.  See the [Facets Doc]`docLang::Facets`
  ** for details.
  **
  Symbol:Obj? facets()

  **
  ** Get a facet by symbol key, or return the 'def' is the facet is not
  ** defined.  See the [Facets Doc]`docLang::Facets` for details.
  **
  Obj? facet(Symbol key, Obj? def := null)

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  **
  ** List of the all defined types.
  **
  Type[] types()

  **
  ** Find a type by name.  If the type doesn't exist and checked
  ** is false then return null, otherwise throw UnknownTypeErr.
  **
  Type? type(Str name, Bool checked := true)

** Use `type`
@deprecated
Type? findType(Str name, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Symbols
//////////////////////////////////////////////////////////////////////////

  **
  ** List of all the defined symbols.
  **
  Symbol[] symbols()

  **
  ** Find a symbol by its unqualified name.  If the symbol doesn't
  ** exist in this pod and checked is false then return null, otherwise
  ** throw UnknownSymbolErr.
  **
  Symbol? symbol(Str name, Bool checked := true)

//////////////////////////////////////////////////////////////////////////
// Resource Files
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the map of all the resource files contained by this pod.
  ** Resources are any files included in the pod's zip file excluding
  ** fcode files.  The files are keyed by their Uri relative to the
  ** root of the pod zip file.
  **
  Uri:File files()

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the raw fandoc for this pod or null if not available.
  ** If there is additional documentation meta-data available it is
  ** included an the start of the string as a series of "@name=value"
  ** lines.
  **
  Str? doc()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the log for this pod's name.  This is a
  ** convenience for 'Log.get(name)'.  Also see `Type.log`.
  **
  Log log()

  **
  ** Return the localized property.  This is convenience for:
  **   Locale.cur.get(name, key, def)
  ** Also see `Locale.get`.
  **
  Str? loc(Str key, Str? def := "name::key")

}