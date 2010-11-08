//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Sep 06  Andy Frank  Creation
//

using System;
using System.Diagnostics;
using System.IO;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Threading;

namespace Fan.Sys
{
  /// <summary>
  /// Err.
  /// </summary>
  public class Err : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // C# to Fantom Mapping
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Map a java exception to it's Fantom Err counter part.  Common runtime
    /// exceptions are mapped into explicit Fantom types.  Otherwise we just
    /// wrap the exception with a generic Err.
    /// </summary>
    public static Err make(Exception ex)
    {
      if (ex == null) return null;
      if (ex is Val)                         return ((Val)ex).m_err;
      if (ex is NullReferenceException)      return new NullErr(ex);
      if (ex is InvalidCastException)        return new CastErr(ex);
      if (ex is IndexOutOfRangeException)    return new IndexErr(ex);
      if (ex is ArgumentOutOfRangeException) return new IndexErr(ex);
      if (ex is ArgumentException)           return new ArgErr(ex);
      if (ex is IOException)                 return new IOErr(ex);
      if (ex is SocketException)             return new IOErr(ex); // TODO?
      if (ex is ThreadInterruptedException)  return new InterruptedErr(ex);
      if (ex is NotSupportedException)       return new UnsupportedErr(ex);
      return new Err(new Err.Val(), ex);
    }

    /// <summary>
    /// This method is used by FCodeEmit to generate extra entries in the
    /// exception table - for example if fcode says to trap NullErr, then
    /// we also need to trap System.NullReferenceException.  Basically this
    /// is the inverse of the mapping done in make(Exception).
    /// </summary>
    public static string fanToDotnet(string ftype)
    {
      // TODO - need to trap as well...
      //if (ftype == "Fan.Sys.IndexErr")) return "ArgumentOutOfRangeException";

      if (ftype == "Fan.Sys.NullErr")  return "System.NullReferenceException";
      if (ftype == "Fan.Sys.CastErr")  return "System.InvalidCastException";
      if (ftype == "Fan.Sys.IndexErr") return "System.IndexOutOfRangeException";
      if (ftype == "Fan.Sys.ArgErr")   return "System.ArgumentException";
      if (ftype == "Fan.Sys.IOErr")    return "System.IO.IOException";
      if (ftype == "Fan.Sys.InterruptedErr") return "System.Threading.ThreadInterruptedException";
      if (ftype == "Fan.Sys.UnsupportedErr") return "System.NotSupportedException";
      return null;
    }

  //////////////////////////////////////////////////////////////////////////
  // C# Convenience
  //////////////////////////////////////////////////////////////////////////

    public static Err make(string msg, Exception e) { return make(msg, make(e)); }

  //////////////////////////////////////////////////////////////////////////
  // Fantom Constructors
  //////////////////////////////////////////////////////////////////////////

    public static Err make() { return make("", (Err)null); }
    public static Err make(string msg) { return make(msg, (Err)null); }
    public static Err make(string msg, Err cause)
    {
      Err err = new Err(new Err.Val());
      make_(err, msg, cause);
      return err;
    }

    public static void make_(Err self) { make_(self, null);  }
    public static void make_(Err self, string msg) { make_(self, msg, null); }
    public static void make_(Err self, string msg, Err cause)
    {
      if (msg == null) throw NullErr.make("msg is null").val;
      self.m_msg = msg;
      self.m_cause = cause;
    }

  //////////////////////////////////////////////////////////////////////////
  // C# Constructors
  //////////////////////////////////////////////////////////////////////////

    public Err() {}

    /// <summary>
    /// All subclasses must call this constructor with their
    /// typed Val exception which the real .NET exception we use.
    /// </summary>
    public Err(Val val)
    {
      this.val = val;
      val.m_err = this;
    }

    /// <summary>
    /// This constructor is used by special subclasses which provide
    /// a transparent mapping between .NET and Fantom exception types.
    /// </summary>
    public Err(Val val, Exception actual)
    {
      this.val = val;
      val.m_err = this;
      this.m_actual = actual;
      this.m_msg = actual.Message;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string msg()
    {
      return m_msg;
    }

    public Err cause()
    {
      return m_cause;
    }

    public Err trace() { return trace(Env.cur().@out(), null, 0, true); }
    public Err trace(OutStream @out) { return trace(@out, null, 0, true); }
    public Err trace(OutStream @out, Map opt) { return trace(@out, opt, 0, true); }
    public Err trace(OutStream @out, Map opt, int indent, bool useActual)
    {
      Exception ex = m_actual != null && useActual ? m_actual : val;
      dumpStack(toStr(), ex, @out, indent);
      if (m_cause != null)
      {
        @out.printLine("Cause:");
        m_cause.trace(@out, opt, indent+2, useActual);
      }
      return this;
    }

    public string traceToStr()
    {
      Buf buf = new MemBuf(1024);
      trace(buf.@out());
      return buf.flip().readAllStr();
    }

    public override Type @typeof()
    {
      return Sys.ErrType;
    }

    public override string toStr()
    {
      if (m_msg == null || m_msg.Length == 0)
        return @typeof().qname();
      else
        return @typeof().qname() + ": " + m_msg;
    }

  //////////////////////////////////////////////////////////////////////////
  // Rebasing
  //////////////////////////////////////////////////////////////////////////

    public Val rebase()
    {
      m_actual = new RebaseException();
      return val;
    }

    public class RebaseException : Exception
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Val
  //////////////////////////////////////////////////////////////////////////

    public class Val : Exception
    {
      public override string Message { get { return m_err.ToString(); }}
      public Err err() { return m_err; }
      public Err m_err;
    }

  //////////////////////////////////////////////////////////////////////////
  // Tracing
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Dump a readable stack trace.
    /// </summary>
    public static void dumpStack(Exception err) { dumpStack(err.Message, err, 0); }
    public static void dumpStack(string msg, Exception err, int indent)
    {
      StringWriter w = new StringWriter();
      doDumpStack(msg, err, indent, w);
      System.Console.Write(w.ToString());
    }

    /// <summary>
    /// Dump a readable stack trace.
    /// </summary>
    public static void dumpStack(Exception err, OutStream @out) { dumpStack(err.Message, err, @out, 0); }
    public static void dumpStack(string msg, Exception err, OutStream @out, int indent)
    {
      StringWriter w = new StringWriter();
      doDumpStack(msg, err, indent, w);
      @out.writeChars(w.ToString()).flush();
    }

    static void doDumpStack(string msg, Exception err, int depth, StringWriter w)
    {
      // message
      for (int sp=0; sp<depth; sp++) w.Write(" ");
      if (!(err is Err.Val) && msg == err.Message) w.Write(err.GetType() + ": ");
      w.WriteLine(msg);

      // stack
      string stack = err.StackTrace;
      if (err is Err.Val)
      {
        Err e = ((Err.Val)err).err();
        if (e.m_stack != null) stack = e.m_stack;
      }
      if (stack != null)
      {
        string[] lines = stack.Split('\n');
        for (int i=0; i<lines.Length; i++)
        {
          // TODO - could be *way* more efficient

          string s = lines[i].Trim();
          int parOpen  = s.IndexOf('(');
          int parClose = s.IndexOf(')', parOpen);

          string source = s.Substring(parClose+1, s.Length-parClose-1);
          if (source == "") source = "Unknown Source";
          else
          {
            source = source.Substring(4);
            int index = source.LastIndexOf("\\");
            if (index != -1) source = source.Substring(index+1);
            index = source.LastIndexOf(":line");
            source = source.Substring(0, index+1) + source.Substring(index+6);
          }

          string target = s.Substring(0, parOpen);
          if (target.StartsWith("at Fan."))
          {
            int a = target.IndexOf(".", 7);
            int b = target.IndexOf(".", a+1);
            string pod  = target.Substring(7, a-7);
            string type = target.Substring(a+1, b-a-1);
            string meth = target.Substring(b+1);

            // check for closures
            int dollar1 = type.IndexOf('$');
            int dollar2 = dollar1 < 0 ? -1 : type.IndexOf('$', dollar1+1);
            if (dollar2 > 0)
            {
              // don't print callX for closures
              if (meth.StartsWith("call")) continue;
              // remap closure class back to original method
              if (meth.StartsWith("doCall"))
              {
                meth = type.Substring(dollar1+1, dollar2-dollar1-1);
                type = type.Substring(0, dollar1);
              }
            }

            target = FanStr.decapitalize(pod) + "::" + type + "." + meth;
          }

          for (int sp=0; sp<depth; sp++) w.Write(" ");
          w.Write("  ");
          w.Write(target);
          w.Write(" (");
          w.Write(source);
          w.Write(")");
          w.Write("\n");
        }
      }
      // inner exception
      Exception cause = err.InnerException;
      if (cause != null) doDumpStack(msg, cause, depth+1, w);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly Val val;
    internal string m_msg;
    internal Err m_cause = null;
    internal Exception m_actual;
    internal string m_stack;       // only used for Method.invoke()

  }
}