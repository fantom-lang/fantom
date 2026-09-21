//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Sep 26  Mike Jarmy  Creation
//

using util

**************************************************************************
** SqlTest
**************************************************************************

** SqlTest is the base for the tests that run against a live database.
** It is abstract, so fant skips it; the concrete subclasses at the bottom
** of this file bind it to a `Dialect`.
**
** Each test method gets a fresh instance, a fresh connection, and drops
** whatever tables it created.  No test may depend on another's state.
abstract class SqlTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Config
//////////////////////////////////////////////////////////////////////////

  ** The database this test runs against
  internal abstract Dialect dialect()

  ** The main test table; see Dialect.valsCols
  const Str valsTable := "test_vals"

  ** A table that is never created
  const Str missingTable := "no_such_table_xyz"

  ** Batch tables; see Dialect.batchCols and Dialect.batchAutoCols
  const Str batchTable     := "test_batch"
  const Str batchAutoTable := "test_batch_auto"

  ** Postgres array table; created with raw ddl since it never runs elsewhere
  const Str arrayTable := "test_arrays"

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    d := dialect
    db = SqlConn.open(d.uri, d.username, d.password)
    db.autoCommit = true

    // fail here rather than deep inside a type assertion if the
    // uris ever get crossed
    verifyEq(db.meta.productName, d.productName)
  }

  override Void teardown()
  {
    if (db == null || db.isClosed) return
    try
    {
      // a test may have left a transaction open
      if (!db.autoCommit) db.rollback
      db.autoCommit = true

      tables.each |t|
      {
        try
          db.sql("drop table if exists $t").execute
        catch (Err e)
          log.warn("cannot drop $t", e)
      }
    }
    finally
    {
      db.close
    }
  }

//////////////////////////////////////////////////////////////////////////
// Smoke
//////////////////////////////////////////////////////////////////////////

  ** Exercise the fixture machinery end to end: connect, create, describe,
  ** insert, select, and verify both metadata and values.
  Void testSmoke()
  {
    verifyFalse(db.isClosed)
    verify(db.isValid)

    createVals
    verify(db.meta.tableExists(valsTable))

    // the declared schema round-trips through getColumns
    verifyColDefs(db.meta.tableRow(valsTable), Dialect.valsCols)

    vals := sampleVals
    id := insertVals(vals)

    rows := db.sql("select * from $valsTable").query
    verifyEq(rows.size, 1)
    row := rows[0]

    // and through the result set
    verifyColDefs(row, Dialect.valsCols)
    verifyRow(row, vals)
    verifyEq(row->id, id)
  }

//////////////////////////////////////////////////////////////////////////
// Meta
//////////////////////////////////////////////////////////////////////////

  Void testMeta()
  {
    meta := db.meta

    // productName is asserted during setup
    verify(meta.productVersionStr.size > 0)
    verify(meta.driverName.size > 0)
    verify(meta.driverVersionStr.size > 0)
    verifyNotNull(meta.productVersion)
    verifyNotNull(meta.driverVersion)

    // limits are driver reported, and may be unknown
    if (meta.maxColName != null)   verify(meta.maxColName > 0)
    if (meta.maxTableName != null) verify(meta.maxTableName > 0)

    // a table that does not exist
    verifyFalse(meta.tableExists(missingTable))
    verifyFalse(meta.tables.contains(missingTable))
    verifyErr(SqlErr#) { db.meta.tableRow(missingTable) }

    // and one that does; note meta is a live view of the connection,
    // so the instance obtained above sees the new table
    createVals
    verify(meta.tableExists(valsTable))
    verify(meta.tables.contains(valsTable))
    verifyColDefs(meta.tableRow(valsTable), Dialect.valsCols)
  }

//////////////////////////////////////////////////////////////////////////
// Insert and Select
//////////////////////////////////////////////////////////////////////////

  Void testInsertAndSelect()
  {
    createVals

    a := insertVals(["v_str": "alpha", "v_i32": 1, "v_bool": true])
    b := insertVals(["v_str": "beta",  "v_i32": 2, "v_bool": false])
    c := insertVals(["v_str": "gamma", "v_i32": 3, "v_bool": null])

    // keys are distinct, and each reads back its own row
    verifyNotEq(a, b)
    verifyNotEq(b, c)
    verifyNotEq(a, c)
    stmt := db.sql("select * from $valsTable where id = @id").prepare
    try
    {
      verifyEq(stmt.query(["id": a])[0]->v_str, "alpha")
      verifyEq(stmt.query(["id": b])[0]->v_str, "beta")
      verifyEq(stmt.query(["id": c])[0]->v_str, "gamma")
    }
    finally
      stmt.close

    rows := db.sql("select * from $valsTable order by id").query
    verifyType(rows, Row[]#)
    verifyEq(rows.size, 3)
    verifyRow(rows[0], ["v_str": "alpha", "v_i32": 1, "v_bool": true])
    verifyRow(rows[1], ["v_str": "beta",  "v_i32": 2, "v_bool": false])
    verifyRow(rows[2], ["v_str": "gamma", "v_i32": 3, "v_bool": null])

    // columns we never inserted come back null
    verifyNull(rows[0]->v_dt)
    verifyNull(rows[0]->v_buf)

    // cells are reachable by trap, by col, and by the index operator
    row := rows[0]
    col := row.col("v_str")
    verifyEq(row->v_str,    "alpha")
    verifyEq(row.get(col),  "alpha")
    verifyEq(row[col],      "alpha")

    // col lookup is case insensitive
    verifySame(row.col("V_STR"), col)
    verifySame(row.col("v_StR"), col)
    verifyEq(row->V_STR, "alpha")

    // set is in-memory only.  It mutates the detached row through any of
    // the three write paths, and never writes back to the database.
    row.set(col, "mutated")
    verifyEq(row->v_str, "mutated")
    row[col] = "again"
    verifyEq(row.get(col), "again")
    row->v_str = "third"
    verifyEq(row[col], "third")
    verifyEq(db.sql("select * from $valsTable order by id").query[0]->v_str, "alpha")

    // and cols is read-only
    verify(row.cols.isRO)

    // unknown column
    verifyNull(row.col("nope", false))
    verifyErr(ArgErr#) { row.col("nope") }
  }

//////////////////////////////////////////////////////////////////////////
// Query Each
//////////////////////////////////////////////////////////////////////////

  Void testQueryEach()
  {
    createVals
    3.times |i| { insertVals(["v_str": "s$i", "v_i32": i]) }

    // queryEach visits every row, in order
    acc := Int[,]
    db.sql("select * from $valsTable order by id").queryEach(null) |row|
    {
      acc.add((Int)row->v_i32)
    }
    verifyEq(acc, Int[0, 1, 2])

    // the same Row instance is reused across iterations, so a callback
    // must copy values out rather than retain the row
    seen := Row[,]
    db.sql("select * from $valsTable order by id").queryEach(null) |row|
    {
      seen.add(row)
    }
    verifyEq(seen.size, 3)
    verifySame(seen[0], seen[1])
    verifySame(seen[1], seen[2])

    // queryEachWhile stops at the first non-null result
    visits := 0
    res := db.sql("select * from $valsTable order by id").queryEachWhile(null) |row->Obj?|
    {
      visits++
      return (row->v_i32 == 1) ? row->v_str : null
    }
    verifyEq(res, "s1")
    verifyEq(visits, 2)

    // and returns null if the callback never matches
    visits = 0
    res = db.sql("select * from $valsTable").queryEachWhile(null) |row->Obj?|
    {
      visits++
      return null
    }
    verifyNull(res)
    verifyEq(visits, 3)

    // prepared form takes params
    acc.clear
    stmt := db.sql("select * from $valsTable where v_i32 > @n order by id").prepare
    try
      stmt.queryEach(["n": 0]) |row| { acc.add((Int)row->v_i32) }
    finally
      stmt.close
    verifyEq(acc, Int[1, 2])
  }

//////////////////////////////////////////////////////////////////////////
// Transactions
//////////////////////////////////////////////////////////////////////////

  Void testTransactions()
  {
    createVals
    insertVals(["v_str": "keep"])

    verify(db.autoCommit)
    db.autoCommit = false
    verifyFalse(db.autoCommit)

    // rollback discards
    insertVals(["v_str": "discard"])
    verifyEq(rowCount, 2)
    db.rollback
    verifyEq(rowCount, 1)
    verifyEq(strs, Str["keep"])

    // commit keeps
    insertVals(["v_str": "commit"])
    db.commit
    verifyEq(strs, Str["commit", "keep"])

    // and a later rollback does not undo a commit
    db.rollback
    verifyEq(strs, Str["commit", "keep"])

    db.autoCommit = true
    verify(db.autoCommit)
  }

//////////////////////////////////////////////////////////////////////////
// Prepared Statements
//////////////////////////////////////////////////////////////////////////

  Void testPrepared()
  {
    createVals
    insertVals(["v_str": "alpha", "v_i32": 1])
    insertVals(["v_str": "beta",  "v_i32": 2])
    insertVals(["v_str": "gamma", "v_i32": 3])

    // one statement, many executions
    stmt := db.sql("select * from $valsTable where v_str = @s").prepare
    try
    {
      verifyEq(stmt.query(["s": "alpha"])[0]->v_i32, 1)
      verifyEq(stmt.query(["s": "beta"])[0]->v_i32,  2)
      verifyEq(stmt.query(["s": "gamma"])[0]->v_i32, 3)
      verifyEq(stmt.query(["s": "nope"]).size, 0)
    }
    finally
      stmt.close

    // several params
    stmt = db.sql("select * from $valsTable where v_str = @s and v_i32 = @n").prepare
    try
    {
      verifyEq(stmt.query(["s": "beta", "n": 2]).size, 1)
      verifyEq(stmt.query(["s": "beta", "n": 3]).size, 0)
    }
    finally
      stmt.close

    // one param bound to two locations
    stmt = db.sql("select * from $valsTable where v_i32 = @n or v_i32 = @n + 1 order by v_i32").prepare
    try
    {
      rows := stmt.query(["n": 1])
      verifyEq(rows.size, 2)
      verifyEq(rows[0]->v_i32, 1)
      verifyEq(rows[1]->v_i32, 2)
    }
    finally
      stmt.close

    // null param
    stmt = db.sql("update $valsTable set v_char = @c where v_i32 = @n").prepare
    try
    {
      verifyEq(stmt.execute(["c": "abcd", "n": 1]), 1)
      verifyEq(stmt.execute(["c": null,   "n": 2]), 1)
    }
    finally
      stmt.close
    rows := db.sql("select * from $valsTable order by v_i32").query
    verifyEq(rows[0]->v_char, "abcd")
    verifyNull(rows[1]->v_char)

    // column aliases name the cells
    aliased := db.sql("select v_str as a, v_i32 as b from $valsTable where v_i32 = @n").prepare
    rows = aliased.query(["n": 1])
    aliased.close
    verifyEq(rows[0]->a, "alpha")
    verifyEq(rows[0]->b, 1)

    // withPrepare closes the statement for us
    res := db.withPrepare("select v_str from $valsTable where v_i32 = @n") |s|
    {
      return s.query(["n": 3])[0]->v_str
    }
    verifyEq(res, "gamma")
  }

//////////////////////////////////////////////////////////////////////////
// Execute
//////////////////////////////////////////////////////////////////////////

  ** Statement.execute returns one of three shapes depending on the sql
  Void testExecute()
  {
    createVals

    // an insert returns the auto-generated keys
    res := db.sql("insert into $valsTable (v_str) values ('a')").execute
    keys := res as Int[]
    verifyNotNull(keys, "expected keys, got $res")
    verifyEq(keys.size, 1)
    id := keys[0]

    // a query returns the rows
    res = db.sql("select * from $valsTable").execute
    rows := res as Row[]
    verifyNotNull(rows, "expected rows, got $res")
    verifyEq(rows.size, 1)
    verifyEq(rows[0]->id, id)

    // an update returns the count
    insertVals(["v_str": "b"])
    insertVals(["v_str": "c"])
    verifyEq(db.sql("update $valsTable set v_i32 = 7").execute, 3)

    // as does a delete
    verifyEq(db.sql("delete from $valsTable where v_str = 'a'").execute, 1)
    verifyEq(rowCount, 2)
  }

//////////////////////////////////////////////////////////////////////////
// Limit
//////////////////////////////////////////////////////////////////////////

  Void testLimit()
  {
    createVals
    5.times |i| { insertVals(["v_str": "s$i"]) }

    // unprepared: the limit applies to each execution
    stmt := db.sql("select * from $valsTable")
    verifyNull(stmt.limit)
    verifyEq(stmt.query.size, 5)

    stmt.limit = 3
    verifyEq(stmt.limit, 3)
    verifyEq(stmt.query.size, 3)

    stmt.limit = null
    verifyNull(stmt.limit)
    verifyEq(stmt.query.size, 5)

    // prepared, with the limit set before prepare
    stmt = db.sql("select * from $valsTable")
    stmt.limit = 2
    stmt.prepare
    try
      verifyEq(stmt.query.size, 2)
    finally
      stmt.close

    // and set after prepare, which has to reach the statement that
    // prepare already created
    stmt = db.sql("select * from $valsTable").prepare
    try
    {
      verifyEq(stmt.query.size, 5)
      stmt.limit = 2
      verifyEq(stmt.limit, 2)
      verifyEq(stmt.query.size, 2)

      // and clearing it again restores the full result
      stmt.limit = null
      verifyNull(stmt.limit)
      verifyEq(stmt.query.size, 5)
    }
    finally
      stmt.close
  }

//////////////////////////////////////////////////////////////////////////
// Batch
//////////////////////////////////////////////////////////////////////////

  Void testBatchUpdate()
  {
    createVals
    5.times |i| { insertVals(["v_str": "s$i", "v_i32": 0]) }
    ids := ints("select id from $valsTable order by id")
    verifyEq(ids.size, 5)

    stmt := db.sql("update $valsTable set v_i32 = @n where id = @id")

    // the statement must be prepared first
    bad := [Str:Obj]["n": 1, "id": ids[0]]
    verifyErr(SqlErr#) { stmt.executeBatch([bad]) }

    stmt.prepare
    params := [Str:Obj][,]
    ids.each |id, i| { params.add(Str:Obj["n": i * 10, "id": id]) }
    res := stmt.executeBatch(params)
    stmt.close

    // one row updated per command
    verifyEq(res.updateCounts, Int?[,].fill(1, 5))

    // an update generates no keys
    verifyEq(res.keys, Obj?[,].fill(null, 5))

    // and the rows really changed
    verifyEq(ints("select v_i32 from $valsTable order by id"), Int[0, 10, 20, 30, 40])
  }

  ** Whether a batch insert yields keys depends on both the table and the
  ** driver, so this pins down all four corners of that.
  Void testBatchKeys()
  {
    // a table whose key is not auto-generated
    createTable(batchTable, Dialect.batchCols)
    stmt := db.sql("insert into $batchTable (n, v_str) values (@n, @v_str)").prepare
    params := [Str:Obj][,]
    4.times |i| { params.add(Str:Obj["n": i, "v_str": "s$i"]) }
    res := stmt.executeBatch(params)
    stmt.close

    verifyEq(res.updateCounts, Int?[,].fill(1, 4))
    verifyEq(res.keys.size, 4)

    // some drivers hand back keys even though nothing was generated
    if (dialect.keysOnNonAutoInsert)
      res.keys.each |k| { verifyNotNull(k) }
    else
      verifyEq(res.keys, Obj?[,].fill(null, 4))

    verifyEq(ints("select n from $batchTable order by n"), Int[0, 1, 2, 3])

    // a table whose key really is auto-generated
    createTable(batchAutoTable, Dialect.batchAutoCols)
    stmt = db.sql("insert into $batchAutoTable (v_str) values (@v_str)").prepare
    params = [Str:Obj][,]
    4.times |i| { params.add(Str:Obj["v_str": "s$i"]) }
    res = stmt.executeBatch(params)
    stmt.close

    verifyEq(res.updateCounts, Int?[,].fill(1, 4))
    verifyKeys(res.keys, ["s0", "s1", "s2", "s3"])
  }

  Void testBatchExecutor()
  {
    createTable(batchAutoTable, Dialect.batchAutoCols)
    stmt := db.sql("insert into $batchAutoTable (v_str) values (@v_str)").prepare

    // a chunk size well under the command count, so the queue flushes
    // more than once and the results still have to collate in order
    batch := BatchExecutor(stmt, 2)
    5.times |i| { batch.add(Str:Obj["v_str": "s$i"]) }
    res := batch.finish

    // finishing an empty queue is a no-op returning the same result
    verifySame(batch.finish, res)
    stmt.close

    verifyEq(res.updateCounts, Int?[,].fill(1, 5))
    verifyKeys(res.keys, ["s0", "s1", "s2", "s3", "s4"])
  }

  ** Verify each generated key selects the row that was inserted for it,
  ** which checks both that the keys are real and that they came back in
  ** the order the commands were added.
  private Void verifyKeys(Obj?[] keys, Str[] expected)
  {
    verifyEq(keys.size, expected.size)
    sel := db.sql("select * from $batchAutoTable where id = @id").prepare
    try
    {
      keys.each |k, i|
      {
        verifyNotNull(k, "key $i")
        rows := sel.query(["id": k])
        verifyEq(rows.size, 1, "key $i")
        verifyEq(rows[0]->v_str, expected[i])
      }
    }
    finally
      sel.close
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  ** Everything the driver rejects should surface as SqlErr, not as a
  ** raw SQLException or a null
  Void testErrors()
  {
    createVals
    insertVals(["v_str": "alpha", "v_i32": 1])

    // malformed sql.  Note the error may surface at prepare or at
    // execution depending on whether the driver prepares server-side,
    // so these go all the way through to a query.
    verifyErr(SqlErr#) { db.sql("this is not sql").execute }
    verifyErr(SqlErr#) { db.sql("select nope from").prepare.query }

    // unknown table and unknown column
    verifyErr(SqlErr#) { db.sql("select * from $missingTable").query }
    verifyErr(SqlErr#) { db.sql("select nope from $valsTable").query }

    // v_str is the one not-null column
    verifyErr(SqlErr#) { insert(valsTable, ["v_str": null, "v_i32": 9]) }

    // a statement with params needs a params map, and says which ones
    withParams := db.sql("select * from $valsTable where v_i32 = @n").prepare
    try
    {
      caught := false
      try
        withParams.query
      catch (SqlErr e)
      {
        caught = true
        verify(e.msg.contains("n"), e.msg)
      }
      verify(caught, "expected SqlErr for missing params map")
    }
    finally
      withParams.close

    // but a statement with no params is happy without one
    noParams := db.sql("select * from $valsTable").prepare
    try
      verifyEq(noParams.query.size, 1)
    finally
      noParams.close

    // a statement is unusable once closed
    stmt := db.sql("select * from $valsTable").prepare
    verifyEq(stmt.query.size, 1)
    stmt.close
    verifyErr(SqlErr#) { stmt.query }

    // one bad command fails the whole batch
    createTable(batchAutoTable, Dialect.batchAutoCols)
    batch := db.sql("insert into $batchAutoTable (v_str) values (@v_str)").prepare
    try
    {
      cmds := [Str:Obj][,]
      cmds.add(Str:Obj["v_str": "ok"])
      cmds.add(Str:Obj?["v_str": null])
      verifyErr(SqlErr#) { batch.executeBatch(cmds) }
    }
    finally
      batch.close

    // and a closed connection is unusable.  Use our own connection here
    // so that teardown still has a live one.
    d := dialect
    other := SqlConn.open(d.uri, d.username, d.password)
    verifyFalse(other.isClosed)
    verify(other.close)
    verify(other.isClosed)
    verify(other.close)              // closing twice is a no-op
    verifyErr(SqlErr#) { other.sql("select 1 as n").query }
  }

  ** A parameter missing from the map currently binds as null rather than
  ** raising, so a typo in a param name is silent.  This pins the current
  ** behavior; it is not necessarily the behavior we want.
  Void testMissingParam()
  {
    createVals
    insertVals(["v_str": "alpha", "v_i32": 1])

    stmt := db.sql("update $valsTable set v_char = @c where v_i32 = @n").prepare
    try
    {
      // "typo" is never read, so @c binds as null
      verifyEq(stmt.execute(["typo": "abcd", "n": 1]), 1)
    }
    finally
      stmt.close

    verifyNull(selectOne("alpha")->v_char)
  }

//////////////////////////////////////////////////////////////////////////
// Nulls
//////////////////////////////////////////////////////////////////////////

  Void testNulls()
  {
    createVals

    // a column left out of the insert defaults to null
    id := insertVals(["v_str": "sparse"])
    sparse := selectOne("sparse")
    verifyEq(sparse->id, id)
    verifyNullsExcept(sparse, ["id", "v_str"])

    // and so does binding null explicitly, which exercises setObject
    // with a null for every one of our column types
    nulls := Str:Obj?[:]
    Dialect.valsCols.each |def|
    {
      if (def.name == "id") return
      nulls[def.name] = (def.name == "v_str") ? "explicit" : null
    }
    insertVals(nulls)
    explicit := selectOne("explicit")
    verifyNullsExcept(explicit, ["id", "v_str"])

    // column metadata comes from the schema rather than the values, so
    // an all-null row still reports its declared types
    verifyColDefs(explicit, Dialect.valsCols)
  }

//////////////////////////////////////////////////////////////////////////
// Empty Results
//////////////////////////////////////////////////////////////////////////

  Void testEmptyResult()
  {
    createVals
    insertVals(["v_str": "alpha", "v_i32": 1])

    empty := "select * from $valsTable where 1 = 0"

    // query returns an empty Row[], never null
    rows := db.sql(empty).query
    verifyType(rows, Row[]#)
    verifyEq(rows.size, 0)

    // queryEach never fires
    n := 0
    db.sql(empty).queryEach(null) |row| { n++ }
    verifyEq(n, 0)

    // queryEachWhile returns null without firing
    n = 0
    res := db.sql(empty).queryEachWhile(null) |row->Obj?| { n++; return "x" }
    verifyNull(res)
    verifyEq(n, 0)

    // execute still reports a result set, just an empty one
    exec := db.sql(empty).execute
    verifyType(exec, Row[]#)
    verifyEq(((Row[])exec).size, 0)

    // prepared, params that match nothing
    stmt := db.sql("select * from $valsTable where v_i32 = @n").prepare
    try
    {
      verifyEq(stmt.query(["n": 999]).size, 0)
      verifyEq(stmt.query(["n": 1]).size, 1)
    }
    finally
      stmt.close

    // and a write that matches nothing reports zero rows
    verifyEq(db.sql("update $valsTable set v_i32 = 5 where 1 = 0").execute, 0)
    verifyEq(db.sql("delete from $valsTable where 1 = 0").execute, 0)
    verifyEq(rowCount, 1)
  }

//////////////////////////////////////////////////////////////////////////
// Type Round Trip
//////////////////////////////////////////////////////////////////////////

  ** Round-trip a set of values through every column of the main test
  ** table, so that a failure names the exact type and value that broke.
  ** This is the conformance matrix: what each database can actually
  ** store and hand back unchanged.
  Void testTypeRoundTrip()
  {
    createVals
    cases := typeCases

    Dialect.valsCols.each |def|
    {
      if (def.name == "id") return

      vals := cases[def.type] ?: throw Err("no type cases for '$def.type'")
      vals.each |val, i|
      {
        // v_str is not null, so it gets a filler that the str column's
        // own cases overwrite when it is the column under test
        row := Str:Obj?[:]
        row["v_str"]  = "case"
        row[def.name] = val

        got    := selectById(insertVals(row))
        actual := got.get(got.col(def.name))
        verify(valEq(actual, val), "$def.name[$i]: expected $val, got $actual")
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Buf
//////////////////////////////////////////////////////////////////////////

  ** Binary round-trips through the setBinaryStream path in setParameters
  Void testBuf()
  {
    createVals

    mem := Buf()
    mem.writeUtf("Don Quixote")
    verifyEq(mem.typeof.qname, "sys::MemBuf")
    verifyBuf("mem", mem)

    con := "Sancho Panza".toBuf.toImmutable
    verifyEq(con.typeof.qname, "sys::ConstBuf")
    verifyBuf("con", con)

    // every byte value, to catch anything that round-trips as text
    all := Buf()
    256.times |i| { all.write(i) }
    verifyBuf("all", all)

    verifyBuf("empty", Buf())

    // and null is not an empty buf
    insertVals(["v_str": "none", "v_buf": null])
    verifyNull(selectBuf("none"))
  }

  private Void verifyBuf(Str key, Buf buf)
  {
    insertVals(["v_str": key, "v_buf": buf])
    got := selectBuf(key)
    verifyNotNull(got, key)
    verify(got.bytesEqual(buf), key)
  }

  private Buf? selectBuf(Str key)
  {
    return selectOne(key)->v_buf as Buf
  }

//////////////////////////////////////////////////////////////////////////
// Escapes
//////////////////////////////////////////////////////////////////////////

  ** An "@" inside quoted text is literal, not a parameter.  TokenizerTest
  ** covers this at the unit level; here we prove the sql actually runs.
  Void testEscapes()
  {
    createVals
    insertVals(["v_str": "a@b",   "v_i32": 1])
    insertVals(["v_str": "plain", "v_i32": 2])

    stmt := db.sql("select * from $valsTable where v_str = 'a@b' and v_i32 = @n").prepare
    try
    {
      rows := stmt.query(["n": 1])
      verifyEq(rows.size, 1)
      verifyEq(rows[0]->v_str, "a@b")
      verifyEq(stmt.query(["n": 2]).size, 0)
    }
    finally
      stmt.close
  }

  ** A mysql session variable must be escaped inside a prepared statement
  Void testUserVars()
  {
    if (!dialect.hasUserVars) { logSkip; return }

    createVals
    insertVals(["v_str": "alpha", "v_i32": 1])

    // not prepared, so the tokenizer never sees this one
    db.sql("set @v1 = 42").execute

    // prepared, so @v1 has to be escaped or it becomes a bind param
    stmt := db.sql("select v_str, \\@v1 as v from $valsTable where v_i32 = @n").prepare
    try
    {
      rows := stmt.query(["n": 1])
      verifyEq(rows.size, 1)
      verifyEq(rows[0]->v_str, "alpha")
      verifyEq(rows[0]->v, 42)
    }
    finally
      stmt.close
  }

  ** So must the postgres jsonb containment operator; see pod-doc "Escape
  ** Sequences".  No table is needed, so the sql can be a raw dsl literal.
  Void testJsonbOperator()
  {
    if (!dialect.hasJsonb) { logSkip; return }

    hit := db.sql(
      Str<|select 1 as n where '{"x": 99, "y": 1}'::jsonb \@> '{"x": 99}'::jsonb|>).prepare
    try
      verifyEq(hit.query.size, 1)
    finally
      hit.close

    miss := db.sql(
      Str<|select 1 as n where '{"x": 99}'::jsonb \@> '{"z": 0}'::jsonb|>).prepare
    try
      verifyEq(miss.query.size, 0)
    finally
      miss.close
  }

//////////////////////////////////////////////////////////////////////////
// Arrays
//////////////////////////////////////////////////////////////////////////

  ** Postgres array columns map to Fantom Lists; see SqlUtil.fanToSqlObj
  ** and SqlUtil.ToFanList.
  Void testArrays()
  {
    if (!dialect.hasArrays) { logSkip; return }

    createRawTable(arrayTable,
      "create table $arrayTable (
         texts   text[],
         ints    int[],
         longs   bigint[],
         bools   boolean[],
         floats  real[],
         doubles double precision[],
         times   timestamptz[])")

    insert := db.sql(
      "insert into $arrayTable (texts, ints, longs, bools, floats, doubles, times)
       values (@texts, @ints, @longs, @bools, @floats, @doubles, @times)").prepare

    base := 3_000_000_000   // larger than Int32 max
    dt   := DateTime(2026, Month.sep, 4, 9, 30, 15)

    // non-nullable lists round-trip as non-nullable
    insert.execute([
      "texts":   Str["a", "b", "c"],
      "ints":    Int[1, 2, 3],
      "longs":   Int[base+1, base+2, base+3],
      "bools":   Bool[true, false],
      "floats":  Float[1.0f, 2.0f, 3.0f],
      "doubles": Float[4.0f, 5.0f, 6.0f],
      "times":   DateTime[dt, dt+1hr, dt+2hr],
    ])

    rows := db.sql("select * from $arrayTable").query
    verifyEq(rows.size, 1)
    verifyEq(rows[0]->texts,   Str["a", "b", "c"])
    verifyEq(rows[0]->ints,    Int[1, 2, 3])
    verifyEq(rows[0]->longs,   Int[base+1, base+2, base+3])
    verifyEq(rows[0]->bools,   Bool[true, false])
    verifyEq(rows[0]->floats,  Float[1.0f, 2.0f, 3.0f])
    verifyEq(rows[0]->doubles, Float[4.0f, 5.0f, 6.0f])
    verifyEq(rows[0]->times,   DateTime[dt, dt+1hr, dt+2hr])
    db.sql("delete from $arrayTable").execute

    // a null element makes the whole list nullable
    insert.execute([
      "texts":   Str?["a", "b", null],
      "ints":    Int?[1, 2, null],
      "longs":   Int?[base+1, null],
      "bools":   Bool?[true, null],
      "floats":  Float?[1.0f, null],
      "doubles": Float?[4.0f, null],
      "times":   DateTime?[dt, null],
    ])

    rows = db.sql("select * from $arrayTable").query
    verifyEq(rows.size, 1)
    verifyEq(rows[0]->texts,   Str?["a", "b", null])
    verifyEq(rows[0]->ints,    Int?[1, 2, null])
    verifyEq(rows[0]->longs,   Int?[base+1, null])
    verifyEq(rows[0]->bools,   Bool?[true, null])
    verifyEq(rows[0]->floats,  Float?[1.0f, null])
    verifyEq(rows[0]->doubles, Float?[4.0f, null])
    verifyEq(rows[0]->times,   DateTime?[dt, null])
    db.sql("delete from $arrayTable").execute
    insert.close

    // util::FloatArray binds as a java primitive array
    f4 := FloatArray.makeF4(3)
    f4.set(0, 1.0f); f4.set(1, 2.0f); f4.set(2, 3.0f)
    f8 := FloatArray.makeF8(3)
    f8.set(0, 4.0f); f8.set(1, 5.0f); f8.set(2, 6.0f)

    db.withPrepare("insert into $arrayTable (floats, doubles) values (@floats, @doubles)") |s|
    {
      s.execute(["floats": f4, "doubles": f8])
      return null
    }

    rows = db.sql("select * from $arrayTable").query
    verifyEq(rows.size, 1)
    verifyEq(rows[0]->floats,  Float[1.0f, 2.0f, 3.0f])
    verifyEq(rows[0]->doubles, Float[4.0f, 5.0f, 6.0f])
    verifyNull(rows[0]->texts)
    verifyNull(rows[0]->times)
  }

//////////////////////////////////////////////////////////////////////////
// Fixtures
//////////////////////////////////////////////////////////////////////////

  ** A full row of values for the main test table.
  **
  ** Note the float values are exactly representable in binary32, so that
  ** v_f32 round-trips through a 4 byte column without widening error, and
  ** the times carry no fractional seconds, which mysql datetime truncates.
  ** Probing the inexact cases belongs in a dedicated type test.
  Str:Obj? sampleVals()
  {
    return [
      "v_str":  "hello",
      "v_char": "abcd",          // exactly 4; see ColDef char padding note
      "v_bool": true,
      "v_i8":   100,
      "v_i16":  30_000,
      "v_i32":  2_000_000_000,
      "v_i64":  3_000_000_000,   // larger than Int32 max
      "v_f32":  1.5f,
      "v_f64":  2.25f,
      "v_dec":  12.34d,
      "v_dt":   DateTime(2026, Month.sep, 4, 9, 30, 15),
      "v_date": Date(2026, Month.sep, 4),
      "v_time": Time(9, 30, 15),
      "v_buf":  "hello".toBuf,
    ]
  }

  ** Values exercised by testTypeRoundTrip, keyed by logical type.  Null
  ** is covered separately by testNulls.
  **
  ** Constraints these values respect:
  **  - f32 values are exactly representable in binary32 and carry no
  **    more than 6 significant decimal digits.  Exactness alone is not
  **    enough: mysql float round-trips through roughly 6 significant
  **    digits, so 2^24 comes back as 16777200 rather than 16777216
  **  - dec values carry the scale of decimal(9,2).  Decimal equality is
  **    scale sensitive, since FanDecimal.equals delegates to
  **    BigDecimal.equals, so 0d and 0.00d are not equal
  **  - dt and time values are whole seconds, which mysql datetime and
  **    time truncate to by default
  **  - char values are exactly 4 chars, because postgres bpchar pads to
  **    the declared width while mysql char strips trailing spaces
  Str:Obj?[] typeCases()
  {
    // 255 chars, the declared width of the str column
    longStr := StrBuf()
    255.times |i| { longStr.addChar('a' + (i % 26)) }

    // every byte value
    allBytes := Buf()
    256.times |i| { allBytes.write(i) }

    return [
      "str":  Obj?["", "a", "hello world", "it's", "a\\b", "h\u00e9llo \u2603", longStr.toStr],
      "char": Obj?["abcd", "0000", "zzzz"],
      "bool": Obj?[true, false],
      "i8":   Obj?[0, 1, -1, 127, -128],
      "i16":  Obj?[0, 32767, -32768],
      "i32":  Obj?[0, 2147483647, -2147483648],
      "i64":  Obj?[0, 3_000_000_000, Int.maxVal, Int.minVal],
      "f32":  Obj?[0.0f, 0.125f, 0.5f, 1.5f, -2.25f, 65536.0f],
      "f64":  Obj?[0.0f, 0.1f, 1.5f, -1.0e10f],
      "dec":  Obj?[0.00d, 0.01d, 12.34d, -12.34d, 1234567.89d],
      "dt":   Obj?[DateTime(2000, Month.jan, 1, 0, 0, 0),
                   DateTime(2026, Month.sep, 4, 9, 30, 15),
                   DateTime(2030, Month.dec, 31, 23, 59, 59)],
      "date": Obj?[Date(2000, Month.jan, 1),
                   Date(2026, Month.sep, 4),
                   Date(2030, Month.dec, 31)],
      "time": Obj?[Time(0, 0, 0), Time(9, 30, 15), Time(23, 59, 59)],
      "buf":  Obj?[Buf(), "x".toBuf, allBytes],
    ]
  }

//////////////////////////////////////////////////////////////////////////
// Tables
//////////////////////////////////////////////////////////////////////////

  ** Create a table from the given columns, rendering the DDL through
  ** the dialect.  The table is dropped during teardown.
  internal Void createTable(Str name, ColDef[] cols)
  {
    createRawTable(name, dialect.createTable(name, cols))
  }

  ** Create a table from raw ddl, and register it to be dropped during
  ** teardown.  For feature-gated tests, where a portable ColDef schema
  ** would be pointless because the test only ever runs on one database.
  Void createRawTable(Str name, Str ddl)
  {
    db.sql("drop table if exists $name").execute
    db.sql(ddl).execute
    if (!tables.contains(name)) tables.add(name)
  }

  ** Create the main test table
  Void createVals()
  {
    createTable(valsTable, Dialect.valsCols)
  }

//////////////////////////////////////////////////////////////////////////
// Insert
//////////////////////////////////////////////////////////////////////////

  ** Insert a row built from a column-name:value map and return whatever
  ** Statement.execute returned.  Columns are emitted in sorted order so
  ** the generated SQL is deterministic.
  Obj insert(Str table, Str:Obj? vals)
  {
    names := vals.keys.sort
    cols  := names.join(", ")
    binds := names.join(", ") |n| { "@" + n }

    stmt := db.sql("insert into $table ($cols) values ($binds)").prepare
    try
      return stmt.execute(vals)
    finally
      stmt.close
  }

  ** Insert into the main test table and return the auto-generated key
  Int insertVals(Str:Obj? vals)
  {
    res  := insert(valsTable, vals)
    keys := res as Int[]
    verifyNotNull(keys, "expected auto-generated keys, got $res")
    verifyEq(keys.size, 1)
    return keys.first
  }

//////////////////////////////////////////////////////////////////////////
// Query
//////////////////////////////////////////////////////////////////////////

  ** Number of rows in the main test table
  Int rowCount()
  {
    return (Int) db.sql("select count(*) as n from $valsTable").query[0]->n
  }

  ** The single Int column selected by the given sql
  Int[] ints(Str sql)
  {
    acc := Int[,]
    db.sql(sql).queryEach(null) |row| { acc.add((Int)row.get(row.cols[0])) }
    return acc
  }

  ** The row in the main test table with the given key
  Row selectById(Int id)
  {
    stmt := db.sql("select * from $valsTable where id = @id").prepare
    try
    {
      rows := stmt.query(["id": id])
      verifyEq(rows.size, 1, "id $id")
      return rows[0]
    }
    finally
      stmt.close
  }

  ** The one row in the main test table whose v_str is the given key
  Row selectOne(Str key)
  {
    stmt := db.sql("select * from $valsTable where v_str = @s").prepare
    try
    {
      rows := stmt.query(["s": key])
      verifyEq(rows.size, 1, key)
      return rows[0]
    }
    finally
      stmt.close
  }

  ** The v_str values in the main test table, sorted
  Str[] strs()
  {
    acc := Str[,]
    db.sql("select v_str from $valsTable order by v_str").queryEach(null) |row|
    {
      acc.add((Str)row->v_str)
    }
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Verify
//////////////////////////////////////////////////////////////////////////

  ** Compare two cell values.  Buf does not define value equality, so
  ** binary cells are compared by content.
  Bool valEq(Obj? a, Obj? b)
  {
    if (a is Buf && b is Buf) return ((Buf)a).bytesEqual(b)
    return a == b
  }

  ** Verify a Col against its ColDef and this dialect's expectations
  internal Void verifyColDef(Col col, Int index, ColDef def)
  {
    verifyEq(col.index, index, "$def.name index")
    verifyEq(col.name, def.name, "col $index name")

    t := dialect.typeDef(def.type)
    verifySame(col.type, t.fanType, "$def.name type")
    verifyEq(col.sqlType.upper, t.sqlType.upper, "$def.name sqlType")
  }

  ** Verify a row's cols match the given ColDefs, in order
  internal Void verifyColDefs(Row row, ColDef[] defs)
  {
    verifyEq(row.cols.size, defs.size)
    defs.each |def, i| { verifyColDef(row.cols[i], i, def) }
  }

  ** Verify every cell in the row is null, apart from the named columns
  Void verifyNullsExcept(Row row, Str[] except)
  {
    row.cols.each |col|
    {
      if (except.contains(col.name)) return
      verifyNull(row.get(col), col.name)
    }
  }

  ** Verify a row's cells against a column-name:value map.  Only the
  ** named columns are checked.
  Void verifyRow(Row row, Str:Obj? expected)
  {
    expected.each |val, name|
    {
      actual := row.get(row.col(name))
      verify(valEq(actual, val), "$name: expected $val, got $actual")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Connection for the current test method
  SqlConn? db

  ** Tables created by the current test method, dropped during teardown
  private Str[] tables := [,]

  private Log log := Log.get("sqlTest")

  ** Report that the current test does not apply to this dialect.  Skips
  ** are logged rather than silent, so the run says what it did not cover.
  private Void logSkip()
  {
    log.info("skip ${curTestMethod.name} ($dialect.name)")
  }
}

**************************************************************************
** MySqlTest
**************************************************************************

class MySqlTest : SqlTest
{
  internal override Dialect dialect() { Dialect.mysql }
}

**************************************************************************
** PostgresTest
**************************************************************************

class PostgresTest : SqlTest
{
  internal override Dialect dialect() { Dialect.postgres }
}
