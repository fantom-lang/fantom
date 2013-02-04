//
// Copyright (c) 2007, John Sublett
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Dec 07  John Sublett   Creation
//

**
** Statement is an executable statement for a specific database.
** A statement may be executed immediately or prepared and
** executed later with parameters.
** See [pod-doc]`pod-doc#statements`.
**
class Statement
{
  **
  ** Make a new statement with the specified SQL text.
  **
  internal new make(SqlConnImpl conn, Str sql)
  {
    this.conn = conn
    this.sql = sql
    init
  }

  private native Void init()

  **
  ** Prepare this statement by compiling for efficient
  ** execution.  Return this.
  **
  native This prepare()

  **
  ** Execute the statement and return the resulting 'List'
  ** of 'Rows'.  The 'Cols' are available from 'List.of.fields' or
  ** on 'type.fields' of each row instance.
  **
  native Row[] query([Str:Obj]? params := null)

  **
  ** Execute the statement.  For each row in the result, invoke
  ** the specified function 'each'.  The 'Obj' passed to the
  ** 'each' function will be of type 'Row'.
  **
  native Void queryEach([Str:Obj]? params, |Row row| eachFunc)

  **
  ** Execute a SQL statement and if applicable return a result:
  **   - If the statement is a query or procedure which produces
  **     a result set, then return 'Row[]'
  **   - If the statement is an insert and auto-generated keys
  **     are supported by the connector then return 'Int[]' or 'Str[]'
  **     of keys generated
  **   - Return an 'Int' with the update count
  **
  native Obj execute([Str:Obj]? params := null)

  **
  ** If the last execute has more results from a multi-result stored
  ** procedure, then return the next batch of results as Row[].  Otherwise
  ** if there are no more results then return null.
  **
  @NoDoc native Row[]? more()

  **
  ** Close the statement.
  **
  native Void close()

///////////////////////////////////////////////////////////
// Fields
///////////////////////////////////////////////////////////

  **
  ** The connection that this statement uses.
  **
  internal SqlConnImpl conn { private set }

  **
  ** The SQL text used to create this statement.
  **
  const Str sql

  **
  ** Maximum number of rows returned when this statement is
  ** executed.  If limit is exceeded rows are silently dropped.
  ** A value of null indicates no limit.
  **
  native Int? limit

}