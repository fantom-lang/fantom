//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//

**
** SqlConn manages a connection to a relational database.
** See [pod-doc]`pod-doc#connections`.
**
mixin SqlConn
{

//////////////////////////////////////////////////////////////////////////
// Connection
//////////////////////////////////////////////////////////////////////////

  **
  ** Open a connection to the database specified by the given
  ** JDBC uri and username/password credentials.  Raise exception
  ** if connection cannot be established.
  ** See [pod-doc]`pod-doc#connections`.
  **
  static SqlConn open(Str uri, Str? username, Str? password)
  {
    SqlConnImpl.openDefault(uri,username,password)
  }

  **
  ** Close the database connection.  Closing a connection already
  ** closed is a no-op.  This method is guaranteed to never throw
  ** an exception.  Return true if the connection was closed
  ** successfully or 'false' if closed abnormally.
  **
  abstract Bool close()

  **
  ** Return if `close` has been called.
  **
  abstract Bool isClosed()

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the database meta-data
  **
  abstract SqlMeta meta()

  **
  ** Create a statement for this database.
  **
  abstract Statement sql(Str sql)

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  **
  ** If auto-commit is true then each statement is executed and committed
  ** as an individual transaction.  Otherwise statements are grouped into
  ** transaction which must be closed via `commit` or `rollback`.
  **
  abstract Bool autoCommit

  **
  ** Commit all the changes made inside the current transaction.
  **
  abstract Void commit()

  **
  ** Undo any changes made inside the current transaction.
  **
  abstract Void rollback()

}