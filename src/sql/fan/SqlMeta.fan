//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jan 11  Brian Frank  Creation
//

**
** SqlMeta provides access to database meta-data
**
class SqlMeta
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Internal constructor
  internal new make() {}

//////////////////////////////////////////////////////////////////////////
// Versioning
//////////////////////////////////////////////////////////////////////////

  ** Name of database product
  native Str productName()

  ** Product version of database as "major.minor"
  native Version productVersion()

  ** Product version of database as free-form string
  native Str productVersionStr()

  ** Name of connection driver to database
  native Str driverName()

  ** Version of of connection driver to database as "major.minor"
  native Version driverVersion()

  ** Version of of connection driver to database as free-form string
  native Str driverVersionStr()

//////////////////////////////////////////////////////////////////////////
// Limits
//////////////////////////////////////////////////////////////////////////

  ** Max number of chars in column name or null if no known limit
  native Int? maxColName()

  ** Max number of chars in table name or null if no known limit
  native Int? maxTableName()

//////////////////////////////////////////////////////////////////////////
// Tables
//////////////////////////////////////////////////////////////////////////

  ** Does the specified table exist in the database?
  native Bool tableExists(Str tableName)

  ** List the tables in the database.
  native Str[] tables()

  ** Get a column meta-data for for the specified table
  ** as a prototype row instance.
  native Row tableRow(Str tableName)
}