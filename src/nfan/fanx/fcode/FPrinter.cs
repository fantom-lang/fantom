//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;
using Fanx.Util;

namespace Fanx.Fcode
{
  /// <summary>
  /// FPod is the read/write fcode representation of sys::Pod.
  /// </summary>
  public class FPrinter : StreamWriter
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FPrinter(FPod pod) : this(pod, Console.OpenStandardOutput())
    {
    }

    public FPrinter(FPod pod, Stream stream) : base(stream)
    {
      this.pod = pod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Dump
  //////////////////////////////////////////////////////////////////////////

    public void All()
    {
      tables();
      types();
      Flush();
    }

  //////////////////////////////////////////////////////////////////////////
  // Const Tables
  //////////////////////////////////////////////////////////////////////////

    public void tables()
    {
      WriteLine("##### Tables #####");
      WriteLine("--- names ---");      pod.m_names.dump(pod, this);
      WriteLine("--- typeRefs ---");   pod.m_typeRefs.dump(pod, this);
      WriteLine("--- fieldRefs ---");  pod.m_fieldRefs.dump(pod, this);
      WriteLine("--- methodRefs ---"); pod.m_methodRefs.dump(pod, this);
      WriteLine("--- ints ---");       pod.m_literals.m_ints.dump(pod, this);
      WriteLine("--- floats ---");     pod.m_literals.m_floats.dump(pod, this);
      WriteLine("--- strs ---");       pod.m_literals.m_strs.dump(pod, this);
      WriteLine("--- durations ---");  pod.m_literals.m_durations.dump(pod, this);
      WriteLine("--- uris ---");       pod.m_literals.m_uris.dump(pod, this);
      Flush();
    }

  //////////////////////////////////////////////////////////////////////////
  // Types
  //////////////////////////////////////////////////////////////////////////

    public void types()
    {
      WriteLine("##### Types #####");
      for (int i=0; i<pod.m_types.Length; i++)
        type(pod.m_types[i]);
      Flush();
    }

    public void type(FType type)
    {
      WriteLine("--" + typeRef(type.m_self) + " extends " + typeRef(type.m_base) + "--");
      if (type.m_mixins.Length > 0)
      {
        Write("  mixin ");
        for (int i=0; i<type.m_mixins.Length; i++)
        {
          if (i > 0) Write(", ");
          Write(typeRef(type.m_mixins[i]));
        }
        WriteLine();
      }
      attrs(type.m_attrs);
      WriteLine();
      for (int i=0; i<type.m_fields.Length; i++)  field(type.m_fields[i]);
      for (int i=0; i<type.m_methods.Length; i++) method(type.m_methods[i]);
      Flush();
    }
    public void slot(FSlot s)
    {
      if (s is FField)
        field((FField)s);
      else
        method((FMethod)s);
      Flush();
    }

    public void field(FField f)
    {
      WriteLine("  " + typeRef(f.m_type) + " " + f.m_name + " [" + StrUtil.flagsToString(f.m_flags).Trim() + "]");
      attrs(f.m_attrs);
      WriteLine();
    }

    public void method(FMethod m)
    {
      Write("  " + typeRef(m.m_ret) + " " + m.m_name + "(");
      FMethodVar[] pars = m.pars();
      for (int i=0; i<pars.Length; ++i)
      {
        FMethodVar p = pars[i];
        if (i > 0) Write(", ");
        Write(typeRef(p.type) + " " + p.name);
      }
      WriteLine(") [" + StrUtil.flagsToString(m.m_flags).Trim() + "]");
      for (int i=0; i<m.m_vars.Length; i++)
      {
        FMethodVar v = m.m_vars[i];
        string role = v.IsParam() ?  "Param" : "Local";
        int reg = i + ((m.m_flags & FConst.Static) != 0 ? 0 : 1);
        WriteLine("    [" + role + " " + reg + "] " + v.name + ": " + typeRef(v.type));
        if (v.def != null) code(v.def);
      }
      if (m.m_code != null)
      {
        WriteLine("    [Code]");
        code(m.m_code);
      }
      attrs(m.m_attrs);
      WriteLine();
    }

    public void code(FBuf code)
    {
      if (!m_showCode) return;
      Flush();
      //new FCodePrinter(pod, out).code(code);
      WriteLine("      CODE - TODO");
    }

  //////////////////////////////////////////////////////////////////////////
  // Facets
  //////////////////////////////////////////////////////////////////////////

    public void attrs(FAttrs attrs)
    {
    }
    //
    //  if (attrs == null) return;
    //  for (int i=0; i<attrs.Length; ++i)
    //    attr(attrs[i]);
    //}

    public void attr(FAttrs attr)
    {
      /*
      string name = name(attr.name);
      if (name.equals(LineNumbersAttr) && !showLines) return;
      println("    [" + name + "] len=" + attr.data.len);
      if (name.equals(SourceFileAttr))  sourceFile(attr);
      if (name.equals(ErrTableAttr))    errTable(attr);
      if (name.equals(LineNumbersAttr)) lineNumbers(attr);
      if (name.equals(FacetsAttr))      facets(attr);
      */
    }

  //////////////////////////////////////////////////////////////////////////
  // Dump Utils
  //////////////////////////////////////////////////////////////////////////

    private string typeRef(int index)
    {
      if (index == 65535) return "null";
      return pod.m_typeRefs.toString(index) + showIndex(index);
    }

    private string name(int index)
    {
      return pod.name(index) + showIndex(index);
    }

    private string showIndex(int index)
    {
      if (m_showIndex) return "[" + index + "]";
      return "";
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly FPod pod;
    public bool m_showIndex = false;
    public bool m_showCode  = true;
    public bool m_showLines = false;
  }
}
