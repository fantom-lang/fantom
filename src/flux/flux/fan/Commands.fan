//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Br ian Frank  Creation
//
using fwt

** Manages all the main window's commands
internal class Commands
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(Frame frame)
  {
    this.frame = frame
    type.fields.each |Field f|
    {
      cmd := f.get(this) as FluxCommand
      if (cmd != null) cmd.frame = frame
    }
  }

//////////////////////////////////////////////////////////////////////////
// Menu Bar
//////////////////////////////////////////////////////////////////////////

  internal Menu buildMenuBar()
  {
    return Menu
    {
      Menu
      {
        text = type.loc("file.name")
        MenuItem { command = newWindow }
        MenuItem { command = newTab }
        MenuItem { command = start }
        MenuItem { command = openLocation }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { command = save }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { command = exit }
      }

      Menu
      {
        text = type.loc("edit.name")
        MenuItem { command = undo}
        MenuItem { command = redo }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { command = cut }
        MenuItem { command = copy }
        MenuItem { command = paste }
      }

      Menu
      {
        text = type.loc("view.name")
        MenuItem { command = reload }
      }

      Menu
      {
        text = type.loc("history.name")
        MenuItem { command = back }
        MenuItem { command = forward }
        MenuItem { command = up }
      }

      Menu
      {
        text = type.loc("tools.name")
        MenuItem { command = options }
      }

      Menu
      {
        text = type.loc("help.name")
        MenuItem { command = about }
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tool Bar
//////////////////////////////////////////////////////////////////////////

  internal ToolBar buildToolBar()
  {
    return ToolBar
    {
      Button { command = back; text="" }
      Button { command = forward; text="" }
      Button { command = reload; text="" }
      Button { command = up; text="" }
      //Button { mode = ButtonMode.sep }
      Button { command = save; text="" }
      /*
      Button { mode = ButtonMode.sep }
      Button { command = cut; text="" }
      Button { command = copy; text="" }
      Button { command = paste; text="" }
      Button { mode = ButtonMode.sep }
      Button { command = undo; text="" }
      Button { command = redo; text="" }
      */
    }
  }

//////////////////////////////////////////////////////////////////////////
// Update
//////////////////////////////////////////////////////////////////////////

  Void update()
  {
    tab := frame.view.tab
    back.enabled = tab.backEnabled
    forward.enabled = tab.forwardEnabled
    up.enabled = tab.upEnabled
    updateEdit
    updateSave
  }

  Void updateEdit()
  {
    tab := frame.view.tab
    undo.enabled = tab.undoEnabled
    redo.enabled = tab.redoEnabled
  }

  Void updateSave()
  {
    tab := frame.view.tab
    save.enabled = tab.dirty
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  readonly Frame frame

  // File
  readonly Command newWindow := NewWindowCommand()
  readonly Command newTab := NewTabCommand()
  readonly Command start := StartCommand()
  readonly Command openLocation := OpenLocationCommand()
  readonly Command save := SaveCommand()
  readonly Command exit := ExitCommand()

  // Edit
  readonly Command undo := UndoCommand()
  readonly Command redo := RedoCommand()
  readonly Command cut  := CutCommand()
  readonly Command copy := CopyCommand()
  readonly Command paste := PasteCommand()

  // View
  readonly Command back := BackCommand()
  readonly Command forward := ForwardCommand()
  readonly Command reload  := ReloadCommand()
  readonly Command up := UpCommand()

  // Tools
  readonly Command options := OptionsCommand()

  // Help
  readonly Command about := AboutCommand()
}

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

** Open a new frame.
internal class NewWindowCommand : FluxCommand
{
  new make() : super(CommandId.newWindow) {}
  override Void invoke(Event event)
  {
    frame.loadUri(`flux:start`, LoadMode { newWindow=true })
  }
}

** Open a new view tab.
internal class NewTabCommand : FluxCommand
{
  new make() : super(CommandId.newTab) {}
  override Void invoke(Event event)
  {
    frame.loadUri(`flux:start`, LoadMode { newTab=true })
  }
}

** Hyperlink to the flux:start
internal class StartCommand : FluxCommand
{
  new make() : super(CommandId.start) {}
  override Void invoke(Event event) { frame.loadUri(`flux:start`) }
}

** Focus the uri location field
internal class OpenLocationCommand : FluxCommand
{
  new make() : super(CommandId.openLocation) {}
  override Void invoke(Event event) { frame.locator.onLocation(event) }
}

** Save current view
internal class SaveCommand : FluxCommand
{
  new make() : super(CommandId.save) {}
  override Void invoke(Event event) { frame.view.tab.save }
}

** Exit the application
internal class ExitCommand : FluxCommand
{
  new make() : super(CommandId.exit) {}
  override Void invoke(Event event) { Sys.exit }
}

//////////////////////////////////////////////////////////////////////////
// Edit
//////////////////////////////////////////////////////////////////////////

** Undo last command
internal class UndoCommand : FluxCommand
{
  new make() : super(CommandId.undo) {}
  override Void invoke(Event event) { frame.view.tab.undo }
}

** Redo last undone command
internal class RedoCommand : FluxCommand
{
  new make() : super(CommandId.redo) {}
  override Void invoke(Event event) { frame.view.tab.redo }
}

** Cut command routes to 'focus?.cut'
internal class CutCommand : FluxCommand
{
  new make() : super(CommandId.cut) {}
  override Void invoke(Event event)
  {
    try { Desktop.focus?->cut } catch (UnknownSlotErr e) {}
  }
}

** Copy command routes to 'focus?.copy'
internal class CopyCommand : FluxCommand
{
  new make() : super(CommandId.copy) {}
  override Void invoke(Event event)
  {
    try { Desktop.focus?->copy } catch (UnknownSlotErr e) {}
  }
}

** Paste command routes to 'focus?.paste'
internal class PasteCommand : FluxCommand
{
  new make() : super(CommandId.paste) {}
  override Void invoke(Event event)
  {
    try { Desktop.focus?->paste } catch (UnknownSlotErr e) {}
  }
}

//////////////////////////////////////////////////////////////////////////
// View
//////////////////////////////////////////////////////////////////////////

** Reload the current view
internal class ReloadCommand : FluxCommand
{
  new make() : super(CommandId.reload) {}
  override Void invoke(Event event) { frame.view.tab.reload }
}

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

** Hyperlink back in history
internal class BackCommand : FluxCommand
{
  new make() : super(CommandId.back) {}
  override Void invoke(Event event) { frame.view.tab.back }
}

** Hyperlink forward in history
internal class ForwardCommand : FluxCommand
{
  new make() : super(CommandId.forward) {}
  override Void invoke(Event event) { frame.view.tab.forward }
}

** Hyperlink up a level in the hierarchy
internal class UpCommand : FluxCommand
{
  new make() : super(CommandId.up) {}
  override Void invoke(Event event) { frame.view.tab.up }
}

//////////////////////////////////////////////////////////////////////////
// Tools
//////////////////////////////////////////////////////////////////////////

** Hyperlink to the options directory
internal class OptionsCommand : FluxCommand
{
  new make() : super(CommandId.options) {}
  override Void invoke(Event event) { frame.loadUri(Flux.homeDir.uri) }
}

//////////////////////////////////////////////////////////////////////////
// Tools
//////////////////////////////////////////////////////////////////////////

** Hyperlink to the flux:about
internal class AboutCommand : FluxCommand
{
  new make() : super(CommandId.about) {}
  override Void invoke(Event event) { frame.loadUri(`flux:about`) }
}