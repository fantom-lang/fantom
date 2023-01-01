//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 2023  Andy Frank  Creation
//

using graphics
using web

**************************************************************************
** ClipboardTest
**************************************************************************

@NoDoc class ClipboardTest : Weblet
{
  override Void onGet()
  {
    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
    out.head
      .title.w("Clipboard Test").titleEnd
      .includeJs(`/pod/sys/sys.js`)
      .includeJs(`/pod/concurrent/concurrent.js`)
      .includeJs(`/pod/graphics/graphics.js`)
      .includeJs(`/pod/web/web.js`)
      .includeJs(`/pod/dom/dom.js`)
      .headEnd

    out.body
      .h1.w("Clipboard Test").h1End
      .hr

    // writeText
    out.p
      .h2.w("Write Text").h2End
      .textArea("id='write' cols='80' rows='10'")
        .w("Something really cool to add to the clipboard!")
        .textAreaEnd
      .button("value='Write text to clipboard' onclick='fan.dom.ClipboardTestUi.write()'")
      .pEnd

    // readText
    out.p
      .h2.w("Read Text").h2End
      .textArea("id='read' cols='80' rows='10' readonly style='background:#eee'").textAreaEnd
      .button("value='Read clipboard contents' onclick='fan.dom.ClipboardTestUi.read()'")
      .pEnd

    out.bodyEnd.htmlEnd
  }
}

**************************************************************************
** ClipboardTestUi
**************************************************************************

@Js @NoDoc internal class ClipboardTestUi
{
  static Void write()
  {
    text := Win.cur.doc.elemById("write")->value
    Win.cur.clipboardWriteText(text)
  }

  static Void read()
  {
    Win.cur.clipboardReadText |text| {
      Win.cur.doc.elemById("read")->value = text
    }
  }
}

