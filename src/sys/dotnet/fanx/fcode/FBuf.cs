//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.IO;

namespace Fanx.Fcode
{
  /// <summary>
  /// FBuf stores a byte buffer (such as executable fcode, or line numbers).
  /// </summary>
  public class FBuf
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public FBuf(byte[] buf, int len)
    {
      this.m_buf = buf;
      this.m_len = len;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public int u2()
    {
      return m_buf[0] << 16 | m_buf[1];
    }

    public string utf()
    {
      // .NET works different from Java - so eat the first two
      // bytes which indicate the length of the string

      StreamReader r = new StreamReader(new MemoryStream(m_buf, 2, m_buf.Length-2));
      return r.ReadToEnd();
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public static FBuf read(FStore.Input input)
    {
      int len = input.u2();
      if (len == 0) return null;

      byte[] buf = new byte[len];
      for (int r=0; r<len;) r += input.Read(buf, r, len-r);
      return new FBuf(buf, len);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public byte[] m_buf;
    public int m_len;

  }
}
