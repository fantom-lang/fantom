#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

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
          Tab { text = "Buttons";        InsetPane { makeButtons } }
          Tab { text = "Labels";         InsetPane { makeLabels } }
          Tab { text = "WebBrowser";     InsetPane { makeWebBrowser } }
          Tab { text = "Text";           InsetPane { makeText} }
          Tab { text = "EdgePane";       InsetPane { makeEdgePane } }
          Tab { text = "GridPane";       InsetPane { makeGridPane } }
          Tab { text = "Tree and Table"; InsetPane { makeTreeAndTable } }
          Tab { text = "Window";         InsetPane { makeWindow } }
          Tab { text = "Serialization";  InsetPane { makeSerialization } }
          Tab { text = "Eventing";       InsetPane { makeEventing } }
          Tab { text = "Graphics";       InsetPane { makeGraphics } }
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
        MenuItem { text = "Back";    image = backIcon;    onAction.add(&browser.back) }
        MenuItem { text = "Next";    image = nextIcon;    onAction.add(&browser.forward) }
        MenuItem { text = "Refresh"; image = refreshIcon; onAction.add(&browser.refresh) }
        MenuItem { text = "Stop";    image = stopIcon;    onAction.add(&browser.stop) }
        MenuItem { text = "Exit"; onAction.add |,| { Sys.exit } }
      }

      Menu
      {
        text = "Nested";
        Menu
        {
          text = "Alpha"
          image = folderIcon
          MenuItem { text = "Alpha.1"; onAction.add(&cb) }
          Menu
          {
            text = "Alpha.2"
            MenuItem { text = "Alpha.2.I"; onAction.add(&cb) }
            Menu
            {
              text = "Alpha.2.II"
              MenuItem { text = "Alpha.2.II.a"; onAction.add(&cb) }
              MenuItem { text = "Alpha.2.II.b"; onAction.add(&cb) }
            }
            MenuItem { text = "Alpha.2.III"; onAction.add(&cb) }
          }
        }
        Menu
        {
          text = "Beta"
          MenuItem { text = "Beta.1"; onAction.add(&cb) }
          MenuItem { text = "Beta.2"; onAction.add(&cb) }
        }
      }

      Menu
      {
        text = "Modes"
        MenuItem { text = "Check 1"; accelerator=Key.f1; mode = MenuItemMode.check; onAction.add(&cb) }
        MenuItem { text = "Check 2"; accelerator=Key.f2; mode = MenuItemMode.check; onAction.add(&cb) }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { text = "Radio 1"; accelerator=Key.num1+Key.alt; mode = MenuItemMode.radio; onAction.add(&cb) }
        MenuItem { text = "Radio 2"; accelerator=Key.alt+Key.num2; mode = MenuItemMode.radio; onAction.add(&cb); selected = true  }
      }

      Menu
      {
        text = "Dialogs"
        MenuItem { text = "Info"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "Test information!")) } }
        MenuItem { text = "Warn"; onAction.add |Event e| { echo(Dialog.openWarn(e.window, "Test warning!")) } }
        MenuItem { text = "Err"; onAction.add |Event e| { echo(Dialog.openErr(e.window, "Test error!")) } }
        MenuItem { text = "Question"; onAction.add |Event e| { echo(Dialog.openQuestion(e.window, "Test question?")) } }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { text = "Ok/Cancel"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "OK/Cancel", Dialog.okCancel)) } }
        MenuItem { text = "Yes/No"; onAction.add |Event e| { echo(Dialog.openInfo(e.window, "Yes/No", Dialog.yesNo)) } }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { text = "Prompt Str"; onAction.add |Event e| { echo("--> " + Dialog.openPromptStr(e.window, "Enter a string:")) } }
        MenuItem { mode = MenuItemMode.sep }
        MenuItem { text = "Option A"; onAction.add |Event e| { echo(Dialog(e.window, "Str message", [Dialog.ok]).open) } }
        MenuItem { text = "Option B"; onAction.add |Event e| { echo(Dialog(e.window, Button { text="BIG!" }, Dialog.okCancel).open) } }
      }

    }
  }

  **
  ** Build the toolbar
  **
  Widget makeToolBar()
  {
    return ToolBar
    {
      Button { image = backIcon;    onAction.add(&browser.back) }
      Button { image = nextIcon;    onAction.add(&browser.forward) }
      Button { image = refreshIcon; onAction.add(&browser.refresh) }
      Button { image = stopIcon;    onAction.add(&browser.stop) }
      Button { mode  = ButtonMode.sep }
      Button { image = sysIcon;   mode = ButtonMode.check; onAction.add(&cb) }
      Button { image = prefsIcon; mode = ButtonMode.toggle; onAction.add(&cb) }
      Button { mode  = ButtonMode.sep }
      Button { image = audioIcon; mode = ButtonMode.radio; onAction.add(&cb); selected = true }
      Button { image = imageIcon; mode = ButtonMode.radio; onAction.add(&cb); }
      Button { image = videoIcon; mode = ButtonMode.radio; onAction.add(&cb); }
    }
  }

  **
  ** Build a simple web browser
  **
  Widget makeWebBrowser()
  {
    url := Text { text=homeUri }
    url.onAction.add |,| { browser.load(url.text.toUri) }

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
      Label { text = "Text Only" }
      Label { image = stopIcon }
      Label { text = "Both"; image = folderIcon }
      Label { text = "Courier"; font = Font { name = "Courier"; size=10 } }
      Label { text = "Colors"; image = folderIcon; fg = Color.red; bg = Color.yellow }
      Label { text = "Left"; halign = Halign.left }
      Label { text = "Center"; halign = Halign.center }
      Label { text = "Right"; halign = Halign.right }
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
      Button { text = "B1"; image = stopIcon; onAction.add(&cb) }
      Button { text = "Button 2"; font = Font { name = "Courier"; size=10 }; onAction.add(&cb) }
      Button { mode = ButtonMode.toggle; text = "Button 3"; onAction.add(&cb) }
      Button { mode = ButtonMode.check; text = "B4"; onAction.add(&cb) }
      Button { mode = ButtonMode.radio; text = "Button 5"; onAction.add(&cb) }
      Button { mode = ButtonMode.radio; text = "B6"; onAction.add(&cb) }
      Button { text = "Popup 1"; onAction.add(&popup(true)) }
      Button { text = "Popup 2"; onAction.add(&popup(false)) }
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
      font = Font { name = "Courier"; size=10 }
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

        Label { text="Single" }
        Text { onAction.add(ecb); onModify.add(ccb) }

        Label { text="Courier";  }
        Text { font = Font { name ="Courier" }; onAction.add(ecb); onModify.add(ccb)  }

        Label { text="Password" }
        Text { password = true; onAction.add(ecb); onModify.add(ccb) }

        Label { text="Combo" }
        Combo { items=nums; onAction.add(ecb); onModify.add(ccb) }

        Label { text="Combo editable=true" }
        Combo { editable=true; items=nums; onAction.add(ecb); onModify.add(ccb) }

        Label { text="Combo dropDown=false" }
        Combo { dropDown=false; items=nums; onAction.add(ecb); onModify.add(ccb) }

        Label { text="MultiLine" }

        Button { text="Serialize Demo"; onAction.add(&serializeTo(area)) }
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
      Box { color = Color.red }
      Box { color = Color.green }
      Box { color = Color.yellow }
      Box { color = Color.blue }
      Box { color = Color.orange }
      Box { color = Color.darkGray }
      Box { color = Color.purple }
      Box { color = Color.gray }
      Box { color = Color.white }
    }
    colors := [Color.red, Color.green, Color.yellow, Color.blue, Color.orange,
               Color.darkGray, Color.purple, Color.gray, Color.white]

    15.times |Int i| { grid.add(Box { color=colors[i%colors.size] }) }

    controls := GridPane
    {
      numCols = 2
      halignCells = Halign.fill
      Label { text="numCols" };      Text { text="5"; onModify.add(&setInt(grid, "numCols")) }
      Label { text="hgap" };         Text { text="10"; onModify.add(&setInt(grid, "hgap")) }
      Label { text="vgap" };         Text { text="10"; onModify.add(&setInt(grid, "vgap")) }
      Label { text="halignCells" };  Combo { items=Halign.values; onModify.add(&setEnum(grid, "halignCells")) }
      Label { text="valignCells" };  Combo { items=Valign.values; onModify.add(&setEnum(grid, "valignCells")) }
      Label { text="halignPane" };   Combo { items=Halign.values; onModify.add(&setEnum(grid, "halignPane")) }
      Label { text="valignPane" };   Combo { items=Valign.values; onModify.add(&setEnum(grid, "valignPane")) }
      Label { text="expandRow" };    Text { text="null"; onModify.add(&setInt(grid, "expandRow")) }
      Label { text="expandCol" };    Text { text="null"; onModify.add(&setInt(grid, "expandCol")) }
      Label { text="uniformCols" };  Combo { items=[false,true]; onModify.add(&setBool(grid, "uniformCols")) }
      Label { text="uniformRows" };  Combo { items=[false,true]; onModify.add(&setBool(grid, "uniformRows")) }
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
      model = DirTreeModel { demo = this }
    }

    table := Table
    {
      model = DirTableModel { demo = this; dir = File.os(".").list }
    }

    updateTable := |File dir| { table.model->dir = dir.list; table.updateAll }
    tree.onAction.add  |Event e| { updateTable(e.data) }
    table.onAction.add |Event e| { updateTable(table.model->dir->get(e.index)) }

    return SashPane
    {
      weights = [1,3]
      add(tree)
      add(table)
    }
  }

  **
  ** Build a pane showing how the various window options work
  **
  Widget makeWindow()
  {
    mode := Combo  { items = WindowMode.values; editable=false }
    alwaysOnTop := Button { mode = ButtonMode.check; text = "alwaysOnTop" }
    resizable := Button { mode = ButtonMode.check; text = "resizable" }

    open := |,|
    {
      close := Button { text="Close Me" }
      w := Window(mode.window)
      {
        mode = mode.selected
        alwaysOnTop = alwaysOnTop.selected
        resizable = resizable.selected
        GridPane { halignPane = Halign.center; valignPane = Valign.center; add(close) }
        size = Size(200,200)
      }
      close.onAction.add(&w.close)
      w.open
    }

    return GridPane
    {
      add(mode)
      add(alwaysOnTop)
      add(resizable)
      Button { text="Open"; onAction.add(open) }
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
      font = Font { name = "Courier"; size=10 }
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
      Label { text="Press button to deserialize code on the left here" }
    }

    return SashPane
    {
      EdgePane
      {
        center = area
        right = InsetPane
        {
          Button { text="=>"; onAction.add |,| { deserializeTo(area.text, test) } }
        }
      }
      add(test)
    }
  }

  Void deserializeTo(Str text, InsetPane test)
  {
    try
    {
      test.content = InStream.makeForStr(text).readObj
    }
    catch (Err e)
    {
      test.content = Text { multiLine = true; text = e.traceToStr }
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
      EventDemo { name = "A"; demo = this }
      EventDemo { name = "B"; demo = this }
      EventDemo { name = "C"; demo = this }
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
    f := obj.type.field(field)
    Str text := e.widget->text
    int := text.toInt(10, false)
    if (int != null || text=="null") f.set(obj, int)
    obj.relayout
  }

  static Void setBool(Widget obj, Str field, Event e)
  {
    f := obj.type.field(field)
    Str text := e.widget->text
    b := text.toBool(false)
    if (b != null) f.set(obj, b)
    obj.relayout
  }

  static Void setEnum(Widget obj, Str field, Event e)
  {
    f := obj.type.field(field)
    en := f.get(obj)->fromStr(e.widget->text, false)
    if (en != null) f.set(obj, en)
    obj.relayout
  }

  static Void cb(Event event)
  {
    w := event.widget
    echo("${w->text} selected=${w->selected}")
  }

  static Void popup(Bool withPos, Event event)
  {
    Menu
    {
      MenuItem { text = "Popup 1"; onAction.add(&cb) }
      MenuItem { text = "Popup 2"; onAction.add(&cb) }
      MenuItem { text = "Popup 3"; onAction.add(&cb) }
    }.open(event.widget, withPos ? Point.make(0, event.widget.size.h) : null)
  }

  WebBrowser browser := WebBrowser {}
  Str homeUri := "http://fandev.org/"

  File scriptDir  := File.make(type->sourceFile.toStr.toUri).parent

  Uri:File icons    := Pod.find("icons").files
  Image backIcon    := Image.make(icons[`/x16/go-previous.png`])
  Image nextIcon    := Image.make(icons[`/x16/go-next.png`])
  Image cutIcon     := Image.make(icons[`/x16/edit-cut.png`])
  Image copyIcon    := Image.make(icons[`/x16/edit-copy.png`])
  Image pasteIcon   := Image.make(icons[`/x16/edit-paste.png`])
  Image folderIcon  := Image.make(icons[`/x16/folder.png`])
  Image fileIcon    := Image.make(icons[`/x16/text-x-generic.png`])
  Image audioIcon   := Image.make(icons[`/x16/audio-x-generic.png`])
  Image imageIcon   := Image.make(icons[`/x16/image-x-generic.png`])
  Image videoIcon   := Image.make(icons[`/x16/video-x-generic.png`])
  Image sysIcon     := Image.make(icons[`/x16/applications-system.png`])
  Image prefsIcon   := Image.make(icons[`/x16/preferences-system.png`])
  Image refreshIcon := Image.make(icons[`/x16/view-refresh.png`])
  Image stopIcon    := Image.make(icons[`/x16/process-stop.png`])
}

**************************************************************************
** DirTreeModel
**************************************************************************

class DirTreeModel : TreeModel
{
  FwtDemo demo

  override Obj[] roots() { return Sys.homeDir.listDirs }

  override Str text(Obj node) { return node->name }

  override Image image(Obj node) { return demo.folderIcon }

  override Obj[] children(Obj obj) { return obj->listDirs }
}

**************************************************************************
** DirTableModel
**************************************************************************

class DirTableModel : TableModel
{
  FwtDemo demo
  File[] dir
  Str[] headers := ["Name", "Size", "Modified"]
  override Int numCols() { return 3 }
  override Int numRows() { return dir.size }
  override Str header(Int col) { return headers[col] }
  override Halign halign(Int col) { return col == 1 ? Halign.right : Halign.left }
  override Str text(Int col, Int row)
  {
    f := dir[row]
    switch (col)
    {
      case 0:  return f.name
      case 1:  s := f.size; return s == null ? "" : s/1024 +"KB"
      case 2:  return f.modified.toLocale
      default: return "?"
    }
  }
  override Image image(Int col, Int row)
  {
    if (col != 0) return null
    return dir[row].isDir ? demo.folderIcon : demo.fileIcon
  }
}

**************************************************************************
** Box
**************************************************************************

class Box : Widget
{
  Color color := Color.green

  override Size prefSize := Size.make(Int.random(20..100), Int.random(20..80))

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

class EventDemo : Widget
{
  new make()
  {
    onKey.add(&dump)
    onFocus.add(&dump)
    onMouse.add(&dump)
  }

  override Size prefSize(Hints hints := null) { return Size.make(100, 100) }

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
    if (event.id == EventId.focusLost || event.id == EventId.focusGained)
      repaint

    echo("$name> $event")
  }

  Str name
  FwtDemo demo
}

**************************************************************************
** GraphicsDemo
**************************************************************************

class GraphicsDemo : Widget
{
  FwtDemo demo

  override Size prefSize(Hints hints := null) { return Size.make(600,500) }

  override Void onPaint(Graphics g)
  {
    w := size.w
    h := size.h

    g.antialias = true

    g.brush = Gradient.makeLinear(
      Point.make(0,0), Color.white,
      Point.make(w,h), Color.make(0x66_66_66))
    g.fillRect(0, 0, w, h)

    g.brush = Color.black; g.drawRect(0, 0, w-1, h-1)

    g.brush = Color.black
    w.times |Int i| { if (i.isOdd) g.drawPoint(i, 2) }
    w.times |Int i| { if (i.isEven) g.drawPoint(i, 3) }

    g.brush = Color.orange; g.fillRect(10, 10, 50, 60)
    g.brush = Color.blue; g.drawRect(10, 10, 50, 60)

    g.brush = Color.yellow; g.fillOval(40, 40, 120, 100)
    g.pen = Pen { width = 2; dash=[8,4].toImmutable }
    g.brush = Color.green; g.drawOval(40, 40, 120, 100)

    g.pen = Pen { width = 8; join = Pen.joinBevel }
    g.brush = Color.gray; g.drawRect(120, 120, 120, 90)
    g.brush = Color.orange; g.fillArc(120, 120, 120, 90, 45, 90)
    g.pen = Pen { width = 8; cap = Pen.capRound }
    g.brush = Color.blue; g.drawArc(120, 120, 120, 90, 45, 90)

    g.brush = Color.purple; g.drawText("Hello World!", 70, 50)
    g.font = Font { name="Courier"; size=16; bold=true }; g.drawText("Hello World!", 70, 70)

    img := demo.folderIcon
    g.drawImage(img, 220, 30)
    g.copyImage(img, Rect { x=0; y=0; w=img.size.w; h=img.size.h }, Rect { x=250; y=30; w=64; h=64})

    // system font/colors
    y := 20
    g.font = Font.sys
    g.brush = Color.black
    g.drawText(Font.sys.toStr, 480, y)
    y += 20
    g.font = Font.make("Arial", 9)
    y = sysColor(g, y, Color.sysDarkShadow, "sysDarkShadow")
    y = sysColor(g, y, Color.sysNormShadow, "sysNormShadow")
    y = sysColor(g, y, Color.sysLightShadow, "sysLightShadow")
    y = sysColor(g, y, Color.sysHighlightShadow, "sysHighlightShadow")
    y = sysColor(g, y, Color.sysFg, "sysFg")
    y = sysColor(g, y, Color.sysBg, "sysBg")
    y = sysColor(g, y, Color.sysBorder, "sysBorder")
    y = sysColor(g, y, Color.sysListBg, "sysListBg")
    y = sysColor(g, y, Color.sysListFg, "sysListFg")
    y = sysColor(g, y, Color.sysListSelBg, "sysListSelBg")
    y = sysColor(g, y, Color.sysListSelFg, "sysListSelFg")

    // rect/text with gradients
    g.brush = Gradient.makeLinear(
      Point.make(260,120), Color.blue,
      Point.make(260+200,120+200), Color.red)
    g.pen = Pen { width=20; join = Pen.joinRound }
    g.drawRect(270, 130, 180, 180)
    6.times |Int i| { g.drawText("Gradients!", 300, 150+i*20) }

    // translate for font metric box
    g.translate(50, 250)
    g.pen = Pen.def
    g.brush = Color.yellow
    g.fillRect(0, 0, 200, 100)

    // font metric box with ascent, descent, baseline
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
