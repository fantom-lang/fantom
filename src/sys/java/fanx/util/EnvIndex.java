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

  public synchronized List<String> get(String key)
  {
    if (index == null) load();
    List<String> list = index.get(key);
    if (list != null) return list;
    return Sys.StrType.emptyList();
  }

  public synchronized List<String> keys()
  {
    if (keys == null) load();
    return keys;
  }

  public synchronized List<String> podNames(String key)
  {
    if (keys == null) load();
    Map<String, List<String>> map = byPodName(key);
    return (List<String>)map.keys().toImmutable();
  }

  public synchronized Map<String, List<String>> byPodName(String key)
  {
    if (keys == null) load();
    Map<String, List<String>> map = keyToByPodName.get(key);
    if (map != null) return map;
    return (Map<String, List<String>>)Map.make(Sys.StrType, Sys.StrType.toListOf()).toImmutable();
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
    final List<String> podNames = env.findAllPodNames();
    HashMap<String, List<String>> index = new HashMap<>(podNames.sz()*11);
    HashMap<String, Map<String, List<String>>> keyToByPodName = new HashMap<>();
    for (int i=0; i<podNames.sz(); ++i)
    {
      final String podName = podNames.get(i);
      try
      {
        Map<String, List<String>> props = env.readIndexProps(podName);
        if (props == null) continue;
        addProps(index, keyToByPodName, podName, props);
      }
      catch (Throwable e)
      {
        System.out.println("ERROR: Env.index load: " + podName + "\n  " + e);
      }
    }

    List<String> keys = List.make(Sys.StrType);

    // long t2 = System.currentTimeMillis();
    // System.out.println("Env.index load " + (t2-t1) + "ms");
    this.index = toImmutableListVals(index, keys);
    this.keys = (List<String>)keys.sort().toImmutable();
    this.keyToByPodName = toImmutableByPodName(keyToByPodName);
  }

  private static void addProps(HashMap<String, List<String>> index,
                               HashMap<String, Map<String, List<String>>> keyToByPodName,
                               String podName,
                               Map<String, List<String>> props)
  {
    Iterator<Entry<String, List<String>>> it = props.pairsIterator();
    while (it.hasNext())
    {
      Entry<String, List<String>> entry = it.next();
      String key       = entry.getKey();
      List<String> val = entry.getValue();
      addListVal(index, key, val);

      Map<String, List<String>> byPodName = keyToByPodName.get(key);
      if (byPodName == null)
      {
        byPodName = Map.make(Sys.StrType, Sys.StrType.toListOf());
        keyToByPodName.put(key, byPodName);
      }
      byPodName.put(podName, (List<String>)val.toImmutable());
    }
  }

  private static void addListVal(HashMap<String, List<String>> acc, String key, List<String> val)
  {
    List<String> master = acc.get(key);
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

  private static HashMap<String, Map<String, List<String>>> toImmutableByPodName(HashMap<String, Map<String, List<String>>> mutable)
  {
    mutable.replaceAll((k, v) -> (Map<String, List<String>>) mutable.get(k).toImmutable());
    return mutable;
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
  private HashMap<String, List<String>> index;
  private List<String> keys;
  private HashMap<String, Map<String, List<String>>> keyToByPodName;

}

