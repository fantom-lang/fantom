//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jan 06  Andy Frank  Creation
//

using System;
using Fan.Sys;

namespace Fanx.Tools
{
  /// <summary>
  /// Fanp runtime for .NET.
  /// </summary>
  public class Fanp : Tool
  {

  //////////////////////////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////////////////////////

    public static int run(string reserved)
    {
      sysInit(reserved);
      return new Fan().execute("compiler::Fanp.main", Tool.getArgv());
    }

  }
}