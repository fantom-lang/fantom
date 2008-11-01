//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Sep 08  Andy Frank  Creation
//

using fwt

**
** FindInFiles searches a set of files for a query string.
**
internal class FindInFiles
{

  **
  ** Create a new instance to search for the given query
  ** in the given file or directory.
  **
  new make(File file, Str query)
  {
    this.query  = query
    this.file = file
  }

  **
  ** Return the occurances of the query in the assocated dir.
  ** If a function is passed in, that function is called each
  ** time a match is found.
  **
  Mark[] find(|Mark m|? func := null)
  {
    if ((Obj?)file == null) throw ArgErr("File cannot be null")
    if (!file.exists) throw ArgErr("File does not exist")
    if ((Obj?)query == null) throw ArgErr("Query cannot be null")
    if (query.size == 0) throw ArgErr("Query cannot be empty")

    marks := Mark[,]
    file.walk |File f|
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
          col := str.indexIgnoreCase(query)
          while (col != null)
          {
            mark := Mark { uri=f.uri; line=line; col=col }
            func?.call([mark])
            marks.add(mark)
            col = str.indexIgnoreCase(query, ++col)
          }
          line++
          str = in.readLine
        }
      }
      catch (IOErr err) {} // skip files we can't read
      finally in.close
    }
    return marks.sort
  }

  readonly File file
  readonly Str query

  **
  ** Open FindInFiles in a dialog.
  **
  static Void dialog(Frame frame)
  {
    query := Text { prefCols=30 }
    uri   := Text { prefCols=30 }

    query.text = Thread.locals["flux.findInFiles.text"] ?: ""
    uri.text   = Thread.locals["flux.findInFiles.uri"]  ?: Sys.homeDir.toStr

    content := GridPane
    {
      numCols = 2
      Label { text="Find" }
      add(query)
      Label { text="In Folder" }
      add(uri)
    }
    dlg := Dialog(frame)
    {
      title = FindInFiles#.loc("findInFiles.name")
      body  = content
      commands = [Dialog.ok, Dialog.cancel]
    }
    query.onAction.add |,| { dlg.close(Dialog.ok) }
    uri.onAction.add   |,| { dlg.close(Dialog.ok) }
    if (Dialog.ok != dlg.open) return

    try
    {
      File f := File(uri.text.toUri, false)
      Str  q := query.text

      Thread.locals["flux.findInFiles.text"] = q
      Thread.locals["flux.findInFiles.uri"]  = f.toStr

      frame.console.show->clear
      frame.marks = Mark[,]
      Console.execWrite(frame.id, "Files containing \"$q\"...\n")
      marks := FindInFiles(f, q).find |Mark m|
      {
        path := m.uri.toFile.osPath
        Console.execWrite(frame.id, "$path(${m.line+1},${m.col+1})\n")
      }
      Console.execWrite(frame.id, "$marks.size results found\n")
      frame.marks = marks
    }
    catch (Err err) { Dialog.openErr(frame, err.message, err) }
  }

}