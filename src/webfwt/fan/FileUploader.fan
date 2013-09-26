//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 2011  Andy Frank  Creation
//

using fwt
using gfx

**
** FileUploader enables file uploading from a browser.
**
@Js
class FileUploader : Pane
{
  ** Return a Dialog to wrap given FileUploader instance.
  static Dialog dialog(Window w, FileUploader f)
  {
    loc := "$<upload=Upload>"
    dlg := WebDialog(w)
    {
      title = loc
      body  = f
      insetsBody = Insets(10)
    }
    Command? upload
    upload = Command.make(loc, null) |e|
    {
      upload.enabled = false
      f.onComplete.add
      {
        dlg.commands = [Dialog.ok]
        dlg.buildContent
        dlg.relayout
      }
      f.upload
    }
    upload.enabled = false
    f._onFilesChanged.add |e| { upload.enabled = e.index > 0 }
    dlg.commands = [upload, Dialog.cancel]
    return dlg
  }

  ** It-block constructor.
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    top = ContentPane()
    list = multi
      ? WebScrollPane { bg=Color.white }
      : BorderPane { bg=Color.white; border=Border("#9f9f9f") }
    content = EdgePane
    {
      // minh prevents content for jumping when icon changes
      it.top = ConstraintPane { minh=32; this.top, }
      center = ConstraintPane
      {
        prefh := multi ? (5*36) : 36
        minw=400; maxw=400
        minh=prefh; maxh=prefh
        list,
      }
    }
    add(content)
    reset
  }

  ** Allow multiple file uploading.
  const Bool multi := false

  ** Target URI to upload files. Each file is uploaded on a
  ** discrete POST request.  The original name of the file is
  ** contained in the 'FileUpload-filename' request header.
  const Uri uri

  ** If 'true' the POST content is formatted as "multipart/form-data".
  ** If 'false' the raw file content is posted.
  const Bool useMultiPart := false

  ** Additional HTTP headers to POST along with file content.
  const Str:Str headers := [:]

  ** EventListener invoked when all uploads have completed.
  once EventListeners onComplete() { EventListeners() }

  ** Invoke upload process for currently selected files.
  Void upload()
  {
    working = true
    top.content = Label
    {
      image = Image(`fan://webfwt/res/img/throbber.gif`)
      text  = "$<uploading=Uploading...>"
    }
    onSubmit
    relayout
  }

  ** Reset this uploader, clearing all completed uploads
  ** or selected files.
  Void reset()
  {
    if (working) throw Err("Upload in progress")
    top.content = GridPane
    {
      numCols = 2
      MiniButton { text="$<chooseFile=Choose File>"; onAction.add { onChoose }},
      Label { text="$<orDragFilesHere=or drag files here>" },
    }
    onClear
    relayout
  }

  ** Callback when all file uploads are complete.
  private Void onUploadComplete(FileUpload[] files)
  {
    // map files into name:response
    map := Str:Str[:]
    files.each |f| { map[f.name] = f.response }

    // update interface and notify listeners
    working = false
    top.content = Label
    {
      image = Image(`fan://icons/x16/check.png`)
      text  = "$<uploadComplete=Upload complete>"
    }
    relayout
    onComplete.fire(Event { id=EventId.action; widget=this; data=map.ro })
  }

  override Size prefSize(Hints hints := Hints.defVal)
  {
    cp := content.prefSize
    return Size(cp.w+12, cp.h+12)
  }

  override Void onLayout()
  {
    content.bounds = Rect(6, 6, size.w-12, size.h-12)
  }

  private native Void onChoose()
  private native Void onRemove(Int index)
  private native Void onClear()
  private native Void onSubmit()

  private Void onFilesChanged(FileUpload[] files)
  {
    vpane := VPane()
    files.each |file,i|
    {
      Widget? status
      if (!file.active)
        status = MiniButton { text="$<remove=Remove>"; onAction.add { onRemove(i) }}
      else if (file.inProgress)
        status = ProgressBar { val=file.progress }
      else
        status = Label { text=file.status; fg=Color("#777") }

      vpane.add(FileUploadRow([
        WebLabel { text=file.name; softClip=true },
        status,
      ], multi && i > 0))
    }
    list.content = vpane
    list.relayout

    // internal hook for dialog
    _onFilesChanged.fire(Event { index=files.size })
  }

  // internal hook for dialog
  internal once EventListeners _onFilesChanged() { EventListeners() }

  private Widget content
  private ContentPane top
  private ContentPane list
  private Bool working := false
}

**************************************************************************
** FileUpload
**************************************************************************
@Js
internal class FileUpload
{
  Str? name               // file name
  Obj? file               // file object
  Bool active   := false  // is upload active
  Bool waiting  := true   // is upload waiting for connection
  Bool complete := false  // is upload complete
  Int progress := 0       // if uploading, cur progress as 0..100%
  Str response := ""      // response text upon completion

  Str status()
  {
    if (!active)  return ""
    if (waiting)  return "$<waiting=Waiting>"
    if (complete) return "$<complete=Complete>"
    return "$progress%"
  }

  Bool inProgress() { active && !waiting && !complete }
}

**************************************************************************
** FileUploadRow
**************************************************************************
@Js
internal class FileUploadRow : Pane
{
  new make(Widget[] kids, Bool sep)
  {
    addAll(kids)
    if (sep) add(BorderPane { border=Border("1,0,0,0 #ccc") })
  }

  override Size prefSize(Hints hints := Hints.defVal) { Size(400, 36) }

  override Void onLayout()
  {
    w := size.w - 12
    h := size.h - 12

    b := children[1]
    bp := b.prefSize
    bx := w - bp.w
    by := (h - bp.h) / 2
    b.bounds = Rect(6+bx, 6+by, bp.w, bp.h)

    a  := children.first
    ap := a.prefSize
    ay := (h - ap.h) / 2
    aw := w - bp.w - 12
    a.bounds = Rect(6, 6+ay, aw, ap.h)

    if (children.size == 3) children.last.bounds = Rect(0, 0, size.w, 1)
  }
}
