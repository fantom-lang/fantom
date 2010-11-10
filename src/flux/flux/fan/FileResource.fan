//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using gfx
using fwt

**
** FileResource models a `sys::File` as a Flux resource.
**
class FileResource : Resource
{

  **
  ** Make a resource for the specified file.
  **
  new make(Uri uri, File file)
  {
    this.uri  = uri
    this.file = file
    this.name = file.name
    this.icon = fileToIcon(file)
  }

  **
  ** Make from file using file's uri - the file must be normalized.
  **
  internal new makeFile(File file) : this.make(file.uri, file) {}

  **
  ** The target file.
  **
  const File file

  **
  ** The absolute file uri
  **
  override Uri uri

  **
  ** Return the file name.
  **
  override Str name

  **
  ** The icon is based on mime type.
  **
  override Image icon

  **
  ** If we haven't loaded the children yet, then return
  ** true for directories and false for normal files.
  **
  override Bool hasChildren()
  {
    if (kids != null) return !kids.isEmpty
    return file.isDir
  }

  **
  ** Get the navigation children of the resource.  Return an
  ** empty list or null to indicate no children.  Default
  ** returns null.
  **
  override FileResource[]? children()
  {
    if (kids != null) return kids

    files := sortFiles(file.list)
    kids = files.map |File f->FileResource| { makeFile(f.normalize) }
    return kids
  }
  private FileResource[]? kids

  **
  ** View types are based on mime type.  Register a file view
  ** using the facet "fluxViewMimeType" with a Str value for the
  ** MIME type such as "image/png".  You can also register with
  ** just the media type, for example use "image" to register a
  ** view on any image file.
  **
  override Type[] views()
  {
    mime := file.mimeType ?: MimeType.fromStr("text/plain")

    // first try exact mime type matching
    acc := Type[,]
    acc.addAll(Flux.qnamesToTypes(Env.cur.index("flux.view.mime.${mime.toStr}")))

    // then match by just media type
    acc.addAll(Flux.qnamesToTypes(Env.cur.index("flux.view.mime.${mime.mediaType}")))

    // filter out abstract
    acc = acc.exclude |Type t->Bool| { return t.isAbstract }

    return acc
  }

  **
  ** Add command specific Files.
  **
  override Menu? popup(Frame? frame, Event? event)
  {
    menu := super.popup(frame, event)
    if (file.isDir)
    {
      menu.addCommand(Command.makeLocale(Pod.of(this), "openIn") { openIn(file) })
      menu.addCommand(Command.makeLocale(Pod.of(this), CommandId.findInFiles, |->| { findInFiles(frame, file) }) { accelerator = null })
      menu.addSep
      menu.addCommand(Command.makeLocale(Pod.of(this), "newDir") { newDir(frame,file) })
    }
    else menu.addSep
    menu.addCommand(Command.makeLocale(Pod.of(this), "duplicate") { duplicate(frame,file) })
    menu.addCommand(Command.makeLocale(Pod.of(this), "rename") { rename(frame,file) })
    return menu
  }

  **
  ** Invoke the find-in-files command on the specified directory
  **
  internal Void findInFiles(Frame? frame, File dir)
  {
    FindHistory.load.pushDir(dir.uri)
    frame?.command(CommandId.findInFiles)?.invoke(null)
  }

  **
  ** Open the given directory using the OS specific directory
  ** browser (i.e. Windows Explorer or Mac Finder)
  **
  internal Void openIn(File dir)
  {
    if (!dir.isDir) throw ArgErr("Not a directory: $dir")
    if (Desktop.isWindows)  Process(["explorer", dir.osPath]).run
    else if (Desktop.isMac) Process(["open", dir.osPath]).run
    else echo("Not yet implemented")
  }

  **
  ** Create a new diretory under the current directory.
  **
  internal Void newDir(Frame frame, File dir)
  {
    if (!dir.isDir) throw ArgErr("Not a directory: $dir")
    newDir := promptFileName(frame, Flux.locale("newDir.name"), dir, "")
    if (newDir == null) return
    uri := dir.uri + "$newDir/".toUri
    File(uri).create
  }

  **
  ** Duplicate the given file.
  **
  internal Void duplicate(Frame frame, File src)
  {
    name := promptFileName(frame, Flux.locale("duplicate.name"), src.parent, src.name)
    if (name == null) return
    target := src.parent + (src.isDir ? "$name/".toUri : name.toUri)
    src.copyTo(target)
  }

  **
  ** Rename the given file.
  **
  internal Void rename(Frame frame, File src)
  {
    name := promptFileName(frame, Flux.locale("rename.name"), src.parent, src.name)
    if (name == null) return
    src.rename(name)
  }

  **
  ** Prompt the user for a new valid filename, returns the new
  ** filename, or null if the dialog was canceled.
  **
  private Str? promptFileName(Frame frame, Str label, File dir, Str oldName)
  {
    Str? newName := oldName
    while (true)
    {
      newName = Dialog.openPromptStr(frame, label, newName)
      if (newName == null) return null
      try
      {
        if (!Uri.isName(newName))
        {
          Dialog.openErr(frame, "Invalid name: $newName")
          continue
        }
        try
        {
          // TODO - need to clean up sys::File to make this easier;
          // if file exists as a dir, this throws an exception b/c
          // the uri is missing a trailing slash
          if ((dir+newName.toUri).exists) throw Err()
        }
        catch (Err err)
        {
          Dialog.openErr(frame, "File already exists: $newName")
          continue
        }
        return newName
      }
      catch (Err err) { Dialog.openErr(frame, "Error", err) }
    }
    return null
  }

  **
  ** Given a file size in bytes return a suitable string
  ** representation for display.  If size is null return "".
  **
  static Str sizeToStr(Int? size)
  {
    size == null ? "" : size.toLocale("B")
  }
  private static const Int kb := 1024
  private static const Int mb := 1024*1024
  private static const Int gb := 1024*1024*1024

  **
  ** Sort files in-place for display.  Directories are always
  ** sorted before normal files using locale name comparison.
  **
  static File[] sortFiles(File[] files)
  {
    return files.sort |File a, File b->Int|
    {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1
      return a.name.localeCompare(b.name)
    }
  }

  **
  ** Get the icon for the specified file based on its mime type.
  **
  static Image fileToIcon(File f)
  {
    if (f.isDir) return Flux.icon(`/x16/folder.png`)

    mimeType := f.mimeType
    if (mimeType == null) return Flux.icon(`/x16/file.png`)

    // look for explicit match based off ext
    try { return Flux.icon("/x16/file${f.ext.capitalize}.png".toUri) }
    catch {}

    if (mimeType.mediaType == "text")
    {
      switch (mimeType.subType)
      {
        //case "html": return Flux.icon(`/x16/fileHtml.png`)
        default:     return Flux.icon(`/x16/file.png`)
      }
    }

    switch (mimeType.mediaType)
    {
      //case "audio": return Flux.icon(`/x16/audio-x-generic.png`)
      case "image": return Flux.icon(`/x16/fileImage.png`)
      //case "video": return Flux.icon(`/x16/video-x-generic.png`)
      default:      return Flux.icon(`/x16/file.png`)
    }
  }

}