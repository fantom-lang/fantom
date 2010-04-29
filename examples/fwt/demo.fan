#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using gfx
using fwt

**
** FwtDemo displays the FWT sampler program.
**
class FwtDemo
{

  **
  ** Put the whole thing together in a tabbed pane
  **
  Void main()
  {
    Window
    {
      title = "FWT Demo"
      size = Size(800, 600)
      menuBar = makeMenuBar
      content = EdgePane
      {
        top = makeToolBar
        center = TabPane
        {
          Tab { text = "Buttons";        InsetPane { makeButtons, }, },
          Tab { text = "Labels";         InsetPane { makeLabels, }, },
          Tab { text = "ProgessBar";     InsetPane { makeProgressBar, }, },
          Tab { text = "WebBrowser";     InsetPane { makeWebBrowser, }, },
          Tab { text = "Text";           InsetPane { makeText, }, },
          Tab { text = "BorderPane";     InsetPane { makeBorderPane, }, },
          Tab { text = "EdgePane";       InsetPane { makeEdgePane, }, },
          Tab { text = "GridPane";       InsetPane { makeGridPane, }, },
          Tab { text = "Tree and Table"; InsetPane { makeTreeAndTable, }, },
          Tab { text = "Window";         InsetPane { makeWindow, }, },
          Tab { text = "Serialization";  InsetPane { makeSerialization, }, },
          Tab { text = "Eventing";       InsetPane { makeEventing, }, },
          Tab { text = "Graphics";       InsetPane { makeGraphics, }, },
        }
      }
    }.open
  }

  **
  ** Build the menu bar
  **
  Menu makeMenuBar()
  {
    return Menu
    {
      Menu
      {
        text = "File";
        MenuItem { text = "Back";    image = backIcon;    onAction.add {browser.back} },
        MenuItem { text = "Next";    image = nextIcon;    onAction.add {browser.forward} },
        MenuItem { text = "Refresh"; image = refreshIcon; onAction.add {browser.refresh} },
        MenuItem { text = "Stop";    image = stopIcon;    onAction.add {browser.stop} },
        MenuItem { text = "Exit"; onAction.add |->| { Env.cur.exit } },
      },

      Menu
      {
        text = "Nested";
        Menu
        {
          text = "Alpha"
          image = folderIcon
          MenuItem { text = "Alpha.1"; onAction.add(cb) },
          Menu
          {
            text = "Alpha.2"
            MenuItem { text = "Alpha.2.I"; onAction.add(cb) },
            Menu
            {
              text = "Alpha.2.II"
              MenuItem { text = "Alpha.2.II.a"; onAction.add(cb) },
              MenuItem { text = "Alpha.2.II.b"; onAction.add(cb) },
            },
            MenuItem { text = "Alpha.2.III"; onAction.add(cb) },
          },
        },
        Menu
        {
          text = "Beta"
          MenuItem { text = "Beta.1"; onAction.add(cb) },
          MenuItem { text = "Beta.2"; onAction.add(cb) },
        },
      },

      Menu
      {
        text = "Modes"
        MenuItem { text = "Check 1"; accelerator=Key.f1; mode = MenuItemMode.check; onAction.add(cb) },
        MenuItem { text = "Check 2"; accelerator=Key.f2; mode = MenuItemMode.check; onAction.add(cb) },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "Radio 1"; accelerator=Key.num1+Key.alt; mode = MenuItemMode.radio; onAction.add(cb) },
        MenuItem { text = "Radio 2"; accelerator=Key.alt+Key.num2; mode = MenuItemMode.radio; onAction.add(cb); selected = true  },
      },

      Menu
      {
        text = "Dialogs"
        MenuItem { text = "Info"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "Test information!")) } },
        MenuItem { text = "Warn"; onAction.add |Event e| { echo(Dialog.openWarn(e.window, "Test warning!")) } },
        MenuItem { text = "Err"; onAction.add |Event e| { echo(Dialog.openErr(e.window, "Test error!")) } },
        MenuItem { text = "Question"; onAction.add |Event e| { echo(Dialog.openQuestion(e.window, "Test question?")) } },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "Ok/Cancel"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "OK/Cancel", Dialog.okCancel)) } },
        MenuItem { text = "Yes/No"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "Yes/No", Dialog.yesNo)) } },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "Details Err"; onAction.add |Event e| { echo(Dialog.openErr(e.window, "Something bad", ArgErr())) } },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "Prompt Str 1"; onAction.add |Event e| { echo("--> " + Dialog.openPromptStr(e.window, "Enter a string:")) } },
        MenuItem { text = "Prompt Str 2"; onAction.add |Event e| { echo("--> " + Dialog.openPromptStr(e.window, "Enter a string:", "123", 4)) } },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "Option A"; onAction.add |Event e| { echo((Dialog(e.window) {body="Str message"; commands=[Dialog.ok]}).open) } },
        MenuItem { text = "Option B"; onAction.add |Event e| { echo((Dialog(e.window) {body=Button { text="BIG!" }; commands=Dialog.okCancel}).open) } },
        MenuItem { mode = MenuItemMode.sep },
        MenuItem { text = "File Open";  onAction.add |Event e| { echo(FileDialog {}.open(e.window)) } },
        MenuItem { text = "Files Open"; onAction.add |Event e| { echo(FileDialog { dir=Env.cur.homeDir; mode=FileDialogMode.openFiles }.open(e.window)) } },
        MenuItem { text = "File Save";  onAction.add |Event e| { echo(FileDialog { name="foo.txt";  mode=FileDialogMode.saveFile }.open(e.window)) } },
        MenuItem { text = "Dir Open";   onAction.add |Event e| { echo(FileDialog { dir=Env.cur.homeDir; mode=FileDialogMode.openDir }.open(e.window)) } },
      },

    }
  }

  **
  ** Build the toolbar
  **
  Widget makeToolBar()
  {
    return ToolBar
    {
      Button { image = backIcon;    onAction.add {browser.back} },
      Button { image = nextIcon;    onAction.add {browser.forward} },
      Button { image = refreshIcon; onAction.add {browser.refresh} },
      Button { image = stopIcon;    onAction.add {browser.stop} },
      Button { mode  = ButtonMode.sep },
      Button { image = sysIcon;   mode = ButtonMode.check; onAction.add(cb) },
      Button { image = prefsIcon; mode = ButtonMode.toggle; onAction.add(cb) },
      Button { mode  = ButtonMode.sep },
      Button { image = audioIcon; mode = ButtonMode.radio; onAction.add(cb); selected = true },
      Button { image = imageIcon; mode = ButtonMode.radio; onAction.add(cb); },
      Button { image = videoIcon; mode = ButtonMode.radio; onAction.add(cb); },
    }
  }

  **
  ** Build a simple web browser
  **
  Widget makeWebBrowser()
  {
    url := Text { text=homeUri }
    url.onAction.add |->| { browser.load(url.text.toUri) }

    return EdgePane
    {
      top = EdgePane { center=url; right=Label{text="Enter to Go!"} }
      center = browser
    }
  }

  **
  ** Build a pane of various labels
  **
  Widget makeLabels()
  {
    return GridPane
    {
      numCols = 2
      hgap = 20
      halignCells = Halign.fill
      Label { text = "Text Only" },
      Label { image = stopIcon },
      Label { text = "Both"; image = folderIcon },
      Label { text = "Monospace"; font = Desktop.sysFontMonospace },
      Label { text = "Colors"; image = folderIcon; fg = Color.red; bg = Color.yellow },
      Label { text = "Left"; halign = Halign.left },
      Label { text = "Center"; halign = Halign.center },
      Label { text = "Right"; halign = Halign.right },
    }
  }

  **
  ** Build a pane of various progress bars
  **
  Widget makeProgressBar()
  {
    return GridPane
    {
      numCols = 1
      hgap = 20
      halignCells = Halign.fill
      ProgressBar { val=25; },
      ProgressBar { min=0; max=100; val=75; },
      ProgressBar { min=-100; max=100; val=80; },
      ProgressBar { min=-100; max=100; val=25; },
      ProgressBar { indeterminate = true },
    }
  }

  **
  ** Build a pane of various buttons
  **
  Widget makeButtons()
  {
    return GridPane
    {
      numCols = 3
      hgap = 20
      Button { text = "B1"; image = stopIcon; onAction.add(cb) },
      Button { text = "Monospace"; font = Desktop.sysFontMonospace; onAction.add(cb) },
      Button { mode = ButtonMode.toggle; text = "Button 3"; onAction.add(cb) },
      Button { mode = ButtonMode.check; text = "B4"; onAction.add(cb) },
      Button { mode = ButtonMode.radio; text = "Button 5"; onAction.add(cb) },
      Button { mode = ButtonMode.radio; text = "B6"; onAction.add(cb) },
      Button { text = "Popup 1"; onAction.add {FwtDemo.popup(true, it)} },
      Button { text = "Popup 2"; onAction.add {FwtDemo.popup(false, it)} },
      Button { text = "Disabled"; enabled=false },
      Button { text = "Invisible"; visible=false },
    }
  }

  **
  ** Build a pane of various text fields
  **
  Widget makeText()
  {
    area := Text
    {
      multiLine = true
      font = Desktop.sysFontMonospace
      text ="Press button above to serialize this entire demo here"
    }

    ecb := |Event e| { echo("onAction: \"${e.widget->text}\"") }
    ccb := |Event e| { echo("onModify: \"${e.widget->text}\"") }

    nums := ["One", "Two", "Three", "Four", "Five", "Six", "Seven" ]

    return EdgePane
    {
      left = GridPane
      {
        numCols = 2

        Label { text="Single" },
        Text { onAction.add(ecb); onModify.add(ccb) },

        Label { text="Monospace";  },
        Text { font = Desktop.sysFontMonospace; onAction.add(ecb); onModify.add(ccb)  },

        Label { text="Password" },
        Text { password = true; onAction.add(ecb); onModify.add(ccb) },

        Label { text="Combo" },
        Combo { items=nums; onAction.add(ecb); onModify.add(ccb) },

        Label { text="Combo editable=true" },
        Combo { editable=true; items=nums; onAction.add(ecb); onModify.add(ccb) },

        Label { text="Combo dropDown=false" },
        Combo { dropDown=false; items=nums; onAction.add(ecb); onModify.add(ccb) },

        Label { text="MultiLine" },

        Button { text="Serialize Demo"; onAction.add {serializeTo(area)} },
      }
      center = InsetPane.make(5) { content=area }
    }
  }

  Void serializeTo(Text area)
  {
    try
    {
      opts := ["indent":2, "skipDefaults":true, "skipErrors":true]
      buf := Buf.make.writeObj(area.window, opts)
      area.text = buf.flip.readAllStr
    }
    catch (Err e)
    {
      area.text = e.traceToStr
    }
  }

  **
  ** Build a demo border pane
  **
  Widget makeBorderPane()
  {
    b := BorderPane
    {
      border = Border.defVal
      insets = Insets(10)
      content = Box { color = Color.blue }
    }

    borderText := Text { text = b.border.toStr }
    insetsText := Text { text = b.insets.toStr }
    bgText     := Text { text = "" }

    update := |->|
    {
      b.border = Border(borderText.text)
      b.insets = Insets(insetsText.text)
      b.bg     = bgText.text.isEmpty ? null : Color(bgText.text)
      b.relayout
      b.repaint
    }

    borderText.onAction.add(update)
    insetsText.onAction.add(update)
    bgText.onAction.add(update)

    controlPane := GridPane
    {
      numCols = 2
      Label { text="border" }, borderText,
      Label { text="insets" }, insetsText,
      Label { text="bg" }, bgText,
      Button { text = "Update"; onAction.add(update) }
    }

    return EdgePane
    {
      left   = controlPane
      center = BorderPane { bg = Color.white; insets = Insets(10); content = b }
    }
  }

  **
  ** Build a demo edge pane
  **
  Widget makeEdgePane()
  {
    return EdgePane
    {
      top    = Button { text = "top" }
      left   = Button { text = "left" }
      right  = Button { text = "right" }
      bottom = Button { text = "bottom" }
      center = Button { text = "center" }
    }
  }

  **
  ** Build a demo grid pane using randomly sized boxes
  **
  Widget makeGridPane()
  {
    grid := GridPane
    {
      numCols = 5
      hgap = 10
      vgap = 10
      Box { color = Color.red },
      Box { color = Color.green },
      Box { color = Color.yellow },
      Box { color = Color.blue },
      Box { color = Color.orange },
      Box { color = Color.darkGray },
      Box { color = Color.purple },
      Box { color = Color.gray },
      Box { color = Color.white },
    }
    colors := [Color.red, Color.green, Color.yellow, Color.blue, Color.orange,
               Color.darkGray, Color.purple, Color.gray, Color.white]

    15.times |Int i| { grid.add(Box { color=colors[i%colors.size] }) }

    controls := GridPane
    {
      numCols = 2
      halignCells = Halign.fill
      Label { text="numCols" },      Text { text="5"; onModify.add {setInt(grid, "numCols", it)} },
      Label { text="hgap" },         Text { text="10"; onModify.add {setInt(grid, "hgap", it)} },
      Label { text="vgap" },         Text { text="10"; onModify.add {setInt(grid, "vgap", it)} },
      Label { text="halignCells" },  Combo { items=Halign.vals; onModify.add {setEnum(grid, "halignCells", it)} },
      Label { text="valignCells" },  Combo { items=Valign.vals; onModify.add {setEnum(grid, "valignCells", it)} },
      Label { text="halignPane" },   Combo { items=Halign.vals; onModify.add {setEnum(grid, "halignPane", it)} },
      Label { text="valignPane" },   Combo { items=Valign.vals; onModify.add {setEnum(grid, "valignPane", it)} },
      Label { text="expandRow" },    Text { text="null"; onModify.add {setInt(grid, "expandRow", it)} },
      Label { text="expandCol" },    Text { text="null"; onModify.add {setInt(grid, "expandCol", it)} },
      Label { text="uniformCols" },  Combo { items=[false,true]; onModify.add {setBool(grid, "uniformCols", it)} },
      Label { text="uniformRows" },  Combo { items=[false,true]; onModify.add {setBool(grid, "uniformRows", it)} },
    }

    return EdgePane { left=controls; center=InsetPane { content=grid } }
  }

  **
  ** Build a demo tree and table for file system
  **
  Widget makeTreeAndTable()
  {
    tree := Tree
    {
      multi = true
      model = DirTreeModel { demo = this }
      onAction.add |Event e| { echo(e) }
      onSelect.add |Event e| { echo(e); echo("selected=${e->widget->selected}") }
      onPopup.add |Event e|  { echo(e); e.popup = makePopup }
      // onMouseMove.add |Event e| { echo(e.pos + ": " + e->widget->nodeAt(e.pos)) }
      // hbar.onModify.add(&onScroll("Tree.hbar"))
      // vbar.onModify.add(&onScroll("Tree.vbar"))
    }

    table := Table
    {
      multi = true
      model = DirTableModel { demo = this; dir = File.os(".").list }
      onAction.add |Event e| { echo(e) }
      onSelect.add |Event e| { echo(e); echo("selected=${e->widget->selected}") }
      onPopup.add |Event e|  { echo(e); e.popup = makePopup }
      // onMouseMove.add |Event e| { Int? row := e->widget->rowAt(e.pos); Int? col := e->widget->colAt(e.pos); echo("Row: $row Col: $col " + ((row != null && col != null) ? e->widget->model->text(col, row) : "")) }
      // hbar.onModify.add(&onScroll("Table.hbar"))
      // vbar.onModify.add(&onScroll("Table.vbar"))
    }

    updateTable := |File dir| { table.model->dir = dir.list; table.refreshAll }
    tree.onAction.add  |Event e| { updateTable(e.data) }
    table.onAction.add |Event e| { updateTable(table.model->dir->get(e.index)) }

    return SashPane
    {
      weights = [1,3]
      tree,
      table,
    }
  }

  **
  ** Build a pane showing how the various window options work
  **
  Widget makeWindow()
  {
    mode := Combo { items = WindowMode.vals; editable=false }
    alwaysOnTop := Button { it.mode = ButtonMode.check; text = "alwaysOnTop" }
    resizable := Button { it.mode = ButtonMode.check; text = "resizable" }
    showTrim := Button { it.mode = ButtonMode.check; text = "showTrim"; selected = true }

    open := |->|
    {
      close := Button { text="Close Me" }
      w := Window(mode.window)
      {
        it.mode = mode.selected
        it.alwaysOnTop = alwaysOnTop.selected
        it.resizable = resizable.selected
        it.showTrim = showTrim.selected
        it.size = Size(200,200)
        GridPane { halignPane = Halign.center; valignPane = Valign.center; add(close) },
      }
      close.onAction.add { w.close }
      w.open
    }

    return GridPane
    {
      mode,
      alwaysOnTop,
      resizable,
      showTrim,
      Button { text="Open"; onAction.add(open) },
    }
  }

  **
  ** Build a pane showing how to use serialization
  **
  Widget makeSerialization()
  {
    area := Text
    {
      multiLine = true
      font = Desktop.sysFontMonospace
      text =
        "fwt::EdgePane\n" +
        "{\n" +
        "  top = fwt::Button { text=\"Top\" }\n" +
        "  center = fwt::Button { text=\"Center\" }\n" +
        "  bottom = fwt::Button { text=\"Bottom\" }\n" +
        "}\n"
    }

    test := InsetPane
    {
      Label { text="Press button to deserialize code on the left here" },
    }

    return SashPane
    {
      EdgePane
      {
        center = area
        right = InsetPane
        {
          Button { text="=>"; onAction.add |->| { deserializeTo(area.text, test) } },
        }
      },
      test,
    }
  }

  Void deserializeTo(Str text, InsetPane test)
  {
    try
    {
      test.content = text.in.readObj
    }
    catch (Err e)
    {
      test.content = Text { it.multiLine = true; it.text = e.traceToStr }
    }
    test.relayout
  }

  **
  ** Build a pane to trace events
  **
  Widget makeEventing()
  {
    return GridPane
    {
      EventDemo { name = "A"; demo = this },
      EventDemo { name = "B"; demo = this },
      EventDemo { name = "C"; demo = this },
    }
  }

  **
  ** Build a pane showing how to use Graphics
  **
  Widget makeGraphics()
  {
    return ScrollPane { content=GraphicsDemo { demo = this } }
  }

  static Void setInt(Widget obj, Str field, Event e)
  {
    f := obj.typeof.field(field)
    Str text := e.widget->text
    int := text.toInt(10, false)
    if (int != null || text=="null") f.set(obj, int)
    obj.relayout
  }

  static Void setBool(Widget obj, Str field, Event e)
  {
    f := obj.typeof.field(field)
    Str text := e.widget->text
    b := text.toBool(false)
    if (b != null) f.set(obj, b)
    obj.relayout
  }

  static Void setEnum(Widget obj, Str field, Event e)
  {
    f := obj.typeof.field(field)
    en := f.get(obj)->fromStr(e.widget->text, false)
    if (en != null) f.set(obj, en)
    obj.relayout
  }

  static |Event e| cb()
  {
    return |Event e|
    {
      w := e.widget
      echo("${w->text} selected=${w->selected}")
    }
  }

  static Void popup(Bool withPos, Event event)
  {
    makePopup.open(event.widget, withPos ? Point.make(0, event.widget.size.h) : event.pos)
  }

  static Menu makePopup()
  {
    return Menu
    {
      MenuItem { text = "Popup 1"; onAction.add(cb) },
      MenuItem { text = "Popup 2"; onAction.add(cb) },
      MenuItem { text = "Popup 3"; onAction.add(cb) },
    }
  }

  static Void onScroll(Str name, Event e)
  {
    ScrollBar sb := e.widget
    echo("-- onScroll $name $e  [val=$sb.val min=$sb.min max=$sb.max thumb=$sb.thumb page=$sb.page orient=$sb.orientation")
  }

  WebBrowser browser := WebBrowser {}
  Str homeUri := "http://fantom.org/"

  File scriptDir  := File.make(this.typeof->sourceFile.toStr.toUri).parent

  Image backIcon    := Image(`fan://icons/x16/arrowLeft.png`)
  Image nextIcon    := Image(`fan://icons/x16/arrowRight.png`)
  Image cutIcon     := Image(`fan://icons/x16/cut.png`)
  Image copyIcon    := Image(`fan://icons/x16/copy.png`)
  Image pasteIcon   := Image(`fan://icons/x16/paste.png`)
  Image folderIcon  := Image(`fan://icons/x16/folder.png`)
  Image fileIcon    := Image(`fan://icons/x16/file.png`)
  Image audioIcon   := Image(`fan://icons/x16/file.png`)
  Image imageIcon   := Image(`fan://icons/x16/file.png`)
  Image videoIcon   := Image(`fan://icons/x16/file.png`)
  Image sysIcon     := Image(`fan://icons/x16/file.png`)
  Image prefsIcon   := Image(`fan://icons/x16/file.png`)
  Image refreshIcon := Image(`fan://icons/x16/refresh.png`)
  Image stopIcon    := Image(`fan://icons/x16/err.png`)
  Image cloudIcon   := Image(`fan://icons/x16/cloud.png`)
}

**************************************************************************
** DirTreeModel
**************************************************************************

class DirTreeModel : TreeModel
{
  FwtDemo? demo

  override Obj[] roots() { return Env.cur.homeDir.listDirs }

  override Str text(Obj node) { return node->name }

  override Image? image(Obj node) { return demo.folderIcon }

  override Obj[] children(Obj obj) { return obj->listDirs }
}

**************************************************************************
** DirTableModel
**************************************************************************

class DirTableModel : TableModel
{
  FwtDemo? demo
  File[]? dir
  Str[] headers := ["Name", "Size", "Modified"]
  override Int numCols() { return 3 }
  override Int numRows() { return dir.size }
  override Str header(Int col) { return headers[col] }
  override Halign halign(Int col) { return col == 1 ? Halign.right : Halign.left }
  override Font? font(Int col, Int row) { return col == 2 ? Font {name=Desktop.sysFont.name; size=Desktop.sysFont.size-1} : null }
  override Color? fg(Int col, Int row)  { return col == 2 ? Color("#666") : null }
  override Color? bg(Int col, Int row)  { return col == 2 ? Color("#eee") : null }
  override Str text(Int col, Int row)
  {
    f := dir[row]
    switch (col)
    {
      case 0:  return f.name
      case 1:  return f.size?.toLocale("B") ?: ""
      case 2:  return f.modified.toLocale
      default: return "?"
    }
  }
  override Int sortCompare(Int col, Int row1, Int row2)
  {
    a := dir[row1]
    b := dir[row2]
    switch (col)
    {
      case 1:  return a.size <=> b.size
      case 2:  return a.modified <=> b.modified
      default: return super.sortCompare(col, row1, row2)
    }
  }
  override Image? image(Int col, Int row)
  {
    if (col != 0) return null
    return dir[row].isDir ? demo.folderIcon : demo.fileIcon
  }
}

**************************************************************************
** Box
**************************************************************************

class Box : Canvas
{
  Color color := Color.green

  override Size prefSize(Hints hints := Hints.defVal)
  {
    Size(Int.random(20..100), Int.random(20..80))
  }

  override Void onPaint(Graphics g)
  {
    size := this.size
    g.brush = color
    g.fillRect(0, 0, size.w, size.h)
    g.brush = Color.black
    g.drawRect(0, 0, size.w-1, size.h-1)
  }
}

**************************************************************************
** EventDemo
**************************************************************************

class EventDemo : Canvas
{
  new make()
  {
    d := |e| { dump(e) }
    onFocus.add(d)
    onBlur.add(d)
    onKeyUp.add(d)
    onKeyDown.add(d)
    onMouseUp.add(d)
    onMouseDown.add(d)
    onMouseEnter.add(d)
    onMouseExit.add(d)
    onMouseMove.add(d)
    onMouseHover.add(d)
    onMouseWheel.add(d)
  }

  override Size prefSize(Hints hints := Hints.defVal) { return Size.make(100, 100) }

  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h

    g.brush = Color.black
    g.drawRect(0, 0, w-1, h-1)
    g.drawText(name, 45, 40)

    if (hasFocus)
    {
      g.brush = Color.red
      g.drawRect(1, 1, w-3, h-3)
      g.drawRect(2, 2, w-5, h-5)
    }
  }

  Void dump(Event event)
  {
    if (event.id == EventId.focus || event.id == EventId.blur)
      repaint

    echo("$name> $event")
  }

  Str? name
  FwtDemo? demo
}

**************************************************************************
** GraphicsDemo
**************************************************************************

class GraphicsDemo : Canvas
{
  FwtDemo? demo

  override Size prefSize(Hints hints := Hints.defVal) { return Size.make(750, 450) }

  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h

    g.antialias = true

    g.brush = Gradient("0% 0%, 100% 100%, #fff, #666")
    g.fillRect(0, 0, w, h)

    g.brush = Color.black; g.drawRect(0, 0, w-1, h-1)

    g.brush = Color.orange; g.fillRect(10, 10, 50, 60)
    g.brush = Color.blue; g.drawRect(10, 10, 50, 60)

    g.brush = Color("#80ffff00"); g.fillOval(40, 40, 120, 100)
    g.pen = Pen { width = 2; dash=[8,4].toImmutable }
    g.brush = Color.green; g.drawOval(40, 40, 120, 100)

    g.pen = Pen { width = 8; join = Pen.joinBevel }
    g.brush = Color.gray; g.drawRect(120, 120, 120, 90)
    g.brush = Color.orange; g.fillArc(120, 120, 120, 90, 45, 90)
    g.pen = Pen { width = 8; cap = Pen.capRound }
    g.brush = Color.blue; g.drawArc(120, 120, 120, 90, 45, 90)

    g.brush = Color.purple; g.drawText("Hello World!", 70, 50)
    g.font = Desktop.sysFontMonospace.toSize(16).toBold; g.drawText("Hello World!", 70, 70)

    g.pen = Pen { width = 2; join = Pen.joinBevel }
    g.brush = Color("#a00")
    g.drawPolyline([
      Point(10, 380),
      Point(30, 420),
      Point(50, 380),
      Point(70, 420),
      Point(90, 380)])

    polygon := [Point(180, 380), Point(140, 440), Point(220, 440)]
    g.pen = Pen("1")
    g.brush = Color("#f88"); g.fillPolygon(polygon)
    g.brush = Color("#800"); g.drawPolygon(polygon)

    img := demo.folderIcon
    g.drawImage(img, 220, 20)
    g.copyImage(img, Rect(0, 0, img.size.w, img.size.h), Rect(250, 30, 64, 64))
    g.drawImage(img.resize(Size(64, 64)), 320, 30)
    g.push
    try
    {
      g.alpha=128; g.drawImage(img, 220, 40)
      g.alpha=64;  g.drawImage(img, 220, 60)
    }
    finally g.pop

    // image brush
    g.brush = Pattern(demo.cloudIcon)
    g.fillOval(390, 20, 80, 80)
    g.brush = Color.black
    g.pen = Pen { width = 1 }
    g.drawOval(390, 20, 80, 80)

    // system font/colors
    y := 20
    g.brush = Color.black
    g.font = Desktop.sysFont
    g.drawText("sysFont: $Desktop.sysFont.toStr", 480, y)
    g.font = Desktop.sysFontSmall
    g.drawText("sysFontSmall: $Desktop.sysFontSmall.toStr", 480, y+18)
    g.font = Desktop.sysFontView
    g.drawText("sysFontView: $Desktop.sysFontView.toStr", 480, y+30)
    y += 60
    g.font = Font("9pt Arial")
    y = sysColor(g, y, Desktop.sysDarkShadow, "sysDarkShadow")
    y = sysColor(g, y, Desktop.sysNormShadow, "sysNormShadow")
    y = sysColor(g, y, Desktop.sysLightShadow, "sysLightShadow")
    y = sysColor(g, y, Desktop.sysHighlightShadow, "sysHighlightShadow")
    y = sysColor(g, y, Desktop.sysFg, "sysFg")
    y = sysColor(g, y, Desktop.sysBg, "sysBg")
    y = sysColor(g, y, Desktop.sysBorder, "sysBorder")
    y = sysColor(g, y, Desktop.sysListBg, "sysListBg")
    y = sysColor(g, y, Desktop.sysListFg, "sysListFg")
    y = sysColor(g, y, Desktop.sysListSelBg, "sysListSelBg")
    y = sysColor(g, y, Desktop.sysListSelFg, "sysListSelFg")

    // rect/text with gradients
    g.brush = Gradient("260px 120px, 460px 320px, #00f, #f00")
    g.pen = Pen { width=20; join = Pen.joinRound }
    g.drawRect(270, 130, 180, 180)
    6.times |Int i| { g.drawText("Gradients!", 300, 150+i*20) }

    // translate for font metric box
    g.translate(50, 250)
    g.pen = Pen.defVal
    g.brush = Color.yellow
    g.fillRect(0, 0, 200, 100)

    // font metric box with ascent, descent, baseline
    g.font = Desktop.sysFont.toSize(20)
    tw := g.font.width("Font Metrics")
    tx := (200-tw)/2
    ty := 30
    g.brush = Color.gray
    g.drawLine(tx-10, ty, tx+10, ty)
    g.drawLine(tx, ty-10, tx, ty+10)
    g.brush = Color.orange
    my := ty+g.font.leading; g.drawLine(tx, my, tx+tw, my)
    g.brush = Color.green
    my += g.font.ascent; g.drawLine(tx, my, tx+tw, my)
    g.brush = Color.blue
    my += g.font.descent; g.drawLine(tx, my, tx+tw, my)
    g.brush = Color.black
    g.drawText("Font Metrics", tx, ty)

    // alpha
    g.translate(430, 80)
    // checkerboard bg
    g.brush = Color.white
    g.fillRect(0, 0, 240, 120)
    g.brush = Color("#ccc")
    12.times |Int by| {
      24.times |Int bx| {
        if (bx.isEven.xor(by.isEven))
          g.fillRect(bx*10, by*10, 10, 10)
      }
    }
    // change both alpha and color
    a := Color("#ffff0000")
    b := Color("#80ff0000")
    g.alpha=255; g.brush=a; g.fillRect(0, 0,  30, 30); g.brush=b; g.fillRect(30, 0,  30, 30)
    g.alpha=192; g.brush=a; g.fillRect(0, 30, 30, 30); g.brush=b; g.fillRect(30, 30, 30, 30)
    g.alpha=128; g.brush=a; g.fillRect(0, 60, 30, 30); g.brush=b; g.fillRect(30, 60, 30, 30)
    g.alpha=64;  g.brush=a; g.fillRect(0, 90, 30, 30); g.brush=b; g.fillRect(30, 90, 30, 30)
    // change only alpha
    g.brush = a
    g.alpha=255; g.fillRect(60, 0,  30, 30);
    g.alpha=192; g.fillRect(60, 30, 30, 30);
    g.alpha=128; g.fillRect(60, 60, 30, 30);
    g.alpha=64;  g.fillRect(60, 90, 30, 30);
    // change only color
    g.alpha = 128
    g.brush = Color("#f00"); g.fillRect(90, 0,  30, 30);
    g.brush = Color("#ff0"); g.fillRect(90, 30, 30, 30);
    g.brush = Color("#0f0"); g.fillRect(90, 60, 30, 30);
    g.brush = Color("#00f"); g.fillRect(90, 90, 30, 30);
    // gradients
    g.alpha = 255
    g.brush = Gradient("0px 0px, 0px 120px, #f00, #fff");           g.fillRect(120, 0, 20, 120)
    g.brush = Gradient("0px 0px, 0px 120px, #f00, #80ffffff");      g.fillRect(140, 0, 20, 120)
    g.brush = Gradient("0px 0px, 0px 120px, #80ff0000, #80ffffff"); g.fillRect(160, 0, 20, 120)
    g.brush = Gradient("0px 0px, 0px 120px, #f00, #fff");
      g.alpha = 128; /* set alpha after gradient */  g.fillRect(180, 0, 20, 120)
    g.brush = Gradient("0px 0px, 0px 120px, #f00, #80ffffff");      g.fillRect(200, 0, 20, 120)
    g.brush = Gradient("0px 0px, 0px 120px, #80ff0000, #80ffffff"); g.fillRect(220, 0, 20, 120)
  }

  Int sysColor(Graphics g, Int y, Color c, Str name)
  {
    g.brush = c
    g.fillRect(480, y, 140, 20)
    g.brush = Color.green
    g.drawText(name, 490, y+3)
    return y + 20
  }
}