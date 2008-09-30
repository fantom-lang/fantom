//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 08  Andy Frank  Creation
//

using fwt

**
** StartView is the default splash screen view
**
@fluxView=StartResource#
internal class StartView : View
{
  override Void onLoad()
  {
    model := StartRecentTableModel()
    content = EdgePane
    {
      top = InsetPane(4) { Label { text = "Recently Viewed"; font = Font.sys.toBold }}
      center = Table
      {
        model = model
        border = false
        onAction.add |Event e| { frame.load(model.items[e.index].uri, LoadMode(e)) }
      }
    }
  }
}

internal class StartRecentTableModel : TableModel
{
  new make()
  {
    items = History.load.items
    icons = Image[,]
    items.map(icons) |HistoryItem item->Obj|
    {
      return Image(item.iconUri, false) ?: def
    }
  }

  override Int numCols() { return 2 }
  override Int numRows() { return items.size }
  override Image image(Int col, Int row) { return col==0 ? icons[row] : null }
  override Color fg(Int col, Int row)  { return col==1 ? pathCol : null }
  override Str header(Int col) { return headers[col] }
  override Str text(Int col, Int row)
  {
    switch (col)
    {
      case 0:  return items[row].uri.name
      case 1:  return items[row].uri.toStr
      default: return ""
    }
  }
  HistoryItem[] items
  Image[] icons
  Str[] headers := ["Resource", "Uri"]
  Image def := Flux.icon(`/x16/text-x-generic.png`)
  Color pathCol := Color("#666")
}

**
** StartResource models an Start document.
**
internal class StartResource : Resource
{
  new make(Uri uri) { this.uri = uri }
  override Uri uri
  override Str name() { return uri.toStr }
  override Image icon() { return Flux.icon(`/x16/dialog-information.png`) }
}