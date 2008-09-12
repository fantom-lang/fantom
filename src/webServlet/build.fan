#! /usr/bin/env fan
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 06  Brian Frank  Creation
//

using build

**
** Build: webServlet
**
class Build : BuildPod
{

  override Void setup()
  {
    podName     = "webServlet"
    version     = globalVersion
    description = "WebEnv for a Java servlet engine"
    depends     = ["sys 1.0", "web 1.0"]
    srcDirs     = [`fan/`]
    javaDirs    = [`java/`]
    javaLibs    = [`ext/servlet-api.jar`]
  }

}
