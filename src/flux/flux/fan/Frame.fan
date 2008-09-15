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

//////////////////////////////////////////////////////////////////////////
// Views
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the list of views this frame has opened in tabs.
  **
  View[] views() { return tabPane.views }

  **
  ** Get the active view.  A given frame always has
  ** exactly one view active.
  **
  View view() { return tabPane.active.view }

  **
  ** Select the active view tab.
  **
  Void select(View view) { tabPane.select(view.tab) }

  **
  ** Load the specified resource in the active tab.
  ** The default mode will replace the current tab.
  **
  Void load(Resource r, LoadMode mode := LoadMode())
  {
    doLoad(this, r, mode)
  }

  **
  ** Load the specified resource Uri in the active tab.
  ** The default mode will replace the current tab.
  **
  Void loadUri(Uri uri, LoadMode mode := LoadMode())
  {
    doLoad(this, uri, mode)
  }

  **
  ** Internal common implementation for loading.
  **
  internal static Void doLoad(Frame frame, Obj target, LoadMode mode)
  {
    // get window to load
    if (mode.newWindow)
    {
      echo("TODO: new window not done yet")
      mode.newTab = true
    }

    // get tab to load
    tab := frame.view.tab
    if (mode.newTab || frame.view.dirty)
     tab = frame.tabPane.newTab

    // load the tab
    if (target is Uri)
      tab.loadUri(target, mode)
    else
      tab.load(target, mode)

    // select the tab once loading is done to deactivate old
    // tab and activate this one (if we switched tabs)
    frame.tabPane.select(tab)
  }

//////////////////////////////////////////////////////////////////////////
// SideBar
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the sidebars which are currently created for this frame.
  ** This list includes both showing and hidden sidebars.
  **
  SideBar[] sideBars()
  {
    return sideBarPane.sideBars.ro
  }

  **
  ** Get the sidebar for the specified SideBar type.  If the
  ** sidebar has already been created for this frame then return
  ** that instance.  Otherwise if make is true, then create a
  ** new sidebar for this frame.  If make is false return null.
  **
  SideBar sideBar(Type t, Bool make := true)
  {
    return sideBarPane.sideBar(t, make)
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  **
  ** Lookup a predefined command by id or return null if not
  ** found.  See `CommandId` for the predefined id strings.
  **
  FluxCommand command(Str id)
  {
    return commands.byId[id]
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  internal Void loadState()
  {
    state := FrameState.load
    if (state.pos != null)  this.pos = state.pos
    if (state.size != null) this.size = state.size
  }

  internal Void saveState()
  {
    state := FrameState()
    state.pos = this.pos
    state.size = this.size
    state.save
  }

//////////////////////////////////////////////////////////////////////////
// Internal Construction
//////////////////////////////////////////////////////////////////////////

  internal new make() : super()
  {
    title = "Flux"
    icon  = Flux.icon(Desktop.isMac ? `/x256/flux.png` : `/x16/flux.png`)
    menuBar = commands.buildMenuBar
    content = EdgePane
    {
      top = EdgePane
      {
        left = InsetPane(4,2,2,2) { commands.buildToolBar }
        center = InsetPane(4,2,2,2) { add(locator) }
        bottom = Desktop.isMac ? null : ToolBarBorder()
      }
      center = sideBarPane
    }
    commands.update
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal LocatorBar locator := LocatorBar(this)
  internal ViewTabPane tabPane := ViewTabPane(this)
  internal SideBarPane sideBarPane := SideBarPane(this, tabPane)
  internal Commands commands := Commands(this)
}

**************************************************************************
** FrameState
**************************************************************************

@serializable
internal class FrameState
{
  static FrameState load() { return Flux.loadOptions("session/frame", FrameState#) }
  Void save() { Flux.saveOptions("session/frame", this) }

  Point pos := null
  Size size := Size(800, 600)
}

**************************************************************************
** ToolBarBorder
**************************************************************************

internal class ToolBarBorder : Widget
{
  override Size prefSize(Hints hints := Hints.def) { return Size(100,4) }
  override Void onPaint(Graphics g)
  {
    g.brush = Gradient.makeLinear(Point(0,0), Color.sysBg,
      Point(0,size.h), Color.sysNormShadow);
    g.fillRect(0, 0, size.w, size.h)
  }
}

**************************************************************************
** StatusBarBorder
**************************************************************************

internal class StatusBarBorder : Widget
{
  override Size prefSize(Hints hints := Hints.def) { return Size(100,4) }
  override Void onPaint(Graphics g)
  {
    g.brush = Gradient.makeLinear(Point(0,0), Color.sysNormShadow,
      Point(0,size.h), Color.sysBg);
    g.fillRect(0, 0, size.w, size.h)
  }
}