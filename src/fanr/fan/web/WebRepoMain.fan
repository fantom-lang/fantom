//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//

using web
using util

**
** WebRepoMain is a super simple daemon that exposes a
** file based repository on an HTTP port.
**
@NoDoc
class WebRepoMain : AbstractMain
{
  @Opt { help = "http port" }
  Int port := 8080

  @Opt { help = "username to use for authentication"; aliases=["u"] }
  Str? username

  @Opt { help = "password to use for authentication"; aliases=["p"] }
  Str? password := ""

  @Arg { help = "local repo to publish" }
  Str? localRepo

  override Int run()
  {
    if (username != null) log.info("Running with authentication")

    // create web repo
    mod := WebRepoMod
    {
      it.repo = Repo.makeForUri(localRepo.toUri)
      if (username != null)
        it.auth = SimpleWebRepoAuth(username, password)
    }

    // use reflection to create WispService
    wispType := Type.find("wisp::WispService")
    wispPort := wispType.field("port")
    wispRoot := wispType.field("root")
    wisp := wispType.make([Field.makeSetFunc([wispPort: this.port, wispRoot: mod])])

    // run service
    return runServices([wisp])
  }
}

