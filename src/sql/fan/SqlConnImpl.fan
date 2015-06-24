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
@NoDoc
class SqlConnImpl : SqlConn
{

//////////////////////////////////////////////////////////////////////////
// Connection
//////////////////////////////////////////////////////////////////////////

  ** Internal constructor
  internal new make() {}

  ** Backward compatiblity method
  static native SqlConn openDefault(Str uri, Str? username, Str? password)

  ** Return plain text information about JDBC drivers installed
  @NoDoc static native Str debugDrivers()

  ** Print debugDrivers report to stdout
  @NoDoc static Void printDebugDrivers() { echo; echo(debugDrivers) }

  **
  ** Close the database connection.  Closing a connection already
  ** closed is a no-op.  This method is guaranteed to never throw
  ** an exception.  Return true if the connection was closed
  ** successfully or 'false' if closed abnormally.
  **
  override native Bool close()

  **
  ** Return if `close` has been called.
  **
  override native Bool isClosed()

//////////////////////////////////////////////////////////////////////////
// Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the database meta-data
  **
  override native SqlMeta meta()

  **
  ** Create a statement for this database.
  **
  override Statement sql(Str sql) { Statement(this, sql) }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  **
  ** If auto-commit is true then each statement is executed and committed
  ** as an individual transaction.  Otherwise statements are grouped into
  ** transaction which must be closed via `commit` or `rollback`.
  **
  override native Bool autoCommit

  **
  ** Commit all the changes made inside the current transaction.
  **
  override native Void commit()

  **
  ** Undo any changes made inside the current transaction.
  **
  override native Void rollback()

}