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
** See also: [pod doc]`pod-doc#cardBox`
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

  protected override Void onAdd(Elem c)    { updateStyle }
  protected override Void onRemove(Elem c) { updateStyle }

  private Void updateStyle()
  {
    // implicitly select first card if not specified
    if (children.size > 0 && selectedIndex == null) selectedIndex = 0

    children.each |kid,i|
    {
      kid.style["display" ] = i==selectedIndex ? "block" : "none"
    }
  }
}