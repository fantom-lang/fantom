//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jun 2016  Andy Frank  Creation
//

using dom

**
** AccordionBox displays collapsible content panels for presenting
** information in a limited amount of vertical space.
**
** See also: [pod doc]`pod-doc#accordionBox`
**
@Js class AccordionBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-AccordionBox")
    this.onEvent(EventType.mouseDown, false) |e| { onMouseDown(e) }
  }

  ** Add a new group with given header and child nodes. Optionally
  ** configure default expansion state with 'expanded' paramter
  ** (defaults to collapsed).
  This addGroup(Elem header, Elem[] kids, Bool expanded := false)
  {
    // default display styles for all nodes
    header.style->display = "block"
    kids.each |k| { k.style->display = "none" }

    // wrap into group node
    group := Elem { it.style.addClass("domkit-AccordionBox-group collapsed") }
    group.add(header)
    group.addAll(kids)

    // check if we need to expand group
    if (expanded) toggle(group)

    this.add(group)
    return this
  }

  ** Toggle a group or fire action for child.
  private Void onMouseDown(Event e)
  {
    // find group
    group := this.children.find |g| { g.containsChild(e.target) }
    if (group == null) return

    // toggle if fired on header
    if (group.firstChild.containsChild(e.target)) toggle(group)
  }

  ** Toggle expansion state for group.
  private Void toggle(Elem group)
  {
    if (group.style.hasClass("collapsed"))
    {
      // expand
      group.style.removeClass("collapsed").addClass("expanded")
      group.children.each |k| { k.style->display = "block" }
    }
    else
    {
      // collapse
      group.style.removeClass("expanded").addClass("collapsed")
      group.children.eachRange(1..-1) |k| { k.style->display = "none" }
    }
  }
}