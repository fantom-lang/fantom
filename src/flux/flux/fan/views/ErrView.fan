//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

using gfx
using fwt

**
** ErrView is a place holder view when we can't load the
** real view.  It displays an error message and optional
** stack trace.
**
internal class ErrView : View
{
  new make(Str msg, Err? cause := null)
  {
    this.msg = msg
    this.cause = cause
  }

  override Void onLoad()
  {
    content := GridPane
    {
      numCols = 1
      halignPane = Halign.center
      valignPane = Valign.center
      vgap = 0
      Label
      {
        image  = Flux.icon(`/x16/err.png`)
        font   = Font("bold 12pt Dialog")
        text   = "ERROR: $msg"
      },
      InsetPane
      {
        insets = Insets(0, 0, 0, 20)
        Label
        {
          font = Font("bold 10pt Dialog")
          text = resource.uri.toStr
        },
      },
    }

    if (cause != null)
    {
      trace := Label { text=cause.traceToStr; font=Font("10pt Courier") }
      content.add(InsetPane { it.insets=Insets(0,0,0,20); it.content=trace })
    }

    this.content = content
  }

  const Str msg
  const Err? cause
}