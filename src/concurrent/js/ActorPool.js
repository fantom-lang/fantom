//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 10  Andy Frank  Creation
//   13 May 10  Andy Frank  Move from sys to concurrent
//

/**
 * ActorPool.
 */
fan.concurrent.ActorPool = fan.sys.Obj.$extend(fan.sys.Obj);

fan.concurrent.ActorPool.prototype.$ctor = function()
{
  fan.sys.Obj.prototype.$ctor.call(this);
  this.m_$name = "ActorPool";
  this.m_$maxThreads = 100;
}

fan.concurrent.ActorPool.prototype.$typeof = function() { return fan.concurrent.ActorPool.$type; }

fan.concurrent.ActorPool.make = function(f)
{
  var self = new fan.concurrent.ActorPool();
  fan.concurrent.ActorPool.make$(self, f);
  return self;
}

fan.concurrent.ActorPool.make$ = function(self, f)
{
  if (f === undefined) f = null;
  if (f != null) f.call(self);
}