//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

class IpAddrTest : Test
{

  public Void test()
  {
    // numeric IPv4
    verifyAddr("192.168.1.105", [192, 168, 1, 105])
    verifyAddr("255.0.128.0",   [255, 0, 128, 0])

    // numeric IPv6
    verifyAddr("1123:4567:89ab:cdef:fedc:ba98:7654:3210",
               [0x11, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10],
               "1123:4567:89ab:cdef:fedc:ba98:7654:3210")
    verifyAddr("f123:4567::89ab:cdef",
               [0xf1, 0x23, 0x45, 0x67, 0, 0, 0, 0, 0, 0, 0, 0, 0x89, 0xab, 0xcd, 0xef],
               "f123:4567:0:0:0:0:89ab:cdef",
               "f123:4567::89ab:cdef")
    verifyAddr("::f123:89ab:CDEF",
               [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xf1, 0x23, 0x89, 0xab, 0xcd, 0xef],
               "0:0:0:0:0:f123:89ab:cdef",
               "::f123:89ab:cdef")
    verifyAddr("::FE77:169.2.30.200",
               [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xfe, 0x77, 169, 2, 30, 200],
               "0:0:0:0:0:fe77:a902:1ec8",
               "::fe77:a902:1ec8")
    verifyAddr("::169.2.30.200",
               [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 169, 2, 30, 200],
               "0:0:0:0:0:0:a902:1ec8",
               "::169.2.30.200")

    // invalid
    verifyErr(UnknownHostErr#) { IpAddr("0123:4567:89ab:cdef:fedc:ba98:7654:3210:ffff") }
    verifyErr(UnknownHostErr#) { IpAddr("::fx54:3210:ffff") }
    verifyErr(UnknownHostErr#) { IpAddr("not.going.to.happen.") }

    // local
    verifySame(IpAddr.local, IpAddr.local)

    // host lookup (will this test last the test of time...
    ms := IpAddr.makeAll("microsoft.com")
    verify(ms.size > 1)

    // identity
    verifyEq(ms[0], IpAddr(ms[0].numeric))
    verifyEq(ms[0].hash, IpAddr(ms[0].numeric).hash)
    verifyNotEq(ms[0], IpAddr(ms[1].numeric))
    verifyNotEq(ms[0].hash, IpAddr(ms[1].numeric).hash)
    verifyEq(IpAddr("www.microsoft.com"), IpAddr("WWW.Microsoft.COM"))
    verifyEq(IpAddr("www.microsoft.com").hash, IpAddr("WWW.Microsoft.COM").hash)
  }

  Void verifyAddr(Str str, Int[] bytes, Str numeric := str, Str? numericAlt := null)
  {
    // check fields
    a := IpAddr(str)
    verifyEq(a.toStr, str)
    verifyEq(a.isIPv4,  bytes.size == 4)
    verifyEq(a.isIPv6,  bytes.size == 16)
    try
    {
      verifyEq(a.numeric, numeric)
    }
    catch (Err err)
    {
      if (numericAlt != null)
        verifyEq(a.numeric, numericAlt)
      else
        throw err
    }

    // map bytes to Buf
    buf := Buf.make
    bytes.each |Int b| { buf.write(b) }
    verifyEq(a.bytes.toHex, buf.toHex)

    // ensure buf ready to read
    2.times
    {
      abytes := a.bytes
      bytes.each |Int b| { verifyEq(abytes.read, b) }
    }

    // map to new instance by bytes
    // NOTE: Java appears to normalize the host address string
    // differently when made by bytes, but I don't think we should
    // push that into the Fantom API contract
    x := IpAddr.makeBytes(a.bytes)
    verifyEq(a, x)
    verifyEq(a.bytes.toHex, x.bytes.toHex)
    verifyEq(a.isIPv4,  x.isIPv4)

    // makeAll
    all := IpAddr.makeAll(str)
    verifyEq(all.size, 1)
    verifyEq(all[0].toStr, str)
    verifyEq(all[0], a)
  }

  /*
  Void dump(IpAddr a)
  {
    echo("-------------------")
    echo("toStr    = $a")
    echo("isIPv4   = $a.isIPv4")
    echo("isIPv6   = $a.isIPv6")
    echo("bytes    = $a.bytes")
    echo("numeric  = $a.numeric")
    echo("hostname = $a.hostname")
    echo("hash     = $a.hash")
  }
  */

}