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
internal class LocatorBar : Widget
{

  new make(Frame frame)
  {
    this.frame = frame
    add(uriText)
    onMouse.add(&onViewPopup)
  }

  readonly Frame frame

  Void load(Resource r)
  {
    uriText.text = r.uri.toStr
    view = frame.view.type.name
    repaint
  }

  Void go(Type view, Event event)
  {
    uri := uriText.text.toUri
    if (view != null) uri = uri.plusQuery(["view":view.qname])
    frame.loadUri(uri)
  }

  Void onViewPopup(Event event)
  {
    vw := Font.sys.width(view) + viewInsets.left + viewInsets.right
    vx := size.w - vw
    if (event.pos.x > vx && event.pos.x < vx+vw)
    {
      views := frame.view.tab.resource.views
      if (views == null || views.isEmpty) return
      menu := Menu {}
      views.each |Type t|
      {
        menu.add(MenuItem { text=t.name; onAction.add(&go(t)) })
      }
      menu.open(this, Point(vx, size.h-1))
    }
  }

  Void onLocation(Event event)
  {
    uriText.focus
    uriText.selectAll
  }

  override Size prefSize(Hints hints := Hints.def)
  {
    ph := uriText.prefSize.h + textInsets.top + textInsets.bottom
    return Size(100, ph)
  }

  override Void onPaint(Graphics g)
  {
    vw := Font.sys.width(view) + viewInsets.left + viewInsets.right
    vh := Font.sys.height + viewInsets.top + viewInsets.bottom
    vx := size.w - vw

    g.brush = Color.sysListBg
    g.fillRect(0, 0, size.w-vw, size.h)
    g.brush = Color.sysBg
    g.fillRect(vx, 0, vw, size.h)

    g.brush = Color.sysNormShadow
    g.drawRect(0, 0, size.w-1, size.h-1)
    g.drawRect(vx, 0, vx, size.h-1)

    g.brush = Color.sysFg
    g.drawText(view, vx+viewInsets.left, (vh-Font.sys.height)/2)

    tp := uriText.prefSize
    tx := textInsets.left
    ty := textInsets.top
    tw := size.w - vw - textInsets.left - textInsets.right
    th := size.h - textInsets.top - textInsets.bottom
    uriText.bounds = Rect(tx, ty, tw, th)
  }

  const Insets textInsets := Insets(5,5,5,5)
  const Insets viewInsets := Insets(5,5,5,5)
  Text uriText := Text { onAction.add(&go(null)); border = false }
  Str view := "Views"

}

