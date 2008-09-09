//
// Copyright (c) 2008, John Sublett
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jan 08  John Sublett  Creation
//

**
** Dialect encapsulates database specific behaviors for common database
** functions.
**
abstract const class Dialect
{
  **
  ** Get the maximum length for table names for the database type.
  **
  abstract Int maxTableNameLength()

  **
  ** Get the maximum length for index names for the database type.
  **
  abstract Int maxIndexNameLength()

  **
  ** Get the db specific qualifier for a unique column.
  ** Default is "UNIQUE".
  **
  virtual Str unique()
  {
    return "UNIQUE"
  }

  **
  ** Get the db specific qualifier for a column whose
  ** value cannot be null.  Default is "NOT NULL".
  **
  virtual Str notNull()
  {
    return "NOT NULL"
  }

  **
  ** Get the database specific blob type for a blob
  ** with the specified maximum length.
  **
  abstract Str getBlobType(Int maxLen)

  **
  ** Get the database specific clob type for a clob
  ** with the specified maximum length.
  **
  abstract Str getClobType(Int maxLen)

  **
  ** Get the db specific qualifier for a column whose
  ** value is automatically incremented for a new row.
  ** Default throws SqlErr.
  **
  virtual Str auto()
  {
    throw SqlErr("Auto increment is not supported by this database.")
  }
}