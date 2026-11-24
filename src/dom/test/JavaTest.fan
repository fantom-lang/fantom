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

  Void testHtmlSet()
  {
    // markup is parsed into the children, replacing what was there
    root := Elem("div") { Elem("i"), }
    root.html = Str<|a &lt; b<P Title='x &amp; "y"' hidden data-n=3>one<br>two<b>three</b></p><!-- gone -->tail &#65;&#x42;&nope;|>
    verifyEq(root.html, Str<|a &lt; b<p title="x &amp; &quot;y&quot;" hidden="" data-n="3">one<br>two<b>three</b></p>tail AB&amp;nope;|>)
    verifyEq(root.childNodes.size, 3)
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
    verifySel(ul,   "div li",                  li)   // an ancestor outside the scope counts

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

    // what is not handled is an error
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
