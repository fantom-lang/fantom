//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Original typedb
//   05 Feb 09  Brian Frank  Rework into EnvIndex
//

using System.Collections;
using System.Runtime.CompilerServices;
using Fan.Sys;

/**
 * EnvIndex manages the coalescing of all the pod index.props
 */
namespace Fanx.Util
{

  public class EnvIndex
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public EnvIndex(Env env) { this.m_env = env; }

  //////////////////////////////////////////////////////////////////////////
  // Get
  //////////////////////////////////////////////////////////////////////////

    [MethodImpl(MethodImplOptions.Synchronized)]
    public List get(string key)
    {
      if (m_index == null) load();
      List list = (List)m_index[key];
      if (list != null) return list;
      return Sys.StrType.emptyList();
    }

  //////////////////////////////////////////////////////////////////////////
  // Load
  //////////////////////////////////////////////////////////////////////////

    private void load()
    {
      Log log = Log.get("podindex");

      // load all the props
      List podNames = m_env.findAllPodNames();
      Hashtable mutable = new Hashtable(podNames.sz()*11);
      for (int i=0; i<podNames.sz(); ++i)
      {
        string n = (string)podNames.get(i);
        try
        {
// TODO-FACETS
//          File f = ((LocalFile)env.findPodFile(n)).toJava();
//          loadPod(mutable, n, f);
System.Console.WriteLine("EnvIndex.load " + n);
        }
        catch (System.Exception e)
        {
          log.err("Cannot load " + n, e);
        }
      }

      // now make all the lists immutable
      Hashtable immutable = new Hashtable(mutable.Count*3);
      IDictionaryEnumerator en = mutable.GetEnumerator();
      while (en.MoveNext())
      {
        immutable[en.Key] = ((List)en.Value).toImmutable();
      }

      this.m_index = immutable;
    }

/*
    private static void loadPod(HashMap index, String n, File f)
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
    */

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Env m_env;
    private Hashtable m_index;
  }
}