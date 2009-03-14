//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Mar 08  Brian Frank  Creation
//

**
** WebStep defines a single step of a WebService's pipeline.
**
** See [docLib::Web]`docLib::Web#pipeline`
**
abstract const class WebStep
{

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return 'type.name'
  **
  override Str toStr() { type.name }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Callback when WebService is started.
  **
  virtual Void onStart(WebService service) {}

  **
  ** Callback when WebService is stopped.
  **
  virtual Void onStop(WebService service) {}

//////////////////////////////////////////////////////////////////////////
// Service
//////////////////////////////////////////////////////////////////////////

  **
  ** Callback before we begin servicing the request.
  **
  virtual Void onBeforeService(WebReq req, WebRes res) {}

  **
  ** Perform this step against the specified request and response.
  ** Return true
  **
  virtual Void service(WebReq req, WebRes res) {}

  **
  ** Callback after we've serviced the request.
  **
  virtual Void onAfterService(WebReq req, WebRes res) {}

}