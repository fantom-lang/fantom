//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Oct 11  Brian Frank  Creation
//

**
** ObixErr is used to raise an obix '<err>' object as a
** Fantom exception.
**
const class ObixErr : Err
{
  ** Construct error ObixObj
  static ObixErr make(ObixObj obj)
  {
    doMake(obj.contract, obj.display ?: "")
  }

  private new doMake(Contract contract, Str display) : super.make("$contract: $display")
  {
    this.contract = contract
    this.display  = display
  }

  ** The 'is' attribute of the '<err>' object
  const Contract contract

  ** The 'display' attribute of the '<err>' object
  const Str display
}