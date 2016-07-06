//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Mar 2015  Andy Frank  Creation
//

using dom

**
** FlipBox displays content on a 3D card, and allows transitiong
** between the front and back using a flipping animation.
**
@Js class FlipBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-FlipBox")
    this.add(card = Elem { it.style.addClass("domkit-FlipBox-card") })
  }

  ** Front card content.
  Elem? front
  {
    get { card.children.getSafe(0) }
    set { card.add(it); it.style.addClass("domkit-FlipBox-front") }
  }

  ** Back card content.
  Elem? back
  {
    get { card.children.getSafe(1) }
    set { card.add(it); it.style.addClass("domkit-FlipBox-back") }
  }

  ** Flip content, and invoke the specified callback
  ** when the flip animation has completed.
  Void flip(|This|? onComplete := null)
  {
    card.style.toggleClass("flip")
    if (onComplete != null) Win.cur.setTimeout(500ms) |->| { onComplete(this) }
  }

  ** Is card showing front content.
  Bool isFront() { !isBack }

  ** Is card showing back content.
  Bool isBack() { card.style.hasClass("flip") }

  ** Show front card content if not already visible.
  This toFront()
  {
    if (isBack) flip
    return this
  }

  ** Show back card content if not already visible.
  This toBack()
  {
    if (isFront) flip
    return this
  }

  private Elem card
}