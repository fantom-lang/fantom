//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Nov 07  Brian Frank  Creation
//
package fan.sql;

import java.sql.*;
import fan.sys.*;

/*
  TODO: do we need this?

public class TableResourcePeer
  extends MemResourcePeer
{

//////////////////////////////////////////////////////////////////////////
// Peer Factory
//////////////////////////////////////////////////////////////////////////

  public static TableResourcePeer make(TableResource resource)
  {
    return new TableResourcePeer(resource);
  }

  TableResourcePeer(TableResource resource)
  {
    super(resource);
  }

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static TableResource make(Uri uri)
  {
    TableResource r = TableResource.internalMake(uri);
    TableResourcePeer p = (TableResourcePeer)r.peer();
    return r;
  }

//////////////////////////////////////////////////////////////////////////
// MemResourcePeer
//////////////////////////////////////////////////////////////////////////

  public Resource newResource(Uri uri)
  {
    return TableResource.internalMake(uri);
  }

  public List list()
  {
    // TODO
    return Resource.emptyList;
  }

  public void add(Resource child)
  {
    checkMountedWorking();
    // TODO
  }

}
*/