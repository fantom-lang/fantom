//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//
package fan.sys;

/**
 * Service
 */
public interface Service
{
  public boolean isInstalled();

  public boolean isRunning();

  public Service install();

  public Service uninstall();

  public Service start();

  public Service stop();

  public void onStart();

  public void onStop();

}