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
@Js class FilePicker : Elem
{
  new make() : super("input")
  {
    this.style.addClass("domkit-FilePicker")
    this->type = "file"
    this->tabindex = 0
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

  ** Does this picker allow seleting multiple files?
  Bool multi
  {
    get { this->multiple }
    set { this->multiple = it }
  }

  ** Get the list of currently selected files.
  DomFile[] files() { this->files }
}