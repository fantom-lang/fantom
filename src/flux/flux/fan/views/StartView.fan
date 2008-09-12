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
    recent := GridPane
    {
      vgap = 0
      InsetPane(0,0,5,0) { Label { text="Recent Files"; font=Font.sys.toBold }}
    }
    History.load.items.each |HistoryItem item| { recent.add(file(item.uri)) }
    content = ScrollPane { InsetPane(10,10,10,10) { add(recent) }}
  }

  private Widget file(Uri uri)
  {
    return Label
    {
      text = uri.toStr
      fg   = Color.blue
      onMouse.add(|Event e| { frame.loadUri(uri) })
    }
  }

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