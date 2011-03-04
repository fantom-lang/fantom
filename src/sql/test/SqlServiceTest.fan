//
// Copyright (c) 2008, John Sublett
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

  SqlConn? db

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
      statements
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
    uri  := pod.config("test.uri")      ?: throw Err("Missing 'sql::test.uri' config prop")
    user := pod.config("test.username") ?: throw Err("Missing 'sql::test.username' config prop")
    pass := pod.config("test.password") ?: throw Err("Missing 'sql::test.password' config prop")
    db = SqlConn.open(uri, user, pass)
    verifyEq(db.isClosed, false)
  }

//////////////////////////////////////////////////////////////////////////
// Verify Meta
//////////////////////////////////////////////////////////////////////////

  **
  ** Drop all tables in the database
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
    Str[] tables := db.meta.tables.dup
    while (tables.size != 0)
    {
      Int dropped := 0
      tables.each |Str tableName|
      {
        verifyEq(db.meta.tableExists(tableName), true)
        try
        {
          db.sql("drop table $tableName").execute
          tables.remove(tableName)
          dropped++
        }
        catch (Err e)
        {
          e.trace
        }
      }

      if (dropped == 0)
        throw SqlErr("All tables could not be dropped.")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Create Table
//////////////////////////////////////////////////////////////////////////

  Void createTable()
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

    verifyEq(f[f.col("pet")], "Pooh")
  }

  Void insertFarmer(Obj[] row)
  {
    s := "insert farmers (name, married, pet, ss, age, pigs, cows, ducks, height, weight, bigdec, dt, d, t) values ("
    s += row.join(", ") |Obj? o->Str|
    {
      if (o == null)     return "null"
      if (o is Str)      return "'$o'"
      if (o is DateTime) return "'" + o->toLocale("YYYY-MM-DD hh:mm:ss") + "'"
      if (o is Date)     return "'" + o->toLocale("YYYY-MM-DD") + "'"
      if (o is Time)     return "'" + o->toLocale("hh:mm:ss") + "'"
      return o.toStr
    }
    s += ")"

    // verify we got key back
    Int[] keys := execute(s)
    verifyEq(keys.size, 1)
    verifyEq(keys.typeof, Int[]#)

    // read with key and verify it is what we just wrote
    farmer := db.sql("select * from farmers where farmer_id = $keys.first").query.first
    verifyEq(farmer->name, row[0])
  }

  Void verifyFarmerCols(Row r)
  {
    verifyEq(r.cols.size, 15)
    verifyEq(r.cols.isRO, true)
    verifyCol(r.cols[0],  0,  "farmer_id", Int#,   "INT")
    verifyCol(r.cols[1],  1,  "name",      Str#,   "VARCHAR")
    verifyCol(r.cols[2],  2,  "married",   Bool#,  "BIT")
    verifyCol(r.cols[3],  3,  "pet",       Str#,   "VARCHAR")
    verifyCol(r.cols[4],  4,  "ss",        Str#,   "CHAR")
    verifyCol(r.cols[5],  5,  "age",       Int#,   "TINYINT")
    verifyCol(r.cols[6],  6,  "pigs",      Int#,   "SMALLINT")
    verifyCol(r.cols[7],  7,  "cows",      Int#,   "INT")
    verifyCol(r.cols[8],  8,  "ducks",     Int#,   "BIGINT")
    verifyCol(r.cols[9],  9,  "height",    Float#, "FLOAT")
    verifyCol(r.cols[10], 10, "weight",    Float#, "DOUBLE")
    verifyCol(r.cols[11], 11, "bigdec",    Decimal#, "DECIMAL")
    verifyCol(r.cols[12], 12, "dt",        DateTime#, "DATETIME")
    verifyCol(r.cols[13], 13, "d",         Date#,  "DATE")
    verifyCol(r.cols[14], 14, "t",         Time#,  "TIME")
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
// Statements
//////////////////////////////////////////////////////////////////////////

  Void statements()
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

