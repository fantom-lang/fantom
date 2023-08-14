//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2023  Matthew Giannini  Creation
//   22 Jun 2023  Matthew Giannini  Refactor for JS
//

/**
 * ActorFuture.
 */
class ActorFuture extends Future {
  constructor() { super(); }

  typeof$() { return ActorFuture.type$; }
}