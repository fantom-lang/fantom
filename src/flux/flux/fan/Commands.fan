//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
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
        MenuItem { command = back }
        MenuItem { command = forward }
        MenuItem { command = refresh }
        MenuItem { command = up }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { command = locator }
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
      Button { command = refresh; text="" }
      Button { command = up; text="" }
      /*
      Button { mode = ButtonMode.sep }
      Button { command = save; text="" }
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
    tab := frame.viewTab
    back.enabled = tab.backEnabled
    forward.enabled = tab.forwardEnabled
    up.enabled = tab.upEnabled
    updateEdit
    updateSave
  }

  Void updateEdit()
  {
    tab := frame.viewTab
    undo.enabled = tab.undoEnabled
    redo.enabled = tab.redoEnabled
  }

  Void updateSave()
  {
    tab := frame.viewTab
    save.enabled = tab.dirty
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  readonly Frame frame

  // File
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
  readonly Command refresh := RefreshCommand()
  readonly Command up := UpCommand()
  readonly Command locator := LocatorCommand()

  // Tools
  readonly Command options := OptionsCommand()

  // Help
  readonly Command about := AboutCommand()
}

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

** Save current view
internal class SaveCommand : FluxCommand
{
  new make() : super(CommandId.save) {}
  override Void invoke(Event event) { frame.viewTab.view?.save }
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
  override Void invoke(Event event) { frame.viewTab.undo }
}

** Redo last undone command
internal class RedoCommand : FluxCommand
{
  new make() : super(CommandId.redo) {}
  override Void invoke(Event event) { frame.viewTab.redo }
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

** Hyperlink back in history
internal class BackCommand : FluxCommand
{
  new make() : super(CommandId.back) {}
  override Void invoke(Event event) { frame.viewTab.back }
}

** Hyperlink forward in history
internal class ForwardCommand : FluxCommand
{
  new make() : super(CommandId.forward) {}
  override Void invoke(Event event) { frame.viewTab.forward }
}

** Refresh the current view
internal class RefreshCommand : FluxCommand
{
  new make() : super(CommandId.refresh) {}
  override Void invoke(Event event) { frame.viewTab.refresh }
}

** Hyperlink up a level in the hierarchy
internal class UpCommand : FluxCommand
{
  new make() : super(CommandId.up) {}
  override Void invoke(Event event) { frame.viewTab.up }
}

** Focus the uri location field
internal class LocatorCommand : FluxCommand
{
  new make() : super(CommandId.location) {}
  override Void invoke(Event event) { frame.locator.onLocation(event) }
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
