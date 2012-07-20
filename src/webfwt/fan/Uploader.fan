//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Oct 09  Andy Frank  Creation
//

using fwt
using gfx

**
** Uploader uploads files using a POST request. Once the
** dialog has been been closed via 'Ok', a form submission
** is invoked for the page.
**
@NoDoc
@Js
// TODO: get reworked like fresco?
class Uploader
{
  ** Open Uploader in dialog.
  Void open(Window win, Uri uri, Str name)
  {
    id := "webfwt-uploader"
    ok = Command("Upload", null) |e|
    {
      ok.enabled = false
      cancel.enabled = false
      submit(id)
    }
    cancel = Dialog.cancel

    Dialog(win)
    {
      title = "Upload"
      body = HtmlPane
      {
        width = 350
        html =
          "<form id='$id' enctype='multipart/form-data' method='post' action='$uri.encode.toXml'>
           <input type='file' name='$name' />
           </form>"
      }
      commands = [this.ok, this.cancel]
    }.open
  }

  private native Void submit(Str id)
  private Command? ok
  private Command? cancel
}

