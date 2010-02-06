//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** Resource represents the objects a user navigates, views, and
** edits in a flux application.  Resources are mapped to objects
** via the indexed prop 'flux.resource.{target}={resource}', where
** both "target" and "resource" are qualied type names.  Subclasses
** must define a 'make(Uri, Obj)' constructor.
**
** See [pod doc]`pod-doc#resources` for details.
**
abstract class Resource
{

  **
  ** Get the root resources.
  **
  static Resource[] roots()
  {
    File.osRoots.map |File f->Resource| { FileResource.makeFile(f) }
  }

  **
  ** Resolve a uri into a resource:
  **   1.  Resolve uri to obj via `sys::Uri.get`
  **   2.  If obj is Resource, return it
  **   3.  Resolve to obj type to resource type via 'flux.resource.{qname}'
  **       indexed property for type hierarchy
  **
  ** Throw UnresolvedErr if the uri can't be resolved, and UnsupportedErr
  ** if resource can't be mapped to a resource.
  **
  static Resource resolve(Uri uri)
  {
    // 1. resolve uri
    obj := uri.get

    // 2. if already resource return it
    if (obj is Resource) return obj

    // 3. map via fluxResource facet
    rtype := Flux.indexForInheritance("flux.resource.", obj.typeof).first
    if (rtype == null) throw UnsupportedErr("No resource mapping for $obj.typeof")
    return rtype.make([uri, obj])
  }

  **
  ** Get the absolute Uri of this resource.
  **
  abstract Uri uri()

  **
  ** Get the display name of the resource.
  **
  abstract Str name()

  **
  ** Get a 16x16 icon for the resource.
  **
  virtual Image icon() { return Flux.icon(`/x16/file.png`) }

  **
  ** Return if this resource has or might have children.  This
  ** is an optimization to display the expansion control in a tree
  ** without loading all the children.  The default calls 'children'.
  **
  virtual Bool hasChildren()
  {
    c := children
    return c != null ? !c.isEmpty : false
  }

  **
  ** Get the navigation children of the resource.  Return an
  ** empty list or null to indicate no children.  Default
  ** returns null.
  **
  virtual Resource[]? children() { return null}

  **
  ** Get the list of available `View` types for the resource.
  ** The first view should be the default view.  The default
  ** implementation searches the type database index props formatted
  ** as "flux.view.{target}={view}", where "target" is this type (and
  ** its inherited classes, and "view" is view type qname.
  **
  virtual Type[] views()
  {
    Flux.indexForInheritance("flux.view.", typeof)
  }

  **
  ** Make a popup menu for this resource or return null.
  ** The default popup menu returns the `viewsMenu`.
  **
  virtual Menu? popup(Frame? frame, Event? event)
  {
    return Menu { add(viewsMenu(frame, event)) }
  }

  **
  ** Return a menu to hyperlink to the views supported
  ** by this resource.
  **
  virtual Menu? viewsMenu(Frame? frame, Event? event)
  {
    menu := Menu { text = Flux.locale("views.name") }
    views.each |Type v, Int i|
    {
      viewUri := i == 0 ? uri : uri.plusQuery(["view":v.qname])
      c := Command(v.name, null) { frame.load(viewUri, LoadMode(event)) }
      menu.add(MenuItem { command = c })
    }
    return menu
  }

  **
  ** Return `uri`.
  **
  override Str toStr() { return uri.toStr }
}

**************************************************************************
** ErrResource
**************************************************************************

**
** ErrResource models a resource that cannot be resolved.
**
class ErrResource : Resource
{

  new make(Uri uri) { this.uri = uri }

  override Uri uri

  override Str name() { n := uri.name; return n.isEmpty ? uri.toStr : n }

  override Image icon() { return Flux.icon(`/x16/err.png`) }

  override Type[] views() { return Type[,] }

}