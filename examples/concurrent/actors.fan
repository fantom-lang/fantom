#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Sep 09  Brian Frank  Creation
//

using concurrent

**
** Basic actor examples
**
class Actors
{

  Void main()
  {
    echoActor
    counterActor
    coalescingActor
  }

  Void echoActor()
  {
    echo("\n--- echoActor ---")
    // this actor just echos messages sent to it
    a := Actor(ActorPool()) |msg| { echo(msg); return msg }

    // send some messages and have them printed to console
    f1 := a.send("message 1")
    f2 := a.send("message 2")
    f3 := a.send("message 3")

    // now block for the result of each message
    echo("Result 1 = " + f1.get)
    echo("Result 2 = " + f2.get)
    echo("Result 3 = " + f3.get)
  }

  Void counterActor()
  {
    echo("\n--- echoCounter ---")

    // this actor stores state in context to keep
    // track of a simple counter everytime a message is received
    a := Actor(ActorPool()) |msg|
    {
      if (msg == "current") return Actor.locals["counter"]
      if (msg == "reset") { Actor.locals["counter"] = 0; return null }
      Actor.locals["counter"] = 1 + (Int)Actor.locals["counter"]
      return null  // ignored
    }

    // reset the counter to zero
    a.send("reset")

    // send 100 messages
    100.times { a.send(it) }

    // send the "get" message and block for result
    echo("Result " + a.send("current").get)
  }

  Void coalescingActor()
  {
    echo("\n--- coalescingActor ---")

    // this function is used to get coalesing key
    toKey := |Rec msg->Obj| { msg.key }

    // this function is used to coalesce two messages with same key
    coalesce := |Rec oldOne, Rec newOne->Rec| { Rec(oldOne.key, oldOne.data.dup.addAll(newOne.data)) }

    // this our receive function
    receive := |Rec msg| { echo(msg.key + ": " + msg.data) }

    // create an actor that "writes" multiple records
    // to standard out, we coalesce and pending writes
    // into a single write
    a := Actor.makeCoalescing(ActorPool(), toKey, coalesce, receive)

    // blast messages to the actor with the same key to see how
    // pending messages are coalesced
    100.times |i|
    {
      key := i.isEven ? "a" : "b"
      a.send(Rec(key, [i.toStr]))
    }

    // stop and wait until done
    a.pool.stop.join
  }
}


const class Rec
{
  new make(Str k, Str[] d) { key = k; data = d  }
  const Str key
  const Str[] data
}


