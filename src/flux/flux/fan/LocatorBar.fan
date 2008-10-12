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
    onMouseUp.add(&onViewPopup)
  }

  readonly Frame frame

  Void load(Resource r)
  {
    icon = r.icon
    uriText.text = r.uri.toStr
    view = frame.view.type.name
    repaint
  }

  Void go(Type view, Event event)
  {
    uri := uriText.text.toUri
    if (view != null) uri = uri.plusQuery(["view":view.qname])
    frame.load(uri)
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
    ph := uriText.prefSize.h.max(icon.size.h) + textInsets.top + textInsets.bottom
    return Size(100, ph)
  }

  override Void onPaint(Graphics g)
  {
    vw := Font.sys.width(view) + viewInsets.left + viewInsets.right
    vx := size.w - vw
    vy := (size.h - Font.sys.height) / 2

    g.brush = Color.sysListBg
    g.fillRect(0, 0, size.w, size.h)

    g.brush = Color.sysNormShadow
    g.drawRect(0, 0, size.w-1, size.h-1)

    g.drawImage(icon, 4, 4)

    g.brush = Color.sysFg
    g.drawText(view, vx+viewInsets.left, vy)

    ax := size.w - viewInsets.right + 3
    ay := (size.h - 3) / 2
    g.drawLine(ax  , ay,   ax+4, ay)
    g.drawLine(ax+1, ay+1, ax+3, ay+1)
    g.drawLine(ax+2, ay+2, ax+2, ay+2)

    tp := uriText.prefSize
    tx := textInsets.left
    ty := (size.h - uriText.prefSize.h) / 2
    tw := size.w - vw - textInsets.left - textInsets.right
    th := size.h - textInsets.top - textInsets.bottom
    uriText.bounds = Rect(tx, ty, tw, th)
  }

  const Insets textInsets := Insets(4,4,4,22)
  const Insets viewInsets := Insets(4,13,4,4)
  Image? icon
  Text uriText := Text { onAction.add(&go(null)); border = false }
  Str view := "Views"

}