//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** Frame is the main top level window in flux applications.
**
class Frame : Window
{

  **
  ** Construct a new flux window.
  **
  internal new make() : super()
  {
    title = "Flux"
    icon  = Flux.icon(`/x16/flux.png`)
    menuBar = commands.buildMenuBar
    content = EdgePane
    {
      top = EdgePane
      {
        left=InsetPane(2,2,2,2) { commands.buildToolBar }
        center=InsetPane(2,2,2,2) { buildLocatorBar }
      }
      center = SashPane
      {
        weights = [1, 3]
        buildSideBar
        buildViewPane
      }
    }
    commands.update
  }

  **
  ** Load the specified resource in the active tab.
  **
  Void load(Resource r) { viewTab.load(r, true) }

  **
  ** Load the specified resource Uri in the active tab.
  **
  Void loadUri(Uri uri) { viewTab.loadUri(uri, true) }

  internal Widget buildLocatorBar() { return locator }

  internal Widget buildSideBar() { return NavSideBar {} }

  internal Widget buildViewPane() { return ViewTabPane { viewTab } }

  internal Commands commands := Commands(this)
  internal LocatorBar locator := LocatorBar(this)
  internal ViewTab viewTab := ViewTab(this)
}
