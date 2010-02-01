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
  ** Get the maximum length for table names for the database
  ** type. Default is 64.
  **
  virtual Int maxTableNameSize() { 64 }

  **
  ** Get the maximum length for index names for the database
  ** type. Default is 64.
  **
  virtual Int maxIndexNameSize() { 64 }

  **
  ** Get the db specific qualifier for a unique column.
  ** Default is "UNIQUE".
  **
  virtual Str unique() { "UNIQUE" }

  **
  ** Get the db specific qualifier for a column whose
  ** value cannot be null.  Default is "NOT NULL".
  **
  virtual Str notNull() { "NOT NULL" }

  **
  ** Get the database specific blob type for a blob with
  ** the specified maximum length.  Default is "BLOB".
  **
  virtual Str blobType(Int maxLen) { "BLOB" }

  **
  ** Get the database specific clob type for a clob
  ** with the specified maximum length.  Default is "TEXT".
  **
  virtual Str clobType(Int maxLen) { "TEXT" }

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