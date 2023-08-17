//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Aug 23  Brian Frank  Creation
//

**
** QueueOverflowErr is raised by a Future for messages sent to
** actor that has exceeded the max queue size.
**
const class QueueOverflowErr : Err
{

  **
  ** Construct with specified error message and optional root cause.
  **
  new make(Str msg := "", Err? cause := null) : super(msg, cause) {}

}


