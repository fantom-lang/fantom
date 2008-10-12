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
**
** See `docLib::Sql`.
**
class Statement
{
  **
  ** Make a new statement with the specified SQL text.
  **
  internal new make(Connection conn, Str sql)
  {
    this.conn = conn
    this.sql = sql
  }

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
  ** Execute a SQL statement and if applicable return
  ** the number of rows modified.
  **
  native Int execute([Str:Obj]? params := null)

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
  internal readonly Connection conn

  **
  ** The SQL text used to create this statement.
  **
  readonly Str sql
}