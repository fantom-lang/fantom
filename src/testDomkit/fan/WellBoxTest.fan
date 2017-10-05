//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Oct 2017  Andy Frank  Creation
//

using dom
using domkit

@Js
class WellBoxTest : DomkitTest
{
  new make()
  {
    this.add(SashBox {
      it.style->padding = "20px"
      it.style->width   = "600px"
      it.dir = Dir.down
      it.sizes = ["auto"] //, "10px", "auto", "10px", "auto", "10px", "auto"]
      docDomkit1,
      // Box {},
      // docDomkit2,
      // Box {},
      // docDomkit3,
      // Box {},
      // docDomkit4,
    })
  }

  WellBox docDomkit1()
  {
    WellBox {
      Label { it.text="Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor" },
    }
  }

  Elem docDomkit2()
  {
    docDomkit1.mergeHeader(Label { it.text="Header" })
  }

  Elem docDomkit3()
  {
    docDomkit1.mergeHeader(Label { it.text="Header" }, Align.center)
  }

  Elem docDomkit4()
  {
    docDomkit1.mergeHeader(Label { it.text="Header" }, Align.right)
  }
}