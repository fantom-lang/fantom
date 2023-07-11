//
// Copyright (c) 2022, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Feb 2022  Brian Frank  Creation
//

using graphics
using dom
using domkit
using web
using wisp

const class MainDomMod : WebMod
{
  new make()
  {
    pods := [typeof.pod]
    this.jsPack  = FilePack(FilePack.toAppJsFiles(pods))
    this.cssPack = FilePack(FilePack.toAppCssFiles(pods))
  }

  const FilePack jsPack

  const FilePack cssPack

  override Void onGet()
  {
    n := req.uri.path.first
    if (n == null)     return onIndex
    if (n == "test")   return onTest
    if (n == "res")    return onRes
    if (n == "app.js") return jsPack.onService
    if (n == "app.css") return cssPack.onService
    res.sendErr(404)
  }

  Void onIndex()
  {
    res.redirect(`/test/BasicsTest`)
  }

  Void onTest()
  {
    type := uriToType
    if (type == null) return res.sendErr(404)

    env := Str:Str[:]
    env["main"] = MainDom#.qname
    env["typeName"] = type.name

    res.headers["Content-Type"] = "text/html; charset=utf-8"
    out := res.out
    out.docType
    out.html
      .initJs(env)
      .includeCss(`/app.css`)
      .includeJs(`/app.js`)
      .style.w(
       "html { height: 100%; }
        body {
          height: 100%;
          overflow: hidden;
          font: 14px 'Helvetica Neue', Arial, sans-serif;
          padding: 0;
          margin: 0;
          background: #fff;
          color: #000;
        }")
    out.headEnd
    out.body.bodyEnd
    out.htmlEnd
  }

  private Type? uriToType()
  {
    name := req.modRel.path.getSafe(1) ?: ""
    type := typeof.pod.type(name, false)
    if (type == null || !type.fits(AbstractTest#) || type.isAbstract) return null
    return type
  }

  Void onRes()
  {
    file := typeof.pod.file(req.uri, false)
    if (file == null) return res.sendErr(404)
    return FileWeblet(file).onService
  }
}

**************************************************************************
** MainDom
**************************************************************************

@Js
class MainDom
{

  static Void main()
  {
    typeName := Env.cur.vars["typeName"]
    test := (AbstractTest)MainDom#.pod.type(typeName).make


    |->|? repaint := null

    header := FlowBox
    {
      it.style.setCss("background:#e0e0e0; border-bottom:1px solid #999; padding:12px;")
      it.gaps = ["12px"]
      ListButton
      {
        it.items = AbstractTest.list.map |t| { t.name }
        it.sel.index = it.items.findIndex |t| { t == test.typeof.name }
        it.onSelect |d|
        {
          type := d.sel.item
          Win.cur.hyperlink(`/test/$type`)
        }
      },
      Button
      {
        it.text = "Repaint"
        it.onAction
        {
          repaint()
        }
      },
      //Elem("a") { it->href=`/svg/${typeName}`; it.text = "SVG"; it.style->lineHeight = "25px" },
    }

    size := Size(1000, 800)
    canvas := Elem("canvas")
    canvas.setAttr("width", "${size.w.toInt}px")
    canvas.setAttr("height", "${size.h.toInt}px")
    canvas.renderCanvas |g| { test.paint(size, g) }

    repaint = |->|
    {
      canvas.renderCanvas |g| { test.paint(size, g) }
    }

    sash := SashBox
    {
      sizes = ["48px", "100%"]
      dir = Dir.down
      header,
      Elem("div") { canvas, },
    }

    Win.cur.doc.body.add(sash)
  }
}