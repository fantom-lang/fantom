//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jul 08  Brian Frank  Creation2
//

using fwt

**
** LocatorBar is used to display/edit the current Uri
**
internal class LocatorBar : GridPane
{

  new make(Frame frame)
  {
    this.frame = frame
    numCols = 2
    halignCells=Halign.fill
    valignCells=Valign.center
    expandCol=0
    add(uriText)
    add(viewsButton)
  }

  readonly Frame frame

  Void load(Resource r)
  {
    uriText.text = r.uri.toStr
    viewsButton.text = frame.viewTab.view?.type?.name ?: "Error"
    relayout
  }

  Void go(Type view, Event event)
  {
    uri := uriText.text.toUri
    if (view != null) uri = uri.plusQuery(["view":view.qname])
    frame.loadUri(uri)
  }

  Void onViewPopup(Event event)
  {
    views := frame.viewTab.resource?.views
    if (views == null || views.isEmpty) return
    menu := Menu {}
    views.each |Type t|
    {
      menu.add(MenuItem { text=t.name; onAction.add(&go(t)) })
    }
    menu.open(viewsButton, Point(0, viewsButton.size.h))
  }

  Void onLocation(Event event)
  {
    uriText.focus
    uriText.selectAll
  }

  Text uriText := Text { onAction.add(&go(null)) }
  Button viewsButton := Button { text="Views"; onAction.add(&onViewPopup) }
}
