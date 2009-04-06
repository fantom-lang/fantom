//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 08  Brian Frank  Creation
//

using fwt

**
** ErrView is a place holder view when we can't load the
** real view.  It displays an error message and optional
** stack trace.
**
internal class ErrView : View
{
  new make(Str message, Err? cause := null)
  {
    this.message = message
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
        font   = Font("Dialog", 12, true)
        text   = "ERROR: $message"
      }
      InsetPane
      {
        insets=Insets{left=20}
        Label
        {
          font = Font("Dialog", 10, true)
          text = resource.uri.toStr
        }
      }
    }

    if (cause != null)
    {
      trace := Label { text=cause.traceToStr; font=Font("Courier", 10) }
      content.add(InsetPane { it.insets=Insets{left=20}; it.content=trace })
    }

    this.content = content
  }

  const Str message
  const Err? cause
}