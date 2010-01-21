//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Dec 08  Andy Frank  Ported from Java
//

using System;
using System.Management;
using System.Net;
using System.Net.Sockets;
using System.Runtime.CompilerServices;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Uuid.
  /// </summary>
  public sealed class Uuid : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Uuid fromStr(string str) { return fromStr(str, true); }
    public static Uuid fromStr(string str, bool check)
    {
      try
      {
        // sanity check
        if (str.Length != 36 || str[8] != '-' ||
            str[13] != '-' || str[18] != '-' || str[23] != '-')
          throw new Exception();

        // parse hex components
        long a = Convert.ToInt64(str.Substring(0, 8), 16);
        long b = Convert.ToInt64(str.Substring(9, 4), 16);
        long c = Convert.ToInt64(str.Substring(14, 4), 16);
        long d = Convert.ToInt64(str.Substring(19, 4), 16);
        long e = Convert.ToInt64(str.Substring(24), 16);

        return new Uuid((a << 32) | (b << 16) | c, (d << 48) | e);
      }
      catch (Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Uuid", str).val;
      }
    }

    public static Uuid make()
    {
      try
      {
        return m_factory.make();
      }
      catch (Exception e)
      {
        throw Err.make(e).val;
      }
    }

    public static Uuid makeBits(long hi, long lo)
    {
      return new Uuid(hi, lo);
    }

    private Uuid(long hi, long lo)
    {
      this.m_hi = hi;
      this.m_lo = lo;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public long bitsHi() { return m_hi; }

    public long bitsLo() { return m_lo; }

    public override bool Equals(object obj)
    {
      if (obj is Uuid)
      {
        Uuid x = (Uuid)obj;
        return this.m_hi == x.m_hi && this.m_lo == x.m_lo;
      }
      return false;
    }

    public override int GetHashCode()
    {
      long h = hash();
      return (int)(h ^ (h >> 32));
    }

    public override long hash()
    {
      return m_hi ^ m_lo;
    }

    public override long compare(object that)
    {
      Uuid x = (Uuid)that;
      if (m_hi != x.m_hi) return m_hi < x.m_hi ? -1 : 1;
      if (m_lo == x.m_lo) return 0;
      return m_lo < x.m_lo ? -1 : 1;
    }

    public override Type @typeof()
    {
      return Sys.UuidType;
    }

    public override string toStr()
    {
      StringBuilder s = new StringBuilder(36);
      append(s, ((m_hi >> 32) & 0xFFFFFFFFL), 8);
      s.Append('-');
      append(s, ((m_hi >> 16) & 0xFFFFL), 4);
      s.Append('-');
      append(s, m_hi & 0xFFFFL, 4);
      s.Append('-');
      append(s, (m_lo >> 48) & 0xFFFFL, 4);
      s.Append('-');
      append(s, m_lo & 0xFFFFFFFFFFFFL, 12);
      return s.ToString();
    }

    private static void append(StringBuilder s, long val, int width)
    {
      string str = val.ToString("X").ToLower();
      for (int i=str.Length; i<width; ++i) s.Append('0');
      s.Append(str);
    }

    /*
    public string format()
    {
      DateTime t = created();
      stringBuilder s = new stringBuilder();
      s.append(t.toLocale("YYYYMMDD-hhmmss.fffffffff"))
       .append('-')
       .append(Long.toHexstring((lo >> 48) & 0xFFFFL))
       .append('-')
       .append(Long.toHexstring(lo & 0xFFFFFFFFFFFFL));
      return s.tostring();
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // Factory
  //////////////////////////////////////////////////////////////////////////

    internal class Factory
    {
      internal Factory()
      {
        nodeAddr = resolveNodeAddr();
        seq = FanInt.random();
      }

      [MethodImpl(MethodImplOptions.Synchronized)]
      internal Uuid make()
      {
        return new Uuid(makeHi(), makeLo());
      }

      private long makeHi()
      {
        long now = (System.DateTime.Now.Ticks - DateTime.diffDotnet) / 10000L;
        if (lastMillis != now)
        {
          millisCounter = 0;
          lastMillis = now;
        }
        return (now * 1000000L) + millisCounter++;
      }

      private long makeLo()
      {
        return ((seq++ & 0xFFFFL) << 48) | nodeAddr;
      }

      private long resolveNodeAddr()
      {
        try { return resolveMacAddr(); } catch (Exception e) { Err.dumpStack(e); }
        try { return resolveIpAddr();  } catch (Exception e) { Err.dumpStack(e); }
        return FanInt.random();
      }

      private long resolveMacAddr()
      {
        ManagementClass m = new ManagementClass ("Win32_NetworkAdapterConfiguration");
        ManagementObjectCollection c = m.GetInstances();
        foreach (ManagementObject obj in c)
        {
          if ((bool)obj["IPEnabled"] == true)
          {
            string[] bytes = obj["MacAddress"].ToString().Split(':');
            byte[] mac = new byte[bytes.Length];
            for (int i=0; i<mac.Length; i++)
              mac[i] = (byte)(0xff & Convert.ToInt64(bytes[i], 16));
            return toLong(mac);
          }
        }
        throw new Exception();
      }

      private long resolveIpAddr()
      {
        // skip IPv6 address to get an IPv4 address
        string hostName = Dns.GetHostName();
        IPAddress local = null;
        IPAddress[] addr = Dns.GetHostAddresses(hostName);
        for (int i=0; i<addr.Length; i++)
          if (addr[i].AddressFamily == AddressFamily.InterNetwork)
          {
            local = addr[i];
            break;
          }
        return toLong(local.GetAddressBytes());
      }

      private long toLong(byte[] bytes)
      {
        // if bytes less then 6 pad with random
        if (bytes.Length < 6)
        {
          byte[] temp = new byte[6];
          Array.Copy(bytes, 0, temp, 0, bytes.Length);
          for (int i=bytes.Length; i<temp.Length; ++i)
            temp[i] = (byte)FanInt.random();
          bytes = temp;
        }

        // mask bytes into 6 byte long
        long x = ((bytes[0] & 0xFFL) << 40) |
                 ((bytes[1] & 0xFFL) << 32) |
                 ((bytes[2] & 0xFFL) << 24) |
                 ((bytes[3] & 0xFFL) << 16) |
                 ((bytes[4] & 0xFFL) <<  8) |
                 ((bytes[5] & 0xFFL) <<  0);

        // if we have more then six bytes mask against primary six bytes
        for (int i=6; i<bytes.Length; ++i)
          x ^= (bytes[i] & 0xFFL) << (((i - 6) % 6) * 8);

        return x;
      }

      internal long lastMillis;    // last use of currentTimeMillis
      internal int millisCounter;  // counter to uniquify currentTimeMillis
      internal long seq;           // 16 byte sequence to protect against clock changes
      internal long nodeAddr;      // 6 bytes for this node's address
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static readonly Factory m_factory = new Factory();

    private readonly long m_hi;
    private readonly long m_lo;

  }
}