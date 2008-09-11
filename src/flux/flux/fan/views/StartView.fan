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
    content = Label { text="Start" }

    /*
    icon := Pod.find("icons").files[`/x48/flux.png`]
    copy := Color("#666")

    content = GridPane
    {
      halignPane = Halign.center
      valignPane = Valign.center
      GridPane
      {
        numCols = 2
        Label { image = Image(icon) }
        GridPane
        {
          vgap = -4
          Label { text = "Flux"; font = Font(Font.sys.name, 16, true) }
          Label { text = "Version $type.pod.version" }
        }
      }
      Label
      {
        fg = copy
        text =
          "Copyright (c) 2008, Brian Frank and Andy Frank
           Licensed under the Academic Free License version 3.0"
      }
    }
    */
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