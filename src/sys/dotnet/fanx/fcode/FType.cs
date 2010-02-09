//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;
using Fan.Sys;

namespace Fanx.Fcode
{
  ///
  /// FType is the read fcode representation of sys::Type.
  ///
  public class FType
  {
  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FType(FPod pod)
    {
      this.m_pod = pod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Meta IO
  //////////////////////////////////////////////////////////////////////////

    public FType readMeta(FStore.Input input)
    {
      m_self  = input.u2();
      m_base  = input.u2();
      m_mixins = new int[input.u2()];
      for (int i=0; i<m_mixins.Length; i++) m_mixins[i] = input.u2();
      m_flags  = input.u4();
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Body IO
  //////////////////////////////////////////////////////////////////////////

    public string filename()
    {
      return "fcode/" + m_pod.typeRef(m_self).typeName + ".fcode";
    }

    public void read()
    {
      read(m_pod.m_store.read(filename()));
    }

    public void read(FStore.Input input)
    {
      if (input.fpod.m_fcodeVersion == null)
        throw new IOException("FStore.Input.version == null");

      m_fields = new FField[input.u2()];
      for (int i=0; i<m_fields.Length; i++)
        m_fields[i] = new FField().read(input);

      m_methods = new FMethod[input.u2()];
      for (int i=0; i<m_methods.Length; i++)
        m_methods[i] = new FMethod().read(input);

      m_attrs = FAttrs.read(input);

      m_hollow = false;
      input.Close();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public bool m_hollow = true;  // have we only read meta-data
    public FPod m_pod;            // parent pod
    public int m_self;            // self typeRef index
    public int m_flags;           // bitmask
    public int m_base;            // base typeRef index
    public int[] m_mixins;        // mixin TypeRef indexes
    public FField[] m_fields;     // fields
    public FMethod[] m_methods;   // methods
    public FAttrs m_attrs;        // type attributes
  }
}