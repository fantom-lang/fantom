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
  ** Open an information message box.  Return selected command.
  ** Commands passed must be predefined, or if omitted the default is ok.
  **
  static native Obj openInfo(Window parent, Str msg, Command[] commands := [ok])

  **
  ** Open a warning message box.  Return selected command.
  ** Commands passed must be predefined, or if omitted the default is ok.
  **
  static native Obj openWarn(Window parent, Str msg, Command[] commands := [ok])

  **
  ** Open an error message box.  Return selected command.
  ** Commands passed must be predefined, or if omitted the default is ok.
  **
  static native Obj openErr(Window parent, Str msg, Command[] commands := [ok])

  **
  ** Open a question message box.  Return selected command.
  ** Commands passed must be predefined, or if omitted the default is ok.
  **
  static native Obj openQuestion(Window parent, Str msg, Command[] commands := [ok])

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Window parent, Obj content := null, Command[] commands := null)
    : super(parent)
  {
    // TODO
  }

}

**************************************************************************
** DialogCommand
**************************************************************************

**
** Internal class used for predefined Dialog commands.
**
internal class DialogCommand : Command
{
  new make(DialogCommandId id)
    : super.makeLocale(Dialog#.pod, id.name)
  {
    this.id = id
  }

  override Int hash() { return id.hash }

  override Bool equals(Obj that)
  {
    if (that isnot DialogCommand) return false
    return ((DialogCommand)that).id == id
  }

  const DialogCommandId id
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
  no
}
