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
  extends RuntimeException
{

//////////////////////////////////////////////////////////////////////////
// Java to Fantom Mapping
//////////////////////////////////////////////////////////////////////////

  /**
   * Map a java exception to it's Fantom Err counter part.  Common runtime
   * exceptions are mapped into explicit Fantom types.  Otherwise we just
   * wrap the exception with a generic Err.
   */
  public static Err make(Throwable ex)
  {
    // NOTE: everything in this list must be synchronized
    // with the mapping used below for FCodeEmit.errTable()
    // and tested in TryTest
    if (ex == null) return null;
    if (ex instanceof Err) return (Err)ex;
    if (ex instanceof NullPointerException)      return new NullErr(ex);
    if (ex instanceof ClassCastException)        return new CastErr(ex);
    if (ex instanceof IndexOutOfBoundsException) return new IndexErr(ex);
    if (ex instanceof IllegalArgumentException)  return new ArgErr(ex);
    if (ex instanceof IOException)               return new IOErr(ex);
    if (ex instanceof InterruptedException)      return new InterruptedErr(ex);
    if (ex instanceof UnsupportedOperationException)  return new UnsupportedErr(ex);
    return new Err(ex);
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

  public static Err make(String msg, Throwable e) { return make(msg, make(e)); }

//////////////////////////////////////////////////////////////////////////
// Fantom Constructors
//////////////////////////////////////////////////////////////////////////

  public static Err make() { return make("", (Err)null); }
  public static Err make(String msg) { return make(msg, (Err)null); }
  public static Err make(String msg, Err cause)
  {
    Err err = new Err();
    make$(err, msg, cause);
    return err;
  }

  public static void make$(Err self) { make$(self, null);  }
  public static void make$(Err self, String msg) { make$(self, msg, null); }
  public static void make$(Err self, String msg, Err cause)
  {
    if (msg == null) throw NullErr.make("msg is null");
    self.msg = msg;
    self.cause = cause;
  }

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * This constructor is used by special subclasses which provide
   * a transparent mapping between Java and Fantom exception types.
   */
  public Err(Throwable actual)
  {
    this.actual = actual;
    this.msg = actual.toString();
  }

  /**
   * No argument constructor.
   */
  public Err()
  {
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String msg() { return msg; }

  public Err cause() { return cause; }

  public Type typeof() { return Sys.ErrType; }

  public String toStr()
  {
    // wrap with try block to safely handle boot-strap problems
    String qname;
    try { qname = typeof().qname(); }
    catch (Throwable e) { qname = getClass().getName(); }

    if (msg == null || msg.length() == 0)
      return qname;
    else
      return qname + ": " + msg;
  }

//////////////////////////////////////////////////////////////////////////
// Trace
//////////////////////////////////////////////////////////////////////////

  public Err trace() { return trace(Env.cur().out(), null, 0, true); }
  public Err trace(OutStream out) { return trace(out, null, 0, true); }
  public Err trace(OutStream out, Map opt) { return trace(out, opt, 0, true); }
  public Err trace(OutStream out, Map opt, int indent, boolean useActual)
  {
    // map exception to stack trace
    Throwable ex = actual != null && useActual ? actual : this;
    StackTraceElement[] elems = ex.getStackTrace();

    // extract options
    int maxDepth = 20;
    if (opt != null)
    {
      Long m = (Long)opt.get("maxDepth");
      if (m != null) { maxDepth = m.longValue() > Integer.MAX_VALUE ? Integer.MAX_VALUE : m.intValue(); }
    }

    // skip calls to make the Err itself
    int start = 0;
    for (; start<elems.length; ++start)
    {
      StackTraceElement elem = elems[start];
      if (elem.getClassName().endsWith("Err"))
      {
        String m = elem.getMethodName();
        if (m.equals("make") || m.equals("<init>") || m.equals("rebase")) continue;
      }
      break;
    }

    // print each level of the stack trace
    out.indent(indent).writeChars(toStr()).writeChar('\n');
    int num = 0;
    for (int i=start; i<elems.length; ++i)
    {
      if (trace(elems[i], out, indent+2)) num++;
      if (num >= maxDepth)
      {
        int more = elems.length - i - start;
        if (more > 0)
          out.indent(indent+2).writeChars(more + " More...\n");
        break;
      }
    }
    out.flush();

    // if this was a rebase, then dump original stack trace
    if (useActual && actual instanceof RebaseException)
      trace(out, opt, indent+2, false);

    // if there is a cause, then recurse
    if (cause != null)
    {
      out.indent(indent).writeChars("Cause:\n");
      cause.trace(out, opt, indent+2, true);
    }

    return this;
  }

  public static boolean trace(StackTraceElement elem, OutStream out, int indent)
  {
    String className  = elem.getClassName();
    String methodName = elem.getMethodName();
    String fileName = elem.getFileName();
    int line = elem.getLineNumber();

    // skip crap like reflection internals
    if (className.startsWith("sun.reflect.")) return false;

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
          if (slotName.startsWith("call")) return false;
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
    return true;
  }

  public String traceToStr()
  {
    Buf buf = new MemBuf(1024);
    trace(buf.out());
    return buf.flip().readAllStr();
  }

//////////////////////////////////////////////////////////////////////////
// Interop
//////////////////////////////////////////////////////////////////////////

  public Throwable toJava()
  {
    if (actual != null) return actual;
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Rebasing
//////////////////////////////////////////////////////////////////////////

  public Err rebase()
  {
    actual = new RebaseException();
    return this;
  }

  public static class RebaseException extends RuntimeException
  {
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  String msg = "";
  Err cause;
  Throwable actual;

}