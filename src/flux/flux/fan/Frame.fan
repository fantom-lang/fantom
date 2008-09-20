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
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the id of this frame within the VM.  The id may be used
  ** as an immutable pointer to the frame to pass between threads.
  ** See `findById` to resolve a frame by id.  The id is an opaque
  ** string, no attempt should be made to interpret the format.
  **
  const Str id

  **
  ** Lookup a frame by its id within the VM.  If the frame
  ** cannot be found and checked is true then throw an Err,
  ** otherwise return null.  This method can only be called
  ** on the UI thread.
  **
  static Frame findById(Str id, Bool checked := true)
  {
    Frame f := Thread.locals["flux.$id"]
    if (f != null) return f
    if (!checked) return null
    throw Err("Frame not found $id")
  }

  **
  ** Internal id initialization
  **
  internal Str initId()
  {
    // allocate next id and register as thread local
    Int idInt := Thread.locals.get("flux.nextFrameId", 0)
    Thread.locals.set("flux.nextFrameId", idInt+1)
    id := "Frame-$idInt"
    Thread.locals["flux.$id"] = this
    return id
  }

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
  ** Load the specified resource Uri in the active tab.
  ** The default mode will replace the current tab.
  **
  Void load(Uri uri, LoadMode mode := LoadMode())
  {
    // get tab to load
    tab := view.tab
    if (mode.newTab || view.dirty)
      tab = tabPane.newTab

    // load the tab
    tab.load(uri, mode)

    // select the tab once loading is done to deactivate old
    // tab and activate this one (if we switched tabs)
    tabPane.select(tab)
  }

  **
  ** Load the specified mark's Uri in the active tab.
  ** If the current tab is already at the specified uri,
  ** then it is not reloaded.
  **
  Void loadMark(Mark mark, LoadMode mode := LoadMode())
  {
    if (mark.uri != view.resource.uri)
      load(mark.uri, mode)
    sideBarPane.onGotoMark(mark)
    view.tab.onGotoMark(mark)
    try { curMark = marks.indexSame(mark) } catch {}
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

  **
  ** Convenience for getting the console sidebar.
  **
  Console console()
  {
    return sideBar(Console#)
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
// Mark
//////////////////////////////////////////////////////////////////////////

  **
  ** The current mark list for the frame.  This is the
  ** list of uris with optional line/col numbers which the
  ** user can currently cycle thru using the jumpPrev and
  ** jumpNext commands.  This list is always readonly, set
  ** the field to update the marks and invoke the onMarks
  ** callback for each view.
  **
  Mark[] marks := Mark[,].ro
  {
    set
    {
      @marks = val.ro
      curMark = null
      sideBarPane.onMarks(@marks)
      tabPane.tabs.each |ViewTab tab| { tab.onMarks(@marks) }
    }
  }

  **
  ** Index into marks for current mark
  **
  internal Int curMark

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  internal Void loadState()
  {
    state := FrameState.load
    if (state.pos != null)  this.pos = state.pos
    if (state.size != null) this.size = state.size
    sideBar(NavBar#).show // TODO: eventually need to persistent open sidebars
  }

  internal Void saveState()
  {
    state := FrameState()
    state.pos = this.pos
    state.size = this.size
    state.save
    sideBarPane.onUnload
  }

//////////////////////////////////////////////////////////////////////////
// Internal Construction
//////////////////////////////////////////////////////////////////////////

  internal new make() : super()
  {
    id = initId
    title = "Flux"
    icon  = Flux.icon(Desktop.isMac ? `/x256/flux.png` : `/x16/flux.png`)
    menuBar = commands.buildMenuBar
    onClose.add |Event e| { e.consume; commands.exit.invoke(e) }
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