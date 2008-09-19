//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Oct 07  Andy Frank  Creation
//

using System;
using System.IO;
using System.Text;

namespace Fanx.Util
{
  /// <summary>
  /// DataReader is an implemention of java.io.DataInputStream for .NET.
  /// </summary>
  public class DataReader : BinaryReader
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Construct a new DataReader for the given stream.
    /// </summary>
    public DataReader(Stream baseStream) : base(baseStream)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Reads one input byte and returns true if that byte is
    /// nonzero, false if that byte is zero.
    /// </summary>
    public override bool ReadBoolean()
    {
      return ReadByte() != 0;
    }

    /// <summary>
    /// Reads and returns one input byte.
    /// </summary>
    //public byte ReadByte()
    //{
    //  return base.ReadByte() & 0xff;
    //}

    /// <summary>
    /// Reads an input char and returns the char value
    /// </summary>
    public override char ReadChar()
    {
      Read(buf, 0, 2);
      return (char)((buf[0] << 8) | (buf[1] & 0xff));
    }

    /// <summary>
    /// Reads eight input bytes and returns a double value.
    /// </summary>
    public override double ReadDouble()
    {
      return BitConverter.Int64BitsToDouble(ReadLong());
    }

    /// <summary>
    /// Reads four input bytes and returns a float value.
    /// </summary>
    public float ReadFloat()
    {
      Read(buf, 0, 4);
      return BitConverter.ToSingle(buf, 0);
    }

    /// <summary>
    /// Reads some bytes from an input stream and stores them
    /// into the buffer array b.
    /// </summary>
    public void ReadFully(byte[] b)
    {
      ReadFully(b, 0, b.Length);
    }

    /// <summary>
    /// Reads len bytes from an input stream.
    /// </summary>
    public void ReadFully(byte[] b, int off, int len)
    {
      for (int r=off; r<len;) r += Read(b, r, len-r);
    }

    /// <summary>
    /// Reads four input bytes and returns an int value.
    /// </summary>
    public int ReadInt()
    {
      Read(buf, 0, 4);
      return ((buf[0] & 0xff) << 24) |
             ((buf[1] & 0xff) << 16) |
             ((buf[2] & 0xff) << 8) |
              (buf[3] & 0xff);
    }

    /// <summary>
    /// Reads eight input bytes and returns a long value.
    /// </summary>
    public long ReadLong()
    {
      Read(buf, 0, 8);
      return ((long)(buf[0] & 0xff) << 56) |
             ((long)(buf[1] & 0xff) << 48) |
             ((long)(buf[2] & 0xff) << 40) |
             ((long)(buf[3] & 0xff) << 32) |
             ((long)(buf[4] & 0xff) << 24) |
             ((long)(buf[5] & 0xff) << 16) |
             ((uint)(buf[6] & 0xff) <<  8) |
             ((uint)(buf[7] & 0xff));
    }

    /// <summary>
    /// Reads two input bytes and returns a short value.
    /// </summary>
    public short ReadShort()
    {
      Read(buf, 0, 2);
      return (short)((buf[0] << 8) | (buf[1] & 0xff));
    }

    /// <summary>
    /// Reads one input byte, zero-extends it to type int, and
    /// returns the result, which is therefore in the range 0
    /// through 255.
    /// </summary>
    public int ReadUnsignedByte()
    {
      return ReadByte() & 0xff;
    }

    /// <summary>
    /// Reads two input bytes and returns an int value in the
    /// range 0 through 65535.
    /// </summary>
    public int ReadUnsignedShort()
    {
      Read(buf, 0, 2);
      return ((buf[0] & 0xff) << 8) | (buf[1] & 0xff);
    }

    /// <summary>
    /// Reads in a string that has been encoded using a modified
    /// UTF-8 format.
    /// </summary>
    public string ReadUTF()
    {
      // Java actually uses a modified UTF-8 encoding, so we
      // need to manually decode the date to get it right:
      // http://java.sun.com/javase/6/docs/api/java/io/DataInput.html#modified-utf-8
      // http://java.sun.com/javase/6/docs/api/java/io/DataInput.html#readUTF()

      int len = ReadUnsignedShort();
      if (len == 0) return "";

      byte[] buf = new byte[len];
      ReadFully(buf);
      StringBuilder s = new StringBuilder(len);

      for (int i=0; i<len;)
      {
        byte a = buf[i++];
        if ((a & 0x80) == 0) // 0xxxxxxx
        {
          // single byte
          s.Append((char)(a & 0xff));
        }
        else if ((a & 0xe0) == 0xc0) // 110xxxxx
        {
          // two bytes
          if (i >= len) throw utfErr();
          byte b = buf[i++];  if ((b & 0xc0) != 0x80) throw utfErr();
          s.Append((char)(((a & 0x1f) << 6) | (b & 0x3f)));
        }
        else if ((a & 0xf0) == 0xe0) // 1110xxxx
        {
          // three bytes
          if (i+1 >= len) throw utfErr();
          byte b = buf[i++];  if ((b & 0xc0) != 0x80) throw utfErr();
          byte c = buf[i++];  if ((c & 0xc0) != 0x80) throw utfErr();
          s.Append((char)(((a & 0x0f) << 12) | ((b & 0x3f) << 6) | (c & 0x3f)));
        }
        else throw utfErr(); // 1111xxxx or 10xxxxxx
      }

      return s.ToString();
    }

    /// <summary>
    /// Makes an attempt to skip over n bytes of data from the
    /// input stream, discarding the skipped bytes.
    /// </summary>
    public int SkipBytes(int n)
    {
      byte[] buf = new byte[n];
      return Read(buf, 0, n);
    }

    Exception utfErr()
    {
      return new IOException("Invalid UTF-8 encoding");
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    byte[] buf = new byte[8];  // reuse array for perf

  }
}
