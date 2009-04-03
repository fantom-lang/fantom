//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 06  Andy Frank  Creation
//

using System;
using System.IO;
using Fanx.Util;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FCodePrinter prints a human readable syntax for fcode.
  /// </summary>
  public class FCodePrinter : StreamWriter
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FCodePrinter(FPod pod) : this(pod, Console.OpenStandardOutput())
    {
    }

    public FCodePrinter(FPod pod, Stream stream) : base(stream)
    {
      this.m_pod = pod;
    }

  //////////////////////////////////////////////////////////////////////////
  // Write
  //////////////////////////////////////////////////////////////////////////

    public void code(FBuf code)
    {
      try
      {
        this.m_code = code;
        this.m_input = new DataReader(new MemoryStream(m_code.m_buf, 0, m_code.m_len));

        /*
        if (false)
        {
          int c;
          while ((c = m_input.Read()) >= 0)
            WriteLine("  0x" + c);
          return;
        }
        */

        int op;
        while ((op = m_input.Read()) >= 0)
        {
          m_n++;
          this.op(op);
        }
      }
      catch (IOException e)
      {
        Err.dumpStack(e);
      }

      Flush();

      this.m_code  = null;
      this.m_input = null;
    }

    private void op(int opcode)
    {
      if (opcode >= m_ops.Length)
        throw new Exception("Unknown opcode: " + opcode);
      Op op = m_ops[opcode];
      Write("    " + StrUtil.padl(""+(m_n-1), 3) + ": " + StrUtil.padr(op.name,16) + " ");
      if (opcode == FConst.Switch) printSwitch();
      else switch (op.arg)
      {
        case None:     break;
        case Long:     Write(integer()); break;
        case Float:    Write(floatpt()); break;
        case Str:      Write(str()); break;
        case Dur:      Write(duration()); break;
        case Uri:      Write(uri()); break;
        case Reg:      Write(u2()); break;
        case Type:     Write(type()); break;
        case Field:    Write(field()); break;
        case Method:   Write(method()); break;
        case Jmp:      Write(jmp()); break;
        default: throw new Exception(op.sig);
      }
      WriteLine();
    }

    private void printSwitch()
    {
      int count = u2();
      for (int i=0; i<count; ++i)
      {
        WriteLine();
        Write("          " + i + " -> " + u2());
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Sig
  //////////////////////////////////////////////////////////////////////////

    const int None     = -1;
    const int Long     = 0;
    const int Float    = 1;
    const int Str      = 2;
    const int Dur      = 3;
    const int Uri      = 4;
    const int Reg      = 5;
    const int Type     = 6;
    const int Field    = 7;
    const int Method   = 8;
    const int Jmp      = 9;

    static readonly Op[] m_ops;
    static FCodePrinter()
    {
      m_ops = new Op[FConst.OpNames.Length];
      for (int i=0; i<m_ops.Length; ++i)
        m_ops[i] = new Op(i);
    }

    internal class Op
    {
      internal Op(int id)
      {
        this.id   = id;
        this.name = FConst.OpNames[id];
        this.sig  = FConst.OpSigs[id];
        arg = parseArg(sig);
      }

      internal int id;
      internal string name;
      internal string sig;
      internal int arg;
    }

    static int parseArg(string sig)
    {
      if (sig == "()")       return None;
      if (sig == "(int)")    return Long;
      if (sig == "(float)")  return Float;
      if (sig == "(str)")    return Str;
      if (sig == "(dur)")    return Dur;
      if (sig == "(uri)")    return Uri;
      if (sig == "(reg)")    return Reg;
      if (sig == "(type)")   return Type;
      if (sig == "(field)")  return Field;
      if (sig == "(method)") return Method;
      if (sig == "(jmp)")    return Jmp;
      throw new Exception(sig);
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    private int u1() { m_n +=1; return m_input.ReadByte(); }
    private int u2() { m_n +=2; return m_input.ReadUnsignedShort(); }
    private int u4() { m_n +=4; return m_input.ReadInt(); }

    private string integer()
    {
      int index = u2();
      try
      {
        return m_pod.m_literals.integer(index).ToString() + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string floatpt()
    {
      int index = u2();
      try
      {
        return m_pod.m_literals.floats(index).ToString() + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string str()
    {
      int index = u2();
      try
      {
        return m_pod.m_literals.str(index).ToString() + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string duration()
    {
      int index = u2();
      try
      {
        return m_pod.m_literals.duration(index).ToString() + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string uri()
    {
      int index = u2();
      try
      {
        return m_pod.m_literals.uri(index).ToString() + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string type()
    {
      int index = u2();
      try
      {
        return m_pod.m_typeRefs.toString(index) + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string field()
    {
      int index = u2();
      try
      {
        return m_pod.m_fieldRefs.toString(index) + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string method()
    {
      int index = u2();
      try
      {
        return m_pod.m_methodRefs.toString(index) + showIndex(index);
      }
      catch (Exception)
      {
        return "Error [" + index + "]";
      }
    }

    private string jmp()
    {
      int jmp = u2();
      return ""+jmp;
    }

    private string showIndex(int index)
    {
      if (m_showIndex) return "[" + index + "]";
      return "";
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly FPod m_pod;
    public bool m_showIndex;
    private FBuf m_code;
    private DataReader m_input;
    private int m_n;


  }
}