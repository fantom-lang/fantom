//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 07  Brian Frank  Original typedb
//   05 Feb 09  Brian Frank  Rework into EnvIndex
//

using System.Collections;
using System.IO;
using System.Runtime.CompilerServices;
using Fan.Sys;
using ICSharpCode.SharpZipLib.Zip;

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
          FileSystemInfo f = ((LocalFile)m_env.findPodFile(n)).toDotnet();
          loadPod(mutable, n, f);
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

    private static void loadPod(Hashtable index, string n, FileSystemInfo f)
    {
      ZipFile zip = new ZipFile(f.FullName);
      try
      {
        ZipEntry entry = zip.GetEntry("index.props");
        if (entry != null)
        {
          SysInStream input = new SysInStream(new BufferedStream(zip.GetInputStream(entry)));
          addProps(index, input.readPropsListVals());
        }
      }
      finally
      {
        zip.Close();
      }
    }

    private static void addProps(Hashtable index, Map props)
    {
      IDictionaryEnumerator en = props.pairsIterator();
      while (en.MoveNext())
      {
        string key = (string)en.Key;
        List val   = (List)en.Value;
        List master = (List)index[key];
        if (master == null)
          index[key] = val;
        else
          master.addAll(val);

      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Env m_env;
    private Hashtable m_index;
  }
}