//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Sep 26  Mike Jarmy  Creation
//

**************************************************************************
** DialectType
**************************************************************************

** DialectType is how a single logical type is spelled in one database:
** the DDL used to declare it, and the metadata we expect back for it.
internal const class DialectType
{
  new make(Str ddl, Str sqlType, Type fanType)
  {
    this.ddl     = ddl
    this.sqlType = sqlType
    this.fanType = fanType
  }

  ** DDL fragment used in "create table"
  const Str ddl

  ** Expected Col.sqlType; compared case-insensitively
  const Str sqlType

  ** Expected Col.type
  const Type fanType

  override Str toStr() { "$ddl [$sqlType -> $fanType.name]" }
}

**************************************************************************
** ColDef
**************************************************************************

** ColDef is one column in a test table: its name, and the logical type
** key that each Dialect maps to real DDL.
internal const class ColDef
{
  new make(Str name, Str type, Bool notNull := false)
  {
    this.name    = name
    this.type    = type
    this.notNull = notNull
  }

  const Str name
  const Str type
  const Bool notNull

  override Str toStr() { "$name $type" }
}

**************************************************************************
** Dialect
**************************************************************************

** Dialect models the DDL and metadata differences between the databases
** that SqlTest runs against.
**
** Dialect is test-only.  The sql pod itself has no notion of database
** identity beyond `SqlMeta.productName`, and should not grow one: what
** differs here is mostly DDL, which is outside the pod's remit.
internal const class Dialect
{

//////////////////////////////////////////////////////////////////////////
// Instances
//////////////////////////////////////////////////////////////////////////

  ** See pod-doc "Test Setup" for the one-time local server config.
  static const Dialect mysql := Dialect
  {
    it.name        = "mysql"
    it.productName = "MySQL"
    it.uri         = "jdbc:mysql://localhost:3306/fantest"
    it.username    = "fantest"
    it.password    = "fantest"

    // auto_increment must be a key
    it.autoKeySuffix = "primary key (id)"

    it.hasArrays           = false
    it.hasUserVars         = true
    it.hasJsonb            = false
    it.keysOnNonAutoInsert = false

    it.types = [
      "id":   DialectType("int auto_increment", "INT",      Int#),
      "str":  DialectType("varchar(255)",       "VARCHAR",  Str#),
      "char": DialectType("char(4)",            "CHAR",     Str#),
      "bool": DialectType("bit",                "BIT",      Bool#),
      "i8":   DialectType("tinyint",            "TINYINT",  Int#),
      "i16":  DialectType("smallint",           "SMALLINT", Int#),
      "i32":  DialectType("int",                "INT",      Int#),
      "i64":  DialectType("bigint",             "BIGINT",   Int#),
      "f32":  DialectType("float",              "FLOAT",    Float#),
      "f64":  DialectType("double",             "DOUBLE",   Float#),
      "dec":  DialectType("decimal(9,2)",       "DECIMAL",  Decimal#),
      "dt":   DialectType("datetime",           "DATETIME", DateTime#),
      "date": DialectType("date",               "DATE",     Date#),
      "time": DialectType("time",               "TIME",     Time#),
      "buf":  DialectType("blob",               "BLOB",     Buf#),
    ]
  }

  ** See pod-doc "Test Setup" for the one-time local server config.
  static const Dialect postgres := Dialect
  {
    it.name        = "postgres"
    it.productName = "PostgreSQL"
    it.uri         = "jdbc:postgresql://localhost:5432/postgres"
    it.username    = "fantest"
    it.password    = "fantest"

    // serial needs no separate key constraint
    it.autoKeySuffix = null

    it.hasArrays           = true
    it.hasUserVars         = false
    it.hasJsonb            = true
    it.keysOnNonAutoInsert = true

    it.types = [
      // postgres has no 1-byte int, so i8 widens to smallint; the column
      // still round-trips, it just doesn't exercise JDBC Types.TINYINT
      "id":   DialectType("serial",       "SERIAL",      Int#),
      "str":  DialectType("varchar(255)", "VARCHAR",     Str#),
      "char": DialectType("char(4)",      "BPCHAR",      Str#),
      "bool": DialectType("bool",         "BOOL",        Bool#),
      "i8":   DialectType("smallint",     "INT2",        Int#),
      "i16":  DialectType("smallint",     "INT2",        Int#),
      "i32":  DialectType("int",          "int4",        Int#),
      "i64":  DialectType("bigint",       "INT8",        Int#),
      "f32":  DialectType("real",         "FLOAT4",      Float#),
      "f64":  DialectType("float",        "FLOAT8",      Float#),
      "dec":  DialectType("decimal(9,2)", "NUMERIC",     Decimal#),
      "dt":   DialectType("timestamptz",  "TIMESTAMPTZ", DateTime#),
      "date": DialectType("date",         "DATE",        Date#),
      "time": DialectType("time",         "TIME",        Time#),
      "buf":  DialectType("bytea",        "BYTEA",       Buf#),
    ]
  }

  ** All dialects SqlTest runs against
  static const Dialect[] all := [mysql, postgres]

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  new make(|This| f) { f(this) }

  ** Short name used in test output
  const Str name

  ** Expected SqlMeta.productName; asserted at connect so that crossed
  ** ports fail immediately instead of deep inside a type assertion
  const Str productName

  ** JDBC uri
  const Str uri

  ** Credentials
  const Str? username
  const Str? password

  ** Table constraint appended by `createTable` when the table has an
  ** "id" column, or null if the auto-key type needs no separate key
  const Str? autoKeySuffix

  ** Logical type name to how this database spells it
  const Str:DialectType types

//////////////////////////////////////////////////////////////////////////
// Features
//////////////////////////////////////////////////////////////////////////

  ** Does this database support array columns (postgres "text[]" etc)?
  const Bool hasArrays

  ** Does this database support session variables (mysql "@v1")?
  const Bool hasUserVars

  ** Does this database support the jsonb containment operator "@>"?
  const Bool hasJsonb

  ** Does the driver return generated keys for an insert into a table
  ** with no auto-increment column?  Postgres does; mysql does not.
  const Bool keysOnNonAutoInsert

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Lookup a logical type, or raise ArgErr if not defined
  DialectType typeDef(Str logical)
  {
    types[logical] ?: throw ArgErr("$name has no logical type '$logical'")
  }

  ** Generate a "create table" statement for the given columns.  If any
  ** column uses the "id" logical type then autoKeySuffix is appended.
  Str createTable(Str table, ColDef[] cols)
  {
    buf := StrBuf()
    buf.add("create table ").add(table).add(" (\n")
    cols.each |c, i|
    {
      if (i > 0) buf.add(",\n")
      buf.add("  ").add(c.name).add(" ").add(typeDef(c.type).ddl)
      if (c.notNull) buf.add(" not null")
    }
    if (autoKeySuffix != null && cols.any |c| { c.type == "id" })
      buf.add(",\n  ").add(autoKeySuffix)
    buf.add(")")
    return buf.toStr
  }

  override Str toStr() { name }

//////////////////////////////////////////////////////////////////////////
// Schemas
//////////////////////////////////////////////////////////////////////////

  ** The main test table: one column per logical type, named after the
  ** type so that a failure message identifies what broke.  "v_str" is
  ** the one not-null column, so it doubles as the constraint-violation
  ** target for the error tests.
  static const ColDef[] valsCols :=
  [
    ColDef("id",     "id"),
    ColDef("v_str",  "str", true),
    ColDef("v_char", "char"),
    ColDef("v_bool", "bool"),
    ColDef("v_i8",   "i8"),
    ColDef("v_i16",  "i16"),
    ColDef("v_i32",  "i32"),
    ColDef("v_i64",  "i64"),
    ColDef("v_f32",  "f32"),
    ColDef("v_f64",  "f64"),
    ColDef("v_dec",  "dec"),
    ColDef("v_dt",   "dt"),
    ColDef("v_date", "date"),
    ColDef("v_time", "time"),
    ColDef("v_buf",  "buf"),
  ]

  ** A table with no auto-generated key, so that the batch tests can
  ** distinguish drivers that return keys anyway; see keysOnNonAutoInsert.
  static const ColDef[] batchCols :=
  [
    ColDef("n",     "i32", true),
    ColDef("v_str", "str", true),
  ]

  ** A table whose key really is auto-generated
  static const ColDef[] batchAutoCols :=
  [
    ColDef("id",    "id"),
    ColDef("v_str", "str", true),
  ]
}
