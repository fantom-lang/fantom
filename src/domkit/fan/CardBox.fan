//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 2015  Andy Frank  Creation
//

using dom

**
** CardBox lays out child elements as a stack of cards, where
** only one card may be visible at a time.
**
** See also: [docDomkit]`docDomkit::Layout#cardBox`
**
@Js class CardBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-CardBox")
  }

  ** Selected card instance, or null if no children.
  Elem? selected()
  {
    selectedIndex==null ? null : children[selectedIndex]
  }

  ** Selected card index, or null if no children.
  virtual Int? selectedIndex
  {
    set
    {
      &selectedIndex = it.max(0).min(children.size)
      updateStyle
    }
  }

  **
  ** Transition effect to apply when 'selectedIndex' is changed.
  ** If null, no effect is applied.
  **
  ** Valid values are:
  **   - 'slideLeft': animate cards sliding in from right-to-left
  **   - 'slideLeft': animate cards sliding in from left-to-right
  **
  Str? effect := null

  ** Duratin for `effect` animation to last.
  Duration effectDur := 350ms

  protected override Void onAdd(Elem c)    { updateStyle }
  protected override Void onRemove(Elem c) { updateStyle }

  private Void updateStyle()
  {
    // TODO:
    //   currently require style.width/height to be set on CardBox
    //   should probalby check, or throw if not configured?

    kids := children

    // implicitly select first card if not specified
    if (kids.size > 0 && selectedIndex == null) selectedIndex = 0

    // if effect is set, stage the card we will show next
    fx   := this.effect
    cur  := kids.find |k| { k.style->display == "block" }
    next := fx == null ? null : children[selectedIndex]
    size := fx == null ? null : this.size

    // if cur is selected short-circuit effect
    if (cur == null) cur = next
    if (cur === next) { fx=null; next=null }
    curIndex := kids.findIndex |k| { k == cur }

    switch (fx)
    {
      case "slideLeft":
        cy := curIndex > selectedIndex ? "-${size.h}px" : "0px"
        ny := curIndex < selectedIndex ? "-${size.h}px" : "0px"
        cur.style->transform  = "translateX(0) translateY($cy)"
        next.style->transform = "translateX(${size.w}px) translateY($ny)"
        next.style->display   = "block"
        cur.transition(["transform":"translateX(-${size.w}px) translateY($cy)", "opacity":"0"], null, effectDur)
        next.transition(["transform":"translateX(0px) translateY($ny)"], null, effectDur) {
          updateDis
        }

      case "slideRight":
        cy := curIndex > selectedIndex ? "-${size.h}px" : "0px"
        ny := curIndex < selectedIndex ? "-${size.h}px" : "0px"
        cur.style->transform  = "translateX(0) translateY($cy)"
        next.style->transform = "translateX(-${size.w}px) translateY($ny)"
        next.style->display   = "block"
        cur.transition(["transform":"translateX(${size.w}px) translateY($cy)", "opacity":"0"], null, effectDur)
        next.transition(["transform":"translateX(0px) translateY($ny)"], null, effectDur) {
          updateDis
        }

      default:
        // if no effect, just update display
        updateDis
     }
  }

  private Void updateDis()
  {
    children.each |kid,i|
    {
      kid.style->display = i==selectedIndex ? "block" : "none"
      kid.style->opacity = "1.0"
      kid.transition(["transform":"translateX(0) translateY(0)"], null, 0ms)
    }
  }
}