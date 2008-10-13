//
// Copyright (c) 2008, John Sublett
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 07  John Sublett  Creation
//

**
** SqlServiceTest: this is not actually a Test.  It defines
** all common database tests and is used by the database
** specific tests.
**
class SqlServiceTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  once SqlService db()
  {
    return SqlService(
      null,
      Sys.env["sql.test.connection"],
      Sys.env["sql.test.username"],
      Sys.env["sql.test.password"],
      Type.find(Sys.env["sql.test.dialect"]).make)
  }

//////////////////////////////////////////////////////////////////////////
// Top
//////////////////////////////////////////////////////////////////////////

  Void test()
  {
    try
    {
      if (!checkDb) return
      openCount

      db.open
      verify(!db.isClosed)
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
      db.stop
    }
  }

//////////////////////////////////////////////////////////////////////////
// Open
//////////////////////////////////////////////////////////////////////////

  Bool checkDb()
  {
    try
    {
      db.start
      db.open
      db.close
      return true
    }
    catch (Err e)
    {
      echo("**")
      echo("** WARNING: Cannot perform SqlServiceTest without available database: " + db.type.qname)
      echo("**          $e")
      echo("**")
      return false
    }
  }

  Void openCount()
  {
    verify(db.isClosed)
    db.open
    verify(!db.isClosed)
    db.open
    db.close
    verify(!db.isClosed)
    db.close
    verify(db.isClosed)
  }

//////////////////////////////////////////////////////////////////////////
// Drop Tables
//////////////////////////////////////////////////////////////////////////

  **
  ** Drop all tables in the database
  **
  Void dropTables()
  {
    Str[] tables := db.tables.dup
    while (tables.size != 0)
    {
      Int dropped := 0
      tables.each |Str tableName|
      {
        try
        {
          db.sql("drop table $tableName").execute
          tables.remove(tableName)
          dropped++
        }
        catch(Err e)
        {
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
      primary key (farmer_id))
      ").execute

    row := db.tableRow("farmers")
    rowType := row.type

    verify(rowType.field("farmer_id", false) != null, "Missing farmer_id")
    verify(rowType.field("name", false) != null,      "Missing name")
    verify(rowType.field("married", false) != null,   "Missing married")
    verify(rowType.field("pet", false) != null,       "Missing pet")
    verify(rowType.field("ss", false) != null,        "Missing ss")
    verify(rowType.field("age", false) != null,       "Missing age")
    verify(rowType.field("pigs", false) != null,      "Missing pigs")
    verify(rowType.field("cows", false) != null,      "Missing cows")
    verify(rowType.field("ducks", false) != null,     "Missing ducks")
    verify(rowType.field("height", false) != null,    "Missing height")
    verify(rowType.field("weight", false) != null,    "Missing weight")
  }

//////////////////////////////////////////////////////////////////////////
// Insert Table
//////////////////////////////////////////////////////////////////////////

  Void insertTable()
  {
    // insert a couple rows
    data := [
      [1, "Alice",   false, "Pooh",     "abcd", 21,   1,   80,  null, 5.3f,  120f],
      [2, "Brian",   true,  "Haley",    "1234", 35,   2,   99,   5,   5.7f,  140f],
      [3, "Charlie", null,  "Addi",     null,   null, 3,   44,   7,   null, 6.1f],
      [4, "Donny",   true,  null,       "wxyz", 40,  null, null, 8,   null, null],
      [5, "John",    true,  "Berkeley", "5678", 35,  null, null, 8,   null, null],
    ]
    data.each |Obj[] row| { insertFarmer(row[1..-1]) }

    // query
    rows := query("select * from farmers order by farmer_id")
    verifyPlayCols(rows.of)
    verifyEq(data.size, rows.size)
    data.each |Obj[] d, Int i| { verifyRow(rows[i], d) }

    // query with type
    farmers := db.sql("select * from farmers order by farmer_id").query
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
  }

  Void insertFarmer(Obj[] row)
  {
    s := "insert farmers (name, married, pet, ss, age, pigs, cows, ducks, height, weight) values ("
    s += row.join(", ") |Obj? o->Str|
    {
      if (o == null) return "null"
      if (o is Str) return "'$o'"
      return o.toStr
    }
    s += ")"
    verifyEq(execute(s), 1)
  }

  Void verifyPlayCols(Type t)
  {
    verifyEq(t.isDynamic, true)
    verifyEq(t.fields.size, 11)
// TODO
//    verifyCol(t.fields[0],  0,  "farmer_id", Int#,   "INT")
    verifyCol(t.fields[1],  1,  "name",      Str#,   "VARCHAR")
    verifyCol(t.fields[2],  2,  "married",   Bool#,  "BIT")
    verifyCol(t.fields[3],  3,  "pet",       Str#,   "VARCHAR")
    verifyCol(t.fields[4],  4,  "ss",        Str#,   "CHAR")
    verifyCol(t.fields[5],  5,  "age",       Int#,   "TINYINT")
    verifyCol(t.fields[6],  6,  "pigs",      Int#,   "SMALLINT")
// TODO
//    verifyCol(t.fields[7],  7,  "cows",      Int#,   "INT")
    verifyCol(t.fields[8],  8,  "ducks",     Int#,   "BIGINT")
    verifyCol(t.fields[9],  9,  "height",    Float#, "FLOAT")
    verifyCol(t.fields[10], 10, "weight",    Float#, "DOUBLE")
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
      verifyEq(row.type.fields.size, Farmer#.fields.size)
      Farmer#.fields.each |Field f, Int index|
      {
        //verifyEq(row.type.field(f.name), null)
        col := row.type.field(f.name)
        verify(col != null)
        if (f.name == "farmer_id") verifyEq(col.of, Int#)
        if (f.name == "married") verifyEq(col.of, Bool#)
        if (f.name == "pet") verifyEq(col.of, Str#)
        if (f.name == "height") verifyEq(col.of, Float#)
      }
      i++
    }
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  Void transactions()
  {
    verifyEq(db.isAutoCommit, true)
    db.autoCommit(false)
    verifyEq(db.isAutoCommit, false)
    db.commit

    rows := query("select name from farmers order by name")
    verifyEq(rows.size, 5)
    verifyEq(rows[0]->name, "Alice")
    verifyEq(rows[1]->name, "Brian")
    verifyEq(rows[2]->name, "Charlie")
    verifyEq(rows[3]->name, "Donny")
    verifyEq(rows[4]->name, "John")

    insertFarmer(["Bad", false, "Bad",  "bad!", 21, 1, 80, null, 5.3f, 120f])
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
    result.each |Obj row| { verify(result[0]->age > 30, result[0]->age + " <= 30") }
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

  Int execute(Str sql)
  {
    // echo("  q> $sql")
    return db.sql(sql).execute
  }

  Void verifyCol(Field f, Int index, Str name, Type of, Str sqlType)
  {
    col := f as Col
    verifyEq(col.index, index)
    verifyEq(col.name, name)
    verifySame(col.of, of)
    verifyEq(col.sqlType, sqlType)
  }

  Void verifyRow(Obj row, Obj[] cells)
  {
    r := row as Row
    verifyEq(r.type.fields.size, cells.size)
    r.type.fields.each |Field f, Int i|
    {
      verifyEq(f.get(r), cells[i])
    }
  }

}

**************************************************************************
** Farmer
**************************************************************************

internal class Farmer
{
  Int farmer_id
  Str name
  Bool married
  Str pet
  Str ss
  Int age
  Num pigs
  Num cows
  Num ducks
  Float height
  Float weight
}