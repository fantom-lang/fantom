//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using dom

**
** FilePicker allows selection of files.
**
** See also: [docDomkit]`docDomkit::Controls#filePicker`
**
@Js class FilePicker : Elem
{
  new make() : super("input")
  {
    this.style.addClass("domkit-FilePicker")
    this->type = "file"
    this->tabIndex = 0
    this.onEvent("change", false)
    {
      if (cbSelect != null) cbSelect(this)
    }
  }

  ** Indicate the types of files that the server accepts.
  ** The value must be a comma-separated list of unique
  ** content type specifiers:
  **
  **   - A file extension starting with a '.': (e.g. .jpg, .png, .doc)
  **   - A valid MIME type with no extensions
  **   - 'audio/*' representing sound files
  **   - 'video/*' representing video files
  **   - 'image/*' representing image files
  Str? accept
  {
    get { this->accept }
    set { this->accept = it }
  }

  ** Does this picker allow selecting multiple files?
  Bool multi
  {
    get { this->multiple }
    set { this->multiple = it }
  }

  ** Programmtically open the client file chooser interface.
  Void open() { this.invoke("click") }

  ** Get the list of currently selected files.
  DomFile[] files() { this->files }

  ** Callback when a file has been selected by this picker.
  Void onSelect(|FilePicker| f) { this.cbSelect = f }

  private Func? cbSelect := null
}