//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//
package fanx.test;

import java.io.*;
import java.util.*;
import fan.sys.MemBuf;
import fan.sys.SysInStream;
import fan.sys.SysOutStream;
import fanx.util.*;

/**
 * FileUtilTest
 */
public class FileUtilTest
  extends Test
{

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  public void run()
    throws Exception
  {
    verifyRead();
    verifyJavaOutputStream();
    verifyJavaInputStream();
  }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  void verifyRead()
    throws Exception
  {
    // simple
    verifyRead("",          "");
    verifyRead("x",         "x");
    verifyRead("foo",       "foo");
    verifyRead("foo bar",   "foo bar");

    // newline: \n
    verifyRead("x\n",       "x\n");
    verifyRead("x\n\n",     "x\n\n");
    verifyRead("\nx",       "\nx");
    verifyRead("\n\nx",     "\n\nx");
    verifyRead("\nx\n",     "\nx\n");
    verifyRead("\n\nx\n",   "\n\nx\n");
    verifyRead("a\nb",      "a\nb");
    verifyRead("foo\n",     "foo\n");
    verifyRead("foo\n\n",   "foo\n\n");
    verifyRead("\nfoo",     "\nfoo");
    verifyRead("\n\nfoo",   "\n\nfoo");
    verifyRead("\nfoo\n",   "\nfoo\n");
    verifyRead("\n\nfoo\n", "\n\nfoo\n");
    verifyRead("foo\nbar",  "foo\nbar");

    // newline: \r
    verifyRead("x\r",       "x\n");
    verifyRead("x\r\r",     "x\n\n");
    verifyRead("\rx",       "\nx");
    verifyRead("\r\rx",     "\n\nx");
    verifyRead("\rx\r",     "\nx\n");
    verifyRead("\r\rx\r",   "\n\nx\n");
    verifyRead("a\rb",      "a\nb");
    verifyRead("foo\r",     "foo\n");
    verifyRead("foo\r\r",   "foo\n\n");
    verifyRead("\rfoo",     "\nfoo");
    verifyRead("\r\rfoo",   "\n\nfoo");
    verifyRead("\rfoo\r",   "\nfoo\n");
    verifyRead("\r\rfoo\r", "\n\nfoo\n");
    verifyRead("foo\rbar",  "foo\nbar");

    // newline: \r\n
    verifyRead("x\r\n",           "x\n");
    verifyRead("x\r\n\r\n",       "x\n\n");
    verifyRead("\r\nx",           "\nx");
    verifyRead("\r\n\r\nx",       "\n\nx");
    verifyRead("\r\nx\r\n",       "\nx\n");
    verifyRead("\r\n\r\nx\r\n",   "\n\nx\n");
    verifyRead("a\r\nb",          "a\nb");
    verifyRead("foo\r\n",         "foo\n");
    verifyRead("foo\r\n\r\n",     "foo\n\n");
    verifyRead("\r\nfoo",         "\nfoo");
    verifyRead("\r\n\r\nfoo",     "\n\nfoo");
    verifyRead("\r\nfoo\r\n",     "\nfoo\n");
    verifyRead("\r\n\r\nfoo\r\n", "\n\nfoo\n");
    verifyRead("foo\r\nbar",      "foo\nbar");

    // mix
    verifyRead("a\nb\rc\r\nd\r\re\nf", "a\nb\nc\nd\n\ne\nf");

    // unicode UTF-8
    verifyRead("\u00f0",    "\u00f0");
    verifyRead("\u0f00",    "\u0f00");
    verifyRead("\u1234",    "\u1234");
    verifyRead("x\u0080\u0700 \n \u7abc!",   "x\u0080\u0700 \n \u7abc!");
    verifyRead("x\u0080\u0700 \r \u7abc!",   "x\u0080\u0700 \n \u7abc!");
    verifyRead("x\u0080\u0700 \r\n \u7abc!", "x\u0080\u0700 \n \u7abc!");
  }

  void verifyRead(String text, String expected)
    throws Exception
  {
    File f = new File(temp(), "FileUtil-read.txt");

    FileOutputStream fout = new FileOutputStream(f);
    OutputStreamWriter out = new OutputStreamWriter(fout, "UTF8");
    out.write(text);
    out.close();

    char[] actual = FileUtil.read(f);
    verify(actual.length == expected.length());
    verify(new String(actual).equals(expected));
  }

//////////////////////////////////////////////////////////////////////////
// JavaOutputStream
//////////////////////////////////////////////////////////////////////////

  void verifyJavaOutputStream()
    throws Exception
  {
    MemBuf buf = new MemBuf(1024);
    OutputStream out = SysOutStream.java(buf.out());
    out.write(0xFF);
    out.write(new byte[] { 'a', 'b', 'c' });
    out.write(new byte[] { 'a', 'b', 'c' }, 1, 1);
    out.write(new byte[] { '0', '1', '2', '3' }, 2, 2);
    out.close();
    verify(buf.size() == 7);
    verify(buf.get(0) == 0xFF);
    verify(buf.get(1) == 'a');
    verify(buf.get(2) == 'b');
    verify(buf.get(3) == 'c');
    verify(buf.get(4) == 'b');
    verify(buf.get(5) == '2');
    verify(buf.get(6) == '3');
  }

//////////////////////////////////////////////////////////////////////////
// JavaInputStream
//////////////////////////////////////////////////////////////////////////

  void verifyJavaInputStream()
    throws Exception
  {
    MemBuf src = new MemBuf(new byte[] { '0', '1', '2', '3', '4', '5', '6'});

    InputStream in = SysInStream.java(src.in());
    byte[] buf = new byte[3];
    verify(in.read() == '0');
    verify(in.read(buf) == 3);
    verify(buf[0] == '1');
    verify(buf[1] == '2');
    verify(buf[2] == '3');
    verify(in.read(buf, 1, 1) == 1);
    verify(buf[0] == '1');
    verify(buf[1] == '4');
    verify(buf[2] == '3');
    verify(in.read(buf) == 2);
    verify(buf[0] == '5');
    verify(buf[1] == '6');
    verify(buf[2] == '3');
    verify(in.read(buf) == -1);
    verify(in.read() == -1);
    verify(in.read() == -1);
    in.close();
  }


}
