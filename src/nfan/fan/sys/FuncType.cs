//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jul 07  Andy Frank  Creation
//

using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// FuncType is a parameterized type for Funcs.
  /// </summary>
  public class FuncType : GenericType
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FuncType(Type[] pars, Type ret)
      : base(Sys.FuncType)
    {
      this.m_params = pars;
      this.m_ret    = ret;

      // I am a generic parameter type if any my args or
      // return type are generic parameter types.
      this.m_genericParameterType |= ret.isGenericParameter();
      for (int i=0; i<m_params.Length; ++i)
        this.m_genericParameterType |= m_params[i].isGenericParameter();
    }

  //////////////////////////////////////////////////////////////////////////
  // Type
  //////////////////////////////////////////////////////////////////////////

    public override Int hash()
    {
      return signature().hash();
    }

    public override Bool equals(Obj obj)
    {
      if (obj is FuncType)
      {
        FuncType x = (FuncType)obj;
        if (m_params.Length != x.m_params.Length) return Bool.False;
        for (int i=0; i<m_params.Length; ++i)
          if (!m_params[i].equals(x.m_params[i]).val) return Bool.False;
        return m_ret.equals(x.m_ret);
      }
      return Bool.False;
    }

    public override Type @base()
    {
      return Sys.FuncType;
    }

    public override Str signature()
    {
      if (m_sig == null)
      {
        StringBuilder s = new StringBuilder();
        s.Append('|');
        for (int i=0; i<m_params.Length; ++i)
        {
          if (i > 0) s.Append(',');
          s.Append(m_params[i].signature().val);
        }
        s.Append('-').Append('>');
        s.Append(m_ret.signature().val);
        s.Append('|');
        m_sig = Str.make(s.ToString());
      }
      return m_sig;
    }

    public override bool @is(Type type)
    {
      if (this == type) return true;
      if (type is FuncType)
      {
        FuncType t = (FuncType)type;

        // match return type (if void is needed, anything matches)
        if (t.m_ret != Sys.VoidType && !m_ret.@is(t.m_ret)) return false;

        // match params - it is ok for me to have less than
        // the type params (if I want to ignore them), but I
        // must have no more
        if (m_params.Length > t.m_params.Length) return false;
        for (int i=0; i<m_params.Length; ++i)
          if (!t.m_params[i].@is(m_params[i])) return false;

        // this method works for the specified method type
        return true;
      }
      return @base().@is(type);
    }


    internal override Map makeParams()
    {
      Map map = new Map(Sys.StrType, Sys.TypeType);
      for (int i=0; i<m_params.Length; ++i)
        map.set(Str.m_ascii['A'+i], m_params[i]);
      return map.set(Str.m_ascii['R'], m_ret).ro();
    }

  //////////////////////////////////////////////////////////////////////////
  // GenericType
  //////////////////////////////////////////////////////////////////////////

    public override Type getRawType()
    {
      return Sys.FuncType;
    }

    public override bool isGenericParameter()
    {
      return m_genericParameterType;
    }

    protected override Type doParameterize(Type t)
    {
      // return
      if (t == Sys.RType) return m_ret;

      // if A-H maps to avail params
      int name = t.m_name.val[0] - 'A';
      if (name < m_params.Length) return m_params[name];

      // otherwise let anything be used
      return Sys.ObjType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Method Support
  //////////////////////////////////////////////////////////////////////////

    internal List toMethodParams()
    {
      Param[] p = new Param[m_params.Length];
      for (int i=0; i<p.Length; ++i)
        p[i] = new Param(Str.m_ascii['a'+i], m_params[i], 0);
      return new List(Sys.ParamType, p);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly Type[] m_params;
    public readonly Type m_ret;
    private Str m_sig;
    private bool m_genericParameterType;

  }
}