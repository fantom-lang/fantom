//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Apr 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import java.math.*;
import java.nio.*;
import java.security.*;
import javax.crypto.*;
import javax.crypto.spec.*;
import java.util.zip.*;

/**
 * Buf
 */
public abstract class Buf
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static Buf make() { return new MemBuf(1024); }
  public static Buf make(long capacity) { return new MemBuf((int)capacity); }

  public static Buf random(long s)
  {
    int size = (int)s;
    byte[] buf = new byte[size];

    for (int i=0; i<size;)
    {
      int x = FanInt.random.nextInt();
      buf[i++] = (byte)(x >> 24);
      if (i < size)
      {
        buf[i++] = (byte)(x >> 16);
        if (i < size)
        {
          buf[i++] = (byte)(x >> 8);
          if (i < size) buf[i++] = (byte)x;
        }
      }
    }

    return new MemBuf(buf);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object that)
  {
    return this == that;
  }

  public String toStr()
  {
    return typeof().name() + "(pos=" + pos() + " size=" + size() + ")";
  }

  public Type typeof() { return Sys.BufType; }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  public abstract int getByte(long pos);
  public abstract void getBytes(long pos, byte[] dst, int off, int len);
  public abstract void setByte(long pos, int x);

  public abstract void pipeTo(byte[] dst, int dstPos, int len);
  public abstract void pipeTo(OutputStream dst, long len) throws IOException;
  public abstract void pipeTo(RandomAccessFile dst, long len) throws IOException;
  public abstract void pipeTo(ByteBuffer dst, int len);

  public abstract void pipeFrom(byte[] src, int srcPos, int len);
  public abstract long pipeFrom(InputStream src, long len) throws IOException;
  public abstract long pipeFrom(RandomAccessFile src, long len) throws IOException;
  public abstract int pipeFrom(ByteBuffer src, int len);

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public final boolean isEmpty()
  {
    return size() == 0;
  }

  public long capacity()
  {
    return Long.MAX_VALUE;
  }

  public void capacity(long c)
  {
  }

  public abstract long size();

  public abstract void size(long s);

  public abstract long pos();

  abstract void pos(long p);

  public final long remaining()
  {
    return size()-pos();
  }

  public final boolean more()
  {
    return size()-pos() > 0;
  }

  public Buf seek(long pos)
  {
    long size = size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos > size) throw IndexErr.make(pos);
    pos(pos);
    return this;
  }

  public final Buf flip()
  {
    size(pos());
    pos(0);
    return this;
  }

  public final long get(long pos)
  {
    long size = size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos >= size) throw IndexErr.make(pos);
    return getByte(pos);
  }

  public final Buf getRange(Range range)
  {
    long size = size();
    long s = range.startIndex(size);
    long e = range.endIndex(size);
    int n = (int)(e - s + 1);
    if (n < 0) throw IndexErr.make(range);

    byte[] slice = new byte[n];
    getBytes(s, slice, 0, n);

    Buf result = new MemBuf(slice, n);
    result.charset(charset());
    return result;
  }

  public final Buf dup()
  {
    int size = (int)size();
    byte[] copy = new byte[size];
    getBytes(0, copy, 0, size);

    Buf result = new MemBuf(copy, size);
    result.charset(charset());
    return result;
  }

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  public final Buf set(long pos, long b)
  {
    long size = size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos >= size) throw IndexErr.make(pos);
    setByte(pos, (int)b);
    return this;
  }

  public Buf trim()
  {
    return this;
  }

  public final Buf clear()
  {
    pos(0);
    size(0);
    return this;
  }

  public final Buf flush()
  {
    return sync();
  }

  public Buf sync()
  {
    return this;
  }

  public boolean close()
  {
    return true;
  }

  public final Endian endian()
  {
    return out.endian();
  }

  public final void endian(Endian endian)
  {
    out.endian(endian);
    in.endian(endian);
  }

  public final Charset charset()
  {
    return out.charset();
  }

  public final void charset(Charset charset)
  {
    out.charset(charset);
    in.charset(charset);
  }

  public final Buf fill(long b, long times)
  {
    if (capacity() < size()+times) capacity(size()+times);
    int t = (int)times;
    for (int i=0; i<t; ++i) out.write(b);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public final OutStream out() { return out; }

  public final Buf write(long b) { out.write(b); return this; }

  public final Buf writeBuf(Buf other) { out.writeBuf(other); return this; }
  public final Buf writeBuf(Buf other, long n) { out.writeBuf(other, n); return this; }

  public final Buf writeI2(long x) { out.writeI2(x); return this; }

  public final Buf writeI4(long x) { out.writeI4(x); return this; }

  public final Buf writeI8(long x) { out.writeI8(x); return this; }

  public final Buf writeF4(double x) { out.writeF4(x); return this; }

  public final Buf writeF8(double x) { out.writeF8(x); return this; }

  public final Buf writeDecimal(BigDecimal x) { out.writeDecimal(x); return this; }

  public final Buf writeBool(boolean x) { out.writeBool(x); return this; }

  public final Buf writeUtf(String x) { out.writeUtf(x); return this; }

  public final Buf writeChar(long c) { out.writeChar(c); return this; }

  public final Buf writeChars(String s) { out.writeChars(s); return this; }
  public final Buf writeChars(String s, long off) { out.writeChars(s, off); return this; }
  public final Buf writeChars(String s, long off, long len) { out.writeChars(s, off, len); return this; }

  public final Buf print(Object obj) { out.print(obj); return this; }

  public final Buf printLine() { out.printLine(); return this; }
  public final Buf printLine(Object obj) { out.printLine(obj); return this; }

  public final Buf writeProps(Map props) { out.writeProps(props); return this; }

  public final Buf writeObj(Object obj) { out.writeObj(obj); return this; }
  public final Buf writeObj(Object obj, Map opt) { out.writeObj(obj, opt); return this; }

  public final Buf writeXml(String s) { out.writeXml(s, 0); return this; }
  public final Buf writeXml(String s, long flags) { out.writeXml(s, flags); return this; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public InStream in() { return in; }

  public final Long read() {  return in.read(); }

  public final Long readBuf(Buf other, long n) { return in.readBuf(other, n); }

  public final Buf unread(long n) { in.unread(n); return this; }

  public final Buf readBufFully(Buf buf, long n) { return in.readBufFully(buf, n); }

  public final Buf readAllBuf() { return in.readAllBuf(); }

  public final Long peek() { return in.peek(); }

  public final long readU1() { return in.readU1(); }

  public final long readS1() { return in.readS1(); }

  public final long readU2() { return in.readU2(); }

  public final long readS2() { return in.readS2(); }

  public final long readU4() { return in.readU4(); }

  public final long readS4() { return in.readS4(); }

  public final long readS8() { return in.readS8(); }

  public final double readF4() { return in.readF4(); }

  public final double readF8() { return in.readF8(); }

  public final BigDecimal readDecimal() { return in.readDecimal(); }

  public final boolean readBool() { return in.readBool(); }

  public final String readUtf() { return in.readUtf(); }

  public final Long readChar() { return in.readChar(); }

  public final Buf unreadChar(long c) { in.unreadChar(c); return this; }

  public final Long peekChar() { return in.peekChar(); }

  public final String readChars(long n) { return in.readChars(n); }

  public final String readLine() { return in.readLine(); }
  public final String readLine(Long max) { return in.readLine(max); }

  public final String readStrToken() { return in.readStrToken(); }
  public final String readStrToken(Long max) { return in.readStrToken(max); }
  public final String readStrToken(Long max, Func f) { return in.readStrToken(FanInt.Chunk, f); }

  public final List readAllLines() { return in.readAllLines(); }

  public final void eachLine(Func f) { in.eachLine(f); }

  public final String readAllStr() { return in.readAllStr(); }
  public final String readAllStr(boolean normalizeNewlines)  { return in.readAllStr(normalizeNewlines); }

  public final Map readProps() { return in.readProps(); }

  public final Object readObj() { return in.readObj(); }
  public final Object readObj(Map opt) { return in.readObj(opt); }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  public File toFile(Uri uri)
  {
    throw UnsupportedErr.make("Only supported on memory buffers");
  }

//////////////////////////////////////////////////////////////////////////
// Hex
//////////////////////////////////////////////////////////////////////////

  public String toHex()
  {
    byte[] buf = unsafeArray();
    int size = sz();
    char[] hexChars = Buf.hexChars;
    StringBuilder s = new StringBuilder(size*2);
    for (int i=0; i<size; ++i)
    {
      int b = buf[i] & 0xFF;
      s.append(hexChars[b>>4]).append(hexChars[b&0xf]);
    }
    return s.toString();
  }

  public static Buf fromHex(String str)
  {
    String s = str;
    int slen = s.length();
    byte[] buf = new byte[slen/2];
    int[] hexInv = Buf.hexInv;
    int size = 0;

    for (int i=0; i<slen; ++i)
    {
      int c0 = s.charAt(i);
      int n0 = c0 < 128 ? hexInv[c0] : -1;
      if (n0 < 0) continue;

      int n1 = -1;
      if (++i < slen)
      {
        int c1 = s.charAt(i);
        n1 = c1 < 128 ? hexInv[c1] : -1;
      }
      if (n1 < 0) throw IOErr.make("Invalid hex str");

      buf[size++] = (byte)((n0 << 4) | n1);
    }

    return new MemBuf(buf, size);
  }

  static char[] hexChars = "0123456789abcdef".toCharArray();
  static int[] hexInv    = new int[128];
  static
  {
    for (int i=0; i<hexInv.length; ++i) hexInv[i] = -1;
    for (int i=0; i<10; ++i)  hexInv['0'+i] = i;
    for (int i=10; i<16; ++i) hexInv['a'+i-10] = hexInv['A'+i-10] = i;
  }

//////////////////////////////////////////////////////////////////////////
// Base64
//////////////////////////////////////////////////////////////////////////

  public String toBase64()
  {
    return doBase64(Buf.base64chars, true);
  }

  public String toBase64Uri()
  {
    return doBase64(Buf.base64UriChars, false);
  }

  private String doBase64(char[] table, final boolean pad)
  {
    byte[] buf = this.unsafeArray();
    int size = this.sz();
    StringBuilder s = new StringBuilder(size*2);
    int i = 0;

    // append full 24-bit chunks
    int end = size-2;
    for (; i<end; i += 3)
    {
      int n = ((buf[i] & 0xff) << 16) + ((buf[i+1] & 0xff) << 8) + (buf[i+2] & 0xff);
      s.append(table[(n >>> 18) & 0x3f]);
      s.append(table[(n >>> 12) & 0x3f]);
      s.append(table[(n >>> 6) & 0x3f]);
      s.append(table[n & 0x3f]);
    }

    // pad and encode remaining bits
    int rem = size - i;
    if (rem > 0)
    {
      int n = ((buf[i] & 0xff) << 10) | (rem == 2 ? ((buf[size-1] & 0xff) << 2) : 0);
      s.append(table[(n >>> 12) & 0x3f]);
      s.append(table[(n >>> 6) & 0x3f]);
      s.append(rem == 2 ? table[n & 0x3f] : (pad ? '=' : ""));
      if (pad) s.append('=');
    }

    return s.toString();
  }

  public static Buf fromBase64(String s)
  {
    int slen = s.length();
    int si = 0;
    int max = slen * 6 / 8;
    byte[] buf = new byte[max];
    int size = 0;

    while (si < slen)
    {
      int n = 0;
      int v = 0;
      for (int j=0; j<4 && si<slen;)
      {
        int ch = s.charAt(si++);
        int c = ch < 128 ? base64inv[ch] : -1;
        if (c >= 0)
        {
          n |= c << (18 - j++ * 6);
          if (ch != '=') v++;
        }
      }

      if (v > 1) buf[size++] = (byte)(n >> 16);
      if (v > 2) buf[size++] = (byte)(n >> 8);
      if (v > 3) buf[size++] = (byte)n;
    }

    return new MemBuf(buf, size);
  }

  static char[] base64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".toCharArray();
  static char[] base64UriChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".toCharArray();
  static final int[] base64inv = new int[128];
  static
  {
    for (int i=0; i<base64inv.length; ++i)   base64inv[i] = -1;
    for (int i=0; i<base64chars.length; ++i) base64inv[base64chars[i]] = i;
    base64inv['-'] = 62;
    base64inv['_'] = 63;
    base64inv['='] = 0;
  }

//////////////////////////////////////////////////////////////////////////
// Digest
//////////////////////////////////////////////////////////////////////////

  public Buf toDigest(String algorithm)
  {
    try
    {
      MessageDigest md = MessageDigest.getInstance(algorithm);
      md.update(unsafeArray(), 0, sz());
      return new MemBuf(md.digest());
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unknown digest algorthm: " + algorithm);
    }
  }

//////////////////////////////////////////////////////////////////////////
// CRC
//////////////////////////////////////////////////////////////////////////

  public final long crc(String algorithm)
  {
    if (algorithm.equals("CRC-16")) return crc16();
    if (algorithm.equals("CRC-32")) return crc(new CRC32());
    if (algorithm.equals("CRC-32-Adler")) return crc(new Adler32());
    throw ArgErr.make("Unknown CRC algorthm: " + algorithm);
  }

  private long crc(Checksum checksum)
  {
    checksum.update(unsafeArray(), 0, sz());
    return checksum.getValue() & 0xffffffff;
  }

  private long crc16()
  {
    byte[] array = unsafeArray();
    int size = sz();
    int seed = 0xffff;
    for (int i=0; i<size; ++i) seed = crc16(array[i], seed);
    return seed;
  }

  private int crc16(int dataToCrc, int seed)
  {
    int dat = ((dataToCrc ^ (seed & 0xFF)) & 0xFF);
    seed = (seed & 0xFFFF) >>> 8;
    int index1 = (dat & 0x0F);
    int index2 = (dat >>> 4);
    if ((CRC16_ODD_PARITY[index1] ^ CRC16_ODD_PARITY[index2]) == 1)
      seed ^= 0xC001;
    dat  <<= 6;
    seed ^= dat;
    dat  <<= 1;
    seed ^= dat;
    return seed;
  }

  static private final int[] CRC16_ODD_PARITY = { 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0 };

//////////////////////////////////////////////////////////////////////////
// HMAC
//////////////////////////////////////////////////////////////////////////

  public Buf hmac(String algorithm, Buf keyBuf)
  {
    // get digest algorthim
    MessageDigest md = null;
    int blockSize = 64;
    try
    {
      md = MessageDigest.getInstance(algorithm);
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unknown digest algorthm: " + algorithm);
    }

    // get secret key bytes
    byte[] keyBytes = null;
    int keySize = 0;
    try
    {
      // get key bytes
      keyBytes = keyBuf.safeArray();
      keySize  = keyBytes.length;

      // key is greater than block size we hash it first
      if (keySize > blockSize)
      {
        md.update(keyBytes, 0, keySize);
        keyBytes = md.digest();
        keySize = keyBytes.length;
        md.reset();
      }
    }
    catch (ClassCastException e)
    {
      throw UnsupportedErr.make("key parameter must be memory buffer");
    }

    // RFC 2104:
    //   ipad = the byte 0x36 repeated B times
    //   opad = the byte 0x5C repeated B times
    //   H(K XOR opad, H(K XOR ipad, text))

    // inner digest: H(K XOR ipad, text)
    for (int i=0; i<blockSize; ++i)
    {
      if (i < keySize)
        md.update((byte)(keyBytes[i] ^ 0x36));
      else
        md.update((byte)0x36);
    }
    md.update(unsafeArray(), 0, sz());
    byte[] innerDigest = md.digest();

    // outer digest: H(K XOR opad, innerDigest)
    md.reset();
    for (int i=0; i<blockSize; ++i)
    {
      if (i < keySize)
        md.update((byte)(keyBytes[i] ^ 0x5C));
      else
        md.update((byte)0x5C);
    }
    md.update(innerDigest);

    // return result
    return new MemBuf(md.digest());
  }

//////////////////////////////////////////////////////////////////////////
// pbk
//////////////////////////////////////////////////////////////////////////

  public static Buf pbk(String algorithm, String pass, Buf _salt, long _iterations, long _keyLen)
  {
    try
    {
      // get low-level representation of args
      byte[] salt    = _salt.safeArray();
      int iterations = (int)_iterations;
      int keyLen     = (int)_keyLen;

      // this is not supported until Java8, so use custom implementation
      if (algorithm.equals("PBKDF2WithHmacSHA256"))
        return new MemBuf(PBKDF2WithHmacSHA256.gen(pass, salt, iterations, keyLen));

      // use built-in Java APIs
      PBEKeySpec spec = new PBEKeySpec(pass.toCharArray(), salt, iterations, keyLen*8);
      SecretKeyFactory skf = SecretKeyFactory.getInstance(algorithm);
      return new MemBuf(skf.generateSecret(spec).getEncoded());
    }
    catch (NoSuchAlgorithmException e)
    {
      throw ArgErr.make("Unsupported algorithm: " + algorithm, e);
    }
    catch (Exception e)
    {
      throw Err.make(e);
    }
  }

  // Implementation from:
  //   http://stackoverflow.com/questions/9147463/java-pbkdf2-with-hmacsha256-as-the-prf
  static class PBKDF2WithHmacSHA256
  {
    static byte[] gen(String pass, byte[] salt, int iterations, int dkLen)
      throws Exception
    {
      SecretKeySpec keyspec = new SecretKeySpec(pass.getBytes(), "HmacSHA256");
      Mac prf = Mac.getInstance("HmacSHA256");
      prf.init(keyspec);

      int hLen = prf.getMacLength(); // 20 for SHA1
      int l = Math.max(dkLen, hLen); //  1 for 128bit (16-byte) keys
      int r = dkLen - (l-1)*hLen;    // 16 for 128bit (16-byte) keys
      byte T[] = new byte[l * hLen];
      int ti_offset = 0;
      for (int i = 1; i <= l; i++)
      {
        F(T, ti_offset, prf, salt, iterations, i);
          ti_offset += hLen;
      }

      if (r < hLen)
      {
        // Incomplete last block
        byte DK[] = new byte[dkLen];
        System.arraycopy(T, 0, DK, 0, dkLen);
        return DK;
      }
      return T;
    }

    private static void F(byte[] dest, int offset, Mac prf, byte[] S, int c, int blockIndex)
    {
      final int hLen = prf.getMacLength();
      byte U_r[] = new byte[ hLen ];
      byte U_i[] = new byte[S.length + 4];
      System.arraycopy(S, 0, U_i, 0, S.length);
      INT(U_i, S.length, blockIndex);
      for(int i = 0; i < c; i++)
      {
        U_i = prf.doFinal(U_i);
        xor(U_r, U_i);
      }
      System.arraycopy(U_r, 0, dest, offset, hLen);
    }

    private static void xor(byte[] dest, byte[] src)
    {
      for(int i = 0; i < dest.length; i++)
        dest[i] ^= src[i];
    }

    private static void INT(byte[] dest, int offset, int i)
    {
      dest[offset + 0] = (byte) (i / (256 * 256 * 256));
      dest[offset + 1] = (byte) (i / (256 * 256));
      dest[offset + 2] = (byte) (i / (256));
      dest[offset + 3] = (byte) (i);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /* Get size cast to an int */
  public int sz()
  {
    throw UnsupportedErr.make(typeof()+".array");
  }

  /** Get direct access to backing byte array which contains
      data from 0 to sz.  This array must never be mutated
      outside of the class!!!! */
  public byte[] unsafeArray()
  {
    throw UnsupportedErr.make(typeof()+".array");
  }

  /** Get a copy of the backing byte array that is safe for mutating. */
  final public byte[] safeArray()
  {
    byte[] copy = new byte[this.sz()];
    System.arraycopy(unsafeArray(), 0, copy, 0, this.sz());
    return copy;
  }

  /** Implements {@link Interop#toJava(Buf)} */
  public ByteBuffer toByteBuffer()
  {
    throw UnsupportedErr.make(typeof()+".toByteBuffer");
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out;
  InStream in;

}