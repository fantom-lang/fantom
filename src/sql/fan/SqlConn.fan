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
class SqlConn
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
  native static SqlConn open(Str uri, Str? username, Str? password)

  ** Internal constructor
  internal new make() {}

  **
  ** Close the database connection.  Closing a connection already
  ** closed is a no-op.  This method is guaranteed to never throw
  ** an exception.  Return true if the connection was closed
  ** successfully or 'false' if closed abnormally.
  **
  native Bool close()

  **
  ** Return if `close` has been called.
  **
  native Bool isClosed()

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the database meta-data
  **
  native SqlMeta meta()

  **
  ** Create a statement for this database.
  **
  Statement sql(Str sql) { Statement(this, sql) }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  **
  ** If auto-commit is true then each statement is executed and committed
  ** as an individual transaction.  Otherwise statements are grouped into
  ** transaction which must be closed via `commit` or `rollback`.
  **
  native Bool autoCommit

  **
  ** Commit all the changes made inside the current transaction.
  **
  native Void commit()

  **
  ** Undo any changes made inside the current transaction.
  **
  native Void rollback()

}