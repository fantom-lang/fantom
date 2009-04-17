//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using web
using webapp
using webappClient

class WebappClientFxTest : Widget
{
  override Void onGet()
  {
    head.title.w("WebappClientFx Test").titleEnd
    head.includeJs(`/sys/pod/webappClient/webappClient.js`)
    head.includeJs(`/sys/pod/testWeb/testWeb.js`)

    body.h1.w("WebappClientFx Test").h1End
    body.hr

    showHide
    opacity
  }

  Void showHide()
  {
    body.h2.w("Show/Hide").h2End
    body.table
    body.tr
      f := |Str s|
      {
        id := unique
        body.td("valign='top' style='padding-right:1em;'")
        body.button("value='Show ($s)' onclick='testWeb_FxTestClient.show(\"$id\",\"$s\");'")
        body.button("value='Hide ($s)' onclick='testWeb_FxTestClient.hide(\"$id\",\"$s\");'")
        body.div("id='$id' style='margin-top:5px; padding:1em; background:#ff8;'").w("Hello!").divEnd
        body.tdEnd
      }
      f("0ms")
      f("500ms")
      f("250ms")
      body.trEnd
    body.tableEnd
  }

  Void opacity()
  {
    body.h2.w("Opacity").h2End
    tdStyle  := "padding-right:1em;"
    divStyle := "margin-top:5px; padding:1em; background:#fee;"
    body.table
    body.tr
      f := |Str[] s|
      {
        body.td("valign='top' style='$tdStyle'")
        id := unique
        body.button("value='->${s[0]} (${s[2]})' onclick='testWeb_FxTestClient.opacity(\"$id\", \"${s[0]}\", \"${s[2]}\");'")
        body.button("value='->${s[1]} (${s[2]})' onclick='testWeb_FxTestClient.opacity(\"$id\", \"${s[1]}\", \"${s[2]}\");'")
        body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
        body.tdEnd
      }
      f(["0.3", "1.0", "500ms"])
      f(["0.0", "1.0", "500ms"])
      f(["0.0", "1.0", "250ms"])
      f(["0.2", "1.0", "0ms"])
      body.trEnd
    body.tr
      body.td
      id := unique
      body.button("value='->0->1 (250ms)' onclick='testWeb_FxTestClient.opacityChain(\"$id\", \"250ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
      body.trEnd
    body.tableEnd
  }
}

@javascript
class FxTestClient
{

//////////////////////////////////////////////////////////////////////////
// Show/Hide
//////////////////////////////////////////////////////////////////////////

  static Void show(Str id, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.show(Duration(dur)) |fx|
    {
      end := Duration.now
      fx.elem.html = "Hello! (${(end-start).toMillis}ms)"
    }
  }

  static Void hide(Str id, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.hide(Duration(dur)) |fx|
    {
      end := Duration.now
      fx.elem.html = "Hello! (${(end-start).toMillis}ms)"
    }
  }

//////////////////////////////////////////////////////////////////////////
// Opacity
//////////////////////////////////////////////////////////////////////////

  static Void opacity(Str id, Str stop, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.animate(["opacity":stop], Duration(dur)) |fx|
    {
      end := Duration.now
      op  := fx.elem.style->opacity
      fx.elem.html = "opacity: $op (${(end-start).toMillis}ms)"
    }
  }

  static Void opacityChain(Str id, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    Doc.elem(id).effect.animate(["opacity":"0.0" ], d) |fx|
    {
      t2 := Duration.now
      fx.animate(["opacity":"1.0"], d) |fx2|
      {
        t3 := Duration.now
        fx.elem.html = "Hello! (${(t2-t1).toMillis}ms, ${(t3-t2).toMillis}ms)"
      }
    }
  }

}