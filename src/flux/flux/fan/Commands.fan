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
    this.byId = Str:Command[:]
    type.fields.each |Field f|
    {
      cmd := f.get(this) as FluxCommand
      if (cmd != null)
      {
        byId.add(cmd.id, cmd)
        cmd.frame = frame
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Menu Bar
//////////////////////////////////////////////////////////////////////////

  internal Menu buildMenuBar()
  {
    return Menu
    {
      buildFileMenu
      buildEditMenu
      buildViewMenu
      buildHistoryMenu
      buildToolsMenu
      buildHelpMenu
    }
  }

  private Menu buildFileMenu()
  {
    return Menu
    {
      text = type.loc("file.name")
      addCommand(newWindow)
      addCommand(newTab)
      addCommand(start)
      addCommand(openLocation)
      addSep
      addCommand(save)
      addSep
      addCommand(exit)
    }
  }

  private Menu buildEditMenu()
  {
    return Menu
    {
      text = type.loc("edit.name")
      addCommand(undo)
      addCommand(redo)
      addSep
      addCommand(cut)
      addCommand(copy)
      addCommand(paste)
    }
  }

  private Menu buildViewMenu()
  {
    return Menu
    {
      text = type.loc("view.name")
      addCommand(reload)
    }
  }

  private Menu buildHistoryMenu()
  {
    menu := Menu
    {
      text = type.loc("history.name")
      onOpen.add(&onHistoryMenuOpen)
      addCommand(back)
      addCommand(forward)
      addCommand(up)
      addSep
    }
    historyMenuSize = menu.children.size
    return menu
  }

  private Menu buildToolsMenu()
  {
    return Menu
    {
      text = type.loc("tools.name")
      addCommand(options)
    }
  }

  private Menu buildHelpMenu()
  {
    return Menu
    {
      text = type.loc("help.name")
      addCommand(about)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tool Bar
//////////////////////////////////////////////////////////////////////////

  internal ToolBar buildToolBar()
  {
    return ToolBar
    {
      addCommand(back)
      addCommand(forward)
      addCommand(reload)
      addCommand(up)
      addCommand(save)
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
// Eventing
//////////////////////////////////////////////////////////////////////////

  Void onHistoryMenuOpen(Event event)
  {
    menu := event.widget

    // remove any old items on the history menu
    children := menu.children
    (historyMenuSize...children.size).each |Int i|
    {
      menu.remove(children[i])
    }

    // add most 10 most recent
    recent := History.load.items
    if (recent.size > 10) recent = recent[0..9]
    recent.each |HistoryItem item|
    {
      menu.add(toHistoryMenuItem(item))
    }
  }

  MenuItem toHistoryMenuItem(HistoryItem item)
  {
    name := item.uri.name
    if (item.uri.isDir) name += "/"
    return MenuItem
    {
      text = name
      onAction.add |,| { frame.loadUri(item.uri) }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  readonly Frame frame

  // File
  readonly FluxCommand newWindow := NewWindowCommand()
  readonly FluxCommand newTab := NewTabCommand()
  readonly FluxCommand start := StartCommand()
  readonly FluxCommand openLocation := OpenLocationCommand()
  readonly FluxCommand save := SaveCommand()
  readonly FluxCommand exit := ExitCommand()

  // Edit
  readonly FluxCommand undo := UndoCommand()
  readonly FluxCommand redo := RedoCommand()
  readonly FluxCommand cut  := CutCommand()
  readonly FluxCommand copy := CopyCommand()
  readonly FluxCommand paste := PasteCommand()

  // View
  readonly FluxCommand back := BackCommand()
  readonly FluxCommand forward := ForwardCommand()
  readonly FluxCommand reload  := ReloadCommand()
  readonly FluxCommand up := UpCommand()

  // Tools
  readonly FluxCommand options := OptionsCommand()

  // Help
  readonly FluxCommand about := AboutCommand()

  // misc fields
  readonly Str:FluxCommand byId
  readonly Int historyMenuSize
}

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

** Open a new frame.
internal class NewWindowCommand : FluxCommand
{
  new make() : super(CommandId.newWindow) { enabled=false }
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
  override Void invoke(Event event) { frame.close }
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