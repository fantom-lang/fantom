//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 08  Brian Frank  Creation
//
package fan.sys;

import java.net.*;
import java.util.*;

/**
 * Uuid
 */
public final class Uuid
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Uuid fromStr(String str) { return fromStr(str, true); }
  public static Uuid fromStr(String str, boolean checked)
  {
    try
    {
      // sanity check
      if (str.length() != 36 || str.charAt(8) != '-' ||
          str.charAt(13) != '-' || str.charAt(18) != '-' || str.charAt(23) != '-')
        throw new Exception();

      // parse hex components
      long a = Long.parseLong(str.substring(0, 8), 16);
      long b = Long.parseLong(str.substring(9, 13), 16);
      long c = Long.parseLong(str.substring(14, 18), 16);
      long d = Long.parseLong(str.substring(19, 23), 16);
      long e = Long.parseLong(str.substring(24), 16);

      return new Uuid((a << 32) | (b << 16) | c, (d << 48) | e);
    }
    catch (Throwable e)
    {
      if (!checked) return null;
      throw ParseErr.make("Uuid", str).val;
    }
  }

  public static Uuid make()
  {
    try
    {
      return factory.make();
    }
    catch (Throwable e)
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
    this.hi = hi;
    this.lo = lo;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public long bitsHi() { return hi; }

  public long bitsLo() { return lo; }

  public boolean equals(Object obj)
  {
    if (obj instanceof Uuid)
    {
      Uuid x = (Uuid)obj;
      return this.hi == x.hi && this.lo == x.lo;
    }
    return false;
  }

  public int hashCode()
  {
    long h = hash();
    return (int)(h ^ (h >>> 32));
  }

  public long hash()
  {
    return hi ^ lo;
  }

  public long compare(Object that)
  {
    Uuid x = (Uuid)that;
    if (hi != x.hi) return hi < x.hi ? -1 : 1;
    if (lo == x.lo) return 0;
    return lo < x.lo ? -1 : 1;
  }

  public Type typeof()
  {
    return Sys.UuidType;
  }

  public String toStr()
  {
    StringBuilder s = new StringBuilder(36);
    append(s, ((hi >> 32) & 0xFFFFFFFFL), 8);
    s.append('-');
    append(s, ((hi >> 16) & 0xFFFFL), 4);
    s.append('-');
    append(s, hi & 0xFFFFL, 4);
    s.append('-');
    append(s, (lo >> 48) & 0xFFFFL, 4);
    s.append('-');
    append(s, lo & 0xFFFFFFFFFFFFL, 12);
    return s.toString();
  }

  private static void append(StringBuilder s, long val, int width)
  {
    String str = Long.toHexString(val);
    for (int i=str.length(); i<width; ++i) s.append('0');
    s.append(str);
  }

  /*
  public String format()
  {
    DateTime t = created();
    StringBuilder s = new StringBuilder();
    s.append(t.toLocale("YYYYMMDD-hhmmss.fffffffff"))
     .append('-')
     .append(Long.toHexString((lo >> 48) & 0xFFFFL))
     .append('-')
     .append(Long.toHexString(lo & 0xFFFFFFFFFFFFL));
    return s.toString();
  }
  */

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  static class Factory
  {
    Factory()
    {
      nodeAddr = resolveNodeAddr();
      seq = FanInt.random.nextLong();
    }

    synchronized Uuid make()
      throws Exception
    {
      return new Uuid(makeHi(), makeLo());
    }

    private long makeHi()
    {
      long now = System.currentTimeMillis() - DateTime.diffJava;
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
      // first try MAC address
      try { return resolveMacAddr(); }
      catch (NoSuchMethodError e) {}  // ignore if not on 1.6
      catch (NoSuchElementException e) {}  // ignore if no network interfaces
      catch (Throwable e) { e.printStackTrace(); }

      // then try local IP address
      try { return resolveIpAddr();  }
      catch (Throwable e) { e.printStackTrace(); }

      // last fallback to just a random number
      return FanInt.random.nextLong();
    }

    private long resolveMacAddr()
      throws Exception
    {
      // use 1.6 API to get MAC address
      Enumeration e = NetworkInterface.getNetworkInterfaces();
      while (e.hasMoreElements())
      {
        NetworkInterface net = (NetworkInterface)e.nextElement();
        byte[] mac = net.getHardwareAddress();
        if (mac != null) return toLong(mac);
      }
      throw new NoSuchElementException();
    }

    private long resolveIpAddr()
      throws Exception
    {
      return toLong(InetAddress.getLocalHost().getAddress());
    }

    private long toLong(byte[] bytes)
    {
      // if bytes less then 6 pad with random
      if (bytes.length < 6)
      {
        byte[] temp = new byte[6];
        System.arraycopy(bytes, 0, temp, 0, bytes.length);
        for (int i=bytes.length; i<temp.length; ++i)
          temp[i] = (byte)FanInt.random.nextInt();
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
      for (int i=6; i<bytes.length; ++i)
        x ^= (bytes[i] & 0xFFL) << (((i - 6) % 6) * 8);

      return x;
    }

    long lastMillis;    // last use of currentTimeMillis
    int millisCounter;  // counter to uniquify currentTimeMillis
    long seq;           // 16 byte sequence to protect against clock changes
    long nodeAddr;      // 6 bytes for this node's address
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Factory factory = new Factory();

  private final long hi;
  private final long lo;

}