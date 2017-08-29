//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2016  Andy Frank  Creation
//

using dom

**
** ButtonGroup groups a set of toggle or radio buttons and handles
** making sure only one button in group is selected at a time.
**
** See also: [docDomkit]`docDomkit::Controls#buttonGroup`,
** `ToggleButton`, `RadioButton`
**
@Js class ButtonGroup
{
  ** Buttons in this group.
  Elem[] buttons := [,]
  {
    set { &buttons=it; update }
  }

  ** Convenience to add a button to `buttons`.
  This add(Elem button)
  {
    if (inheritEnabled) button.enabled = this.enabled
    this.buttons = buttons.add(button)
    return this
  }

  ** If 'true', child buttons will inherit the `enabled` state
  ** of this 'ButtonGroup'.  If 'false' buttons can be enabled
  ** or disabled independent of group.
  Bool inheritEnabled := true

  ** Set enabled state for this button group.
  Bool enabled := true
  {
    set {
      &enabled = it
      if (inheritEnabled)
        buttons.each |b| { b.enabled =  &enabled }
    }
  }

  ** Index of selected button, or 'null' if none selected.
  Int? selIndex := null
  {
    set
    {
      old := &selIndex
      mod := cbBeforeSelect?.call(this, it) ?: true
      if (mod) &selIndex = it
      update
      if (it != old) cbSelect?.call(this)
    }
  }

  ** Callback before a selection changes.  Return 'true' to
  ** select the new button (default), or 'false' to keep the
  ** currently selected button.
  Void onBeforeSelect(|ButtonGroup g, Int newIndex->Bool| f)
  {
    this.cbBeforeSelect = f
  }

  ** Callback when selection in group has changed.
  Void onSelect(|This| f) { this.cbSelect = f }

  ** Mark given button as selected.
  internal Void select(Elem button)
  {
    this.selIndex = buttons.findIndex |b| { b === button }
  }

  ** Update group state and make sure buttons are bound to this group.
  internal Void update()
  {
    buttons.each |b,i|
    {
      if (b is ToggleButton)
      {
        t := (ToggleButton)b
        t.group = this
        t.selected = i == selIndex
        return
      }

      if (b is RadioButton)
      {
        r := (RadioButton)b
        r.group = this
        r.checked = i == selIndex
        return
      }

      throw ArgErr("Invalid button for group '$b.typeof'")
    }
  }

  // TODO: not sure how this works yet
  @NoDoc Event? _event

  private Func? cbBeforeSelect
  private Func? cbSelect
}