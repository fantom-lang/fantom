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

  public synchronized List keys()
  {
    if (keys == null) load();
    return keys;
  }

  public synchronized List podNames(String key)
  {
    if (keys == null) load();
    List list = (List)keyToPodNames.get(key);
    if (list != null) return list;
    return Sys.StrType.emptyList();
  }

  public synchronized void reload()
  {
    index = null;
    keys = null;
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private void load()
  {
    // long t1 = System.currentTimeMillis();

    // load all the props
    List podNames = env.findAllPodNames();
    HashMap index = new HashMap(podNames.sz()*11);
    HashMap keyToPodNames = new HashMap();
    for (int i=0; i<podNames.sz(); ++i)
    {
      String podName = (String)podNames.get(i);
      try
      {
        File f = ((LocalFile)env.findPodFile(podName)).toJava();
        loadPod(index, keyToPodNames, podName, f);
      }
      catch (Throwable e)
      {
        System.out.println("ERROR: Env.index load: " + podName + "\n  " + e);
      }
    }

    List keys = new List(Sys.StrType);

    // long t2 = System.currentTimeMillis();
    // System.out.println("Env.index load " + (t2-t1) + "ms");
    this.index = toImmutableListVals(index, keys);
    this.keyToPodNames = toImmutableListVals(keyToPodNames, null);
    this.keys = (List)keys.sort().toImmutable();
  }

  private static void loadPod(HashMap index, HashMap keyToPodNames, String podName, File f)
    throws Exception
  {
    ZipFile zip = new ZipFile(f);
    try
    {
      ZipEntry entry = zip.getEntry("index.props");
      if (entry != null)
      {
        SysInStream in = new SysInStream(new BufferedInputStream(zip.getInputStream(entry)));
        addProps(index, keyToPodNames, podName, in.readPropsListVals());
      }
    }
    finally
    {
      zip.close();
    }
  }

  private static void addProps(HashMap index, HashMap keyToPodNames, String podName, Map props)
  {
    Iterator it = props.pairsIterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      String key  = (String)entry.getKey();
      List val    = (List)entry.getValue();
      addListVal(index, key, val);
      addListVal(keyToPodNames, key, new List(Sys.StrType, 1).add(podName));
    }
  }

  private static void addListVal(HashMap acc, String key, List val)
  {
    List master = (List)acc.get(key);
    if (master == null)
      acc.put(key, val);
    else
      master.addAll(val);
  }

  private static HashMap toImmutableListVals(HashMap mutable, List keys)
  {
    HashMap immutable = new HashMap(mutable.size()*3);
    Iterator it = mutable.entrySet().iterator();
    while (it.hasNext())
    {
      Entry entry = (Entry)it.next();
      String key = (String)entry.getKey();
      immutable.put(key, ((List)entry.getValue()).toImmutable());
      if (keys != null) keys.add(key);
    }
    return immutable;
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
  private List keys;
  private HashMap keyToPodNames;

}