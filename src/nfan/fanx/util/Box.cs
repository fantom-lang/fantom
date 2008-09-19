//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 07  Andy Frank  Creation
//

using System;

namespace Fanx.Util
{
  /// <summary>
  /// Box is a byte buffer used to pack a fcode/class file.
  /// </summary>
  public class Box
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public Box()
    {
      this.buf = new byte[256];
      this.len = 0;
    }

    public Box(byte[] buf)
    {
      this.buf = buf;
      this.len = buf.Length;
    }

    public Box(byte[] buf, int len)
    {
      this.buf = buf;
      this.len = len;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public void u1(int v)
    {
      if (len+1 >= buf.Length) grow();
      buf[len++] = (byte)(v >> 0);
    }

    public void u2(int v)
    {
      if (len+2 >= buf.Length) grow();
      buf[len++] = (byte)(v >> 8);
      buf[len++] = (byte)(v >> 0);
    }

    public void u2(int pos, int v)
    {
      // backpatch
      buf[pos+0] = (byte)(v >> 8);
      buf[pos+1] = (byte)(v >> 0);
    }

    public void u4(uint v) { u4((int)v); }
    public void u4(int v)
    {
      if (len+4 >= buf.Length) grow();
      buf[len++] = (byte)(v >> 24);
      buf[len++] = (byte)(v >> 16);
      buf[len++] = (byte)(v >> 8);
      buf[len++] = (byte)(v >> 0);
    }

    public void u4(int pos, uint v) { u4(pos, (int)v); }
    public void u4(int pos, int v)
    {
      // backpatch
      buf[pos+0] = (byte)(v >> 24);
      buf[pos+1] = (byte)(v >> 16);
      buf[pos+2] = (byte)(v >> 8);
      buf[pos+3] = (byte)(v >> 0);
    }

    public void u8(long v)
    {
      if (len+8 >= buf.Length) grow();
      buf[len++] = (byte)(v >> 56);
      buf[len++] = (byte)(v >> 48);
      buf[len++] = (byte)(v >> 40);
      buf[len++] = (byte)(v >> 32);
      buf[len++] = (byte)(v >> 24);
      buf[len++] = (byte)(v >> 16);
      buf[len++] = (byte)(v >> 8);
      buf[len++] = (byte)(v >> 0);
    }

    public void f4(float v)
    {
      u4(BitConverter.ToInt32(BitConverter.GetBytes(v), 0));
    }

    public void f8(double v)
    {
      u8(BitConverter.DoubleToInt64Bits(v));
    }

    public void append(Box box)
    {
      while (len + box.len >= buf.Length) grow();
      Array.Copy(box.buf, 0, buf, len, box.len);
      len += box.len;
    }

    public void skip(int num)
    {
      while (len + num >= buf.Length) grow();
      len += num;
    }

    public void utf(string s)
    {
      int slen = s.Length;
      int utflen = 0;

      // first we have to figure out the utf length
      for (int i=0; i<slen; ++i)
      {
        int c = s[i];
        if (c <= 0x007F)
        {
          utflen +=1;
        }
        else if (c > 0x07FF)
        {
          utflen += 3;
        }
        else
        {
          utflen += 2;
        }
      }

      // sanity check
      if (utflen > 65536) throw new Exception("string too big");

      // ensure capacity
      while (len + 2 + utflen >= buf.Length)
        grow();

      // write length as 2 byte value
      buf[len++] = (byte)((utflen >> 8) & 0xFF);
      buf[len++] = (byte)((utflen >> 0) & 0xFF);

      // write characters
      for (int i=0; i<slen; ++i)
      {
        int c = s[i];
        if (c <= 0x007F)
        {
          buf[len++] = (byte)c;
        }
        else if (c > 0x07FF)
        {
          buf[len++] = (byte)(0xE0 | ((c >> 12) & 0x0F));
          buf[len++] = (byte)(0x80 | ((c >>  6) & 0x3F));
          buf[len++] = (byte)(0x80 | ((c >>  0) & 0x3F));
        }
        else
        {
          buf[len++] = (byte)(0xC0 | ((c >>  6) & 0x1F));
          buf[len++] = (byte)(0x80 | ((c >>  0) & 0x3F));
        }
      }
    }

    private void grow()
    {
      byte[] temp = new byte[buf.Length*2];
      Array.Copy(buf, 0, temp, 0, buf.Length);
      buf = temp;
    }

    public void dump()
    {
      for (int i=0; i<len; ++i)
        System.Console.WriteLine("  [" + i + "] 0x" + (buf[i] & 0xFF).ToString("X"));
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public byte[] buf;
    public int len;

  }
}
