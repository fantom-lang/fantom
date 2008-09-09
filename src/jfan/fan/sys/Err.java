//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.util.*;

/**
 * Err
 */
public class Err
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Java to Fan Mapping
//////////////////////////////////////////////////////////////////////////

  /**
   * Map a java exception to it's Fan Err counter part.  Common runtime
   * exceptions are mapped into explicit Fan types.  Otherwise we just
   * wrap the exception with a generic Err.
   */
  public static Err make(Throwable ex)
  {
    // NOTE: everything in this list must be synchronized
    // with the mapping used below for FCodeEmit.errTable()
    // and tested in TryTest
    if (ex == null) return null;
    if (ex instanceof Val)                       return ((Val)ex).err;
    if (ex instanceof NullPointerException)      return new NullErr(ex);
    if (ex instanceof ClassCastException)        return new CastErr(ex);
    if (ex instanceof IndexOutOfBoundsException) return new IndexErr(ex);
    if (ex instanceof IllegalArgumentException)  return new ArgErr(ex);
    if (ex instanceof IOException)               return new IOErr(ex);
    if (ex instanceof InterruptedException)      return new InterruptedErr(ex);
    if (ex instanceof UnsupportedOperationException)  return new UnsupportedErr(ex);
    return new Err(new Err.Val(), ex);
  }

  /**
   * This method is used by FCodeEmit to generate extra entries in the
   * exception table - for example if fcode says to trap NullErr, then
   * we also need to trap java.lang.NullPointerException.  Basically this
   * is the inverse of the mapping done in make(Throwable).
   */
  public static String fanToJava(String jtype)
  {
    if (jtype.equals("fan/sys/NullErr"))  return "java/lang/NullPointerException";
    if (jtype.equals("fan/sys/CastErr"))  return "java/lang/ClassCastException";
    if (jtype.equals("fan/sys/IndexErr")) return "java/lang/IndexOutOfBoundsException";
    if (jtype.equals("fan/sys/ArgErr"))   return "java/lang/IllegalArgumentException";
    if (jtype.equals("fan/sys/IOErr"))    return "java/io/IOException";
    if (jtype.equals("fan/sys/InterruptedErr")) return "java/lang/InterruptedException";
    if (jtype.equals("fan/sys/UnsupportedErr")) return "java/lang/UnsupportedOperationException";
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Java Convenience
//////////////////////////////////////////////////////////////////////////

  public static Err make(String msg) { return make(Str.make(msg)); }
  public static Err make(String msg, Throwable e) { return make(Str.make(msg), make(e)); }

//////////////////////////////////////////////////////////////////////////
// Fan Constructors
//////////////////////////////////////////////////////////////////////////

  public static Err make() { return make((Str)null, (Err)null); }
  public static Err make(Str msg) { return make(msg, null); }
  public static Err make(Str msg, Err cause)
  {
    Err err = new Err(new Err.Val());
    make$(err, msg, cause);
    return err;
  }

  public static void make$(Err self) { make$(self, null);  }
  public static void make$(Err self, Str msg) { make$(self, msg, null); }
  public static void make$(Err self, Str msg, Err cause)
  {
    self.message = msg;
    self.cause   = cause;
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * All subclasses must call this constructor with their
   * typed Val exception which the real Java exception we use.
   */
  public Err(Val val)
  {
    this.val = val;
    val.err = this;
  }

  /**
   * This constructor is used by special subclasses which provide
   * a transparent mapping between Java and Fan exception types.
   */
  public Err(Val val, Throwable actual)
  {
    this.val = val;
    val.err = this;
    this.actual = actual;
    this.message = Str.make(actual.toString());
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Str message()
  {
    return message;
  }

  public Err cause()
  {
    return cause;
  }

  public Type type()
  {
    return Sys.ErrType;
  }

  public Str toStr()
  {
    if (message == null)
      return type().qname().toStr();
    else
      return Str.make(type().qname() + ": " + message);
  }

//////////////////////////////////////////////////////////////////////////
// Trace
//////////////////////////////////////////////////////////////////////////

  public Err trace() { return trace(Sys.StdOut, 0); }
  public Err trace(OutStream out) { return trace(out, 0); }
  public Err trace(OutStream out, int indent)
  {
    // map exception to stack trace
    Throwable ex = actual != null ? actual : val;
    StackTraceElement[] elems = ex.getStackTrace();

    // skip calls to make the Err itself
    int start = 0;
    for (; start<elems.length; ++start)
    {
      StackTraceElement elem = elems[start];
      if (!elem.getClassName().endsWith("Err") ||
          (!elem.getMethodName().equals("make") &&
           !elem.getMethodName().equals("<init>")))
        break;
    }

    // print each level of the stack trace
    out.indent(indent).writeChars(toStr()).writeChar('\n');
    for (int i=start; i<elems.length; ++i)
    {
      trace(elems[i], out, indent+2);
      if (i-start >= 20) {out.indent(indent+2).writeChars("More...\n"); break; }
    }
    out.flush();

    // if there is a cause, then recurse
    if (cause != null)
    {
      out.indent(indent).writeChars("Cause:\n");
      cause.trace(out, indent+2);
    }

    return this;
  }

  public static void trace(StackTraceElement elem, OutStream out, int indent)
  {
    String className  = elem.getClassName();
    String methodName = elem.getMethodName();
    String fileName = elem.getFileName();
    int line = elem.getLineNumber();

    // fan class
    if (className.startsWith("fan.") && !className.startsWith("fan.sys."))
    {
      String podName  = "?";
      String typeName = className;
      String slotName = methodName;

      // map Java full qualified name to pod::type
      int dot = className.indexOf('.', 5);
      if (dot > 0)
      {
        podName  = className.substring(4, dot);
        typeName = className.substring(dot+1);

        // check for closures
        int dollar1 = typeName.indexOf('$');
        int dollar2 = dollar1 < 0 ? -1 : typeName.indexOf('$', dollar1+1);
        if (dollar2 > 0)
        {
          // don't print callX for closures
          if (slotName.startsWith("call")) return;
          // remap closure class back to original method
          if (slotName.startsWith("doCall"))
          {
            slotName = typeName.substring(dollar1+1, dollar2);
            typeName = typeName.substring(0, dollar1);
          }
        }
      }

      out.indent(indent).writeChars(podName).writeChar(':').writeChar(':')
         .writeChars(typeName).writeChar('.').writeChars(slotName);
    }

    // java class
    else
    {
      out.indent(indent).writeChars(className)
         .writeChar('.').writeChars(methodName).writeChars("");
    }

    // source
    out.writeChar(' ').writeChar('(');
    if (fileName == null) out.writeChars("Unknown");
    else out.writeChars(fileName);
    if (line > 0) out.writeChar(':').writeChars(String.valueOf(line));
    out.writeChar(')').writeChar('\n');
  }

  public Str traceToStr()
  {
    Buf buf = new MemBuf(1024);
    trace(buf.out());
    return buf.flip().readAllStr();
  }

//////////////////////////////////////////////////////////////////////////
// Val
//////////////////////////////////////////////////////////////////////////

  public static class Val extends RuntimeException
  {
    public String toString() { return err.toString(); }
    public Err err() { return err; }
    Err err;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final Val val;
  Str message;
  Err cause;
  Throwable actual;

}