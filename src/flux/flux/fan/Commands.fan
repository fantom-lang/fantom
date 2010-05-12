//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Br ian Frank  Creation
//

using concurrent
using gfx
using fwt
using compiler

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
    Type.of(this).fields.each |Field f|
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
      buildFileMenu,
      buildEditMenu,
      buildViewMenu,
      buildHistoryMenu,
      buildToolsMenu,
      buildHelpMenu,
    }
  }

  private Menu buildFileMenu()
  {
    return Menu
    {
      text = Flux.locale("file.name")
      addCommand(newTab)
      addCommand(openLocation)
      addCommand(closeTab)
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
      text = Flux.locale("edit.name")
      onOpen.add { onEditMenuOpen(it) }
      addCommand(undo)
      addCommand(redo)
      addSep
      addCommand(cut)
      addCommand(copy)
      addCommand(paste)
      addSep
      addCommand(find)
      addCommand(findNext)
      addCommand(findPrev)
      addCommand(findInFiles)
      addSep
      addCommand(replace)
      addCommand(replaceInFiles)
      addSep
      addCommand(goto)
      addCommand(gotoFile)
      addSep
      addCommand(jumpNext)
      addCommand(jumpPrev)
      addSep
      addCommand(selectAll)
    }
  }

  private Menu buildViewMenu()
  {
    menu := Menu
    {
      text = Flux.locale("view.name")
      onOpen.add { onViewMenuOpen(it) }
      addCommand(reload)
      addSep
    }

    types := Flux.qnamesToTypes(Env.cur.index("flux.sideBar"))
    types = types.dup.sort |Type a, Type b->Int| { return a.name <=> b.name }
    types.each |Type t|
    {
      cmd := SideBarCommand(frame, t)
      byId.add(cmd.id, cmd)
      menu.addCommand(cmd)
    }

    return menu
  }

  private Menu buildHistoryMenu()
  {
    menu := Menu
    {
      text = Flux.locale("history.name")
      onOpen.add { onHistoryMenuOpen(it) }
      addCommand(back)
      addCommand(forward)
      addCommand(up)
      addCommand(home)
      addCommand(recent)
      addSep
    }
    historyMenuSize = menu.children.size
    return menu
  }

  private Menu buildToolsMenu()
  {
    menu := Menu
    {
      text = Flux.locale("tools.name")
      addCommand(options)
      addCommand(refreshTools)
      addSep
    }
    toolsMenuSize = menu.children.size
    toolsMenu = menu
    refreshToolsMenu
    return menu
  }

  private Menu buildHelpMenu()
  {
    return Menu
    {
      text = Flux.locale("help.name")
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
      addCommand(up)
      addCommand(reload)
      addCommand(recent)
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
    closeTab.enabled = frame.views.size > 1
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

  Void onEditMenuOpen(Event event)
  {
    undo := Flux.locale("undo.name")
    redo := Flux.locale("redo.name")

    stack := frame.view.commandStack
    if (stack.listUndo.size > 0) undo = "$undo $stack.listUndo.last.name"
    if (stack.listRedo.size > 0) redo = "$redo $stack.listRedo.last.name"

    kids := event.widget.children
    kids[0]->text = undo
    kids[1]->text = redo
  }

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
    // remove any old items on the history menu
    menu := event.widget
    children := menu.children
    (historyMenuSize..<children.size).each |Int i|
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
      onAction.add |->| { frame.load(item.uri) }
    }
  }

  Void refreshToolsMenu()
  {
    // remove any old items on the tools menu
    children := toolsMenu.children
    (toolsMenuSize..<children.size).each |Int i|
    {
      toolsMenu.remove(children[i])
    }

    // add new menu items
    addToolScripts(toolsMenu, toolsDir, true)
  }

  Void addToolScripts(Menu menu, File f, Bool top := false)
  {
    if (f.isDir)
    {
      if (!top) { sub := Menu { text=f.name }; menu.add(sub); menu = sub }
      FileResource.sortFiles(f.list).each |File k| { addToolScripts(menu, k) }
    }
    else
    {
      if (f.ext == "fan") menu.addCommand(ToolScriptCommand(frame, f))
    }
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  readonly Frame frame

  // File
  readonly FluxCommand newTab := NewTabCommand()
  readonly FluxCommand openLocation := OpenLocationCommand()
  readonly FluxCommand closeTab := CloseTabCommand()
  readonly FluxCommand save := SaveCommand()
  readonly FluxCommand saveAll := SaveAllCommand()
  readonly FluxCommand exit := ExitCommand()

  // Edit
  readonly FluxCommand undo := UndoCommand()
  readonly FluxCommand redo := RedoCommand()
  readonly FluxCommand cut := CutCommand()
  readonly FluxCommand copy := CopyCommand()
  readonly FluxCommand paste := PasteCommand()
  readonly FluxCommand find := ViewManagedCommand(CommandId.find)
  readonly FluxCommand findNext := ViewManagedCommand(CommandId.findNext)
  readonly FluxCommand findPrev := ViewManagedCommand(CommandId.findPrev)
  readonly FluxCommand findInFiles := FindInFilesCommand()
  readonly FluxCommand replace := ViewManagedCommand(CommandId.replace)
  readonly FluxCommand replaceInFiles := ReplaceInFilesCommand()
  readonly FluxCommand goto := ViewManagedCommand(CommandId.goto)
  readonly FluxCommand gotoFile := GotoFileCommand()
  readonly FluxCommand jumpNext := JumpNextCommand()
  readonly FluxCommand jumpPrev := JumpPrevCommand()
  readonly FluxCommand selectAll := SelectAllCommand()

  // View
  readonly FluxCommand reload  := ReloadCommand()

  // History
  readonly FluxCommand back := BackCommand()
  readonly FluxCommand forward := ForwardCommand()
  readonly FluxCommand up := UpCommand()
  readonly FluxCommand home := HomeCommand()
  readonly FluxCommand recent := RecentCommand()

  // Tools
  readonly FluxCommand options := OptionsCommand()
  readonly FluxCommand refreshTools := RefreshToolsCommand()

  // Help
  readonly FluxCommand about := AboutCommand()

  // misc fields
  readonly ViewManagedCommand[] viewManaged
  readonly Str:FluxCommand byId
  readonly Int historyMenuSize
  readonly Menu? toolsMenu
  readonly Int toolsMenuSize
  readonly File toolsDir := Env.cur.homeDir +`etc/flux/tools/`
}

//////////////////////////////////////////////////////////////////////////
// Util Commands
//////////////////////////////////////////////////////////////////////////

** ViewManagedCommands are managed by the current view
internal class ViewManagedCommand : FluxCommand
{
  new make(Str id) : super(id) { enabled=false }
  override Void invoked(Event? event)
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
  override Void invoked(Event? event)
  {
    frame.load(`flux:start`, LoadMode { newTab=true })
  }
}

** Focus the uri location field
internal class OpenLocationCommand : FluxCommand
{
  new make() : super(CommandId.openLocation) {}
  override Void invoked(Event? event) { frame.locator.onLocation(event) }
}

** Close current view tab.
internal class CloseTabCommand : FluxCommand
{
  new make() : super(CommandId.closeTab) {}
  override Void invoked(Event? event)
  {
    if (frame.views.size > 1)
      frame.tabPane.close(frame.view.tab)
  }
}

** Save current view
internal class SaveCommand : FluxCommand
{
  new make() : super(CommandId.save) {}
  override Void invoked(Event? event) { frame.view.tab.save }
}

** Save every dirty view
internal class SaveAllCommand : FluxCommand
{
  new make() : super(CommandId.saveAll) {}
  override Void invoked(Event? event)
  {
    frame.views.each |View view| { view.tab.save }
  }
}

** Exit the application
internal class ExitCommand : FluxCommand
{
  new make() : super(CommandId.exit) {}
  override Void invoked(Event? event)
  {
    dirty := frame.views.findAll |View v->Bool| { return v.dirty }
    if (dirty.size > 0)
    {
      grid := GridPane { Label { text=Flux.locale("saveChanges"); font=Desktop.sysFont.toBold },}
      dirty.each |View v|
      {
        grid.add(InsetPane(0,0,0,8) {
         Button { it.mode=ButtonMode.check; it.text=v.resource.uri.toStr; it.selected=true },
        })
      }
      saveSel  := ExitSaveCommand(Pod.of(this), "saveSelected")
      saveNone := ExitSaveCommand(Pod.of(this), "saveNone")
      cancel   := ExitSaveCommand(Command#.pod, "cancel")
      pane := ConstraintPane
      {
        minw = 400
        add(InsetPane(0,0,12,0).add(grid))
      }
      d := Dialog(frame) { title="Save"; body=pane; commands=[saveSel,saveNone,cancel] }
      r := d.open
      if (r == cancel) return
      if (r == saveSel)
      {
        grid.children.each |Widget w, Int i|
        {
          if (w isnot InsetPane) return
          c := w.children.first as Button
          v := dirty[i-1]
          if (c.selected) v.tab.save
        }
      }
    }
    flux::Main.exit(frame)
  }
}

internal class ExitSaveCommand : Command
{
  new make(Pod pod, Str keyBase) : super.makeLocale(pod, keyBase) {}
  override Void invoked(Event? e) { window?.close(this) }
}

//////////////////////////////////////////////////////////////////////////
// Edit
//////////////////////////////////////////////////////////////////////////

** Undo last command
internal class UndoCommand : FluxCommand
{
  new make() : super(CommandId.undo) {}
  override Void invoked(Event? event) { frame.view.tab.undo }
}

** Redo last undone command
internal class RedoCommand : FluxCommand
{
  new make() : super(CommandId.redo) {}
  override Void invoked(Event? event) { frame.view.tab.redo }
}

** Cut command routes to 'focus?.cut'
internal class CutCommand : FluxCommand
{
  new make() : super(CommandId.cut) {}
  override Void invoked(Event? event)
  {
    try { Desktop.focus?->cut } catch (UnknownSlotErr e) {}
  }
}

** Copy command routes to 'focus?.copy'
internal class CopyCommand : FluxCommand
{
  new make() : super(CommandId.copy) {}
  override Void invoked(Event? event)
  {
    try { Desktop.focus?->copy } catch (UnknownSlotErr e) {}
  }
}

** Paste command routes to 'focus?.paste'
internal class PasteCommand : FluxCommand
{
  new make() : super(CommandId.paste) {}
  override Void invoked(Event? event)
  {
    try { Desktop.focus?->paste } catch (UnknownSlotErr e) {}
  }
}

** Copy command routes to 'focus?.selectAll'
internal class SelectAllCommand : FluxCommand
{
  new make() : super(CommandId.selectAll) {}
  override Void invoked(Event? event)
  {
    try { Desktop.focus?->selectAll } catch (UnknownSlotErr e) {}
  }
}

//////////////////////////////////////////////////////////////////////////
// Search
//////////////////////////////////////////////////////////////////////////

** Find in files
internal class FindInFilesCommand : FluxCommand
{
  new make() : super(CommandId.findInFiles) {}
  override Void invoked(Event? event) { FindInFiles.dialog(frame) }
}

** Replace in files
internal class ReplaceInFilesCommand : FluxCommand
{
  new make() : super(CommandId.replaceInFiles) {}
  override Void invoked(Event? event) { Dialog.openInfo(frame, "TODO: Replace in Files") }
}

** Goto file
internal class GotoFileCommand : FluxCommand
{
  new make() : super(CommandId.gotoFile) {}
  override Void invoked(Event? event)
  {
    if (!FileIndex.instance.ready)
    {
      Dialog.openInfo(frame, "Still indexing file system...")
      return
    }

    // build dialog
    Str last := Actor.locals.get("fluxText.gotoFileLast", "")
    field := Text { it.text = last; it.prefCols = 20}
    pane := GridPane
    {
      numCols = 4
      expandCol = 1
      halignCells=Halign.fill
      Label { text="Goto File:" },
      field,
      Button { image=Flux.icon(`/x16/refresh.png`); onAction.add { rebuild(it.widget) } },
      Button { image=Flux.icon(`/x16/question.png`); onAction.add { showHelp } },
    }
    field.onAction.add |e| { e.widget.window.close(Dialog.ok) }

    // prompt user
    r := Dialog(frame) { title="Goto File"; body=pane; commands=[Dialog.ok, Dialog.cancel] }.open
    if (r != Dialog.ok) return
    target := field.text
    Actor.locals.set("fluxText.gotoFileLast", target)

    // lookup target in our index
    files := FileIndex.instance.find(target)
    if (files.size == 0)
    {
      Dialog.openErr(frame, "File not found: $target")
      return
    }

    // if exactly one match, go straight there
    if (files.size == 1)
    {
      frame.load(files[0])
      return
    }

    // prompt user with list of files (use same dialog as Recent Files)
    items := HistoryItem[,]
    files.each |uri| { items.add(HistoryItem { it.uri = uri; it.iconUri = FileResource.fileToIcon(uri.toFile).uri }) }
    Dialog? dlg
    picker := HistoryPicker(items, true) |HistoryItem item, Event e|
    {
      frame.load(item.uri, LoadMode(e))
      dlg.close
    }
    pickerPane := ConstraintPane { minw = 500; maxh = 300; add(picker) }
    dlg = Dialog(frame) { title="Goto File"; body=pickerPane ; commands=[Dialog.ok, Dialog.cancel] }
    dlg.open
  }

  Void rebuild(Widget widget)
  {
    FileIndex.instance.rebuild
    widget.window.close(Dialog.cancel)
  }

  Void showHelp()
  {
    msg :=
    """Goto File Cheat Sheet:\n
       - Glob any file name such as "SideBar.fan" or "SideBar*.fan"\n
       - Glob any file base name (without extension) such as "SideBar" or "SideBar*"\n
       - Match camel case abbreviation such as "SB" for "SideBar"\n
       Indexing is configured with GeneralOption.indexDirs (very primitive right
       now). Use refresh button to manually rebuild index.  See Regex.glob for
       definition of glob syntax."""
    Dialog.openInfo(frame, msg)
  }
}

** Jump to next error/search position
internal class JumpNextCommand : FluxCommand
{
  new make() : super(CommandId.jumpNext) {}
  override Void invoked(Event? event)
  {
    if (frame.marks.isEmpty) return

    if (frame.curMark == null)
      frame.curMark = 0
    else
      frame.curMark++

    if (frame.curMark >= frame.marks.size)
    {
      frame.curMark = frame.marks.size-1
      return
    }

    frame.loadMark(frame.marks[frame.curMark])
  }
}

** Jump to previous error/search position
internal class JumpPrevCommand : FluxCommand
{
  new make() : super(CommandId.jumpPrev) {}
  override Void invoked(Event? event)
  {
    if (frame.marks.isEmpty) return

    if (frame.curMark == null)
      frame.curMark = frame.marks.size-1
    else
      frame.curMark--

    if (frame.curMark < 0)
    {
      frame.curMark = 0
      return
    }

    frame.loadMark(frame.marks[frame.curMark])
  }
}

//////////////////////////////////////////////////////////////////////////
// View
//////////////////////////////////////////////////////////////////////////

** Reload the current view
internal class ReloadCommand : FluxCommand
{
  new make() : super(CommandId.reload) {}
  override Void invoked(Event? event) { frame.view.tab.reload }
}

** Toggle sidebar shown/hidden
internal class SideBarCommand : FluxCommand
{
  new make(Frame f, Type sbType) : super(sbType.name, sbType.pod)
  {
    this.mode = CommandMode.toggle
    this.frame = f
    this.sbType = sbType
    this.name = sbType.name
  }

  override Void invoked(Event? event)
  {
    sb := frame.sideBar(sbType)
    if (sb.showing) sb.hide; else sb.show
  }

  Void update()
  {
    sb := frame.sideBar(sbType, false)
    selected = sb != null && sb.showing
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
  override Void invoked(Event? event) { frame.view.tab.back }
}

** Hyperlink forward in history
internal class ForwardCommand : FluxCommand
{
  new make() : super(CommandId.forward) {}
  override Void invoked(Event? event) { frame.view.tab.forward }
}

** Hyperlink up a level in the hierarchy
internal class UpCommand : FluxCommand
{
  new make() : super(CommandId.up) {}
  override Void invoked(Event? event) { frame.view.tab.up }
}

** Hyperlink to the home page
internal class HomeCommand : FluxCommand
{
  new make() : super(CommandId.home) {}
  override Void invoked(Event? event) { frame.load(GeneralOptions.load.homePage) }
}

** Open recent history dialog
internal class RecentCommand : FluxCommand
{
  new make() : super(CommandId.recent) {}
  override Void invoked(Event? event)
  {
    Dialog? dlg
    picker := HistoryPicker(History.load.items, false) |HistoryItem item, Event e|
    {
      frame.load(item.uri, LoadMode(e))
      dlg.close
    }
    pane := ConstraintPane { minw = 300; maxh = 300; add(picker) }
    dlg = Dialog(frame) { title="Recent"; body=pane; commands=[Dialog.ok, Dialog.cancel] }
    dlg.open
  }
}

//////////////////////////////////////////////////////////////////////////
// Tools
//////////////////////////////////////////////////////////////////////////

** Hyperlink to the options directory
internal class OptionsCommand : FluxCommand
{
  new make() : super(CommandId.options) {}
  override Void invoked(Event? event) { frame.load((Env.cur.homeDir+`etc/flux/`).uri) }
}

** Refresh the tools menu
internal class RefreshToolsCommand : FluxCommand
{
  new make() : super("refreshTools") {}
  override Void invoked(Event? event) { frame.commands.refreshToolsMenu }
}

** Invoke a tool script
internal class ToolScriptCommand : FluxCommand
{
  new make(Frame frame, File file) : super("tools.${file.basename}")
  {
    this.frame = frame
    this.file  = file
    this.name  = file.basename
  }

  override Void invoked(Event? event)
  {
    try
    {
      FluxCommand cmd := Env.cur.compileScript(file).make([id])
      cmd.frame = frame
      cmd.invoke(event)
    }
    catch (CompilerErr e)
    {
      Dialog.openErr(frame, "Cannot compile tool: $file", e)
    }
    catch (Err e)
    {
      e.trace
      Dialog.openErr(frame, "Cannot invoke tool: $file", e)
    }
  }
  const File file
}

//////////////////////////////////////////////////////////////////////////
// Help
//////////////////////////////////////////////////////////////////////////

** Hyperlink to the flux:about
internal class AboutCommand : FluxCommand
{
  new make() : super(CommandId.about) {}
  override Void invoked(Event? event)
  {
    icon  := Pod.find("icons").file(`/x48/flux.png`)
    big   := Font { it.name=Desktop.sysFont.name; it.size=Desktop.sysFont.size+(Desktop.isMac ? 2 : 3); it.bold=true }
    small := Font { it.name=Desktop.sysFont.name; it.size=Desktop.sysFont.size-(Desktop.isMac ? 3 : 1) }

    versionInfo := GridPane
    {
      halignCells = Halign.center
      vgap = 0
      Label
      {
        text = "Version:  ${this.typeof.pod.version}
                Home Dir:  ${Env.cur.homeDir}
                Work Dir:  ${Env.cur.workDir}
                Env:  ${Env.cur}"
        font = small
      },
    }
    content := GridPane
    {
      halignCells = Halign.center
      Label { image = Image.makeFile(icon) },
      Label { text = "Flux"; font = big },
      versionInfo,
      Label { font = small; text =
        "   Copyright (c) 2008-2010, Brian Frank and Andy Frank
         Licensed under the Academic Free License version 3.0"
      },
    }
    d := Dialog(frame) { title="About Flux"; body=content; commands=[Dialog.ok] }
    d.open
  }
}