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
    content = ScrollPane {
      InsetPane(10,10,10,10) {
        GridPane
        {
          vgap = 0
          InsetPane(0,0,5,0) {
            Label { text="Recent Files"; font=Font.sys.toBold }
          }
          file(`file:/c:/dev/fan/src/flux/flux/fan/Commands.fan`)
          file(`file:/c:/dev/fan/src/flux/flux/locale/en.props`)
          file(`file:/c:/dev/fan/src/flux/flux/fan/views/StartView.fan`)
          file(`file:/c:/dev/fan/src/flux/flux/fan/ViewTabPane.fan`)
        }
      }
    }
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