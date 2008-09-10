//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

using fwt

**
** AboutView is the default splash screen view
**
@fluxView=AboutResource#
internal class AboutView : View
{

  override Void onLoad()
  {
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
  }

}

**
** AboutResource models an about document.
**
internal class AboutResource : Resource
{
  new make(Uri uri) { this.uri = uri }

  override Uri uri

  override Str name() { return uri.toStr }

  override Image icon() { return Flux.icon(`/x16/dialog-information.png`) }
}