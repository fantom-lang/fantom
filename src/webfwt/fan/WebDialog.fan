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
** WebDialog extends Dialog to add features specific to Browsers.
**
@NoDoc
@Js
class WebDialog : Dialog
{
  ** Constructor.
  new make(Window? parent) : super(parent)
  {
    onClose.add |e|
    {
      r := e.data
      if (r == Dialog.ok || r == Dialog.yes)
        onCommit.fire(Event { id=EventId.close; widget=e.widget; data=r })
    }
  }

  **
  ** Convenience to construct a message Widget to display
  ** a heading message along with optional summary text.
  ** Summary text will wrap if needed at given width in
  ** pixels.
  **
  static Widget msg(Image? icon, Str header, Str? summary := null, Int width := 325)
  {
    fh := Desktop.sysFont.toBold
    fs := Desktop.sysFontSmall

    html := "<div style='font:bold ${fh.size}px $fh.name'>$header.toXml</div>"
    if (summary != null)
      html += "<div style='margin-top:6px; font:${fs.size}px $fs.name'>$summary.toXml</div>"

    Widget pane := HtmlPane { it.width=width; it.html=html }
    if (icon != null) pane = GridPane
    {
      hgap = 12
      numCols = 2
      valignCells = Valign.top
      Label { image=icon; font=Font("1pt Arial") },
      pane,
    }

    return pane
  }

  ** Set to false in onValidate to cancel close action.
  Bool invalid := false

  ** Event callback to validate dialog content before commit is called.
  EventListeners onValidate := EventListeners() { private set }

  ** Event callback when dialog is closed with a commit command.
  EventListeners onCommit := EventListeners() { private set }

  ** Insets around body widget.
  Insets insetsBody := Insets(16)

  ** Widget displayed across bottom of dialog opposite command buttons.
  Widget? aux := null

  ** Return command used to toggle 'details' display.
  static Command toggleDetails() { ToggleDetailsCommand() }

  ** Override how content is constructed.
  override This buildContent()
  {
    // build body widget if necessary
    body := this.body
    if (body == null) body = Label {}
    if (body isnot Widget) throw Err("body is not Widget: $body.typeof")

    // detach body if already built
    ((Widget)body).parent?.remove(body)

    // build buttons from commands
    if (commands == null) commands := Command[,]
    buttons := layoutButtons(commands)

    // build overall
    this.content = EdgePane
    {
      center = EdgePane
      {
        center = InsetPane
        {
          insets = insetsBody
          body,
        }
        bottom = InsetPane
        {
          insets = Insets(0, 14, 14, 14)
          EdgePane { left=aux; right=buttons },
        }
      }
    }

    return this
  }

  ** Layout buttons in parent Widget for dialog.
  @NoDoc
  Widget layoutButtons(Command[] cmds)
  {
    buttons := GridPane
    {
      numCols = cmds.size
      halignCells = Halign.fill
      uniformRows = true
      uniformCols = true
      hgap = 2
    }
    cmds.each |c|
    {
      b := Button.makeCommand(c) { insets=Insets(0,10,0,10) }
      if (c == defCommand) setDefButton(b)
      buttons.add(ConstraintPane { minw=70; b, })
    }
    return buttons
  }

  ** Toggle details widget.
  internal Void _toggleDetails(Bool visible)
  {
    if (details == null) return
    if (details is Err) details = ((Err)details).traceToStr
    if (details is Str) details = ConstraintPane { minw=350; Text
    {
      multiLine = true
      editable  = false
      prefRows  = 20
      font = Desktop.sysFontMonospace
      text = details.toStr
    }, }
    if (details isnot Widget)
      throw ArgErr("details not Err, Str, or Widget: ${Type.of(details)}")
    content->bottom = details
    ((Widget)details).visible = visible
    relayout
  }
}

**************************************************************************
** ToggleDetailsCommand
**************************************************************************
@Js
internal class ToggleDetailsCommand : Command
{
  new make() : super.makeLocale(Dialog#.pod, "details")
  {
    mode = CommandMode.toggle
  }

  override Void invoked(Event? e)
  {
    dlg := (WebDialog)widgets.first.window
    dlg._toggleDetails(selected)
  }
}
