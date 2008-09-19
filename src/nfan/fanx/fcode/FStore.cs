//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;
using System.Text;
using ICSharpCode.SharpZipLib.Zip;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FStore models IO streams to use for reading and writing pod files.
  /// </summary>
  public sealed class FStore
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Construct a FStore to read.
    /// </summary>
    public FStore(FPod fpod, ZipFile zipFile)
    {
      this.fpod    = fpod;
      this.zipFile = zipFile;
      if (zipFile == null) throw new Exception();
    }

  //////////////////////////////////////////////////////////////////////////
  // File Access
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// List all the files available.
    /// </summary>
    public string[] list()
    {
      ArrayList acc = new ArrayList();
      IEnumerator en = zipFile.GetEnumerator();
      while (en.MoveNext())
        acc.Add(((ZipEntry)en.Current).Name);
      return (String[])acc.ToArray(System.Type.GetType("System.String"));
    }

    /// <summary>
    /// Return a map to use for Pod.files()
    /// </summary>
    public Map podFiles()
    {
      Map map = new Map(Sys.UriType, Sys.FileType);
      IEnumerator en = zipFile.GetEnumerator();
      while (en.MoveNext())
      {
        ZipEntry entry = (ZipEntry)en.Current;
        string name = entry.Name;
        if (name.EndsWith(".fcode")) continue;
        if (name.EndsWith(".class")) continue;
        Fan.Sys.ZipEntryFile file = new Fan.Sys.ZipEntryFile(zipFile, entry);
        map.set(file.uri(), file);
      }
      return map;
    }

    /// <summary>
    /// Convenience for read(path, false).
    /// </summary>
    public FStore.Input read(string path)
    {
      return read(path, false);
    }

    /// <summary>
    /// Open an input stream for the specified logical path.
    /// Return null if not found.
    /// </summary>
    public FStore.Input read(string path, bool required)
    {
      ZipEntry entry = zipFile.GetEntry(path);
      if (entry == null)
      {
        if (required)
          throw new Exception("Missing required file \"" + path + "\" in pod zup");
        else
          return null;
      }
      return new FStore.Input(fpod, new BufferedStream(zipFile.GetInputStream(entry)));
    }

    /// <summary>
    /// Close this FStore, which should release all file locks
    /// on the pod file. This method exists for testing purposes,
    /// and should not otherwise be used.
    /// </summary>
    public void close()
    {
      zipFile.Close();
    }

  //////////////////////////////////////////////////////////////////////////
  // FStore.Input
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// FStore.Input is used to read from a FStore file.
    /// </summary>
    public class Input : BinaryReader
    {
      public Input(FPod fpod, Stream baseStream) : base(baseStream) { this.fpod = fpod; }

      public int u1()  { return ReadByte() & 0xff; }
      public int u2()
      {
        Read(buf, 0, 2);
        return ((buf[0] & 0xff) << 8) | (buf[1] & 0xff);
      }
      public int u4()
      {
        Read(buf, 0, 4);
        return ((buf[0] & 0xff) << 24) |
               ((buf[1] & 0xff) << 16) |
               ((buf[2] & 0xff) << 8) |
                (buf[3] & 0xff);
      }
      public long u8()
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
      public double f8()
      {
        return BitConverter.Int64BitsToDouble(u8());
      }
      public string utf()
      {
        // Java actually uses a modified UTF-8 encoding, so we
        // need to manually decode the date to get it right:
        // http://java.sun.com/javase/6/docs/api/java/io/DataInput.html#readUTF()

        // TODO - this doesn't look any different that regular UTF8, but
        // I already wrote it so lets keep it around anyways

        int len = u2();
        if (len == 0) return "";

        byte[] buf = new byte[len];
        for (int r=0; r<len;) r += Read(buf, r, len-r);
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
      public string name()
      {
        return fpod.name(u2());
      }
      public int skip(int n)
      {
        byte[] buf = new byte[n];
        return Read(buf, 0, n);
      }

      Exception utfErr()
      {
        return new IOException("Invalid UTF-8 encoding");
      }

      public readonly FPod fpod;
      byte[] buf = new byte[8];
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal readonly FPod fpod;
    internal readonly ZipFile zipFile;

  }
}
