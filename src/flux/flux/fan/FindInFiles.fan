//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 08  Andy Frank  Creation
//

using gfx
using fwt

**
** FindInFiles searches a set of files for a query string.
**
internal class FindInFiles
{
  **
  ** Open FindInFiles in a dialog.
  **
  static Void dialog(Frame frame)
  {
    query := Combo { editable = true }
    uri   := Combo { editable = true }
    err   := Label { fg = Color.red; halign = Halign.right }
    match := Button { mode = ButtonMode.check; text = Flux.locale("find.matchCase") }

    history := FindHistory.load
    query.items = history.find
    uri.items   = history.dirAsStr
    if (uri.items.isEmpty) uri.items = [Env.cur.homeDir.toStr]
    match.selected = history.matchCase

    content := GridPane
    {
      numCols = 2
      expandCol = 1
      halignCells = Halign.fill
      Label { text="Find" },
      ConstraintPane { minw=300; maxw=300; add(query) },
      Label { text="In Folder" },
      ConstraintPane { minw=300; maxw=300; add(uri) },
      Label {}, // spacer
      GridPane
      {
        numCols = 2
        expandCol = 1
        halignCells = Halign.fill
        match,
        err,
      },
    }
    dlg := Dialog(frame)
    {
      title = Flux.locale("findInFiles.name")
      body  = content
      commands = [Dialog.ok, Dialog.cancel]
    }
    query.onAction.add |->| { dlg.close(Dialog.ok) }
    uri.onAction.add   |->| { dlg.close(Dialog.ok) }
    uri.onModify.add   |->|
    {
      err.text = File(uri.text.toUri, false).exists ? "" : "Directory not found"
      err.parent?.parent?.relayout
    }
    if (Dialog.ok != dlg.open) return

    try
    {
      q := query.text
      f := File(uri.text.toUri, false)
      if (!f.exists) throw ArgErr("Directory not found: $f")

      // save history
      history.pushFind(q)
      history.pushDir(f.uri)
      history.matchCase = match.selected
      history.save

      // run in console
      frame.console.show.run(#doFind, [q, f.uri.toStr, match.selected.toStr])
    }
    catch (Err e) { Dialog.openErr(frame, e.msg, e) }
  }

  static Str[] doFind(ExecParams params)
  {
    query   := params.command[0]
    dir     := params.command[1]
    match   := params.command[2] == "true"
    results := Str[,]
    results.add("Files containing \"$query\"...\n")
    results.addAll(find(query, dir.toUri.toFile, match))
    results.add("${results.size-1} results found\n")
    return results
  }

  **
  ** Return the occurances of the query in the assocated dir.
  ** If a function is passed in, that function is called each
  ** time a match is found.
  **
  static Str[] find(Str query, File dir, Bool match := false)
  {
    if (query.size == 0) return Str[,]
    if (!dir.exists) throw ArgErr("Directory not found")

    results := Str[,]
    dir.walk |File f|
    {
      if (f.isDir) return
      f = f.normalize
      in := f.in
      try
      {
        line := 0
        str  := in.readLine
        while (str!= null)
        {
          col := match ? str.index(query) : str.indexIgnoreCase(query)
          while (col != null)
          {
            results.add("$f.osPath(${line+1},${col+1}): $str.trim\n")
            col = match ? str.index(query, ++col) : str.indexIgnoreCase(query, ++col)
          }
          line++
          str = in.readLine
        }
      }
      catch (IOErr err) {} // skip files we can't read
      finally in.close
    }
    return results
  }

}