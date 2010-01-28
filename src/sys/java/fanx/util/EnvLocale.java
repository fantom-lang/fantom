//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Nov 07  Brian Frank  Original Locale code
//   28 Jan 10  Brian Frank  Split out into Env helper class
//
package fanx.util;

import java.util.HashMap;
import fan.sys.*;

/**
 * EnvLocale manages caching and compilation of 'Env.locale'.
 */
public class EnvLocale
{
  public EnvLocale(Env env) { this.env = env; }

  public String get(String pod, String key, String def, Locale locale)
  {
    return pod + "::" + key;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final String noDef = "_EnvLocale_nodef_";

  private final Env env;
}