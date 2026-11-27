//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

class JavaTest : Test
{
  Void testElemBasics()
  {
    elem := Elem {}
    verifyEq(elem.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(elem.tagName, "div")
    verifyAttrProp(elem, "id", null, "")  // to match js behavoir
    verifyAttrProp(elem, "name", null)
    verifyEq(elem.text,  "")

    elem.id = "foo"
    elem.text = "yabba dabba"
    verifyAttrProp(elem, "id", "foo")
    verifyEq(elem.text, "yabba dabba")

    a := Elem {}
    b := Elem {}
    c := Elem {}
    d := Elem {}
    e := Elem {}

    verifyEq(a.parent, null)
    verifyEq(elem.hasChildren, false)
    elem.add(a)
    verifyEq(elem.hasChildren, true)
    verifyEq(elem.children.size, 1)
    verifyEq(a.parent, elem)
    elem.add(b); verifyEq(elem.children.size, 2)
    elem.add(c); verifyEq(elem.children.size, 3)

    verifyEq(elem.firstChild, a)
    verifyEq(elem.lastChild,  c)
    verifyEq(elem.containsChild(b), true)
    verifyEq(a.prevSibling, null)
    verifyEq(b.prevSibling, a)
    verifyEq(b.nextSibling, c)
    verifyEq(c.nextSibling, null)

    elem.insertBefore(d, c)
    verifyEq(elem.children[2], d)

    elem.replace(d, e)
    verifyEq(elem.children[2], e)
    verifyEq(d.parent, null)
    verifyEq(elem.children.contains(d), false)

    elem.remove(a)
    verifyEq(a.parent, null)
    verifyEq(elem.children.contains(a), false)
  }

  Void testAttrs()
  {
    elem := Elem {}

    // an attr is reflected by the prop of the same name until the
    // prop is set
    verifyEq(elem.attrs.size, 0)
    verifyAttrProp(elem, "foo", null)
    elem["foo"] = "bar"
    verifyAttrProp(elem, "foo", "bar")

    // setProp never sets the attr
    elem->bar = false
    elem->zoo = 12
    verifyAttrProp(elem, "bar", null, false)
    verifyAttrProp(elem, "zoo", null, 12)
    elem->foo = "prop"
    verifyAttrProp(elem, "foo", "bar", "prop")
    verifyEq(elem.attrs, Str:Str["foo":"bar"])

    // attrs keep the order they were first set, class included
    elem.setAttr("title", "t").setAttr("class", "a b").setAttr("href", "#").setAttr("title", "u")
    verifyEq(elem.attrs.keys, ["foo", "title", "class", "href"])
    verifyEq(elem.attrs["title"], "u")
    elem.style.addClass("c")
    verifyEq(elem.attrs["class"], "a b c")
    elem.removeAttr("title").setAttr("href", null)
    verifyEq(elem.attrs.keys, ["foo", "class"])
    verifyEq(elem.attr("href"), null)

    // class added thru style with no attr set is an attr too
    x := Elem {}
    x.style.addClass("z")
    verifyEq(x.attrs, Str:Str["class":"z"])

    // TODO: how do we handle camel case????
    // elem->fooBar = "ok"
    // verifyEq(elem->fooBar, "ok")
    // verifyEq(elem["foo-bar"], "ok")
    // verifyEq(elem.get("foo-bar"), "ok")
    //
    // elem.set("foo-bar", "ko")
    // verifyEq(elem->fooBar, "ko")
    // verifyEq(elem["foo-bar"], "ko")
    //
    // elem->fooBar = "xx"
    // verifyEq(elem->fooBar, "xx")
    // verifyEq(elem["foo-bar"], "xx")
    //
    // elem->_foo_bazPaw = "5"
    // verifyEq(elem->_foo_bazPaw, "5")
    // verifyEq(elem["_foo_baz-paw"], "5")
  }

  Void testHtml()
  {
    // children are serialized as a browser does for innerHTML
    root := Elem("div")
    verifyEq(root.html, "")
    p := Elem("p") { it.setAttr("title", "a \"b\" <c> & d"); it.setAttr("class", "x y") }
    p.add(DomText("1 < 2 & \"3\" > 2"))
    root.add(p)
    root.add(DomText("tail"))
    verifyEq(root.html, Str<|<p title="a &quot;b&quot; &lt;c&gt; &amp; d" class="x y">1 &lt; 2 &amp; "3" &gt; 2</p>tail|>)

    // a prop is not an attr; an attr with no value is empty
    in := Elem("input") { it.setAttr("type", "checkbox"); it.setAttr("disabled", "") }
    in->checked = true
    root = Elem("div") { in, Elem("br"), Elem("span"), }
    verifyEq(root.html, Str<|<input type="checkbox" disabled=""><br><span></span>|>)

    // only an html void element has no end tag
    svg := Elem("svg", Svg.ns) { Elem("rect", Svg.ns) { it.setAttr("width", "20") }, Elem("g", Svg.ns), }
    verifyEq(Elem("div").add(svg).html, Str<|<svg><rect width="20"></rect><g></g></svg>|>)
  }

  Void testComment()
  {
    // a comment is a node which is not drawn: html shows it, and an
    // element with only comments is empty
    root := Elem("div")
    c := DomComment("mark")
    root.add(Elem("p") { DomComment(), }).add(c)
    verifyEq(c.typeof, DomComment#)
    verifyEq(c.text, "mark")
    verifySame(c.parentNode, root)
    verifyEq(root.html, "<p><!----></p><!--mark-->")
    verifyEq(root.querySelectorAll("p:empty").size, 1)
    verifyEq(root.children.size, 1)

    // a clone is a comment with the same text
    copy := c.clone
    verifyEq(copy.typeof, DomComment#)
    verifyEq(copy.text, "mark")
    verifyNull(copy.parentNode)
  }

  Void testHtmlSet()
  {
    // markup is parsed into the children, replacing what was there
    root := Elem("div") { Elem("i"), }
    root.html = Str<|a &lt; b<P Title='x &amp; "y"' hidden data-n=3>one<br>two<b>three</b></p><!-- kept -->tail &#65;&#x42;&nope;|>
    verifyEq(root.html, Str<|a &lt; b<p title="x &amp; &quot;y&quot;" hidden="" data-n="3">one<br>two<b>three</b></p><!-- kept -->tail AB&amp;nope;|>)
    verifyEq(root.childNodes.size, 4)
    verifyEq(root.childNodes[2].typeof, DomComment#)
    verifyEq(root.childNodes[2].text, " kept ")
    p := root.children.first
    verifyEq(p.tagName, "p")
    verifyEq(p.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(p.attr("title"), "x & \"y\"")
    verifySame(p.parent, root)
    verifyEq(p.children.map |Elem x->Str| { x.tagName }, ["br", "b"])

    // empty
    root.html = ""
    verifyEq(root.childNodes.size, 0)

    // an end tag closes the nearest of its name, and never the root
    root.html = "<ul><li>a<li>b</ul>c</div>d<span/>e"
    verifyEq(root.html, "<ul><li>a<li>b</li></li></ul>cd<span>e</span>")

    // svg keeps its names and closes itself, and is html again in a
    // foreignObject
    root.html = Str<|<svg viewBox="0 0 4 4"><linearGradient/><path d='M0 0' /><foreignObject><P>x</P></foreignObject></svg><B>y</B>|>
    verifyEq(root.html, Str<|<svg viewBox="0 0 4 4"><linearGradient></linearGradient><path d="M0 0"></path><foreignObject><p>x</p></foreignObject></svg><b>y</b>|>)
    kids := root.children.first.children
    verifyEq(kids.map |Elem x->Uri| { x.ns }, [Svg.ns, Svg.ns, Svg.ns])
    verifyEq(kids[2].children.first.ns, `http://www.w3.org/1999/xhtml`)
    verifyEq(root.children.last.ns, `http://www.w3.org/1999/xhtml`)

    // assigned to an svg element, the children are svg
    icon := Elem("svg", Svg.ns)
    icon.html = Str<|<path d='M20 6 9 17l-5-5' /><circle cx='4' cy='20' r='2' />|>
    verifyEq(icon.html, Str<|<path d="M20 6 9 17l-5-5"></path><circle cx="4" cy="20" r="2"></circle>|>)
    verifyEq(icon.children.map |Elem x->Uri| { x.ns }, [Svg.ns, Svg.ns])

    // fromHtml
    verifyEq(Elem.fromHtml("<em class='a b'>x</em>").attr("class"), "a b")
  }

  Void testStyleBasics()
  {
    elem := Elem {}
    s := elem.style
    verifyEq(s.classes.size, 0)

    s.addClass("foo")
    verifyEq(s.classes.size, 1)
    verifyEq(s.hasClass("foo"), true)
    verifyEq(s.hasClass("bar"), false)

    s.addClass("bar cool")
    verifyEq(s.classes.size, 3)
    verifyEq(s.hasClass("foo"),  true)
    verifyEq(s.hasClass("bar"),  true)
    verifyEq(s.hasClass("cool"), true)

    s.removeClass("bar")
    verifyEq(s.classes.size, 2)
    verifyEq(s.hasClass("foo"),  true)
    verifyEq(s.hasClass("bar"),  false)
    verifyEq(s.hasClass("cool"), true)

    s.removeClass("nada")
    verifyEq(s.classes.size, 2)

    verifyEq(s->background, null)
    s->background = "#eee"
    verifyEq(s->background, "#eee")
  }

  Void testClassAttr()
  {
    // test class handling via xxxAttr methods
    elem := Elem {}
    verifyEq(elem.attrs.size, 0)
    verifyEq(elem.attr("class"), null)

    // add a class
    elem.style.addClass("foo")
    verifyEq(elem.style.hasClass("foo"), true)
    verifyEq(elem.attr("class"), "foo")
    verifyEq(elem.attrs.size, 1)

    // should replace classes
    elem.setAttr("class", "bar zar")
    verifyEq(elem.style.hasClass("foo"), false)
    verifyEq(elem.style.hasClass("bar"), true)
    verifyEq(elem.style.hasClass("zar"), true)
    verifyEq(elem.attr("class"), "bar zar")

    // should remove all classes
    elem.removeAttr("class")
    verifyEq(elem.style.classes.size, 0)
    verifyEq(elem.attr("class"), null)
  }

  Void testQuerySelector()
  {
    Elem? root
    Elem? a
    Elem? b

    root = Elem {
      it.setAttr("foo", "notme")
      a = Elem { it.setAttr("foo", "bar") },
      b = Elem { it.setAttr("foo", "bar") },
    }

    m := root.querySelectorAll("[foo]")
    verifyEq(m.size, 2)
    verifySame(m[0], a)
    verifySame(m[1], b)

    verifySame(root.querySelector("[foo]"), a)

    // match on value, and on every attribute of the selector
    b.setAttr("foo", "baz")
    b.setAttr("x", "y z")
    verifySame(root.querySelector("[foo=baz]"), b)
    verifySame(root.querySelector("[foo=\"bar\"]"), a)
    verifySame(root.querySelector("[foo='bar']"), a)
    verifyEq(root.querySelectorAll("[foo=nope]").size, 0)
    verifySame(root.querySelector("[foo][x]"), b)
    verifySame(root.querySelector("[foo=baz][x]"), b)
    verifyEq(root.querySelectorAll("[foo=bar][x]").size, 0)
    verifyEq(root.querySelectorAll("[x]").size, 1)
  }

  Void testSelectors()
  {
    root := Elem {}
    root.html =
      Str<|<ul id="list" class="menu big">
             <li class="item first" data-k="a b">A</li>
             <li class="item" data-k="en-US" disabled>B<span class="hover:x">s</span></li>
             <li class="item last" title="Say Hi">C<input type="checkbox" checked></li>
           </ul>
           <p></p><p id="p2">t</p>|>
    ul := root.firstChild
    li := ul.children
    span := li[1].firstChild
    input := li[2].firstChild
    p := root.children[1..2]

    //        scope selector                   matches
    verifySel(root, "ul",                      [ul])
    verifySel(root, "UL",                      [ul])
    verifySel(root, "*",                       [ul, li[0], li[1], span, li[2], input, p[0], p[1]])
    verifySel(root, "#list",                   [ul])
    verifySel(root, "ul#list.menu.big",        [ul])
    verifySel(root, ".menu.nope",              Elem[,])
    verifySel(root, ".item",                   li)
    verifySel(root, "li.first, li.last",       [li[0], li[2]])
    verifySel(root, "p, ul",                   [ul, p[0], p[1]])
    verifySel(root, "ul li",                   li)
    verifySel(root, "ul span",                 [span])
    verifySel(root, "ul > span",               Elem[,])
    verifySel(root, "ul > li > span",          [span])
    verifySel(root, "ul>li>span",              [span])
    verifySel(root, ".first + li",             [li[1]])
    verifySel(root, ".first ~ li",             [li[1], li[2]])
    verifySel(root, "ul + p",                  [p[0]])
    verifySel(root, "ul ~ p",                  p)
    verifySel(root, ":scope > p",              p)
    verifySel(ul,   ":scope > li.last",        [li[2]])
    verifySel(ul,   "div li",                  li)   // ancestors outside the scope still match

    // attributes
    verifySel(root, "[data-k]",                [li[0], li[1]])
    verifySel(root, "[data-k='a b']",          [li[0]])
    verifySel(root, Str<|[ data-k = "a b" ]|>, [li[0]])
    verifySel(root, "[data-k~=b]",             [li[0]])
    verifySel(root, "[data-k|=en]",            [li[1]])
    verifySel(root, "[data-k^=en]",            [li[1]])
    verifySel(root, "[data-k\$=US]",           [li[1]])
    verifySel(root, "[data-k*=n-U]",           [li[1]])
    verifySel(root, "[title='say hi']",        Elem[,])
    verifySel(root, "[title='say hi' i]",      [li[2]])
    verifySel(root, "li[class~=item][title]",  [li[2]])
    verifySel(root, "[class='item first']",    [li[0]])
    verifySel(root, Str<|.hover\:x|>,          [span])

    // pseudo-classes
    verifySel(root, "li:first-child",          [li[0]])
    verifySel(root, "li:last-child",           [li[2]])
    verifySel(root, "span:only-child",         [span])
    verifySel(root, "li:nth-child(2)",         [li[1]])
    verifySel(root, "li:nth-child(odd)",       [li[0], li[2]])
    verifySel(root, "li:nth-child(even)",      [li[1]])
    verifySel(root, "li:nth-child(n+2)",       [li[1], li[2]])
    verifySel(root, "li:nth-child(-n + 2)",    [li[0], li[1]])
    verifySel(root, "li:nth-last-child(1)",    [li[2]])
    verifySel(root, "li:not(.first)",          [li[1], li[2]])
    verifySel(root, "li:not(.first, .last)",   [li[1]])
    verifySel(root, "li:is(.first, .last)",    [li[0], li[2]])
    verifySel(root, "p:empty",                 [p[0]])
    verifySel(root, ":disabled",               [li[1]])
    verifySel(root, "li:enabled",              [li[0], li[2]])
    verifySel(root, ":checked",                [input])
    input.setProp("checked", false)
    verifySel(root, ":checked",                Elem[,])

    // closest
    verifySame(span.closest("span"), span)
    verifySame(span.closest("li"), li[1])
    verifySame(span.closest(".menu"), ul)
    verifySame(span.closest("ul > li"), li[1])
    verifySame(span.closest(":not(span):not(li)"), ul)
    verifyEq(span.closest("p"), null)

    // unsupported or invalid selectors raise ArgErr
    ["", "ul >", "> li", "li,", "[x", "[x=]", "[x!=y]", "li:hover", "li::before", "li:nth-child(x)", "a b)", ".", "#"].each |s|
    {
      verifyErr(ArgErr#) { root.querySelector(s) }
    }
  }

  private Void verifySel(Elem scope, Str selector, Elem[] expected)
  {
    actual := scope.querySelectorAll(selector)
    verifyEq(actual.size, expected.size, selector)
    actual.each |e, i| { verifySame(e, expected[i], selector) }
    verifySame(scope.querySelector(selector), expected.first, selector)
  }

  Void testClone()
  {
    a := Elem("section")
    a.html = Str<|<p id="x" class="a b">hi <b>there</b></p>|>
    a.style->color = "red"
    a.setProp("foo", "bar")
    hits := 0
    a.onEvent("click", false) |e| { hits++ }

    deep := a.clone
    verifyNotSame(deep, a)
    verifyEq(deep.parent, null)
    verifyEq(deep.tagName, "section")
    verifyEq(deep.html, a.html)
    verifyNotSame(deep.firstChild, a.firstChild)
    verifyEq(deep.style->color, "red")
    verifyEq(deep.prop("foo"), null)
    deep.dispatchEvent(Event.makeCustom("click"))
    verifyEq(hits, 0)

    shallow := a.clone(false)
    verifyEq(shallow.tagName, "section")
    verifyEq(shallow.html, "")

    text := a.firstChild.firstNode.clone
    verifyEq(text.typeof, DomText#)
    verifyEq(text.text, "hi ")
    verifyEq(text.parentNode, null)
  }

//////////////////////////////////////////////////////////////////////////
// Document
//////////////////////////////////////////////////////////////////////////

  ** Get the document body after removing all its children
  private Elem body()
  {
    doc := Win.cur.doc
    doc.body.removeAll
    return doc.body
  }

  Void testDoc()
  {
    win := Win.cur
    doc := win.doc
    verifySame(Win.cur, win)
    verifySame(win.doc, doc)
    verifySame(win.top, win)
    verifyEq(win.parent, null)
    verifyEq(doc.body.tagName, "body")
    verifyEq(doc.head.tagName, "head")
    verifySame(doc.body.parent, doc.head.parent)
    verifyEq(doc.body.parent.tagName, "html")
    verifySame(doc.body.parent.parentNode, doc)

    doc.title = "Hi"
    verifyEq(doc.title, "Hi")

    body := body
    body.html = Str<|<div id="a" class="x"><span id="b">s</span></div><p id="c"></p>|>
    a := body.firstChild
    verifySame(doc.elemById("a"), a)
    verifySame(doc.elemById("b"), a.firstChild)
    verifyEq(doc.elemById("nope"), null)
    verifySame(doc.querySelector("body > .x"), a)
    verifySame(doc.querySelector("html"), body.parent)
    verifyEq(doc.querySelectorAll("#a, #c").size, 2)
    verifySame(a.firstChild.closest("body"), body)

    e := doc.createElem("input", ["type":"text"])
    verifyEq(e.tagName, "input")
    verifyEq(e.attr("type"), "text")
    verifyEq(e.parent, null)

    // each thread has its own window
    other := concurrent::Actor(concurrent::ActorPool()) |msg| { Unsafe(Win.cur) }.send(null).get(5sec)->val
    verifyNotSame(other, win)
  }

  ** Events on a node in the document also reach the window's listeners
  Void testWinEvents()
  {
    body := body
    kid := Elem {}
    body.add(kid)
    acc := Str[,]
    win := Win.cur
    cap := win.onEvent("ping", true)  |e| { acc.add("win-capture") }
    bub := win.onEvent("ping", false) |e| { acc.add("win-bubble") }
    body.onEvent("ping", false) |e| { acc.add("body") }
    kid.onEvent("ping", false) |e| { acc.add("kid") }

    kid.dispatchEvent(Event.makeCustom("ping", ["bubbles":true]))
    verifyEq(acc, ["win-capture", "kid", "body", "win-bubble"])

    acc.clear
    kid.dispatchEvent(Event.makeCustom("ping"))
    verifyEq(acc, ["win-capture", "kid"])

    // a node outside the document does not reach the window
    acc.clear
    body.remove(kid)
    kid.dispatchEvent(Event.makeCustom("ping", ["bubbles":true]))
    verifyEq(acc, ["kid"])

    win.removeEvent("ping", true, cap)
    win.removeEvent("ping", false, bub)
    body.add(kid)
    acc.clear
    kid.dispatchEvent(Event.makeCustom("ping", ["bubbles":true]))
    verifyEq(acc, ["kid", "body"])
  }

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

  Void testFocus()
  {
    doc := Win.cur.doc
    body := body
    body.html = Str<|<input id="a"><button id="b">B</button><div id="c">C</div><div id="d" tabindex="-1">D</div>
                     <a id="e">E</a><a id="f" href="#">F</a><button id="g" disabled>G</button>
                     <div hidden><input id="h"></div>|>
    a := doc.elemById("a"); b := doc.elemById("b"); c := doc.elemById("c"); d := doc.elemById("d")
    acc := Str[,]
    ["focus", "blur", "focusin", "focusout"].each |type|
    {
      body.onEvent(type, false) |e| { acc.add("body $type $e.target.id") }
      [a, b, d].each |x| { x.onEvent(type, false) |e| { acc.add("$x.id $type from:" + e.relatedTarget?.id) } }
    }

    verifySame(doc.activeElem, body)
    verifyEq(a.hasFocus, false)

    a.focus
    verifySame(doc.activeElem, a)
    verifyEq(a.hasFocus, true)
    verifyEq(acc, ["a focus from:null", "a focusin from:null", "body focusin a"])
    verifySame(body.querySelector(":focus"), a)
    verifyEq(body.querySelectorAll(":focus-within").size, 1)
    verifySame(doc.querySelector("body:focus-within"), body)

    // doing it again has no effect
    acc.clear
    a.focus
    verifyEq(acc, Str[,])

    // moving focus fires blur, focusout, focus, focusin in that order
    b.focus
    verifySame(doc.activeElem, b)
    verifyEq(acc, ["a blur from:b", "a focusout from:b", "body focusout a",
                   "b focus from:a", "b focusin from:a", "body focusin b"])

    // focusing an element which is not focusable does nothing
    acc.clear
    [c, doc.elemById("e"), doc.elemById("g"), doc.elemById("h")].each |x|
    {
      x.focus
      verifySame(doc.activeElem, b, x.id)
    }
    verifyEq(acc, Str[,])

    // a tabindex or an href makes an element focusable
    d.focus
    verifySame(doc.activeElem, d)
    doc.elemById("f").focus
    verifySame(doc.activeElem, doc.elemById("f"))

    // blur only does something on the focused element
    d.focus
    acc.clear
    a.blur
    verifyEq(acc, Str[,])
    d.blur
    verifySame(doc.activeElem, body)
    verifyEq(acc, ["d blur from:null", "d focusout from:null", "body focusout d"])

    // focus and blur also work thru invoke
    a.invoke("focus")
    verifySame(doc.activeElem, a)
    a.invoke("blur")
    verifySame(doc.activeElem, body)

    // an element removed from the document loses focus without
    // firing events, and cannot be focused
    a.focus
    acc.clear
    body.remove(a)
    verifySame(doc.activeElem, body)
    verifyEq(a.hasFocus, false)
    a.focus
    verifyEq(a.hasFocus, false)
    verifyEq(acc, Str[,])
  }

//////////////////////////////////////////////////////////////////////////
// Timers
//////////////////////////////////////////////////////////////////////////

  Void testTimers()
  {
    win := Win.cur
    acc := Str[,]

    // nothing runs until runTimers is called
    win.setTimeout(10ms) |w| { verifySame(w, win); acc.add("10ms") }
    win.setTimeout(0ms) { acc.add("0ms") }
    win.reqAnimationFrame |w| { verifySame(w, win); acc.add("frame") }
    gone := win.setTimeout(5ms) { acc.add("gone") }
    verifyEq(acc, Str[,])

    // animation frames run first, then the timers which are due
    win.clearTimeout(gone)
    win.runTimers
    verifyEq(acc, ["frame", "0ms"])
    win.runTimers(9ms)
    verifyEq(acc, ["frame", "0ms"])
    win.runTimers(1ms)
    verifyEq(acc, ["frame", "0ms", "10ms"])
    win.runTimers(1hr)
    verifyEq(acc, ["frame", "0ms", "10ms"])

    // timers run in order of due time; ties run in the order queued
    acc.clear
    win.setTimeout(30ms) { acc.add("c") }
    win.setTimeout(10ms) { acc.add("a1") }
    win.setTimeout(20ms) { acc.add("b") }
    win.setTimeout(10ms) { acc.add("a2") }
    win.runTimers(1sec)
    verifyEq(acc, ["a1", "a2", "b", "c"])

    // a timer queued by a timer runs if it comes due in time, but a
    // frame requested inside a frame waits for the next call
    acc.clear
    win.setTimeout(10ms) { acc.add("outer"); win.setTimeout(10ms) { acc.add("inner") }; win.setTimeout(1sec) { acc.add("late") } }
    win.reqAnimationFrame { acc.add("f1"); win.reqAnimationFrame { acc.add("f2") } }
    win.runTimers(100ms)
    verifyEq(acc, ["f1", "outer", "inner"])
    win.runTimers(1sec)
    verifyEq(acc, ["f1", "outer", "inner", "f2", "late"])

    // an interval repeats until it is cleared
    acc.clear
    n := 0
    id := win.setInterval(10ms) { n++ }
    win.runTimers(35ms)
    verifyEq(n, 3)
    win.runTimers(5ms)
    verifyEq(n, 4)
    win.clearInterval(id)
    win.runTimers(1sec)
    verifyEq(n, 4)

    // timers which requeue themselves forever raise an error
    spinning = true
    win.setTimeout(0ms) |w| { spin(w) }
    verifyErr(Err#) { win.runTimers }
    spinning = false
    win.runTimers
  }

  private Void spin(Win w) { if (spinning) w.setTimeout(0ms) |x| { spin(x) } }

  private Bool spinning

//////////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////////

  Void testInvoke()
  {
    body := body
    body.html = Str<|<div id="a" class="x"><span>s</span></div>|>
    a := body.firstChild
    span := a.firstChild

    verifyEq(a.invoke("matches", [".x"]), true)
    verifyEq(a.invoke("matches", ["span"]), false)
    verifySame(span.invoke("closest", ["div"]), a)
    verifyEq(a.invoke("contains", [span]), true)
    verifyEq(span.invoke("contains", [a]), false)
    verifyEq(a.invoke("hasAttribute", ["id"]), true)
    verifyEq(a.invoke("getAttribute", ["id"]), "a")
    a.invoke("setAttribute", ["title", "t"])
    verifyEq(a.attr("title"), "t")
    a.invoke("removeAttribute", ["title"])
    verifyEq(a.attr("title"), null)
    verifyEq(a.invoke("toggleAttribute", ["hidden"]), true)
    verifyEq(a.attr("hidden"), "")
    verifyEq(a.invoke("checkVisibility"), false)
    verifyEq(a.invoke("toggleAttribute", ["hidden"]), false)
    verifyEq(a.invoke("checkVisibility"), true)
    verifyEq(a.invoke("toggleAttribute", ["hidden", false]), false)
    verifyEq(a.invoke("scrollIntoView"), null)

    // click fires a click event which bubbles
    clicks := 0
    body.onEvent("click", false) |e| { clicks++ }
    span.invoke("click")
    verifyEq(clicks, 1)

    span.invoke("remove")
    verifyEq(span.parent, null)
    verifyEq(a.hasChildren, false)

    verifyErr(UnsupportedErr#) { a.invoke("getBoundingClientRect") }
    verifyErr(ArgErr#) { a.invoke("matches") }
  }

  Void testPopover()
  {
    win := Win.cur
    doc := win.doc
    body := body
    body.html = Str<|<button id="t">T</button>
                     <div id="p" popover><input id="in" autofocus><div id="q" popover>Q</div></div>
                     <div id="r" popover>R</div>
                     <div id="m" popover="manual">M</div>
                     <div id="x">X</div>|>
    t := doc.elemById("t"); p := doc.elemById("p"); q := doc.elemById("q"); r := doc.elemById("r"); m := doc.elemById("m")
    in := doc.elemById("in")
    acc := Str[,]
    [p, q, r, m].each |x|
    {
      x.onEvent("beforetoggle", false) |e| { acc.add("$x.id before " + e["oldState"] + ">" + e["newState"]) }
      x.onEvent("toggle", false) |e| { acc.add("$x.id toggle " + e["newState"]); if (x === q) verifyEq(e["oldState"], "closed") }
    }

    // content inside a closed popover is not rendered or focusable
    verifyEq(in.invoke("checkVisibility"), false)
    in.focus
    verifySame(doc.activeElem, body)

    // show fires beforetoggle immediately, moves focus to the
    // autofocus element, and fires toggle asynchronously
    t.focus
    p.invoke("showPopover")
    verifyEq(acc, ["p before closed>open"])
    verifySame(body.querySelector(":popover-open"), p)
    verifySame(doc.activeElem, in)
    win.runTimers
    verifyEq(acc, ["p before closed>open", "p toggle open"])

    // doing it again has no effect
    acc.clear
    p.invoke("showPopover")
    win.runTimers
    verifyEq(acc, Str[,])

    // showing a nested popover keeps its parent open; showing an
    // unrelated one hides both, innermost first.  Manual popovers
    // are not affected
    q.invoke("showPopover")
    m.invoke("showPopover")
    verifyEq(body.querySelectorAll(":popover-open"), Elem[p, q, m])
    acc.clear
    r.invoke("showPopover")
    verifyEq(body.querySelectorAll(":popover-open"), Elem[r, m])
    verifyEq(acc, ["r before closed>open", "q before open>closed", "p before open>closed"])
    verifySame(doc.activeElem, t)   // focus returns to where it was

    // each popover fires one toggle event, from its first state to its last
    win.runTimers
    verifyEq(acc[3..-1], ["q toggle closed", "m toggle open", "p toggle closed", "r toggle open"])

    // hidePopover and togglePopover
    acc.clear
    r.invoke("hidePopover")
    r.invoke("hidePopover")
    verifyEq(r.invoke("togglePopover"), true)
    verifyEq(r.invoke("togglePopover"), false)
    verifyEq(r.invoke("togglePopover", [false]), false)
    win.runTimers
    verifyEq(acc.findAll |s| { s.contains("before") }, ["r before open>closed", "r before closed>open", "r before open>closed"])
    verifyEq(body.querySelectorAll(":popover-open"), Elem[m])
    m.invoke("hidePopover")

    // a handler can cancel the show
    no := r.onEvent("beforetoggle", false) |e| { e.preventDefault }
    r.invoke("showPopover")
    verifyEq(body.querySelectorAll(":popover-open").size, 0)
    r.removeEvent("beforetoggle", false, no)

    // a popover removed from the document is closed without events
    r.invoke("showPopover")
    win.runTimers
    acc.clear
    body.remove(r)
    verifyEq(r.invoke("matches", [":popover-open"]), false)
    body.add(r)
    verifyEq(r.invoke("matches", [":popover-open"]), false)
    m.invoke("showPopover")
    m.invoke("hidePopover")
    win.runTimers
    verifyEq(acc.findAll |s| { s.startsWith("r ") }, Str[,])

    // errors: not a popover, and not in a document
    verifyErr(Err#) { doc.elemById("x").invoke("showPopover") }
    body.remove(r)
    verifyErr(Err#) { r.invoke("showPopover") }
    win.runTimers
  }

  Void testDialog()
  {
    win := Win.cur
    doc := win.doc
    body := body
    body.html = Str<|<button id="t">T</button><dialog id="d"><button id="ok" autofocus>OK</button></dialog>|>
    t := doc.elemById("t"); d := doc.elemById("d"); ok := doc.elemById("ok")
    acc := Str[,]
    d.onEvent("close", false) |e| { acc.add("close") }
    d.onEvent("cancel", false) |e| { acc.add("cancel") }

    ok.focus
    verifySame(doc.activeElem, body)

    t.focus
    d.invoke("showModal")
    verifyEq(d.attr("open"), "")
    verifySame(body.querySelector(":modal"), d)
    verifySame(doc.activeElem, ok)
    verifyErr(Err#) { d.invoke("show") }

    d.invoke("close", ["yes"])
    verifyEq(d.attr("open"), null)
    verifyEq(d.prop("returnValue"), "yes")
    verifySame(doc.activeElem, t)
    verifyEq(acc, Str[,])
    win.runTimers
    verifyEq(acc, ["close"])
    d.invoke("close")
    win.runTimers
    verifyEq(acc, ["close"])

    // a handler can cancel requestClose
    acc.clear
    d.invoke("show")
    verifyEq(body.querySelector(":modal"), null)
    no := d.onEvent("cancel", false) |e| { e.preventDefault }
    d.invoke("requestClose")
    verifyEq(d.attr("open"), "")
    d.removeEvent("cancel", false, no)
    d.invoke("requestClose")
    win.runTimers
    verifyEq(d.attr("open"), null)
    verifyEq(acc, ["cancel", "cancel", "close"])

    verifyErr(UnsupportedErr#) { t.invoke("showModal") }
  }

  Void testPointerCapture()
  {
    body := body
    body.html = "<div id='a'></div><div id='b'></div>"
    a := body.children[0]; b := body.children[1]
    acc := Str[,]
    ["gotpointercapture", "lostpointercapture"].each |type|
    {
      body.onEvent(type, false) |e| { acc.add("$e.target.id $type " + e["pointerId"]) }
    }

    verifyEq(a.invoke("hasPointerCapture", [1]), false)
    a.invoke("setPointerCapture", [1])
    a.invoke("setPointerCapture", [1])
    verifyEq(a.invoke("hasPointerCapture", [1]), true)
    verifyEq(a.invoke("hasPointerCapture", [2]), false)
    verifyEq(acc, ["a gotpointercapture 1"])

    // capturing on another element takes it from the first
    b.invoke("setPointerCapture", [1])
    verifyEq(a.invoke("hasPointerCapture", [1]), false)
    verifyEq(acc, ["a gotpointercapture 1", "a lostpointercapture 1", "b gotpointercapture 1"])

    // only the capturing element can release
    acc.clear
    a.invoke("releasePointerCapture", [1])
    verifyEq(acc, Str[,])
    b.invoke("releasePointerCapture", [1])
    verifyEq(acc, ["b lostpointercapture 1"])
    verifyEq(b.invoke("hasPointerCapture", [1]), false)
  }

//////////////////////////////////////////////////////////////////////////
// MutationObserver
//////////////////////////////////////////////////////////////////////////

  Void testMutationObserver()
  {
    win := Win.cur
    root := Elem {}
    root.html = "<p id='p'>one</p><b>two</b>"
    p := root.firstChild
    b := root.lastChild
    text := p.firstNode

    calls := MutationRec[][,]
    mo := MutationObserver(|MutationRec[] recs| { calls.add(recs) })
    verifyErr(ArgErr#) { mo.observe(root, ["subtree":true]) }
    mo.observe(root, ["childList":true, "attrs":true, "charData":true, "subtree":true, "attrOldVal":true, "charDataOldVal":true])

    // records are queued until runTimers
    i := Elem("i")
    root.insertBefore(i, b)
    p.setAttr("title", "t")
    p.setAttr("title", "u")
    p.style.addClass("x y")
    p.style.addClass("x")
    p.style.removeClass("y")
    text.text = "uno"
    root.remove(i)
    p.removeAttr("title")
    p.removeAttr("nope")
    verifyEq(calls.size, 0)
    win.runTimers
    verifyEq(calls.size, 1)
    recs := calls[0]
    verifyRec(recs[0], "childList", root, DomNode[i], DomNode[,], null, null)
    verifySame(recs[0].prevSibling, p)
    verifySame(recs[0].nextSibling, b)
    verifyRec(recs[1], "attrs",     p,    DomNode[,], DomNode[,], "title", null)
    verifyRec(recs[2], "attrs",     p,    DomNode[,], DomNode[,], "title", "t")
    verifyRec(recs[3], "attrs",     p,    DomNode[,], DomNode[,], "class", null)
    verifyRec(recs[4], "attrs",     p,    DomNode[,], DomNode[,], "class", "x y")
    verifyRec(recs[5], "charData",  text, DomNode[,], DomNode[,], null, "one")
    verifyRec(recs[6], "childList", root, DomNode[,], DomNode[i], null, null)
    verifySame(recs[6].prevSibling, p)
    verifySame(recs[6].nextSibling, b)
    verifyRec(recs[7], "attrs",     p,    DomNode[,], DomNode[,], "title", "u")
    verifyEq(recs.size, 8)

    // no callback when there are no records
    win.runTimers
    verifyEq(calls.size, 1)

    // takeRecs returns the queued records without a callback
    root.removeAll
    taken := mo.takeRecs
    verifyEq(taken.size, 1)
    verifyRec(taken[0], "childList", root, DomNode[,], DomNode[p, b], null, null)
    win.runTimers
    verifyEq(calls.size, 1)

    // options are respected: no subtree, an attr filter, no old value
    mo.disconnect
    mo.observe(root, ["attrs":true, "attrFilter":["a"]])
    root.add(p)
    p.setAttr("a", "1")
    root.setAttr("b", "1")
    root.setAttr("a", "1")
    root.setAttr("a", "2")
    taken = mo.takeRecs
    verifyEq(taken.size, 2)
    verifyRec(taken[1], "attrs", root, DomNode[,], DomNode[,], "a", null)

    // nothing is recorded after disconnect
    mo.disconnect
    root.setAttr("a", "3")
    verifyEq(mo.takeRecs.size, 0)
    win.runTimers
    verifyEq(calls.size, 1)
  }

  private Void verifyRec(MutationRec r, Str type, DomNode target, DomNode[] added, DomNode[] removed, Str? attr, Str? oldVal)
  {
    verifyEq(r.type, type)
    verifySame(r.target, target)
    verifyEq(r.added, added)
    verifyEq(r.removed, removed)
    verifyEq(r.attr, attr)
    verifyEq(r.oldVal, oldVal)
  }

//////////////////////////////////////////////////////////////////////////
// Window State
//////////////////////////////////////////////////////////////////////////

  Void testStorage()
  {
    win := Win.cur
    s := win.sessionStorage
    s.clear
    verifySame(win.sessionStorage, s)
    verifyNotSame(win.localStorage, s)
    verifyEq(s.size, 0)
    verifyEq(s["a"], null)
    s["a"] = "x"
    s["b"] = 3
    verifyEq(s.size, 2)
    verifyEq(s["a"], "x")
    verifyEq(s["b"], 3)
    verifyEq(s.keys, ["a", "b"])
    verifyEq(s.key(1), "b")
    verifyEq(s.key(2), null)
    s.remove("a")
    verifyEq(s.keys, ["b"])
    s.clear
    verifyEq(s.size, 0)
    verifyEq(win.localStorage.size, 0)
  }

  Void testHistory()
  {
    win := Win.cur
    pops := Obj?[,]
    f := win.onEvent("popstate", false) |e| { pops.add(e.stash["n"]) }
    start := win.uri

    win.hisPushState("A", `/a`, ["n":1])
    win.hisPushState("B", `/b`, ["n":2])
    verifyEq(win.uri, `/b`)
    verifyEq(win.hisState["n"], 2)
    win.hisReplaceState("B", `/b2`, ["n":22])
    verifyEq(win.uri, `/b2`)

    // back and forward fire popstate asynchronously
    win.hisBack
    verifyEq(win.uri, `/a`)
    verifyEq(pops, Obj?[,])
    win.runTimers
    verifyEq(pops, Obj?[1])
    win.hisForward
    win.hisForward
    win.runTimers
    verifyEq(win.uri, `/b2`)
    verifyEq(pops, Obj?[1, 22])

    // pushing a new entry drops the forward history
    win.hisBack
    win.hyperlink(`/c`)
    win.hisForward
    win.runTimers
    verifyEq(win.uri, `/c`)
    win.hisBack; win.hisBack; win.hisBack; win.hisBack
    verifyEq(win.uri, start)
    win.runTimers
    win.removeEvent("popstate", false, f)
  }

  Void testClipboard()
  {
    win := Win.cur
    Str? got
    win.clipboardWriteText("hi")
    win.clipboardReadText |s| { got = s }
    verifyEq(got, null)
    win.runTimers
    verifyEq(got, "hi")
  }

  Void testWeakMap()
  {
    m := WeakMap()
    a := Elem {}
    b := "b"
    verifyEq(m.has(a), false)
    verifyEq(m[a], null)
    m[a] = 1
    m[b] = 2
    verifyEq(m.has(a), true)
    verifyEq(m[a], 1)
    verifyEq(m[b], 2)
    m[a] = 3
    verifyEq(m[a], 3)

    // keys are compared by identity
    verifyEq(m.has(Elem {}), false)
    verifyEq(m.delete(a), true)
    verifyEq(m.delete(a), false)
    verifyEq(m.has(a), false)
    verifyEq(m[b], 2)
  }

  Void testDataTransfer()
  {
    e := Event.makeCustom("dragstart")
    dt := e.dataTransfer
    verifySame(e.dataTransfer, dt)
    verifyEq(dt.types, Str[,])
    verifyEq(dt.getData("text/plain"), "")
    dt.setData("text/plain", "hi").setData("text/uri-list", "x")
    verifyEq(dt.types, ["text/plain", "text/uri-list"])
    verifyEq(dt.getData("text/plain"), "hi")
    dt.dropEffect = "copy"
    dt.effectAllowed = "all"
    verifyEq(dt.dropEffect, "copy")
    verifyEq(dt.effectAllowed, "all")
    verifyEq(dt.files.size, 0)
  }

  ** There are no stylesheets on the JVM, so computed style is the inline style
  Void testStyleComputed()
  {
    e := Elem {}
    verifyEq(e.style.computed("overflow-y"), null)
    e.style->overflowY = "auto"
    e.style->color = "red"
    verifyEq(e.style.computed("overflow-y"), "auto")
    verifyEq(e.style.effective("color"), "red")
    e.style.addClass("x")
    e.style.clear
    verifyEq(e.style.computed("overflow-y"), null)
    verifyEq(e.style->color, null)
    verifyEq(e.style.classes, ["x"])
  }

  Void testSvg()
  {
    a := Svg.line(0, 0, 10, 10)
    verifyEq(a.ns, `http://www.w3.org/2000/svg`)
    verifyEq(a.tagName, "line")

    // svg prop routes to attr
    verifyEq(a->x1, "0")
    verifyEq(a->y1, "0")
    verifyEq(a->x2, "10")
    verifyEq(a->y2, "10")

    // svg setProp routes to setAttr
    a->x1 = 5
    a->y1 = 5
    verifyEq(a->x1, "5")
    verifyEq(a->y1, "5")
  }

  private Void verifyAttrProp(Elem elem, Str name, Str? attrVal, Obj? propVal := null)
  {
    verifyAttr(elem, name, attrVal)
    verifyProp(elem, name, propVal ?: attrVal)
  }

  private Void verifyAttr(Elem elem, Str name, Str? val)
  {
    // echo("# $elem a[$name]: " + elem.attr(name) + "/" + elem.get(name))
    verifyEq(elem.attr(name), val)
    verifyEq(elem.get(name),  val)
    verifyEq(elem[name],      val)
  }

  private Void verifyProp(Elem elem, Str name, Obj? val)
  {
    // echo("# $elem p[$name]: " + elem.prop(name) + "/" + elem.trap(name))
    verifyEq(elem.prop(name), val)
    verifyEq(elem.trap(name), val)
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  Void testEvents()
  {
    // a > b > c > text
    a := Elem("div")
    b := Elem("ul")
    c := Elem("li")
    t := DomText("x")
    a.add(b); b.add(c); c.addChild(t)

    acc := Str[,]
    a.onEvent("click", true)  |e| { acc.add("a-capture") }
    a.onEvent("click", false) |e| { acc.add("a") }
    b.onEvent("click", false) |e| { acc.add("b") }
    c.onEvent("click", false) |e| { acc.add("c:$e.type:$e.target.tagName") }
    c.onEvent("keydown", false) |e| { acc.add("c-key") }

    // event which does not bubble: capture, then the target
    verifyEq(c.dispatchEvent(Event.makeCustom("click")), true)
    verifyEq(acc, ["a-capture", "c:click:li"])

    // bubbles
    acc.clear
    verifyEq(c.dispatchEvent(Event.makeCustom("click", ["bubbles":true])), true)
    verifyEq(acc, ["a-capture", "c:click:li", "b", "a"])

    // text node target maps to its parent element
    acc.clear
    e := Event.makeCustom("click", ["bubbles":true])
    t.dispatchEvent(e)
    verifyEq(acc, ["a-capture", "c:click:li", "b", "a"])
    verifySame(e.target, c)
    verifySame(e.targetNode, t)

    // only listeners of the type
    acc.clear
    c.dispatchEvent(Event.makeCustom("keydown", ["bubbles":true]))
    verifyEq(acc, ["c-key"])

    // stop ends propagation and cancels
    acc.clear
    stopper := b.onEvent("click", false) |x| { acc.add("stop"); x.stop }
    verifyEq(c.dispatchEvent(Event.makeCustom("click", ["bubbles":true, "cancelable":true])), false)
    verifyEq(acc, ["a-capture", "c:click:li", "b", "stop"])

    // remove
    acc.clear
    b.removeEvent("click", false, stopper)
    b.removeEvent("click", false, stopper)
    c.dispatchEvent(Event.makeCustom("click", ["bubbles":true]))
    verifyEq(acc, ["a-capture", "c:click:li", "b", "a"])

    // preventDefault cancels only a cancelable event, and does not stop
    acc.clear
    c.onEvent("submit", false) |x| { x.preventDefault }
    a.onEvent("submit", false) |x| { acc.add("a-submit") }
    verifyEq(c.dispatchEvent(Event.makeCustom("submit", ["bubbles":true])), true)
    verifyEq(c.dispatchEvent(Event.makeCustom("submit", ["bubbles":true, "cancelable":true])), false)
    verifyEq(acc, ["a-submit", "a-submit"])
  }

  Void testEventAttrs()
  {
    e := Event.makeCustom("keydown", ["keyCode":13, "key":"Enter", "shiftKey":true, "detail":"foo"])
    verifyEq(e.type, "keydown")
    verifyEq(e.key, Key.enter)
    verifyEq(e.keyChar, "Enter")
    verifyEq(e.shift, true)
    verifyEq(e.alt, false)
    verifyEq(e.ctrl, false)
    verifyEq(e.meta, false)
    verifyEq(e.button, null)
    verifyEq(e.targetNode, null)
    verifyEq(e.detail, "foo")
    verifyEq(Event.makeCustom("click").detail, null)
    verifyEq(e.get("notFound"), null)
    verifyEq(e.get("notFound", "def"), "def")
    e["foo"] = 3
    verifyEq(e["foo"], 3)

    m := Event.makeCustom("click", ["button":0])
    verifyEq(m.button, 0)
    verifyEq(m.key, null)
    verifyEq(m.keyChar, null)

    verifyEq(Event.makeMock.type, "mock")
  }
}
