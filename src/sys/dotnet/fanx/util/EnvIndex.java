//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Original typedb
//   05 Feb 09  Brian Frank  Rework into EnvIndex
//
package fanx.util;

import java.io.File;
import java.io.BufferedInputStream;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.zip.*;
import fan.sys.*;

/**
 * EnvIndex manages the coalescing of all the pod index.props
 */
public class EnvIndex
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public EnvIndex(Env env) { this.env = env; }

//////////////////////////////////////////////////////////////////////////
// Get
//////////////////////////////////////////////////////////////////////////

  public synchronized List get(String key)
  {
    if (index == null) load();
    List list = (List)index.get(key);
    if (list != null) return list;
    return Sys.StrType.emptyList();
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private void load()
  {
    Log log = Log.get("podindex");
    long t1 = System.currentTimeMillis();

    // load all the props
    List podNames = env.findAllPodNames();
    HashMap mutable = new HashMap(podNames.sz()*11);
    for (int i=0; i<podNames.sz(); ++i)
    {
      String n = (String)podNames.get(i);
      try
      {
        File f = ((LocalFile)env.findPodFile(n)).toJava();
        loadPod(mutable, n, f);
      }
      catch (Throwable e)
      {
        log.err("Cannot load " + n, e);
      }
    }

    // now make all the lists immutable
    HashMap immutable = new HashMap(mutable.size()*3);
    Iterator it = mutable.entrySet().iterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      immutable.put(entry.getKey(), ((List)entry.getValue()).toImmutable());
    }

    long t2 = System.currentTimeMillis();
    log.debug("Index load " + (t2-t1) + "ms");
    this.index = immutable;
  }

  private static void loadPod(HashMap index, String n, File f)
    throws Exception
  {
    ZipFile zip = new ZipFile(f);
    try
    {
      ZipEntry entry = zip.getEntry("index.props");
      if (entry != null)
      {
        SysInStream in = new SysInStream(new BufferedInputStream(zip.getInputStream(entry)));
        addProps(index, in.readPropsListVals());
      }
    }
    finally
    {
      zip.close();
    }
  }

  private static void addProps(HashMap index, Map props)
  {
    Iterator it = props.pairsIterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      String key  = (String)entry.getKey();
      List val    = (List)entry.getValue();
      List master = (List)index.get(key);
      if (master == null)
        index.put(key, val);
      else
        master.addAll(val);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  /*
  public void dump()
  {
    System.out.println("index.dump ====>");
    Iterator it = index.entrySet().iterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      String key = (String)entry.getKey();
      System.out.println(key + "=" + entry.getValue());
    }
    System.out.println("<==== index.dump");
  }
  */

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final Env env;
  private HashMap index;

}