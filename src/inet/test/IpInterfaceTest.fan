//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jul 13  Brian Frank  Creation
//

using concurrent

class IpInterfaceTest : Test
{

//////////////////////////////////////////////////////////////////////////
// List
//////////////////////////////////////////////////////////////////////////

  Void testList()
  {
    list := IpInterface.list
    verifyEq(list.typeof, IpInterface[]#)
    verifyEq(list.isEmpty, false)
    list.each |x| { verifyEq(x, x) }
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    good := IpAddr.local
    i := IpInterface.find(good)
    verifyEq(i.addrs.contains(good), true)
    verifyEq(i, i)

    bad := IpAddr("0.1.2.3")
    verifyErr(Err#) { IpInterface.find(bad) }
    verifyErr(Err#) { IpInterface.find(bad, true) }
    verifyEq(IpInterface.find(bad, false), null)
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /*
  Void dump(IpInterface i)
  {
    echo("---------")
    echo("name              = $i.name")
    echo("dis               = $i.dis")
    echo("toStr             = $i.toStr")
    echo("isUp              = $i.isUp")
    echo("hardwareAddr      = ${i.hardwareAddr?.toHex}")
    echo("mtu               = $i.mtu")
    echo("supportsMulticast = $i.supportsMulticast")
    echo("isPointToPoint    = $i.isPointToPoint")
    echo("isLoopback        = $i.isLoopback")
    echo("addrs             = $i.addrs")
  }
  */

}