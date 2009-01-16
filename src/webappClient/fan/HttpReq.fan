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
  ** Send the request, after receiving the response, call
  ** the given closure with the resulting HttpRes.
  **
  ** If 'content' is a Map type, then the contents are
  ** encoded as form values. If the Content-Type header
  ** has not been set then it will set to
  ** "application/x-www-form-urlencoded".
  **
  ** If 'content' is any other type, 'toStr' is called
  ** and the content is sent as is.  If the Content-Type
  ** has not been set, it will be set to 'text/plain'.
  **
  Void send(Obj content, |HttpRes res| c) {}

}