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
    this.byId = Str:FluxCommand[:]
    this.viewManaged = ViewManagedCommand[,]
    type.fields.each |Field f|
    {
      cmd := f.get(this) as FluxCommand
      if (cmd != null)
      {
        cmd.frame = frame
        byId.add(cmd.id, cmd)
        if (cmd is ViewManagedCommand)
          viewManaged.add(cmd)
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
      buildSearchMenu
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
      addCommand(newTab)
      addCommand(start)
      addCommand(openLocation)
      addSep
      addCommand(save)
      addCommand(saveAll)
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

  private Menu buildSearchMenu()
  {
    return Menu
    {
      text = type.loc("search.name")
      addCommand(find)
      addCommand(findNext)
      addCommand(findPrev)
      addCommand(findInFiles)
      addSep
      addCommand(replace)
      addCommand(replaceInFiles)
      addSep
      addCommand(goto)
      addSep
      addCommand(jumpNext)
      addCommand(jumpPrev)
    }
  }

  private Menu buildViewMenu()
  {
    menu := Menu
    {
      text = type.loc("view.name")
      onOpen.add(&onViewMenuOpen)
      addCommand(reload)
      addSep
    }

    types := Type.findByFacet("fluxSideBar", true)
    types = types.dup.sort |Type a, Type b->Int| { return a.name <=> b.name }
    types.each |Type t|
    {
      menu.addCommand(SideBarCommand(frame, t))
    }

    return menu
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
    saveAll.enabled = frame.views.any |View v->Bool| { return v.dirty }
  }

  Void disableViewManaged()
  {
    viewManaged.each |Command c| { c.enabled = false }
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  Void onViewMenuOpen(Event event)
  {
    event.widget.each |Widget w|
    {
      if (w is MenuItem && w->command is SideBarCommand)
      {
        cmd := w->command as SideBarCommand
        cmd.update
      }
    }
  }

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
  readonly FluxCommand newTab := NewTabCommand()
  readonly FluxCommand start := StartCommand()
  readonly FluxCommand openLocation := OpenLocationCommand()
  readonly FluxCommand save := SaveCommand()
  readonly FluxCommand saveAll := SaveAllCommand()
  readonly FluxCommand exit := ExitCommand()

  // Edit
  readonly FluxCommand undo := UndoCommand()
  readonly FluxCommand redo := RedoCommand()
  readonly FluxCommand cut := CutCommand()
  readonly FluxCommand copy := CopyCommand()
  readonly FluxCommand paste := PasteCommand()

  // Search
  readonly FluxCommand find := ViewManagedCommand(CommandId.find)
  readonly FluxCommand findNext := ViewManagedCommand(CommandId.findNext)
  readonly FluxCommand findPrev := ViewManagedCommand(CommandId.findPrev)
  readonly FluxCommand findInFiles := FindInFilesCommand()
  readonly FluxCommand replace := ViewManagedCommand(CommandId.replace)
  readonly FluxCommand replaceInFiles := ReplaceInFilesCommand()
  readonly FluxCommand goto := ViewManagedCommand(CommandId.goto)
  readonly FluxCommand jumpNext := JumpNextCommand()
  readonly FluxCommand jumpPrev := JumpPrevCommand()

  // View
  readonly FluxCommand reload  := ReloadCommand()

  // History
  readonly FluxCommand back := BackCommand()
  readonly FluxCommand forward := ForwardCommand()
  readonly FluxCommand up := UpCommand()

  // Tools
  readonly FluxCommand options := OptionsCommand()

  // Help
  readonly FluxCommand about := AboutCommand()

  // misc fields
  readonly ViewManagedCommand[] viewManaged
  readonly Str:FluxCommand byId
  readonly Int historyMenuSize
}

//////////////////////////////////////////////////////////////////////////
// Util Commands
//////////////////////////////////////////////////////////////////////////

** ViewManagedCommands are managed by the current view
internal class ViewManagedCommand : FluxCommand
{
  new make(Str id) : super(id) { enabled=false }
  override Void invoke(Event event)
  {
    frame.view.onCommand(id, event)
  }
}

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

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

** Save every dirty view
internal class SaveAllCommand : FluxCommand
{
  new make() : super(CommandId.saveAll) {}
  override Void invoke(Event event)
  {
    frame.views.each |View view| { view.tab.save }
  }
}

** Exit the application
internal class ExitCommand : FluxCommand
{
  new make() : super(CommandId.exit) {}
  override Void invoke(Event event)
  {
    dirty := frame.views.findAll |View v->Bool| { return v.dirty }
    if (dirty.size > 0)
    {
      // TODO
      r := Dialog.openQuestion(frame, "TODO: Close with $dirty.size views?", Dialog.yesNo)
      if (r != Dialog.yes) return
    }
    frame.close
  }
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
// Search
//////////////////////////////////////////////////////////////////////////

** Find in files
internal class FindInFilesCommand : FluxCommand
{
  new make() : super(CommandId.findInFiles) {}
  override Void invoke(Event event) { Dialog.openInfo(frame, "TODO: Find in Files") }
}

** Replace in files
internal class ReplaceInFilesCommand : FluxCommand
{
  new make() : super(CommandId.replaceInFiles) {}
  override Void invoke(Event event) { Dialog.openInfo(frame, "TODO: Replace in Files") }
}

** Jump to next error/search position
internal class JumpNextCommand : FluxCommand
{
  new make() : super(CommandId.jumpNext) {}
  override Void invoke(Event event) { Dialog.openInfo(frame, "TODO: Jump next") }
}

** Jump to previous error/search position
internal class JumpPrevCommand : FluxCommand
{
  new make() : super(CommandId.jumpPrev) {}
  override Void invoke(Event event) { Dialog.openInfo(frame, "TODO: Jump prev") }
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

** Toggle sidebar shown/hidden
internal class SideBarCommand : FluxCommand
{
  new make(Frame f, Type sbType) : super(sbType.name, sbType.pod)
  {
    this.frame = f
    this.sbType = sbType
    this.name = sbType.name
  }

  override Void invoke(Event event)
  {
    sb := frame.sideBar(sbType)
    if (sb.showing) sb.hide; else sb.show
  }

  Void update()
  {
    sb := frame.sideBar(sbType, false)
    if (sb == null || !sb.showing)
      name = "Show $sbType.name"
    else
      name = "Hide $sbType.name"
    widgets.each |Widget w| { w->text = name }
  }

  const Type sbType
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