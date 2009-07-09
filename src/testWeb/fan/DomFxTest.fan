//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 09  Andy Frank  Creation
//

using dom
using web
using webapp

class DomFxTest : Widget
{
  override Void onGet()
  {
    head.title.w("WebappClientFx Test").titleEnd
    head.includeJs(`/sys/pod/sys/sys.js`)
    head.includeJs(`/sys/pod/dom/dom.js`)
    head.includeJs(`/sys/pod/testWeb/testWeb.js`)

    body.h1.w("WebappClientFx Test").h1End
    body.hr

    showHide
    opacity
    slide
    queueing
  }

  Void showHide()
  {
    body.h2.w("Show/Hide").h2End
    body.table
    body.tr
      f := |Str s, Str css|
      {
        id := unique
        body.td("valign='top' style='padding-right:1em;'")
        body.button("value='Show ($s)' onclick='testWeb_FxTestClient.show(\"$id\",\"$s\");'")
        body.button("value='Hide ($s)' onclick='testWeb_FxTestClient.hide(\"$id\",\"$s\");'")
        body.div("id='$id' style='margin-top:5px; padding:1em; background:#ff8; $css'").w("Hello!").divEnd
        body.tdEnd
      }
      f("0ms",   "")
      f("500ms", "")
      f("250ms", "")
      f("100ms", "border:2px solid #f00;")
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
        body.button("value='->${s[0]} (${s[2]})' onclick='testWeb_FxTestClient.fadeTo(\"$id\", ${s[0].toDecimal}, \"${s[2]}\");'")
        body.button("value='->${s[1]} (${s[2]})' onclick='testWeb_FxTestClient.fadeTo(\"$id\", ${s[1].toDecimal}, \"${s[2]}\");'")
        body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
        body.tdEnd
      }
      f(["0.3", "1.0", "500ms"])
      f(["0.0", "1.0", "500ms"])
      f(["0.0", "1.0", "250ms"])
      f(["0.2", "1.0", "0ms"])
      body.trEnd
    body.tr
    body.td("valign='top' style='$tdStyle'")
      id := unique
      body.button("value='FadeOut/FadeIn (250ms)' onclick='testWeb_FxTestClient.fadeToChain(\"$id\", \"250ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      id = unique
      body.button("value='->0->1 (250ms)' onclick='testWeb_FxTestClient.animateOpacityChain(\"$id\", \"250ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.trEnd
    body.tableEnd
  }

  Void slide()
  {
    body.h2.w("Slide").h2End
    tdStyle  := "padding-right:1em;"
    divStyle := "margin-top:5px; padding:1em; background:#cfc;"
    body.table
    body.tr
      f := |Str s|
      {
        body.td("valign='top' style='$tdStyle'")
        id := unique
        body.button("value='SlideDown ($s)' onclick='testWeb_FxTestClient.slideDown(\"$id\", \"$s\");'")
        body.button("value='SlideUp ($s)' onclick='testWeb_FxTestClient.slideUp(\"$id\", \"$s\");'")
        body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
        body.tdEnd
      }
      f("750ms")
      f("500ms")
      f("250ms")
    body.trEnd
    body.tableEnd
  }

  Void queueing()
  {
    body.h2.w("Queueing").h2End
    tdStyle  := "padding-right:1em;"
    divStyle := "margin-top:5px; padding:1em; background:#eef;"
    body.table
    body.tr
    body.td("valign='top' style='$tdStyle'")
      id := unique
      body.button("value='FadeOut/FadeIn (400ms)' onclick='testWeb_FxTestClient.queue1(\"$id\", \"400ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      id = unique
      body.button("value='SlideUp/SlideDown (400ms)' onclick='testWeb_FxTestClient.queue2(\"$id\", \"400ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      id = unique
      body.button("value='Fade/Slide#1 (400ms)' onclick='testWeb_FxTestClient.queue3(\"$id\", \"400ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      id = unique
      body.button("value='Fade/Slide#2 (400ms)' onclick='testWeb_FxTestClient.queue4(\"$id\", \"400ms\");'")
      body.div("id='$id' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.trEnd
    body.tr
    body.td("valign='top' style='$tdStyle'")
      a := unique
      b := unique
      body.button("value='Complex#1 (400ms)' onclick='testWeb_FxTestClient.queue5(\"$a\",\"$b\",\"400ms\");'")
      body.div("id='$a' style='$divStyle'").w("Hello!").divEnd
      body.div("id='$b' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      a = unique
      b = unique
      body.button("value='Complex#2 (400ms)' onclick='testWeb_FxTestClient.queue6(\"$a\",\"$b\",\"400ms\");'")
      body.div("id='$a' style='$divStyle'").w("Hello!").divEnd
      body.div("id='$b' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.td("valign='top' style='$tdStyle'")
      a = unique
      b = unique
      body.button("value='Complex#3 (400ms)' onclick='testWeb_FxTestClient.queue7(\"$a\",\"$b\",\"400ms\");'")
      body.div("id='$a' style='$divStyle'").w("Hello!").divEnd
      body.div("id='$b' style='$divStyle'").w("Hello!").divEnd
      body.tdEnd
    body.trEnd
    body.tableEnd
  }
}

@js
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
// Fading
//////////////////////////////////////////////////////////////////////////

  static Void fadeTo(Str id, Decimal opacity, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.fadeTo(opacity, Duration(dur)) |fx|
    {
      end := Duration.now
      op  := fx.elem.style->opacity
      fx.elem.html = "opacity: $op (${(end-start).toMillis}ms)"
    }
  }

  static Void fadeToChain(Str id, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    Doc.elem(id).effect.fadeOut(d) |fx|
    {
      t2 := Duration.now
      fx.fadeIn(d) |fx2|
      {
        t3 := Duration.now
        fx.elem.html = "Hello! (${(t2-t1).toMillis}ms, ${(t3-t2).toMillis}ms)"
      }
    }
  }

  static Void animateOpacityChain(Str id, Str dur)
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

//////////////////////////////////////////////////////////////////////////
// Slide
//////////////////////////////////////////////////////////////////////////

  static Void slideDown(Str id, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.slideDown(Duration(dur)) |fx|
    {
      end := Duration.now
      fx.elem.html = "Hello! (${(end-start).toMillis}ms)"
    }
  }

  static Void slideUp(Str id, Str dur)
  {
    start := Duration.now
    Doc.elem(id).effect.slideUp(Duration(dur)) |fx|
    {
      end := Duration.now
      fx.elem.html = "Hello! (${(end-start).toMillis}ms)"
    }
  }

//////////////////////////////////////////////////////////////////////////
// Queueing
//////////////////////////////////////////////////////////////////////////

  static Void queue1(Str id, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    t2 := 0ms
    Doc.elem(id).effect.fadeOut(d) |fx| { t2 = Duration.now }
    Doc.elem(id).effect.fadeIn(d)  |fx|
    {
      t3 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms, ${(t3-t2).toMillis}ms)"
    }
  }

  static Void queue2(Str id, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    t2 := 0ms
    Doc.elem(id).effect.slideUp(d)   |fx| { t2 = Duration.now }
    Doc.elem(id).effect.slideDown(d) |fx|
    {
      t3 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms, ${(t3-t2).toMillis}ms)"
    }
  }

  static Void queue3(Str id, Str dur)
  {
    fx := Doc.elem(id).effect
    d  := Duration(dur)
    t1 := Duration.now
    fx.fadeOut(d)
    fx.fadeIn(d)
    fx.slideUp(d)
    fx.slideDown(d) |fx2|
    {
      t2 := Duration.now
      fx2.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
  }

  static Void queue4(Str id, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    Doc.elem(id).effect.fadeOut(d) |fx1| {
      fx1.fadeIn(d) |fx2| {
        fx2.slideUp(d) |fx3| {
          fx3.slideDown(d) |fx4| {
            t2 := Duration.now
            fx4.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
          }
        }
      }
    }
  }

  static Void queue5(Str a, Str b, Str dur)
  {
    d   := Duration(dur)
    t1  := Duration.now
    fxa := Doc.elem(a).effect
    fxb := Doc.elem(b).effect
    fxa.fadeOut(d)
    fxa.fadeIn(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
    fxb.fadeOut(d)
    fxb.fadeIn(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
  }

  static Void queue6(Str a, Str b, Str dur)
  {
    d  := Duration(dur)
    t1 := Duration.now
    Doc.elem(a).effect.fadeOut(d)
    Doc.elem(a).effect.fadeIn(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
    Doc.elem(b).effect.fadeOut(d)
    Doc.elem(b).effect.fadeIn(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
  }

  static Void queue7(Str a, Str b, Str dur)
  {
    d   := Duration(dur)
    t1  := Duration.now
    fxa := Doc.elem(a).effect
    fxb := Doc.elem(b).effect
    fxa.fadeOut(d)
    fxa.fadeIn(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
    fxb.slideUp(d)
    fxb.slideDown(d) |fx|
    {
      t2 := Duration.now
      fx.elem.html = "Hello! (${(t2-t1).toMillis}ms)"
    }
  }
}