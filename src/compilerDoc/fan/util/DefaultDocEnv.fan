//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 11  Brian Frank  Creation
//

using util
using web
using concurrent

**
** DefaultDocEnv provides simple implementation of DocEnv
** which lazily loads pods from the local environment.
**
@NoDoc
const class DefaultDocEnv : DocEnv
{
  override DocSpace? space(Str name, Bool checked := true)
  {
    space := actor.send(name).get(10sec) as DocSpace
    if (space != null) return space
    if (checked) throw UnknownDocErr("space: $name")
    return null
  }

  protected DocSpace? loadSpace(DocEnv env, Str name)
  {
    file := Env.cur.findPodFile(name)
    if (file == null) return null
    return DocPod.load(env, file)
  }

  private const Actor actor := DefaultDocEnvActor(this)
}

internal const class DefaultDocEnvActor : Actor
{
  new make(DefaultDocEnv env) : super(ActorPool()) { this.env = env }
  const DefaultDocEnv env
  override Obj? receive(Obj? msg)
  {
    // get/init cache map
    spaces := Actor.locals["spaces"] as Str:DocSpace?
    if (spaces == null) Actor.locals["spaces"] = spaces = Str:DocSpace?[:]

    // check if in our cache
    name := (Str)msg
    if (spaces.containsKey(name)) return spaces[name]

    // callback to env to load
    space := env.loadSpace(env, name)
    spaces[name] = space
    return space
  }
}

