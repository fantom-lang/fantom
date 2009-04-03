//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Mar 09  Andy Frank  Creation
//

using System;
using Fanx.Fcode;

namespace Fan.Sys
{
  /// <summary>
  /// Service.
  /// </summary>
  public interface Service
  {

    bool isInstalled();

    bool isRunning();

    Service install();

    Service uninstall();

    Service start();

    Service stop();

    void onStart();

    void onStop();

  }
}