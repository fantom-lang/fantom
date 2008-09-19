//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** FileResource models a `sys::File` as a Flux resource.
**
@fluxResource=File#
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
  override FileResource[] children()
  {
    if (kids != null) return kids

    files := sortFiles(file.list)
    kids = files.map(FileResource[,]) |File f->Obj| { return makeFile(f.normalize) }
    return kids
  }
  private FileResource[] kids

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
    acc.addAll(Type.findByFacet("fluxViewMimeType", mime.toStr, true))

    // then match by just media type
    acc.addAll(Type.findByFacet("fluxViewMimeType", mime.mediaType, true))

    // filter out abstract
    acc = acc.exclude |Type t->Bool| { return t.isAbstract }

    return acc
  }

  **
  ** Add command specific Files.
  **
  override Menu popup(Frame frame, Event event)
  {
    menu := super.popup(frame, event)
    if (file.isDir)
    {
      menu.add(MenuItem { command=Command.makeLocale(type.pod, "openIn", &openIn(file)) })
      menu.addSep
      menu.add(MenuItem { command=Command.makeLocale(type.pod, "newDir", &newDir(frame,file)) })
    }
    return menu
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
    newDir := Dialog.openPromptStr(frame, type.loc("newDir.name"))
    if (newDir != null)
    {
      try
      {
        uri := dir.uri + "$newDir/".toUri
        File(uri).create
      }
      catch (Err err)
      {
        Dialog.openErr(frame, "Error", err)
      }
    }
  }

  **
  ** Given a file size in bytes return a suitable string
  ** representation for display.  If size is null return "".
  **
  static Str sizeToStr(Int size)
  {
    if (size == null) return ""
    if (size == 0) return "0KB"
    if (size < kb) return "1KB"
    if (size < mb) return (size/kb) + "KB"
    if (size < gb) return (size/mb) + "MB"
    return (size/gb) + "GB"
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
    if (mimeType == null) return Flux.icon(`/x16/text-x-generic.png`)

    if (mimeType.mediaType == "text")
    {
      switch (mimeType.subType)
      {
        case "html": return Flux.icon(`/x16/text-html.png`)
        default:     return Flux.icon(`/x16/text-x-generic.png`)
      }
    }

    switch (mimeType.mediaType)
    {
      case "audio": return Flux.icon(`/x16/audio-x-generic.png`)
      case "image": return Flux.icon(`/x16/image-x-generic.png`)
      case "video": return Flux.icon(`/x16/video-x-generic.png`)
      default:      return Flux.icon(`/x16/text-x-generic.png`)
    }
  }

}