//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Mar 25  Brian Frank  Create
//

**
** ActorContext is standardized thread local state stored in by "cx" key
**
@Js
mixin ActorContext
{
  ** Current context for actor thread typed as the call site type.
  ** If not available then return null or raise ContextUnavailableErr.
  ** If available, but not the call site type then raise CastErr.
  static This? cur(Bool checked := true)
  {
    cx := Actor.locals.get(actorLocalsKey, null)
    if (cx != null) return cx
    if (checked) throw ContextUnavailableErr()
    return null
  }

  ** Actor.locals key "cx" for context state
  const static Str actorLocalsKey := "cx"
}

** Thrown by ActorContext.cur when not set for current actor thread
@Js @NoDoc
const class ContextUnavailableErr : Err
{
  new make(Str msg := "", Err? cause := null) : super(msg, cause) {}
}

