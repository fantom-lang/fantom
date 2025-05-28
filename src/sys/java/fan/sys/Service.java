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
  public static List<Service> list() { return Service$.list(); }

  public static Service find(Type t) { return Service$.find(t); }

  public static Service find(Type t, boolean checked) { return Service$.find(t, checked); }

  public static List<Service> findAll(Type t) { return Service$.findAll(t); }

  public default boolean isInstalled() { return Service$.isInstalled(this); }

  public default boolean isRunning() { return Service$.isRunning(this); }

  public default Service install() { return Service$.install(this); }

  public default Service uninstall() { return Service$.uninstall(this); }

  public default Service start() { return Service$.start(this); }

  public default Service stop() { return Service$.stop(this); }

  public default void onStart() {}

  public default void onStop() {}

}

