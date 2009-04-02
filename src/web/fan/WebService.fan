//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  Brian Frank  Creation
//

**
** WebService defines the standard service interface
** for all Fan based web servers.
**
** See [docLib::Web]`docLib::Web#webServices`
**
abstract const class WebService : Service
{

//////////////////////////////////////////////////////////////////////////
// Pipeline
//////////////////////////////////////////////////////////////////////////

  **
  ** The pipeline field stores a series of WebSteps which
  ** are processed in sequence to service a web request.
  **
  ** See [docLib::Web]`docLib::Web#pipeline`
  **
  const WebStep[] pipeline

  **
  ** Service the specified web request with the configured
  ** pipeline.  Any exceptions raised by a step, are propagated
  ** to the caller - internal errors should be handled by
  ** subclasses.  If `WebRes.done` is called, then the pipeline
  ** is terminated.
  **
  virtual Void service(WebReq req, WebRes res)
  {
    // init thread locals
    Actor.locals["web.req"] = req
    Actor.locals["web.res"] = res
    try
    {
      // if pipeline is empty
      if ((Obj?)pipeline == null || pipeline.isEmpty)
        throw Err("Must set WebService.pipeline")

      // onBeforeService
      pipeline.each |WebStep step|
      {
        try { step.onBeforeService(req, res) } catch (Err e) { log.error("BeforeService $step.type", e) }
      }

      // process each step unless done
      pipeline.each |WebStep step|
      {
        if (!res.isDone) step.service(req, res)
      }

      // onAfterService
      pipeline.each |WebStep step|
      {
        try { step.onAfterService(req, res) } catch (Err e) { log.error("AfterService $step.type", e) }
      }
    }
    finally
    {
      // save session if accessed
      sessionMgr.save

      // cleanup thread locals
      Actor.locals.remove("web.req")
      Actor.locals.remove("web.res")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Threading
//////////////////////////////////////////////////////////////////////////

  **
  ** Subclasses must call super if overridden.
  **
  protected override Void onStart()
  {
    pipeline.each |WebStep step|
    {
      try { step.onStart(this) } catch (Err e) { log.error("Starting $step.type", e) }
    }
  }

  **
  ** Subclasses must call super if overridden.
  **
  protected override Void onStop()
  {
    pipeline.each |WebStep step|
    {
      try { step.onStop(this) } catch (Err e) { log.error("Stopping $step.type", e) }
    }
    sessionMgr.stop
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Standard log for web service
  static const Log log := Log.get("web")

  ** Session management thread
  internal const WebSessionMgr sessionMgr := WebSessionMgr()


}