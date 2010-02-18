//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//

**
** Connection manages a logical connection to an SQL database.
**
internal class Connection
{

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Open a connection to a SQL database.  Throw 'Err' on failure.
  **
  ** In a Java platform, the connection is opened using JDBC.  The
  ** connSpec Str specifies the an implementation specific string
  ** for connecting to the database.  In the Java runtime, this
  ** is the 'java.sql.Connection' URL.  The JDBC driver class should
  ** be preloaded.
  **
  static native Connection open(Str connSpec, Str? username, Str? password, Dialect dialect)

  **
  ** Internal constructor.
  **
  internal new make() {}

  **
  ** Return if this connection has been closed.
  **
  native Bool isClosed()

  **
  ** Close the connection.  This method is guaranteed to never throw
  ** an 'Err'.  Return true if the connection was closed successfully
  ** or 'false' if closed abnormally.
  **
  native Bool close()

//////////////////////////////////////////////////////////////////////////
// Database metadata
//////////////////////////////////////////////////////////////////////////

  **
  ** Does the specified table exist in the database?
  **
  native Bool tableExists(Str tableName)

  **
  ** List the tables in the database.  Returns a list of the
  ** table names.
  **
  native Str[] tables()

  **
  ** Get a default row instance for the specified table.  The
  ** result has a field for each table column.
  **
  native Row tableRow(Str tableName)

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  **
  ** Create a statement for this connection.
  **
  Statement sql(Str sql)
  {
    return Statement(this, sql)
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  **
  ** If auto commit is 'true', then each statement is executed
  ** immediately.  Otherwise statements are executed inside a
  ** transaction which is terminated by a call to 'commit'
  ** or 'rollback'.  Auto commit defaults to 'true'.
  **
  Bool autoCommit
  {
    get { return getAutoCommit }
    set { setAutoCommit(it) }
  }
  private native Bool getAutoCommit()
  private native Void setAutoCommit(Bool b)


  **
  ** Commit all the changes made inside the current transaction.
  **
  native Void commit()

  **
  ** Undo any changes made inside the current transaction.
  **
  native Void rollback()

//////////////////////////////////////////////////////////////////////////
// Open count
//////////////////////////////////////////////////////////////////////////

  **
  ** Increment the open count.
  **
  internal native Int increment()

  **
  ** Decrement the open count.
  **
  internal native Int decrement()

}