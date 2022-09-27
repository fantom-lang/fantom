//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 2022  Andy Frank  Creation
//

using dom
using domkit

@Js
class FormTest : DomkitTest
{
  new make()
  {
    grid := GridBox
    {
      it.style->padding = "12px"
      it.cellStyle("*",    "*", "padding: 12px; vertical-align: top")
      it.cellStyle("*", "even", "padding-bottom: 0px")
      it.cellStyle("*",      2, "padding-top: 24px")
      it.addRow([heading("URL Encoded")])
      it.addRow([urlEncoded, urlEncodedOut])
      it.addRow([heading("Multipart")])
      it.addRow([multiPart, multipartOut])
    }

    this.style->overflow = "auto"
    this.style->background = "#eee"
    this.add(grid)
  }

  TextArea urlEncodedOut := TextArea { it.style->font="13px monospace"; it.cols=80; it.rows=12 }
  TextArea multipartOut  := TextArea { it.style->font="13px monospace"; it.cols=80; it.rows=12 }

  Elem heading(Str text)
  {
    Label {
      it.style->display = "block"
      it.style->fontWeight = "bold"
      it.text = text
    }
  }

  Elem urlEncoded()
  {
    GridBox
    {
      g := it
      it.cellStyle("*", "*", "padding: 4px")
      it.addRow([Label { it.text="Field A" }, TextField { it.setAttr("name", "field-a"); it.val="Value A" }])
      it.addRow([Label { it.text="Field B" }, TextField { it.setAttr("name", "field-b"); it.val="Value B" }])
      it.addRow([Label { it.text="Field C" }, TextField { it.setAttr("name", "field-c"); it.val="Value C" }])
      it.addRow([Label {}, Button { it.text="Submit"; it.onAction { onSubmitUrl(g) } }])
    }
  }

  Elem multiPart()
  {
    GridBox
    {
      g := it
      it.cellStyle("*", "*", "padding: 4px")
      it.addRow([Label { it.text="Field A" }, TextField { it.setAttr("name", "field-a"); it.val="Value A" }])
      it.addRow([Label { it.text="Field B" }, TextField { it.setAttr("name", "field-b"); it.val="Value B" }])
      it.addRow([Label { it.text="Field C" }, FilePicker { it.setAttr("name", "field-c") }])
      it.addRow([Label {}, Button { it.text="Submit"; it.onAction { onSubmitMulti(g) } }])
    }
  }

  Void onSubmitUrl(Elem elem)
  {
    form := Str:Str[:]
    elem.querySelectorAll("input.domkit-TextField").each |TextField f|
    {
      n := f.attr("name")
      form[n] = f.val
    }
    req := HttpReq { it.uri=`/form`}
    req.postForm(form) |res| { urlEncodedOut.val = res.content }
  }

  Void onSubmitMulti(Elem elem)
  {
    form := Str:Obj[:]
    elem.querySelectorAll("input.domkit-TextField").each |TextField f|
    {
      n := f.attr("name")
      form[n] = f.val
    }
    elem.querySelectorAll("input.domkit-FilePicker").each |FilePicker f|
    {
      if (f.files.isEmpty) return
      n := f.attr("name")
      form[n] = f.files.first
    }
    req := HttpReq { it.uri=`/form`}
    req.postFormMultipart(form) |res| { multipartOut.val = res.content }
  }
}
