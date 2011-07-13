//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 08  Brian Frank  Creation
//

using gfx

**
** Dialog is a transient window, typically used to notify or
** input information from the user.  Dialog also contains
** convenience routines for opening message boxes.
**
@Js
@Serializable
class Dialog : Window
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Image to the left of the body when building content.
  ** See `buildContent`.
  **
  Image? image

  **
  ** Main body of the content:
  **   - Str: displays string as label
  **   - Widget: used as main content
  ** See `buildContent`.
  **
  Obj? body

  **
  ** The details parameter is hidden by default, but may be displayed by
  ** the user via the "Details" button.  The details button is implicitly
  ** added to the command set if details is non-null.  Details may be any
  ** of the following
  **   - Str: displays string as label
  **   - Err: displays error trace as string
  **   - Widget: mounted as main content of details box
  ** See `buildContent`.
  **
  Obj? details

  **
  ** The commands are mapped to buttons along the bottom of the dialog.
  ** If a predefined command such as `ok` is passed, then it closes
  ** the dialog and is returned as the result.  If a custom command
  ** is passed, then it should close the dialog as appropiate with
  ** the result object.
  **
  Command[]? commands

//////////////////////////////////////////////////////////////////////////
// Predefined Commands
//////////////////////////////////////////////////////////////////////////

  ** Predefined dialog command for OK.
  static Command ok() { return DialogCommand(DialogCommandId.ok) }

  ** Predefined dialog command for Cancel.
  static Command cancel() { return DialogCommand(DialogCommandId.cancel) }

  ** Predefined dialog command for Yes.
  static Command yes() { return DialogCommand(DialogCommandId.yes) }

  ** Predefined dialog command for No.
  static Command no() { return DialogCommand(DialogCommandId.no) }

  ** Convenience for '[ok, cancel]'.
  static Command[] okCancel() { return [ok, cancel] }

  ** Convenience for '[yes, no]'.
  static Command[] yesNo() { return [yes, no] }

//////////////////////////////////////////////////////////////////////////
// Message Boxes
//////////////////////////////////////////////////////////////////////////

  **
  ** Open an information message box.  See `openMsgBox`.
  **
  static Obj? openInfo(Window? parent, Str msg, Obj? details := null,
                      Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "info", parent, msg, details, commands)
  }

  **
  ** Open a warning message box.  See `openMsgBox`.
  **
  static Obj? openWarn(Window? parent, Str msg, Obj? details := null,
                      Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "warn", parent, msg, details, commands)
  }

  **
  ** Open an error message box.  See `openMsgBox`.
  **
  static Obj? openErr(Window? parent, Str msg, Obj? details := null,
                     Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "err", parent, msg, details, commands)
  }

  **
  ** Open a question message box.  See `openMsgBox`.
  **
  static Obj? openQuestion(Window? parent, Str msg, Obj? details := null,
                          Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "question", parent, msg, details, commands)
  }

  **
  ** Open a message box.  The pod's locale properties map as follows:
  **   - "{keyBase}.name": title of the message box
  **   - "{keyBase}.icon": icon for the message box
  **
  ** See `buildContent` for a description of the body, details, and
  ** commands.  You may pass commands as the details parameter if
  ** details are null.
  **
  ** The command invoked to close message box is returned.  If the
  ** dialog is canceled using the window manager then null is returned.
  **
  static Obj? openMsgBox(Pod pod, Str keyBase, Window? parent, Obj body,
                         Obj? details := null, Command[] commands := [ok])
  {
    // get localized props
    title := pod.locale("${keyBase}.name")
    locImage := pod.locale("${keyBase}.image")
    Image? image
    try { image = Image(locImage.toUri) } catch {}

    // swizzle details if passed commands
    if (details is Command[]) { commands = details; details = null }
    dialog := Dialog(parent)
    {
      it.title    = title
      it.image    = image
      it.body     = body
      it.details  = details
      it.commands = commands
    }
    return dialog.open
  }

  **
  ** Open a prompt for the user to enter a string with an ok and cancel
  ** button. Return the string value or null if the dialog is canceled.
  ** The text field is populated with the 'def' string which defaults
  ** to "".
  **
  static Str? openPromptStr(Window? parent, Str msg, Str def := "", Int prefCols := 20)
  {
    field := Text { it.text = def; it.prefCols = prefCols }
    pane := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells=Halign.fill
      Label { text=msg },
      field,
    }
    ok := Dialog.ok
    cancel := Dialog.cancel
    field.onAction.add |Event e| { e.widget.window.close(ok) }
    r := openMsgBox(Dialog#.pod, "question", parent, pane, [ok, cancel])
    if (r != ok) return null
    return field.text
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct dialog.
  **
  new make(Window? parent, |This|? f := null)
    : super(parent, f)
  {
    icon = parent?.icon
  }

  **
  ** If the content field is null, then construct is via `buildContent`.
  **
  override Obj? open()
  {
    if (content == null) buildContent
    return super.open
  }

  **
  ** Build the dialog content using the `image`, `body`,
  ** `details`, and `commands` fields.  Return this.
  ** This method is automatically called by `open` if
  ** the content field is null.
  **
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
        expandCol = 1
        halignCells = Halign.fill
        Label { it.image = this.image },
        body,
      }
    }

    // details
    if (details != null)
    {
      if (details is Err) details = ((Err)details).traceToStr
      if (details is Str) details = Text
      {
        multiLine  =true
        editable = false
        prefRows = 20
        font = Desktop.sysFontMonospace
        text = details.toStr
      }
      if (details isnot Widget) throw ArgErr("details not Err, Str, or Widget: ${Type.of(details)}")
      commands = commands.dup.add(DialogCommand(DialogCommandId.details, details))
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
      hgap = Env.cur.runtime == "js" ? 2 : 4
    }
    commands.each |Command c|
    {
      c.assocDialog = this
      buttons.add(ConstraintPane
      {
        minw = 70
        Button.makeCommand(c) { insets=Insets(0, 10, 0, 10) },
      })
    }

    // build overall
    this.content = GridPane
    {
      expandCol = 0
      expandRow = 0
      valignCells = Valign.fill
      halignCells = Halign.fill
      InsetPane(16)
      {
        ConstraintPane
        {
          minw = (details == null) ? 200 : 350
          bodyAndImage,
        },
      },
      InsetPane
      {
        insets = Env.cur.runtime == "js" ? Insets(0,14,14,14) : Insets(0,16,16,16)
        buttons,
      },
    }

    return this
  }


  // to force native peer
  private native Void dummyDialog()
}

**************************************************************************
** DialogCommand
**************************************************************************

**
** Internal class used for predefined Dialog commands.
**
@Js
internal class DialogCommand : Command
{
  new make(DialogCommandId id, Obj? arg := null)
    : super.makeLocale(Dialog#.pod, id.name)
  {
    this.id = id
    this.arg = arg
    if (id == DialogCommandId.details)
      this.mode = CommandMode.toggle
  }

  override Void invoked(Event? e)
  {
    switch (id)
    {
      case DialogCommandId.details:
        toggleDetails
      default:
        window?.close(this)
    }
  }

  override Int hash() { return id.hash }

  override Bool equals(Obj? that)
  {
    if (that isnot DialogCommand) return false
    return ((DialogCommand)that).id == id
  }

  internal Void toggleDetails()
  {
    Dialog dialog := window
    Widget details := arg
    if (details.parent == null) dialog.content.add(details)
    details.visible = selected
    dialog.pack
  }

  const DialogCommandId id
  Obj? arg
}

**************************************************************************
** DialogCommandId
**************************************************************************

**
** Ids for internal predefined Dialog commands.
**
@Js
internal enum class DialogCommandId
{
  ok,
  cancel,
  yes,
  no,
  details
}