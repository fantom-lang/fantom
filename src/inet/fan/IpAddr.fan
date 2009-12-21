//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 07  Brian Frank  Creation
//

**
** IpAddr models both IPv4 and IPv6 numeric addresses as well
** as provide DNS hostname resolution.
**
final class IpAddr
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse an IP address formated as an IPv4 numeric address, IPv6
  ** numeric address, or a DNS hostname.  If a hostname if provided,
  ** then it is resolved to an IP address potentially blocking the
  ** calling thread.  If the address is invalid or a hostname cannot
  ** be resolved then UnknownHostErr is thrown.
  **
  ** Examples:
  **   IpAddr("169.200.3.103")
  **   IpAddr("1080:0:0:0:8:800:200C:417A")
  **   IpAddr("1080::8:800:200C:417A")
  **   IpAddr("::ffff:129.144.52.38")
  **   IpAddr("somehost")
  **   IpAddr("www.acme.com")
  **
  native static IpAddr make(Str s)

  **
  ** Resolve a hostname to all of its configured IP addresses. If a
  ** numeric IPv4 or IPv6 address is specified then a list of one
  ** IpAddr is returned.  If a hostname if provided, then it is
  ** resolved to all its configured IP addresses potentially blocking
  ** the calling thread.  If the address is invalid or a hostname
  ** cannot be resolved then UnknownHostErr is thrown.
  **
  native static IpAddr[] makeAll(Str s)

  **
  ** Make an IpAddr for the specified raw bytes.  The size of
  ** the byte buffer must be 4 for IPv4 or 16 for IPv6, otherwise
  ** ArgErr is thrown.  The bytes must be a memory backed buffer.
  **
  native static IpAddr makeBytes(Buf bytes)

  **
  ** Return the IpAddr for the local machine.
  **
  native static IpAddr local()

  **
  ** Private constructor.
  **
  internal new internalMake() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Hash code is based the address bytes.
  **
  override native Int hash()

  **
  ** Equality is based on equivalent address bytes.
  **
  override native Bool equals(Obj? obj)

  **
  ** Return the exact string passed to the constructor.
  **
  override native Str toStr()

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Is this a 32 bit (four byte) IP version 4 address.
  **
  native Bool isIPv4()

  **
  ** Is this a 128 bit (sixteen byte) IP version 6 address.
  **
  native Bool isIPv6()

  **
  ** Get the raw bytes of this address as a Buf of 4 or 16 bytes
  ** for IPv4 or IPv6 respectively.  The buf position is zero.
  **
  native Buf bytes()

  **
  ** Get this address as a Str in its numeric notation.  For IPv4
  ** this is four decimal digits separated by dots.  For IPv6 this
  ** is eight hexadecimal digits separated by colons.
  **
  native Str numeric()

  **
  ** Return the hostname of this address.  If a hostname was specified
  ** in make, then that string is used.  Otherwise this method will perform
  ** a reverse DNS lookup potentially blocking the calling thread.  If
  ** the address cannot be mapped to a hostname, then return the address
  ** in its numeric format.
  **
  native Str hostname()

}