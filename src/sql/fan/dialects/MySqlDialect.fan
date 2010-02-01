//
// Copyright (c) 2008, John Sublett
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Jan 08  John Sublett  Creation
//

**
** MySql database specific dialect.
**
const class MySqlDialect : Dialect
{

  **
  ** The maximum length for a table name in MySQL is 64 characters.
  **
  override Int maxTableNameSize() { 64 }

  **
  ** The maximum length for an index name in MySQL is 64 characters.
  **
  override Int maxIndexNameSize() { 64 }

  **
  ** Get the blob type to use for a blob with the specified
  ** maximum length.
  **
  override Str blobType(Int maxLen)
  {
    if (maxLen <= 255)
      return "TINYBLOB"
    else if (maxLen <= 65535)
      return "BLOB"
    else if (maxLen <= 16777215)
      return "MEDIUMBLOB"
    else
      return "LONGBLOB"
  }

  **
  ** Get the clob type to use for a clob with the specified
  ** maximum length.
  **
  override Str clobType(Int maxLen)
  {
    if (maxLen <= 255)
      return "TINYTEXT"
    else if (maxLen <= 65535)
      return "TEXT"
    else if (maxLen <= 16777215)
      return "MEDIUMTEXT"
    else
      return "LONGTEXT"
  }

  **
  ** Get the MySQL specific qualifier for a column whose
  ** value is automatically incremented for a new row.
  **
  override Str auto()
  {
    return "AUTO_INCREMENT"
  }
}