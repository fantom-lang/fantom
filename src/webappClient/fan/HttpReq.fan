//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

**
** HttpReq models the request side of an XMLHttpRequest instance.
**
@javascript
class HttpReq
{

  **
  ** Create a new HttpReq instance with for the given Uri.
  **
  new make(Str uri)
  {
    this.uri = uri
  }

  **
  ** The Uri to send the request.
  **
  Str uri

  **
  ** The HTTP method to use.  Defaults to 'POST'.
  **
  Str method := "POST"

  **
  ** If true then perform this request asynchronously.
  ** Defaults to 'true'
  **
  Bool async := true

  **
  ** Send the request with the specificed content, after
  ** receiving the response, call the given closure with
  ** the resulting HttpRes.
  **
  Void send(Str content, |HttpRes res| c) {}

}