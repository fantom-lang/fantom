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
** information in a limited amount of vertical space, where the
** header element is used to collapse or expand the child content.
**
** See also: [docDomkit]`docDomkit::Layout`
**
@Js class AccordionBox : Box
{
  new make() : super()
  {
    this.style.addClass("domkit-AccordionBox")
    this.onEvent("mousedown", false) |e| { onMouseDown(e) }
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

    this.add(group)

    // check if we need to expand group
    if (expanded) expand(this.children.size-1, true)

    return this
  }

  ** Return 'true' if given group is expanded, or 'false' if not.
  Bool isExpanded(Int groupIndex)
  {
    group := this.children.getSafe(groupIndex)
    if (group == null) return false // TODO: throw err?
    return group.style.hasClass("expanded")
  }

  ** Set expanded state for given group.
  Void expand(Int groupIndex, Bool expanded)
  {
    group := this.children.getSafe(groupIndex)
    if (group == null) return // TODO: throw err?

    if (expanded)
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

  ** Toggle a group or fire action for child.
  private Void onMouseDown(Event e)
  {
    // find group
    kids  := this.children
    group := kids.find |g| { g.containsChild(e.target) }
    if (group == null) return

    // toggle if fired on header
    if (group.firstChild.containsChild(e.target))
    {
      index := kids.findIndex |g| { g == group }
      expand(index, !isExpanded(index))
    }
  }
}