//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 07  John Sublett  Creation
//

**
** SqlServiceTest (maybe rename from old test)
**
class SqlServiceTest : Test
{

  internal SqlConn? db
  internal DbType? dbType

  internal Str? uri
  internal Str? user
  internal Str? pass

//////////////////////////////////////////////////////////////////////////
// Top
//////////////////////////////////////////////////////////////////////////

  Void test()
  {
    open
    try
    {
      verifyMeta
      dropTables
      createTable
      insertTable
      closures
      transactions
      preparedStmts
      executeStmts
      pool
    }
    catch (Err e)
    {
      throw e
    }
    finally
    {
      db.close
      verify(db.isClosed)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Open
//////////////////////////////////////////////////////////////////////////

  Void open()
  {
    pod  := typeof.pod
    uri  = pod.config("test.uri")      ?: throw Err("Missing 'sql::test.uri' config prop")
    user = pod.config("test.username") ?: throw Err("Missing 'sql::test.username' config prop")
    pass = pod.config("test.password") ?: throw Err("Missing 'sql::test.password' config prop")
    db = SqlConn.open(uri, user, pass)
    verifyEq(db.isClosed, false)

    if (uri.contains("mysql"))
    {
      dbType = DbType.mysql
    }
    else if (uri.contains("postgresql"))
    {
      dbType = DbType.postgres
    }
    else
    {
      throw Err("Uri '$uri' connects to unknown database type")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Verify Meta
//////////////////////////////////////////////////////////////////////////

  **
  ** Verify the metadata
  **
  Void verifyMeta()
  {
    // call each SqlMeta no-arg method
    debug := false
    if (debug)  echo("=== SqlMeta ===")
    meta := db.meta
    meta.typeof.methods.each |m|
    {
      if (m.parent != SqlMeta#) return
      if (m.isCtor || !m.isPublic) return
      if (m.params.size > 0) return
      val := m.callOn(meta,[,])
      if (debug) echo("$m.name: " + val)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Drop Tables
//////////////////////////////////////////////////////////////////////////

  **
  ** Drop all tables in the database
  **
  Void dropTables()
  {
    verifyEq(db.meta.tableExists("foo_bar_should_not_exist"), false)

    // TODO Currently, db.meta.tables fetches every single table from every
    // schema.  In both Postgres and MySQL, this means it ends up fetching all
    // the various system tables as well.  We should probably fix SqlMeta so it
    // can fetch tables for a specific schema.  In our test case here, that
    // schema would be 'fantest'.
    //
    // In the original version of this test, it tried to drop every single one
    // of these system tables, which fails spectacularly.  I'm not sure how
    // this test ever worked before.
    //
    // I've modified this test so that it just tries to drop the one table that
    // actually gets created in the 'fantest' schema, namely 'farmers'.

    if (db.meta.tableExists("farmers"))
      db.sql("drop table farmers").execute

    // OLD VERSION
    //Str[] tables := db.meta.tables.dup
    //while (tables.size != 0)
    //{
    //  Int dropped := 0
    //  tables.each |Str tableName|
    //  {
    //    verifyEq(db.meta.tableExists(tableName), true)
    //    try
    //    {
    //      db.sql("drop table $tableName").execute
    //      tables.remove(tableName)
    //      dropped++
    //    }
    //    catch (Err e)
    //    {
    //      e.trace
    //    }
    //  }
    //
    //  if (dropped == 0)
    //    throw SqlErr("All tables could not be dropped.")
    //}
  }

//////////////////////////////////////////////////////////////////////////
// Create Table
//////////////////////////////////////////////////////////////////////////

  Void createTable()
  {
    if (dbType == DbType.postgres)
    {
      db.sql(
       "create table farmers(
        farmer_id serial,
        name      varchar(255) not null,
        married   bool,
        pet       varchar(255),
        ss        char(4),
        age       int,
        pigs      smallint,
        cows      int,
        ducks     bigint,
        height    float,
        weight    real,
        bigdec    decimal(2,1),
        dt        timestamptz,
        d         date,
        t         time)").execute
    }
    else
    {
      db.sql(
       "create table farmers(
        farmer_id int auto_increment not null,
        name      varchar(255) not null,
        married   bit,
        pet       varchar(255),
        ss        char(4),
        age       tinyint,
        pigs      smallint,
        cows      int,
        ducks     bigint,
        height    float,
        weight    double,
        bigdec    decimal(2,1),
        dt        datetime,
        d         date,
        t         time,
        primary key (farmer_id))
        ").execute
    }

    row := db.meta.tableRow("farmers")
    cols := row.cols

    verifyEq(cols.size, 15)
    verifyEq(cols.isRO, true)
    verifyEq(cols is Col[], true)
    verifyType(cols, Col[]#)
    verifyFarmerCols(row)

    verifyEq(row.col("foobar", false), null)
    verifyErr(ArgErr#) { row.col("foobar") }
    verifyErr(ArgErr#) { row.col("foobar", true) }
  }

//////////////////////////////////////////////////////////////////////////
// Insert Table
//////////////////////////////////////////////////////////////////////////

  Void insertTable()
  {
    // insert a couple rows
    dt := DateTime(2009, Month.dec, 15, 23, 19, 21)
    date := Date("1972-09-10")
    time := Time("14:31:55")
    data := [
      [1, "Alice",   false, "Pooh",     "abcd", 21,   1,   80,  null, 5.3f,  120f, 3.2d, dt, date, time],
      [2, "Brian",   true,  "Haley",    "1234", 35,   2,   99,   5,   5.7f,  140f, 1.5d, dt, date, time],
      [3, "Charlie", null,  "Addi",     null,   null, 3,   44,   7,   null, 6.1f,  2.0d, dt, date, time],
      [4, "Donny",   true,  null,       "wxyz", 40,  null, null, 8,   null, null,  5.0d, dt, date, time],
      [5, "John",    true,  "Berkeley", "5678", 35,  null, null, 8,   null, null,  5.7d, dt, date, time],
    ]
    data.each |Obj[] row| { insertFarmer(row[1..-1]) }

    // query
    rows := query("select * from farmers order by farmer_id")
    verifyFarmerCols(rows.first)
    verifyEq(data.size, rows.size)
    data.each |Obj[] d, Int i| { verifyRow(rows[i], d) }

    // query with type
    farmers := db.sql("select * from farmers order by farmer_id").query
    verifyType(farmers, Row[]#)
    verifyEq(farmers is Row[], true)
    verifyEq(farmers[0] is Row, true)
    f := farmers[0]
    verifyEq(f->farmer_id, 1)
    verifyEq(f->name,     "Alice")
    verifyEq(f->married,   false)
    verifyEq(f->pet,      "Pooh")
    verifyEq(f->ss,       "abcd")
    verifyEq(f->age,      21)
    verifyEq(f->pigs,     1)
    verifyEq(f->cows,     80)
    verifyEq(f->ducks,    null)
    verifyEq(f->height,   5.3f)
    verifyEq(f->weight,   120.0f)
    verifyEq(f->bigdec,   3.2d)
    verifyEq(f->dt,       dt)
    verifyEq(f->d,        date)
    verifyEq(f->t,        time)

    // mixed case
    verifyEq(f.get(f.col("name")), "Alice")
    verifyEq(f.get(f.col("Name")), "Alice")
    verifyEq(f.get(f.col("NAME")), "Alice")
    verifyEq(f->Name,  "Alice")
    verifyEq(f->NAME,  "Alice")

    verifyEq(f[f.col("pet")], "Pooh")
  }

  Void insertFarmer(Obj[] row)
  {
    s :=
      "insert into farmers (name, married, pet, ss, age, pigs, cows, ducks, height, weight, bigdec, dt, d, t)
       values (@name, @married, @pet, @ss, @age, @pigs, @cows, @ducks, @height, @weight, @bigdec, @dt, @d, @t)"
    stmt := db.sql(s).prepare
    Int[] keys := stmt.execute([
      "name":    row[0],
      "married": row[1],
      "pet":     row[2],
      "ss":      row[3],
      "age":     row[4],
      "pigs":    row[5],
      "cows":    row[6],
      "ducks":   row[7],
      "height":  row[8],
      "weight":  row[9],
      "bigdec":  row[10],
      "dt":      row[11],
      "d":       row[12],
      "t":       row[13]
    ])
    stmt.close

    // verify we got key back
    verifyEq(keys.size, 1)
    verifyEq(keys.typeof, Int[]#)

    // read with key and verify it is what we just wrote
    stmt = db.sql("select * from farmers where farmer_id = @farmerId").prepare
    farmer := stmt.query(["farmerId":keys.first]).first
    stmt.close
    verifyEq(farmer->name, row[0])
  }

  Void verifyFarmerCols(Row r)
  {
    verifyEq(r.cols.size, 15)
    verifyEq(r.cols.isRO, true)

    if (dbType == DbType.postgres)
    {
      verifyCol(r.cols[0],  0,  "farmer_id", Int#,      "SERIAL")
      verifyCol(r.cols[1],  1,  "name",      Str#,      "VARCHAR")
      verifyCol(r.cols[2],  2,  "married",   Bool#,     "BOOL")
      verifyCol(r.cols[3],  3,  "pet",       Str#,      "VARCHAR")
      verifyCol(r.cols[4],  4,  "ss",        Str#,      "BPCHAR")
      verifyCol(r.cols[5],  5,  "age",       Int#,      "int4")
      verifyCol(r.cols[6],  6,  "pigs",      Int#,      "INT2")
      verifyCol(r.cols[7],  7,  "cows",      Int#,      "int4")
      verifyCol(r.cols[8],  8,  "ducks",     Int#,      "INT8")
      verifyCol(r.cols[9],  9,  "height",    Float#,    "FLOAT8")
      verifyCol(r.cols[10], 10, "weight",    Float#,    "FLOAT4")
      verifyCol(r.cols[11], 11, "bigdec",    Decimal#,  "NUMERIC")
      verifyCol(r.cols[12], 12, "dt",        DateTime#, "TIMESTAMPTZ")
      verifyCol(r.cols[13], 13, "d",         Date#,     "DATE")
      verifyCol(r.cols[14], 14, "t",         Time#,     "TIME")
    }
    else
    {
      verifyCol(r.cols[0],  0,  "farmer_id", Int#,      "INT")
      verifyCol(r.cols[1],  1,  "name",      Str#,      "VARCHAR")
      verifyCol(r.cols[2],  2,  "married",   Bool#,     "BIT")
      verifyCol(r.cols[3],  3,  "pet",       Str#,      "VARCHAR")
      verifyCol(r.cols[4],  4,  "ss",        Str#,      "CHAR")
      verifyCol(r.cols[5],  5,  "age",       Int#,      "TINYINT")
      verifyCol(r.cols[6],  6,  "pigs",      Int#,      "SMALLINT")
      verifyCol(r.cols[7],  7,  "cows",      Int#,      "INT")
      verifyCol(r.cols[8],  8,  "ducks",     Int#,      "BIGINT")
      verifyCol(r.cols[9],  9,  "height",    Float#,    "FLOAT")
      verifyCol(r.cols[10], 10, "weight",    Float#,    "DOUBLE")
      verifyCol(r.cols[11], 11, "bigdec",    Decimal#,  "DECIMAL")
      verifyCol(r.cols[12], 12, "dt",        DateTime#, "DATETIME")
      verifyCol(r.cols[13], 13, "d",         Date#,     "DATE")
      verifyCol(r.cols[14], 14, "t",         Time#,     "TIME")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Closures
//////////////////////////////////////////////////////////////////////////

  Void closures()
  {
    ages := Int?[,]
    db.sql("select age from farmers").query.each |Obj row| { ages.add(row->age) }

    ages2 := Int?[,]
    db.sql("select name, age from farmers").queryEach(null) |Obj row|
    {
      if (row->age != null)
        ages2.add((Int)row->age + 10)
      else
        ages2.add(null)
    }

    ages.each |Int? age, Int i|
    {
      if (age != null) verifyEq(age+10, ages2[i])
    }

    ages.clear
    ages2.clear
    db.sql("select age from farmers where age > 30").query.each |Obj row| { ages.add(row->age) }
    Statement stmt := db.sql("select age from farmers where age > @age").prepare
    stmt.queryEach(["age":30]) |Obj row|
    {
      if (row->age != null)
        row->age = (Int)row->age + 10
      ages2.add(row->age)
    }

    ages.each |Int? age, Int i|
    {
      if (age != null) verifyEq(age+10, ages2[i])
    }

    Int i := 0
    db.sql("select * from farmers").queryEach(null) |Row row|
    {
      if (i != 0) return
      verifyEq(row.cols.size, Farmer#.fields.size)
      Farmer#.fields.each |Field f, Int index|
      {
        //verifyEq(row.type.field(f.name), null)
        col := row.col(f.name)
        verify(col != null)
        if (f.name == "farmer_id") verifyEq(col.type, Int#)
        if (f.name == "married") verifyEq(col.type, Bool#)
        if (f.name == "pet") verifyEq(col.type, Str#)
        if (f.name == "height") verifyEq(col.type, Float#)
      }
      i++
    }

    // queryEachWhile
    verifyEq(
      db.sql("select * from farmers").queryEachWhile(null) |row->Obj?|
        { return (row->age == 40) ? row->name : null },
      "Donny")
    verifyEq(
      db.sql("select * from farmers").queryEachWhile(null) |row->Obj?|
        { return (row->name == "Frodo") ? row->age : null },
      null)
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  Void transactions()
  {
    verifyEq(db.autoCommit, true)
    db.autoCommit = false
    verifyEq(db.autoCommit, false)
    db.commit

    rows := query("select name from farmers order by name")
    verifyEq(rows.size, 5)
    verifyEq(rows[0]->name, "Alice")
    verifyEq(rows[1]->name, "Brian")
    verifyEq(rows[2]->name, "Charlie")
    verifyEq(rows[3]->name, "Donny")
    verifyEq(rows[4]->name, "John")

    insertFarmer(["Bad", false, "Bad",  "bad!", 21, 1, 80, null, 5.3f, 120f, 7.7d, DateTime.now, Date.today, Time.now])
    db.rollback
    rows = query("select name from farmers order by name")
    verifyEq(rows.size, 5)
    verifyEq(rows[0]->name, "Alice")
    verifyEq(rows[1]->name, "Brian")
    verifyEq(rows[2]->name, "Charlie")
    verifyEq(rows[3]->name, "Donny")
    verifyEq(rows[4]->name, "John")
  }

//////////////////////////////////////////////////////////////////////////
// Prepared Statements
//////////////////////////////////////////////////////////////////////////

  Void preparedStmts()
  {
    stmt := db.sql("select name, age from farmers where name = @name").prepare
    result := stmt.query(["name":"Alice"])
    verifyEq(result[0]->name, "Alice");
    result = stmt.query(["name":"Brian"])
    verifyEq(result[0]->name, "Brian");
    result = stmt.query(["name":"Charlie"])
    verifyEq(result[0]->name, "Charlie");
    result = stmt.query(["name":"Donny"])
    verifyEq(result[0]->name, "Donny");
    result = stmt.query(["name":"John"])
    verifyEq(result[0]->name, "John");
    stmt.close()

    stmt = db.sql("select name, age from farmers where age > @age").prepare
    result = stmt.query(["age":30])
    verifyEq(result.size, 3)
    result.each |Obj row| { verify(result[0]->age > 30, result[0]->age.toStr + " <= 30") }
    stmt.close()

    stmt = db.sql("select name, age from farmers where name = @name and age = @age").prepare
    result = stmt.query(["name":"John", "age":35])
    verifyEq(result.size, 1)
    verifyEq(result[0]->name, "John")
    verifyEq(result[0]->age, 35)
    stmt.close()

    stmt = db.sql("select name as x, age as y from farmers where name = @name").prepare
    result = stmt.query(["name":"Alice"])
    verifyEq(result[0]->x, "Alice")
    verifyEq(result[0]->y, 21)

    // Statement.limit
    stmt = db.sql("select name from farmers")
    verifyEq(stmt.query.size, 5)
    verifyEq(stmt.limit, null)
    stmt.limit = 3
    verifyEq(stmt.limit, 3)
    verifyEq(stmt.query.size, 3)
    stmt.limit = null
    verifyEq(stmt.limit, null)
    verifyEq(stmt.query.size, 5)
  }

//////////////////////////////////////////////////////////////////////////
// Execute statements
//////////////////////////////////////////////////////////////////////////

  Void executeStmts()
  {
    r := db.sql(Str<|update farmers set pet='Pepper' where ducks=8|>).execute
    verifyEq(r, 2)

    r = db.sql("select name, pet from farmers").execute
    verifyEq(r.typeof, Row[]#)
    rows := r as Row[]
    rows.sort |a, b| { a->name <=> b->name }
    verifyEq(rows[3]->name, "Donny"); verifyEq(rows[3]->pet, "Pepper")
    verifyEq(rows[4]->name, "John");  verifyEq(rows[4]->pet, "Pepper")
  }

//////////////////////////////////////////////////////////////////////////
// Pool
//////////////////////////////////////////////////////////////////////////

  Void pool()
  {
    pool := TestPool
    {
      it.uri      = this.uri
      it.username = this.user
      it.password = this.pass
    }
    pool.execute(|SqlConn c| {})
    pool.close
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Row[] query(Str sql)
  {
    rows := (Row[])db.sql(sql).query
    // echo("  q> $sql ($rows.size rows)")
    // rows.each |Row row| { echo("     $row") }
    return rows
  }

  Obj execute(Str sql)
  {
    // echo("  q> $sql")
    return db.sql(sql).execute
  }

  Void verifyCol(Col col, Int index, Str name, Type type, Str sqlType)
  {
    verifyEq(col.index, index)
    verifyEq(col.name, name)
    verifySame(col.type, type)
    if (sqlType == "INT")
    {
      verify(col.sqlType.upper == "INT" || col.sqlType.upper == "INTEGER", col.sqlType)
    }
    else
    {
      verifyEq(col.sqlType.upper, sqlType.upper)
    }
  }

  Void verifyRow(Row r, Obj[] cells)
  {
    verifyEq(r.cols.size, cells.size)
    r.cols.each |Col c, Int i|
    {
      verifyEq(r.get(c), cells[i])
    }
  }

}

**************************************************************************
** Farmer
**************************************************************************

internal class Farmer
{
  Int farmer_id
  Str? name
  Bool married
  Str? pet
  Str? ss
  Int age
  Num? pigs
  Num? cows
  Num? ducks
  Float height
  Float weight
  Decimal? bigdec
  DateTime? dt
  Date? d
  Time? t
}

**************************************************************************
** DbType
**************************************************************************

internal enum class DbType
{
  mysql,
  postgres
}

**************************************************************************
** TestPool
**************************************************************************

const internal class TestPool : SqlConnPool
{
  new make(|This|? f) : super(f) {}

  protected override Void onOpen(SqlConn c)
  {
    if (!c.stash.isEmpty) throw Err("test failure")
    c.stash["foo"] = 42
  }

  protected override Void onClose(SqlConn c)
  {
    if (c.stash["foo"] != 42) throw Err("test failure")
  }
}
