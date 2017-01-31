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
      it.cellStyle("all", "all", "vertical-align: top")
      it.addRow([picker("Single Default", FilePicker {})])
      it.addRow([picker("Multi Default",  FilePicker { it.multi=true })])
      it.addRow([picker("Accept image/*", FilePicker { it.accept="image/*" })])
    })
  }

  Elem picker(Str label, FilePicker picker)
  {
    list := Button { it.text="List Files";    it.onAction { listFiles(picker)   }}
    text := Button { it.text="Read Text";     it.onAction { readText(picker)    }}
    data := Button { it.text="Read Data URI"; it.onAction { readDataUri(picker) }}
    return GridBox
    {
      it.cellStyle("all", "all", "padding: 12px 4px;")
      it.cellStyle(    0, "all", "width: 100px;")
      it.cellStyle(    1, "all", "width: 250px;")
      it.addRow([Label { it.text="$label:" }, picker, list, text, data])
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
