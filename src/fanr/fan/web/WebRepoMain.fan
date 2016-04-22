//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    11 May 11  Brian Frank  Creation
//    20 Apr 16  Steve Krytkowski HTTPS Update
//

using web
using util

**
** WebRepoMain is a super simple daemon that exposes a
** file based repository on an HTTP/S port.
**
@NoDoc
class WebRepoMain : AbstractMain
{
  @Opt { help = "http port" }
  Int? httpPort := 80

  @Opt { help = "https port" }
  Int? httpsPort := 443

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

    // create WispService
    wisp := makeWispService(mod, this.httpPort, this.httpsPort)

    // run service
    return runServices([wisp])
  }

  internal static Service makeWispService(WebMod mod, Int httpPort, Int? httpsPort)
  {
    // use reflection to create WispService
    wispType := Type.find("wisp::WispService")
    wispHttpPort := wispType.field("httpPort")
    wispHttpsPort := wispType.field("httpsPort")
    wispRoot := wispType.field("root")
    return wispType.make([Field.makeSetFunc([wispHttpPort: httpPort, wispHttpsPort: httpsPort, wispRoot: mod])])
  }

}