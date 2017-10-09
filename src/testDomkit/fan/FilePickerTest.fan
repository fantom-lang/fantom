//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class FilePickerTest : DomkitTest
{
  new make()
  {
    add(GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*", "*", "vertical-align: top")
      it.addRow([picker("Single Default", FilePicker {})])
      it.addRow([picker("Multi Default",  FilePicker { it.multi=true })])
      it.addRow([picker("Accept image/*", FilePicker { it.accept="image/*" })])
      it.addRow([picker("Hidden",         FilePicker { it.style->display="none" })])
      it.addRow([picker("onSelect",       FilePicker { it.onSelect |f| { listFiles(f) } })])
      it.addRow([docDomkit])
    })
  }

  Elem picker(Str label, FilePicker picker)
  {
    open := Button { it.text="Open";          it.onAction { picker.open         }}
    list := Button { it.text="List Files";    it.onAction { listFiles(picker)   }}
    text := Button { it.text="Read Text";     it.onAction { readText(picker)    }}
    data := Button { it.text="Read Data URI"; it.onAction { readDataUri(picker) }}
    return GridBox
    {
      it.cellStyle("*", "*", "padding: 12px 4px;")
      it.cellStyle(  0, "*", "width: 100px;")
      it.cellStyle(  1, "*", "width: 250px;")
      it.addRow([Label { it.text="$label:" }, picker, open, list, text, data])
    }
  }

  Elem docDomkit()
  {
    Elem {
      it.style->paddingTop = "20px"
      picker := FilePicker { it.style->display="none" }
      picker,
      Button { it.text="Choose Files"; it.onAction { picker.open }},
    }
  }

  Void listFiles(FilePicker p)
  {
    files := p.files
    echo("# $p -- Files [$files.size]")
    files.each |f,i| { echo("#  [$i] $f.name ($f.size) ($f.type)") }
  }

  Void readText(FilePicker p)
  {
    files := p.files
    echo("# $p -- Files [$files.size]")
    files.each |f,i|
    {
      f.readAsText |s| {
        echo("#  [$i] $f.name ----")
        echo(s)
      }
    }
  }

  Void readDataUri(FilePicker p)
  {
    files := p.files
    echo("# $p -- Files [$files.size]")
    files.each |f,i|
    {
      f.readAsDataUri |u| {
        echo("#  [$i] $f.name ----")
        echo(u)
      }
    }
  }
}
