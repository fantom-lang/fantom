//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 2015  Andy Frank  Creation
//

using dom
using graphics

**
** SashBox lays out children in a single direction allowing both
** fixed and pertange sizes that can fill the parent container.
**
** See also: [docDomkit]`docDomkit::Layout#sashBox`
**
@Js class SashBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-SashBox")
    this.onEvent("mousedown", true) |e| { onMouseDown(e) }
    this.onEvent("mouseup",   true) |e| { onMouseUp(e)   }
    this.onEvent("mousemove", true) |e| { onMouseMove(e) }
  }

  **
  ** Direction to layout child elements:
  **   - 'Dir.right': layout children left to right
  **   - 'Dir.down': layout childrent top to bottom
  **
  Dir dir := Dir.right

  ** Allow user to resize sash positions. See `div`.
  Bool resizable := false

  **
  ** Size to apply to each child, width or height based on `dir`.  Fixed
  ** 'px' and percentage sizes are allowed.  Percentage sizes will be
  ** subtracted from total fixed size using CSS 'calc()' method.
  **
  Str[] sizes := [,]
  {
    set
    {
      &sizes = it
      dims = it.map |s| { CssDim(s) }.toImmutable
      applyStyle
    }
  }

  ** Minimum size a child can be resized to if 'resizable' is 'true'.
  ** Only percentage sizes allowed.
  Str minSize := "10%"

  ** Create a new divider element for resizing children. Dividers are
  ** required between children when `resizable` is 'true'.
  static Elem div()
  {
    Box { it.style.addClass("domkit-SashBox-div") }
  }

  protected override Void onAdd(Elem c)    { applyStyle }
  protected override Void onRemove(Elem c) { applyStyle }

  private Void applyStyle()
  {
    fixed := Str:Float[:]  // unit:sum
    dims.each |d|
    {
      if (d.unit == "%") return
      fixed[d.unit] = (fixed[d.unit] ?: 0f) + d.val.toFloat
    }

    kids := children
    kids.each |kid,i|
    {
      d := dims.getSafe(i)
      if (d == null) return

      css := d.toStr
      if (d.unit == "%" && fixed.size > 0)
      {
        per := fixed.join(" - ") |sum,unit| { "${d.val.toFloat / 100f * sum}$unit" }
        css = "calc($d.toStr - ${per})"
      }

      kid.style->display = css == "0px"
         ? "none"
         : (kid is FlexBox ? "flex" : "block")

      vert := dir == Dir.down
      kid.style->float  = vert ? "none" : "left"
      kid.style->width  = vert ? "100%" : css
      kid.style->height = vert ? css : "100%"
    }
  }

  private Void onMouseDown(Event e)
  {
    if (!resizable) return
    if (resizeIndex == null) return

    e.stop
    div := children[resizeIndex+1]
    this.active = true

    splitter = Elem { it.style.addClass("domkit-resize-splitter") }
    if (dir == Dir.down)
    {
      this.pivoff = this.relPos(e.pagePos).y - div.pos.y
      splitter.style->top    = "${div.pos.y}px"
      splitter.style->width  = "100%"
      splitter.style->height = "${div.size.h}px"
    }
    else
    {
      this.pivoff = this.relPos(e.pagePos).x - div.pos.x
      splitter.style->left   = "${div.pos.x}px"
      splitter.style->width  = "${div.size.w}px"
      splitter.style->height = "100%"
    }

    doc := Win.cur.doc
    Obj? fmove
    Obj? fup

    fmove = doc.onEvent("mousemove", true) |de| { onMouseMove(de) }
    fup = doc.onEvent("mouseup", true) |de| {
      onMouseUp(de)
      de.stop
      doc.removeEvent("mousemove", true, fmove)
      doc.removeEvent("mouseup",   true, fup)
    }

    this.add(splitter)
  }

  private Void onMouseUp(Event e)
  {
    if (!resizable) return
    if (!active) return

    p := this.relPos(e.pagePos)
    kids := children
    if (dir == Dir.down)
    {
      y := 0
      for (i:=0; i<=resizeIndex; i++) y += kids[i].size.h.toInt
      applyResize(resizeIndex, p.y - y - pivoff)
    }
    else
    {
      x := 0
      for (i:=0; i<=resizeIndex; i++) x += kids[i].size.w.toInt
      applyResize(resizeIndex, p.x - x - pivoff)
    }

    this.active = false
    this.resizeIndex = null
    this.remove(splitter)
  }

  private Void onMouseMove(Event e)
  {
    if (!resizable) return

    p := this.relPos(e.pagePos)
    if (active)
    {
      // drag splitter
      if (dir == Dir.down)
      {
        sy := 0f.max(p.y - pivoff).min(this.size.h-splitter.size.h)
        splitter.style->top = "${sy}px"
        e.stop
      }
      else
      {
        sx := 0f.max(p.x - pivoff).min(this.size.w-splitter.size.w)
        splitter.style->left = "${sx}px"
        e.stop
      }
      return
    }
    else
    {
      // check for roll-over cursor
      div := toDiv(e.target)
      if (div != null)
      {
        this.style->cursor = dir==Dir.down ? "row-resize" : "col-resize"
        this.resizeIndex = 0.max(children.findIndex |c| { c == div } - 1)
      }
      else
      {
        this.style->cursor = "default"
        this.resizeIndex = null
      }
    }
  }

  private Elem? toDiv(Elem? elem)
  {
    while (elem != null)
    {
      if (elem.style.hasClass("domkit-SashBox-div") && elem.parent == this) return elem
      elem = elem.parent
    }
    return null
  }

  private Void applyResize(Int index, Float delta)
  {
    // convert to % if needed
    sizesToPercent

    // get adjacent child nodes
    da  := dims[index]
    db  := dims[index+2]

    // if already at minSize bail here
    min := CssDim(minSize).val.toFloat
    dav := da.val.toFloat
    dbv := db.val.toFloat
    if (dav + dbv <= min + min) return

    // split delta between adjacent children
    working := sizes.dup
    sz := dir == Dir.down ? this.size.h : this.size.w
    dp := delta / sz * 100f
    av := (dav + dp).toLocale("0.00", Locale.en).toFloat
    bv := (dav + dbv - av).toLocale("0.00", Locale.en).toFloat
    if (av < min)
    {
      av = min
      bv = (dav + dbv - av).toLocale("0.00", Locale.en).toFloat
    }
    else if (bv < min)
    {
      bv = min
      av = (dav + dbv - bv).toLocale("0.00", Locale.en).toFloat
    }
    working[index]   = "${av}%"
    working[index+2] = "${bv}%"

    // update
    this.sizes = working
    applyStyle
  }

  ** Convert `sizes` to %
  private Void sizesToPercent()
  {
    // short-circuit if already converted
    if (dims.all |d| { d.unit == "%" }) return

    sz := dir == Dir.down ? this.size.h : this.size.w
    converted := CssDim[,]
    remainder := 100f

    // convert px -> %
    kids := children
    dims.each |d,i|
    {
      if (d.unit == "%") { converted.add(CssDim.defVal); return }
      ksz  := kids.getSafe(i)?.size ?: Size.defVal
      kval := dir == Dir.down ? ksz.h : ksz.w
      val  := ((kval / sz.toFloat) * 100f).toLocale("0.00", Locale.en).toFloat
      converted.add(CssDim(val, "%"))
      remainder -= val
    }

    // divide up existing % into new %
    dims.each |d,i|
    {
      if (d.unit != "%") return
      val := (d.val.toFloat * remainder / 100f).toLocale("0.00", Locale.en).toFloat
      converted[i] = CssDim(val, "%")
    }

    // trim last child to 100% if needed
    sum := 0f
    converted.each |d| { sum += d.val.toFloat }
    if (sum > 100f) converted[-1] = CssDim(converted.last.val.toFloat-(sum-100f), "%")

    // update
    this.sizes = converted.map |c| { c.toStr }
  }

  private CssDim[] dims := CssDim#.emptyList

  private Bool active := false
  private Int? resizeIndex
  private Float? pivoff
  private Elem? splitter
}