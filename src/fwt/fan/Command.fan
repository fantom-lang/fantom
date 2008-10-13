//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jul 08  Brian Frank  Creation
//

**
** Command packages up the diplay name, icon, execution,
** and undo support for a user command.  You can create a
** command two ways:
**   1. use a closure (or any function) for `onInvoke`
**   2. subclass Command and override `invoke`
**
** If the command supports undo, then you must create a
** a subclass and override `undo`.
**
** Commands are often used to centralize control of multiple
** widgets.  For example if a Command is associated with
** both a menu item and a toolbar button, then disabling the
** command will disable both the menu item and toolbar button.
**
class Command
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Name of the command.
  **
  Str name

  **
  ** Icon of the command or null.  Typically a 16x16.
  **
  Image? icon

  **
  ** Accelerator of the command or null.
  **
  Key? accelerator

  **
  ** The function to invoke when the command is executed.  If
  ** empty, then `invoke` must be overridden.
  **
  @transient readonly EventListeners onInvoke := EventListeners()

  **
  ** The command mode determines who associated widgets are
  ** visualized.  The CommandMode maps to the `ButtonMode`
  ** and `MenuItemMode`.  The default is 'push'.
  **
  CommandMode mode := CommandMode.push

  **
  ** If this command is using toggle mode, then set the
  ** selected state and update all the registered widgets.
  **
  Bool selected := false
  {
    set
    {
      if (mode != CommandMode.toggle) return
      @selected = val
      widgets.each |Widget w|
      {
        try { w->selected = val } catch {}
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a command with the specified onInvoke function.
  ** If onInvoke is not specified, then the `invoke` method
  ** must be overridden to execute the command.
  **
  new make(Str? name := null, Image? icon := null, |Event event|? onInvoke := null)
  {
    if (name != null) this.name = name
    this.icon = icon
    if (onInvoke != null) this.onInvoke.add(onInvoke)
  }

  **
  ** Construct a localized command using the specified pod name
  ** and keyBase.  The command is initialized from the following
  ** [localized]`sys::Locale.get` properties:
  **   - "{keyBase}.name.{plat}": text string for the command
  **   - "{keyBase}.icon.{plat}": uri for the icon image
  **   - "{keyBase}.accelerator.{plat}": string representation of Key
  **
  ** The '{plat}' string comes from `Desktop.platform`.  If the
  ** paltform specific key is not found, then we attempt to fallback
  ** to a generic key.  For example:
  **
  **    back.name=Back
  **    back.accelerator=Alt+Left
  **    back.accelerator.mac=Command+[
  **
  ** On all platforms the command name would be "Back".  On Macs
  ** the accelerator would be 'Command+[', and all others it would
  ** be 'Alt+Left'.  If running on a Mac and an explicit ".mac"
  ** property was not specified, then automatically swizzle Ctrl
  ** to Command.
  **
  new makeLocale(Pod pod, Str keyBase, |Event event|? onInvoke := null)
  {
    plat := Desktop.platform

    // name
    name := pod.loc("${keyBase}.name.${plat}", null)
    if (name == null)
      name = pod.loc("${keyBase}.name")
    this.name = name

    // icon
    locIcon := pod.loc("${keyBase}.icon.${plat}", null)
    if (locIcon == null)
      locIcon = pod.loc("${keyBase}.icon", null)
    try
    {
      if (locIcon != null)
        this.icon = Image.make(locIcon.toUri)
    }
    catch type.log.error("Command: cannot load '${keyBase}.icon' => $locIcon")

    // accelerator
    locAcc := pod.loc("${keyBase}.accelerator.${plat}", null)
    locAccPlat := locAcc != null
    if (locAcc == null)
      locAcc = pod.loc("${keyBase}.accelerator", null)
    try
    {
      if (locAcc != null)
      {
        this.accelerator = Key.fromStr(locAcc)

        // if on a Mac and an explicit .mac prop was not defined,
        // then automatically swizzle Ctrl to Command
        if (!locAccPlat && Desktop.isMac)
          this.accelerator = this.accelerator.replace(Key.ctrl, Key.command)
      }
    }
    catch type.log.error("Command: cannot load '${keyBase}.accelerator ' => $locAcc")

    // onInvoke
    if (onInvoke != null) this.onInvoke.add(onInvoke)
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the window associated with this command.  If this
  ** command is being used as the action of a dialog, then
  ** return the dialog.  Otherwise try to map to a window
  ** via one of the widgets bound to this command.  Return
  ** null if no associated window can be found.
  **
  Window? window()
  {
    if (assocDialog != null) return assocDialog
    return widgets.eachBreak |Widget w->Window| { return w.window }
  }
  internal Dialog? assocDialog

  **
  ** The enable state of the command automatically controls
  ** the enabled state of all the registered widgets.
  **
  Bool enabled := true
  {
    set
    {
      if (@enabled == val) return
      @enabled = val
      registry.each |Widget w| { w.enabled = val }
    }
  }

  **
  ** Get the associated widgets with this command.  Widgets are
  ** automatically associated with their command field is set.
  **
  Widget[] widgets() { return registry.ro }

  **
  ** Register a widget with this command.  This is done
  ** automatically by the widget.  You only need to call
  ** this method if you are developing a custom widget.
  **
  Void register(Widget w) { registry.add(w) }

  **
  ** Unregister a widget with this command.  This is done
  ** automatically by the widget.  You only need to call
  ** this method if you are developing a custom widget.
  **
  Void unregister(Widget w) { registry.removeSame(w) }

  **
  ** Return name.
  **
  override Str toStr() { return name }

  private Widget[] registry := Widget[,]

//////////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////////

  **
  ** Invoke the command.  If the user event is known
  ** then is passed, otherwise it might be null.
  **
  virtual Void invoke(Event? event)
  {
    if (onInvoke.isEmpty) throw UnsupportedErr("Must set onInvoke or override invoke: $name")
    onInvoke.fire(event)
  }

//////////////////////////////////////////////////////////////////////////
// Undo
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if the command can be undone.  Default implementation
  ** returns true is the `undo` method has been overridden.
  **
  virtual Bool undoable()
  {
    return type.method("undo").parent != Command#
  }

  **
  ** This method is invoked when the command invoked as
  ** a redo.  It is not called on the first invocation.
  ** Default calls `invoke` with a null event.
  **
  virtual Void redo()
  {
    invoke(null)
  }

  **
  ** This method is invoked to undo the command.  This
  ** method is only used if `undoable` returns true.
  **
  virtual Void undo()
  {
    throw UnsupportedErr("Command not undoable $name")
  }

}

**************************************************************************
** CommandStack
**************************************************************************

**
** Manages a stack of commands for undo/redo.
**
class CommandStack
{
  **
  ** Max number of undo commands stored in the stack.
  **
  Int limit := 1000

  **
  ** Are any commands available for undo.
  **
  Bool hasUndo() { return undoStack.size > 0 }

  **
  ** Are any commands available for redo.
  **
  Bool hasRedo() { return redoStack.size > 0 }

  **
  ** List all the undo commands in the stack.
  **
  Command[] listUndo() { return undoStack.ro }

  **
  ** List all the redo commands in the stack.
  **
  Command[] listRedo() { return redoStack.ro }

  **
  ** Clear the undo/redo stacks.  Return this.
  **
  CommandStack clear() { undoStack.clear; redoStack.clear; fireModified; return this }

  **
  ** Callback when command stack is modified.
  **
  @transient readonly EventListeners onModify := EventListeners()

  private Void fireModified() { onModify.fire(Event { id = EventId.modified }) }

  **
  ** Push a command onto the undo stack.  This clears
  ** the redo stack.  If c is null or returns false
  ** for `Command.undoable` then ignore this call.
  ** Return this.
  **
  CommandStack push(Command? c)
  {
    if (c == null || !c.undoable) return this
    undoStack.push(c)
    if (undoStack.size > limit) undoStack.removeAt(0)
    redoStack.clear
    fireModified
    return this
  }

  **
  ** Call `Command.undo` on the last undo command and
  ** then push it onto the redo stack.  If the undo stack
  ** is empty, then ignore this call.  Return command undone.
  **
  Command? undo()
  {
    c := undoStack.pop
    if (c == null) return null
    c.undo
    redoStack.push(c)
    fireModified
    return c
  }

  **
  ** Call `Command.redo` on the last redo command and
  ** then push it onto the undo stack.  If the redo stack
  ** is empty, then ignore this call.  Return command redone.
  **
  Command? redo()
  {
    c := redoStack.pop
    if (c == null) return null
    c.redo
    undoStack.push(c)
    fireModified
    return c
  }

  private Command[] undoStack := Command[,]
  private Command[] redoStack := Command[,]
}