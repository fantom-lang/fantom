//
// Copyright (c) 2015, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   26 Aug 2015  Andy Frank  Creation
//

using dom
using domkit

@Js
class KeyTest : DomkitTest
{
  new make()
  {
    Box? box
    add(FlowBox {
      it.style->padding = "24px"
      box = Box {
        it->tabIndex = 0
        it.style->border  = "1px solid #999"
        it.style->padding = "24px"
        it.style->width   = "400px"
        it.style->height  = "64px"
        it.style->textAlign = "center"
        it.text = "Focus and Press a key"
        // it.onEvent(EventType.mouseDown, false) |e|
        // {
        //   box.text = "MouseDown - $e.key"
        // }
        it.onEvent(EventType.keyDown, false) |e|
        {
          str := "$e.key.name - $e.key.code"
          if (e.alt   && e.key != Key.alt)   str = "Alt + $str"
          if (e.ctrl  && e.key != Key.ctrl)  str = "Ctrl + $str"
          if (e.meta  && e.key != Key.meta)  str = "Meta + $str"
          if (e.shift && e.key != Key.shift) str = "Shift + $str"
          box.text = str
        }
      },
    })
  }
}