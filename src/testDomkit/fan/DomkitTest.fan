//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
abstract class DomkitTest : Box
{
  ** Get a unique color even if index is out-of-bounds
  static Str safeColor(Int index)
  {
    i := index % colors.size
    return colors.vals[i]
  }

  ** List of colors we can use for test cases.
  static const Str:Str colors := [:] {
    it.ordered = true
    it["red"]        = "#e74c3c"
    it["darkRed"]    = "#c0392b"
    it["orange"]     = "#e67e22"
    it["darkOrange"] = "#d35400"
    it["yellow"]     = "#f1c40f"
    it["darkYellow"] = "#f39c12"
    it["green"]      = "#2ecc71"
    it["darkGren"]   = "#27ae60"
    it["mint"]       = "#1abc9c"
    it["darkMint"]   = "#16a085"
    it["blue"]       = "#3498db"
    it["darkBlue"]   = "#2980b9"
    it["purple"]     = "#9b59b6"
    it["darkPurple"] = "#8e44ad"
    it["silver"]     = "#ecf0f1"
    it["darkSilver"] = "#bdc3c7"
    it["grey"]       = "#95a5a6"
    it["darkGrey"]   = "#7f8c8d"
    it["indigo"]     = "#34495e"
    it["darkIndigo"] = "#2c3e50"
  }

  static Void main()
  {
    qname := Env.cur.vars["ui.test.qname"]
    DomkitTest.mount(qname)
  }

  static Type[] list()
  {
    DomkitTest#.pod.types
      .findAll |t| { t.fits(DomkitTest#) && !t.isAbstract }
      .sort |a,b| { a.name <=> b.name }
  }

  static Void mount(Str qname)
  {
    test   := (DomkitTest)Type.find(qname).make
    header := FlowBox
    {
      it.style.setCss("background:#e5e5e5; border-bottom:1px solid #bbb; padding:12px;")
      it.gaps = ["12px"]
      ListButton
      {
        it.items = DomkitTest.list.map |t| { t.name }
        it.sel.index = it.items.findIndex |t| { t == test.typeof.name }
        it.onSelect |d|
        {
          type := d.sel.item
          Win.cur.hyperlink(`/test/$type`)
        }
      },
      Button
      {
        it.text = "Options"
        it.enabled = test.hasOptions
        it.onAction { test.onOptions }
      },
    }

    sash := SashBox
    {
      sizes = ["48px", "100%"]
      dir = Dir.down
      header,
      test,
    }

    Win.cur.doc.body.add(sash)
  }

  virtual Bool hasOptions() { false }
  virtual Void onOptions() {}
}
