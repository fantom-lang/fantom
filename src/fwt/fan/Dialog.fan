//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Sep 08  Brian Frank  Creation
//

**
** Dialog is a transient window, typically used to notify or
** input information from the user.  Dialog also contains
** convenience routines for opening message boxes.
**
class Dialog : Window
{

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
  static Obj openInfo(Window parent, Str msg, Obj details := null,
                      Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "info", parent, msg, details, commands)
  }

  **
  ** Open a warning message box.  See `openMsgBox`.
  **
  static Obj openWarn(Window parent, Str msg, Obj details := null,
                      Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "warn", parent, msg, details, commands)
  }

  **
  ** Open an error message box.  See `openMsgBox`.
  **
  static Obj openErr(Window parent, Str msg, Obj details := null,
                     Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "err", parent, msg, details, commands)
  }

  **
  ** Open a question message box.  See `openMsgBox`.
  **
  static Obj openQuestion(Window parent, Str msg, Obj details := null,
                          Command[] commands := [ok])
  {
    return openMsgBox(Dialog#.pod, "question", parent, msg, details, commands)
  }

  **
  ** Open a message box.  The pod's locale properties map as follows:
  **   - "{keyBase}.name": title of the message box
  **   - "{keyBase}.icon": icon for the message box
  **
  ** The content parameter may be any of the following:
  **   - Str: displays string as label
  **   - Widget: mounted as main content of message box

  ** The details parameter is hidden by default, but may be displayed by
  ** the user via the "Details" button.  The details button is implicitly
  ** added to the command set if details is non-null.  Details may be any
  ** of the following
  **   - Err: displays error trace as string
  **   - Str: displays string as label
  **   - Widget: mounted as main content of details box
  **   - Command[]: you may pass in the command list via the details parameter
  **
  ** The command invoked to close message box is returned.  If the
  ** dialog is canceled using the window manager then null is returned.
  **
  static Obj openMsgBox(Pod pod, Str keyBase, Window parent, Obj content,
                        Obj details := null, Command[] commands := [ok])
  {
    // get localized props
    title := pod.loc("${keyBase}.name")
    locIcon := pod.loc("${keyBase}.icon")
    Image icon
    try { icon = Image(locIcon.toUri.get) } catch {}

    // build content
    if (content is Str) content = Label { text = content }
    if (content isnot Widget) throw ArgErr("content not Str or Widget: " + content?.type)

    // details
    if (details is Command[]) { commands = details; details = null }
    if (details != null)
    {
      if (details is Err) details = ((Err)details).traceToStr
      if (details is Str) details = Text
      {
        multiLine=true
        editable=false
        prefRows=20
        font=Font.sysMonospace
        text=details.toStr
      }
      if (details isnot Widget) throw ArgErr("details not Err, Str, or Widget: " + details.type)
      commands = commands.dup.add(DialogCommand(DialogCommandId.details, details))
    }

    // build main pane
    pane := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells=Halign.fill
      Label { image = icon }
      add(content)
    }

    dialog := Dialog(parent, pane, commands) { title = title }
    return dialog.open
  }

  **
  ** Open a prompt for the user to enter a string with an ok and cancel
  ** button. Return the string value or null if the dialog is canceled.
  ** The text field is populated with the 'def' string which defaults
  ** to "".
  **
  static Str openPromptStr(Window parent, Str msg, Str def := "", Int prefCols := 20)
  {
    field := Text { text = def; prefCols = prefCols }
    pane := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells=Halign.fill
      Label { text=msg }
      add(field)
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
  ** Make a standard option dialog.  If content is a string, then
  ** it is displayed as a lable, otherwise content must be a Widget.
  **
  ** The commands are mapped to buttons along the bottom of the dialog.
  ** If a predefined command such as `ok` is passed, then it closes
  ** the dialog and is returned as the result.  If a custom command
  ** is passed, then it should close the dialog as appropiate with
  ** the result object.
  **
  new make(Window parent, Obj content := null, Command[] commands := null)
    : super(parent)
  {
    if (content == null || commands == null) return

    // build content widget if necessary
    if (content is Str) content = Label { text = content.toStr }

    // build buttons from commands
    buttons := GridPane
    {
      numCols = commands.size
      halignCells = Halign.fill
      halignPane = Halign.right
      uniformRows = true
      uniformCols = true
    }
    commands.each |Command c|
    {
      c.assocDialog = this
      buttons.add(Button.makeCommand(c) { insets=Insets(0, 10, 0, 10) })
    }

    // build overall
    this.content = GridPane
    {
      expandCol = 0
      expandRow = 0
      valignCells = Valign.fill
      halignCells = Halign.fill
      InsetPane { add(content) }
      InsetPane { insets = Insets(0, 10, 10, 10); add(buttons) }
    }
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
internal class DialogCommand : Command
{
  new make(DialogCommandId id, Obj arg := null)
    : super.makeLocale(Dialog#.pod, id.name)
  {
    this.id = id
    this.arg = arg
    if (id == DialogCommandId.details)
      this.mode = CommandMode.toggle
  }

  override Void invoke(Event e)
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

  override Bool equals(Obj that)
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
  Obj arg
}

**************************************************************************
** DialogCommandId
**************************************************************************

**
** Ids for internal predefined Dialog commands.
**
internal enum DialogCommandId
{
  ok,
  cancel,
  yes,
  no,
  details
}
