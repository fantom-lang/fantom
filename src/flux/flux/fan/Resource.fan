//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** Resource represents the objects a user navigates, views, and
** edits in a flux application.  Resources are mapped to objects
** via the '@fluxResource' facet - if keyed by this facet, then
** subclass must define a 'make(Uri, Obj)' constructor.
**
** See `docLib::Flux` for details.
**
abstract class Resource
{

  **
  ** Get the root resources.
  **
  static Resource[] roots()
  {
    return File.osRoots.map(Resource[,]) |File f->Obj| { return FileResource.makeFile(f) }
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
  virtual Image icon() { return Flux.icon(`/x16/text-x-generic.png`) }

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
  virtual Resource[] children() { return null}

  **
  ** Get the list of available `View` types for the resource.
  ** The first view should be the default view.  The default
  ** implementation searches the type database for '@fluxView'
  ** bindings to this resource type.
  **
  virtual Type[] views()
  {
    acc := Type.findByFacet("fluxView", type, true)
    acc = acc.exclude |Type t->Bool| { return t.isAbstract }
    return acc
  }

  **
  ** Make a popup menu for this resource or return null.
  ** The default popup menu returns the `viewsMenu`.
  **
  virtual Menu popup(Frame frame, Event event)
  {
    return Menu { viewsMenu(frame, event) }
  }

  **
  ** Return a menu to hyperlink to the views supported
  ** by this resource.
  **
  virtual Menu viewsMenu(Frame frame, Event event)
  {
    menu := Menu { text = type.loc("views.name") }
    views.each |Type v, Int i|
    {
      viewUri := i == 0 ? uri : uri.plusQuery(["view":v.qname])
      c := Command(v.name, null, &frame.loadUri(viewUri, LoadMode(event)))
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

  override Str name() { return uri?.name ?: uri.toStr }

  override Image icon() { return Flux.icon(`/x16/dialog-error.png`) }

  override Type[] views() { return Type[,] }

}