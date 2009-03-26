//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Mar 09  Brian Frank  Creation
//

**
** Services are used to publish functionality in a VM for use by
** other software components.  The service registry for the VM is
** keyed by public types each service implements.  Service are
** automatically mapped into the namespace under "/sys/service/{qname}"
** for all their public types.
**
const mixin Service
{

  **
  ** List all the installed services.
  **
  static Service[] list()

  **
  ** Find an installed service by type.  If not found and checked
  ** is false return null, otherwise throw UnknownServiceErr.  If
  ** multiple services are registered for the given type then return
  ** the first one registered.
  **
  static Service? find(Type t, Bool checked := true)

  **
  ** Find all services installed for the given type.  If no
  ** services are found then return an empty list.
  **
  static Service[] findAll(Type t)

  **
  ** Install this service into the VM's service registry.
  ** If already installed, do nothing.  Return this.
  **
  This install()

  **
  ** Uninstall this service from the VM's service registry.
  ** If not installed, do nothing.  Return this.
  **
  This uninstall()

}