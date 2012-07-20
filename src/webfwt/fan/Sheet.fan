//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jan 11  Andy Frank  Creation
//

using fwt
using gfx

**
** Sheet is special modal window that displays from the top
** of a parent Window.
**
@NoDoc
@Js
class Sheet : ContentPane
{

//////////////////////////////////////////////////////////////////////////
// Conveniences
//////////////////////////////////////////////////////////////////////////

  ** Make a new Sheet displaying a warning icon, and given
  ** title and message.  Width is used to control the width
  ** of the message text.
  static new makeWarn(Str title, Str msg, Int width := 300)
  {
    Sheet
    {
      it.image = Image(`fan://icons/x64/warn.png`)
      it.body = makeHtmlPane(title, msg, width)
      it.commands = [Sheet.cancel]
    }
  }

  ** Layout an HtmlPane with given title and msg.
  private static Widget makeHtmlPane(Str title, Str msg, Int w := 300)
  {
    HtmlPane
    {
      width = w
      html = "<b>$title.toXml</b>
              <div style='margin-top:1em; font-size:${Desktop.sysFontSmall.size}px;'>
              $msg.toXml
              </div>"
    }
  }

//////////////////////////////////////////////////////////////////////////
// Content
//////////////////////////////////////////////////////////////////////////

  ** Image to the left of the body when building content.
  ** See `buildContent`.
  Image? image

  ** Main body of the content:
  **   - Str: displays string as label
  **   - Widget: used as main content
  ** See `buildContent`.
  Obj? body

  ** The commands are mapped to buttons along the bottom of the sheet.
  ** If a predefined command such as `ok` is passed, then it closes
  ** the sheet and is returned as the result.  If a custom command
  ** is passed, then it should close the dialog as appropiate with
  ** the result object.
  Command[]? commands

//////////////////////////////////////////////////////////////////////////
// Predefined Commands
//////////////////////////////////////////////////////////////////////////

  ** Predefined dialog command for OK.
  static Command ok() { return SheetCommand("ok") }

  ** Predefined dialog command for Cancel.
  static Command cancel() { return SheetCommand("cancel") }

  ** Predefined dialog command for Yes.
  static Command yes() { return SheetCommand("yes") }

  ** Predefined dialog command for No.
  static Command no() { return SheetCommand("no") }

  ** Convenience for '[ok, cancel]'.
  static Command[] okCancel() { return [ok, cancel] }

  ** Convenience for '[yes, no]'.
  static Command[] yesNo() { return [yes, no] }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  ** Open sheet under given Window.
  native This open(Window win)

  ** Close sheet.
  native Void close(Obj? result := null)

  ** Callback function when popup is closed.
  **  - Event.id: EventId.close
  **  - Event.data: command used to close sheet
  @Transient EventListeners onClose := EventListeners() { private set }

//////////////////////////////////////////////////////////////////////////
// Build
//////////////////////////////////////////////////////////////////////////

  ** Build the sheet content using the `image`, `body`, and `commands`
  ** fields.  Return this. This method is automatically called by `open`
  ** if the content field is null.
  virtual This buildContent()
  {
    // build body widget if necessary
    body := this.body
    if (body == null) body = Label {}
    if (body is Str) body = Label { text = body.toStr }
    if (body isnot Widget) throw Err("body is not Str or Widget: ${Type.of(body)}")

    // combine body with image if specified
    bodyAndImage := body as Widget
    if (image != null)
    {
      bodyAndImage = GridPane
      {
        numCols = 2
        hgap = 16
        expandCol = 1
        halignCells = Halign.fill
        valignCells = Valign.top
        Label { it.image = this.image },
        body,
      }
    }

    // build buttons from commands
    if (commands == null) commands := Command[,]
    buttons := GridPane
    {
      numCols = commands.size
      halignCells = Halign.fill
      halignPane = Halign.right
      uniformRows = true
      uniformCols = true
      hgap = 2
    }
    commands.each |c|
    {
      if (c is SheetCommand) ((SheetCommand)c).sheet = this
      buttons.add(ConstraintPane
      {
        minw = 70
        Button.makeCommand(c) { insets=Insets(0,10,0,10) },
      })
    }

    // build overall
    this.content = WebBorderPane
    {
      bg = Color("#eaeeeeee")
      GridPane
      {
        expandCol = 0
        expandRow = 0
        valignCells = Valign.fill
        halignCells = Halign.fill
        InsetPane(16) { bodyAndImage, },
        InsetPane
        {
          insets = Insets(0,14,14,14)
          buttons,
        },
      },
    }

    return this
  }
}

**************************************************************************
** SheetCommand
**************************************************************************
@Js
internal class SheetCommand : Command
{
  new make(Str id) : super.makeLocale(typeof.pod, id)
  {
    this.id = id
  }
  override Void invoked(Event? e) { sheet?.close(this) }
  override Int hash() { return id.hash }
  override Bool equals(Obj? that)
  {
    if (that isnot SheetCommand) return false
    return that->id == id
  }
  Sheet? sheet
  const Str id
}