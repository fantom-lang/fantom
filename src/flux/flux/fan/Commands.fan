//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Br ian Frank  Creation
//

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
      text = type.loc("edit.name")
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
      text = type.loc("view.name")
      onOpen.add(&onViewMenuOpen)
      addCommand(reload)
      addSep
    }

    types := Type.findByFacet("fluxSideBar", true)
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
      text = type.loc("history.name")
      onOpen.add(&onHistoryMenuOpen)
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
      text = type.loc("tools.name")
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
      onAction.add |,| { frame.load(item.uri) }
    }
  }

  Void refreshToolsMenu()
  {
    // remove any old items on the tools menu
    children := toolsMenu.children
    (toolsMenuSize...children.size).each |Int i|
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
  readonly Menu toolsMenu
  readonly Int toolsMenuSize
  readonly File toolsDir := Flux.homeDir+`tools/`
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
    frame.load(`flux:start`, LoadMode { newTab=true })
  }
}

** Focus the uri location field
internal class OpenLocationCommand : FluxCommand
{
  new make() : super(CommandId.openLocation) {}
  override Void invoke(Event event) { frame.locator.onLocation(event) }
}

** Close current view tab.
internal class CloseTabCommand : FluxCommand
{
  new make() : super(CommandId.closeTab) {}
  override Void invoke(Event event)
  {
    if (frame.views.size > 1)
      frame.tabPane.close(frame.view.tab)
  }
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
      grid := GridPane { Label { text=type.pod.loc("saveChanges"); font=Font.sys.toBold }}
      dirty.each |View v|
      {
        grid.add(InsetPane(0,0,0,8) {
         Button { mode=ButtonMode.check; text=v.resource.uri.toStr; selected=true }
        })
      }
      saveSel  := ExitSaveCommand(type.pod, "saveSelected")
      saveNone := ExitSaveCommand(type.pod, "saveNone")
      cancel   := ExitSaveCommand(Command#.pod, "cancel")
      pane := ConstraintPane
      {
        minw = 400
        add(InsetPane(0,0,12,0).add(grid))
      }
      d := Dialog(frame, pane, [saveSel,saveNone,cancel]) { title="Save" }
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
  override Void invoke(Event e) { window?.close(this) }
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

** Copy command routes to 'focus?.selectAll'
internal class SelectAllCommand : FluxCommand
{
  new make() : super(CommandId.selectAll) {}
  override Void invoke(Event event)
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
  override Void invoke(Event event)
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
  override Void invoke(Event event)
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
  override Void invoke(Event event) { frame.view.tab.reload }
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

  override Void invoke(Event event)
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

** Hyperlink to the home page
internal class HomeCommand : FluxCommand
{
  new make() : super(CommandId.home) {}
  override Void invoke(Event event) { frame.load(GeneralOptions.load.homePage) }
}

** Open recent history dialog
internal class RecentCommand : FluxCommand
{
  new make() : super(CommandId.recent) {}
  override Void invoke(Event event)
  {
    Dialog dlg
    model := RecentTableModel()
    table := Table
    {
      headerVisible = false
      model = model
      onAction.add |Event e|
      {
        frame.load(model.items[e.index].uri, LoadMode(e))
        dlg.close
      }
      onKeyDown.add |Event e|
      {
        code := e.keyChar
        if (code >= 97 && code <= 122) code -= 32
        code -= 65
        if (code >= 0 && code < 26 && code < model.numRows)
        {
          frame.load(model.items[code].uri, LoadMode(e))
          dlg.close
        }
      }
    }
    pane := ConstraintPane
    {
      minw = 300
      maxh = 300
      add(table)
    }
    dlg = Dialog(frame, pane, [Dialog.ok, Dialog.cancel]) { title = "Recent" }
    dlg.open
  }
}

internal class RecentTableModel : TableModel
{
  new make()
  {
    items = History.load.items
    icons = Image[,]
    items.map(icons) |HistoryItem item->Obj|
    {
      return Image(item.iconUri, false) ?: def
    }
  }

  override Int numCols() { return 2 }
  override Int numRows() { return items.size }
  override Image image(Int col, Int row) { return col==0 ? icons[row] : null }
  override Font font(Int col, Int row) { return col==1 ? accFont : null }
  override Color fg(Int col, Int row)  { return col==1 ? accColor : null }
  override Str text(Int col, Int row)
  {
    switch (col)
    {
      case 0:  return items[row].uri.name
      case 1:  return (row < 26) ? (row+65).toChar : ""
      default: return ""
    }
  }
  HistoryItem[] items
  Image[] icons
  Image def := Flux.icon(`/x16/text-x-generic.png`)
  Font accFont := Font.sys.toSize(Font.sys.size-1)
  Color accColor := Color("#666")
}

//////////////////////////////////////////////////////////////////////////
// Tools
//////////////////////////////////////////////////////////////////////////

** Hyperlink to the options directory
internal class OptionsCommand : FluxCommand
{
  new make() : super(CommandId.options) {}
  override Void invoke(Event event) { frame.load(Flux.homeDir.uri) }
}

** Refresh the tools menu
internal class RefreshToolsCommand : FluxCommand
{
  new make() : super("refreshTools") {}
  override Void invoke(Event event) { frame.commands.refreshToolsMenu }
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

  override Void invoke(Event event)
  {
    try
    {
      FluxCommand cmd := Sys.compile(file).make([id])
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
  override Void invoke(Event event)
  {
    icon  := Pod.find("icons").files[`/x48/flux.png`]
    big   := Font(Font.sys.name, Font.sys.size+(Desktop.isMac ? 2 : 3), true)
    small := Font(Font.sys.name, Font.sys.size-(Desktop.isMac ? 3 : 1), false)
    content := GridPane
    {
      halignCells = Halign.center
      Label { image = Image.makeFile(icon) }
      Label { text = "Flux"; font = big }
      GridPane
      {
        halignCells = Halign.center
        vgap = 0
        Label { text = "Version $type.pod.version"; font = small }
        Label { text = "Fan Home ${Sys.homeDir}"; font = small }
      }
      Label { font = small; text =
        "   Copyright (c) 2008, Brian Frank and Andy Frank
         Licensed under the Academic Free License version 3.0"
      }
    }
    d := Dialog(frame, content, [Dialog.ok]) { title="About Flux" }
    d.open
  }
}