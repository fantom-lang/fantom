//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jun 08  Brian Frank  Creation
//

using gfx

**
** TabPane is a container used organize a set of [Tabs]`Tab`.
** Tabs are added and removed using normal `Widget.add` and
** `Widget.remove`.
**
@Js
@Serializable { collection = true }
class TabPane : Widget
{
  **
  ** Callback when the new tab is selected.
  **
  ** Event id fired:
  **   - `EventId.select`
  **
  ** Event fields:
  **   - `Event.index`: index of selected tab
  **   - `Event.data`: new active Tab instance
  **
  @Transient EventListeners onSelect := EventListeners() { private set }

  **
  ** Get the list of installed tabs.  Tabs are added and
  ** removed using normal `Widget.add` and `Widget.remove`.
  **
  Tab[] tabs() { return Tab[,].addAll(children) }

  **
  ** The currently selected index of `tabs`.
  **
  @Transient native Int? selectedIndex

  **
  ** The currently selected tab.
  **
  @Transient Tab? selected
  {
    get { i := selectedIndex; return i == null ? null : tabs[i] }
    set { i := index(it); if (i != null) selectedIndex = i }
  }

  **
  ** Get the index of the specified tab.
  **
  Int? index(Tab tab) { return tabs.index(tab) }

  **
  ** Only `Tab` children may be added.
  **
  @Operator override This add(Widget? kid)
  {
    if (kid isnot Tab)
      throw ArgErr("Child of TabPane must be Tab, not ${Type.of(kid)}")
    super.add(kid)
    return this
  }

}

**************************************************************************
** Tab
**************************************************************************

**
** Tab is the child widget of a `TabPane`.  It is used to
** configure the tab's text, image, and content widget.
**
@Js
@Serializable { collection = true }
class Tab : Widget
{

  **
  ** Text of the tab's label. Defaults to "".
  **
  native Str text

  **
  ** Image to display on tab. Defaults to null.
  **
  native Image? image

}