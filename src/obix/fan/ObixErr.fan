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
  ** Convert error message and cause back to an '<err>' object
  static ObixObj toObj(Str msg, Err? cause := null)
  {
    obj :=  ObixObj { elemName = "err"; display = msg }
    if (cause != null)
      obj.add(ObixObj { elemName="str"; name="trace"; val = cause.traceToStr })
    return obj
  }

  ** Convert to '<err>' with BadUriErr contract
  static ObixObj toUnresolvedObj(Uri uri)
  {
    ObixObj
    {
      elemName = "err"
      display = "Unresolved uri: $uri"
      href = uri
      contract = Contract.badUriErr
    }
  }

  ** Construct error ObixObj
  static new make(ObixObj obj)
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

  ** Return if the oBIX error defines the 'obix:BadUriErr' contract
  Bool isBadUri() { contract.uris.contains(`obix:BadUriErr`) }
}