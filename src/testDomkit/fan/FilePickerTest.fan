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
    list := Button { it.text="List Files"; it.onAction { listFiles(picker) }}
    return GridBox
    {
      it.cellStyle("all", "all", "padding: 12px;")
      it.addRow([Label { it.text="$label:" }, picker, list])
    }
  }

  Void listFiles(FilePicker p)
  {
    files := p.files
    echo("# $p -- Files [$files.size]")
    files.each |f,i| { echo("#  [$i] $f.name ($f.size) ($f.type)") }
  }
}
