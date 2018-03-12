//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//

**
** Network interface which models name and IP addresses assigned
**
final const class IpInterface
{

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  **
  ** List the interfaces on this machine
  **
  native static IpInterface[] list()

  **
  ** Find the interface bound to the given IP address.  If multiple
  ** interfaces are bound to the address it is undefined which one is
  ** returned.  If no interfaces are bound then return null or raise
  ** UnresolvedErr based on checked flag.
  **
  native static IpInterface? findByAddr(IpAddr addr, Bool checked := true)

  **
  ** Find the interface by its name.  If the interface is not found
  ** then return null or raise UnresolvedErr based on checked flag.
  **
  native static IpInterface? findByName(Str name, Bool checked := true)

  **
  ** Private constructor.
  **
  internal new make() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Hash code is based on interface name and addresses
  **
  override native Int hash()

  **
  ** Return string representation.
  **
  override native Str toStr()

  **
  ** Equality is based on interface name and addresses
  **
  override native Bool equals(Obj? obj)

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Name of the interface
  **
  native Str name()

  **
  ** Display name of the interface
  **
  native Str dis()

  **
  ** Return list of IP addresses bound to this interface
  **
  native IpAddr[] addrs()

  **
  ** Return list of all broadcast IP addresses bound to this interface
  **
  native IpAddr[] broadcastAddrs()

  **
  ** Return true if interface is up and running
  **
  native Bool isUp()

  **
  ** Media Access Control (MAC) or physical address for this interface
  ** return null if address does not exist.
  **
  native Buf? hardwareAddr()

  **
  ** Maximum transmission unit of interface
  **
  native Int mtu()

  **
  ** Return true if interface supports multicast
  **
  native Bool supportsMulticast()

  **
  ** Return true if point to point interface (PPP through modem)
  **
  native Bool isPointToPoint()

  **
  ** Return true if a loopback interface
  **
  native Bool isLoopback()

}