//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.test;

import fan.sys.*;
import java.io.*;

/**
 * CharsetTest
 */
public class CharsetTest
  extends Test
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    verifyFactory();
    verifyUnicode();
    verifyISO_8859();
  }

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public void verifyFactory()
  {
    verify(Charset.fromStr("UTF-8", true) == Charset.utf8());
    verify(Charset.fromStr("Utf-8", true) == Charset.utf8());
    verify(Charset.fromStr("utf-8", true) == Charset.utf8());
    verify(Charset.fromStr("utf8", true)  == Charset.utf8());

    verify(Charset.fromStr("UTF-16BE", true) == Charset.utf16BE());
    verify(Charset.fromStr("Utf-16BE", true)  == Charset.utf16BE());
    verify(Charset.fromStr("utf-16be", true)  == Charset.utf16BE());

    verify(Charset.fromStr("UTF-16LE", true) == Charset.utf16LE());
    verify(Charset.fromStr("Utf-16LE", true)  == Charset.utf16LE());
    verify(Charset.fromStr("utf-16le", true)  == Charset.utf16LE());
  }

//////////////////////////////////////////////////////////////////////////
// Coders
//////////////////////////////////////////////////////////////////////////

  public void verifyUnicode()
    throws Exception
  {
    String[] strings =
    {
      "a", "ab", "abc", "\u0080", "\u00FE", "\uabcd", "x\u00FE", "x\uabcd", "\uabcd-\u00FE"
    };

    Charset[] charsets =
    {
      Charset.utf8(), Charset.utf16BE(), Charset.utf16LE(),
    };

    for (int i=0; i<strings.length; ++i)
      for (int j=0; j<charsets.length; ++j)
        verifyCoders(strings[i], charsets[j]);
  }

  public void verifyISO_8859()
    throws Exception
  {
    // Since ISO-8859 maps to bytes, we have to select specific
    // Unicode characters present in each charset to test
    String s;

    // ISO-8850-1 Latin 1 Western Europe (maps directly to Unicode)
    // http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-1.TXT
    s = "ab\u00C0\u00FD\u00FE";
    verifyCoders(s, Charset.fromStr("ISO-8859-1", true));
    verifyCoders(s, Charset.fromStr("8859_1", true));
    verifyCoders(s, Charset.fromStr("cp819", true));
    verifyCoders(s, Charset.fromStr("latin1", true));

    // ISO-8850-2 Latin 2 Central Europe
    // http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-2.TXT
    s = "ab\u0107\u00f7\u02D9";
    verifyCoders(s, Charset.fromStr("ISO-8859-2", true));

    // ISO-8850-5 Latin/Cyrillic
    // http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-5.TXT
    s = "ab\u0440\u2116\u045f";
    verifyCoders(s, Charset.fromStr("ISO-8859-5", true));

    // ISO-8850-8 Latin/Hebrew
    // http://www.unicode.org/Public/MAPPINGS/ISO8859/8859-8.TXT
    s = "ab\u05d0\u05e0\u200F";
    verifyCoders(s, Charset.fromStr("ISO-8859-8", true));
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public void verifyCoders(String string, Charset cs)
    throws Exception
  {
    // encode with Java as control
    ByteArrayOutputStream control = new ByteArrayOutputStream();
    OutputStreamWriter reader = new OutputStreamWriter(control, cs.name());
    reader.write(string);
    reader.flush();

    // encode with Buf
    MemBuf buf = new MemBuf(1024);
    buf.charset(cs);
    for (int i=0; i<string.length(); ++i)
      buf.writeChar(Long.valueOf(string.charAt(i)));
    verify(control.toByteArray(), buf.bytes());

    // encode with OutStream
    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    OutStream out = new SysOutStream(bout);
    out.charset(cs);
    for (int i=0; i<string.length(); ++i)
      out.writeChar(Long.valueOf(string.charAt(i)));
    out.flush();
    verify(control.toByteArray(), bout.toByteArray());

    // decode with Buf
    String bufStr = "";
    buf.flip();
    while (buf.more()) bufStr += (char)buf.readChar().longValue();
    verify(buf.readChar() == null);
    verify(bufStr.equals(string));

    // decode with InStream
    String inStr = "";
    InStream in = new SysInStream(new ByteArrayInputStream(control.toByteArray()));
    in.charset(cs);
    while (true)
    {
      Long c = in.readChar();
      if (c == null) break;
      inStr += (char)c.longValue();
    }
    verify(inStr.equals(string));
  }

  private void verify(byte[] control, byte[] fan)
  {
    verify(control.length == fan.length);
    for (int i=0; i<control.length; ++i)
    {
      verify(control[i] == fan[i]);
    }
  }

}
