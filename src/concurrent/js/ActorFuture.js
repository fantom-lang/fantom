//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 2023  Matthew Giannini  Creation
//

/**
 * ActorFuture.
 */
fan.concurrent.ActorFuture = fan.sys.Obj.$extend(fan.concurrent.Future);

fan.concurrent.Future.prototype.$ctor = function() {}
fan.concurrent.Future.prototype.$typeof = function() { return fan.concurrent.ActorFuture.$type; }