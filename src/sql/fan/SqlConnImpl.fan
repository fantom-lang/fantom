//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jun 07  Brian Frank  Creation
//

using concurrent

**
** SqlConn manages a connection to a relational database.
** See [pod-doc](pod-doc#connections).
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
  ** successfully or `false` if closed abnormally.
  **
  override native Bool close()

  **
  ** Return if [close] has been called.
  **
  override native Bool isClosed()

  **
  ** Ping that the connection is still alive using JDBC Connection.isValid.
  **
  @NoDoc override native Bool isValid(Duration timeout)

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

  **
  ** Default statement timeout, applied by Statement as each JDBC
  ** statement is created.  Null means no timeout.
  **
  @NoDoc Duration? queryTimeout

  @NoDoc override Void setQueryTimeout(Duration? t) { queryTimeout = t }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  **
  ** If auto-commit is true then each statement is executed and committed
  ** as an individual transaction.  Otherwise statements are grouped into
  ** transaction which must be closed via [commit] or [rollback].
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

**************************************************************************
** TestSqlConn
**************************************************************************

@NoDoc
internal class TestSqlConn: SqlConn
{
  static const AtomicInt idCounter := AtomicInt()

  ** Connections created minus connections closed; a pool that leaks a
  ** connection leaves this above where it started.
  static const AtomicInt openCount := AtomicInt()

  internal new make() { id = idCounter.getAndIncrement; openCount.increment }
  const Int id
  override Bool close()
  {
    if (!closed) { closed = true; openCount.decrement }
    return true
  }
  override Bool isClosed() { return closed }
  override Bool isValid(Duration timeout)
  {
    lastValidateTimeout = timeout
    return valid
  }
  override SqlMeta meta() { throw Err() }
  override Statement sql(Str sql) { throw Err() }
  override Bool autoCommit
  {
    set { ops.add("autoCommit($it)"); &autoCommit = it }
  }
  override Void commit() { commits++; ops.add("commit") }
  override Void rollback() { rollbacks++; ops.add("rollback") }
  override Str toStr() { "TestSqlConn-$id" }
  private Bool closed

  override Void setQueryTimeout(Duration? t) { queryTimeout = t }

  // test hooks to simulate failures and record pool behavior
  Bool valid := true
  Duration? lastValidateTimeout
  Duration? queryTimeout
  Int commits
  Int rollbacks
  Str[] ops := [,]
}

