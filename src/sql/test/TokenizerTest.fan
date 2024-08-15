//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 July 2024  Mike Jarmy   Creation
//

**
** TokenizerTest
**
class TokenizerTest : Test
{
  Void test()
  {
    //---------------------------------------------------------------
    // Tokenizer doesn't know anything about real SQL syntax, so lets
    // test against all kinds of cases that it can process successfully even if
    // the SQL is dubious or obviously bogus.

    doVerify("", "", Str:Int[][:])
    doVerify("x", "x", Str:Int[][:])

    // params
    doVerify("@a", "?", Str:Int[]["a": [1]])
    doVerify("@a @b @a", "? ? ?", Str:Int[]["a": [1,3], "b": [2]])
    doVerify("@a @b @a @a @c", "? ? ? ? ?", Str:Int[]["a": [1,3,4], "b": [2], "c": [5]])
    doVerify("@", "@", Str:Int[][:])
    doVerify("@@ x", "@@ x", Str:Int[][:])

    // params and normal
    doVerify("-@a-", "-?-", Str:Int[]["a": [1]])
    doVerify("@a@>-@a@@@>", "?@>-?@@@>", Str:Int[]["a": [1,2]])

    // params and quoted
    doVerify("'x'@a", "'x'?", Str:Int[]["a": [1]])
    doVerify("'x'y@a", "'x'y?", Str:Int[]["a": [1]])
    doVerify("@a'@b'", "?'@b'", Str:Int[]["a": [1]])
    doVerify("x'123'@a", "x'123'?", Str:Int[]["a": [1]])

    // escape
    doVerify("\\@b", "@b", Str:Int[][:])
    doVerify("\\\\", "\\", Str:Int[][:])
    doVerify("\\@\\\\\\@", "@\\@", Str:Int[][:])
    doVerify("@a\\@b", "?@b", Str:Int[]["a": [1]])
    doVerify("@a\\@\\@b", "?@@b", Str:Int[]["a": [1]])
    doVerify("\\@b@a", "@b?", Str:Int[]["a": [1]])
    doVerify("x\\@b@a", "x@b?", Str:Int[]["a": [1]])
    doVerify("x\\@b'123'@a", "x@b'123'?", Str:Int[]["a": [1]])

    // invalid escape
    verifyErr(SqlErr#) { p := Tokenizer("\\^") }

    // unterminated
    verifyErr(SqlErr#) { p := Tokenizer("'") }
    verifyErr(SqlErr#) { p := Tokenizer("@a'") }
    verifyErr(SqlErr#) { p := Tokenizer("'x'@a'y") }

    //--------------------------------------------------------
    // Now lets go ahead and do some syntactically correct sql

    doVerify(
      "select * from foo",
      "select * from foo",
      Str:Int[][:])

    // one param
    doVerify(
      "select name, age from farmers where name = @name",
      "select name, age from farmers where name = ?",
      Str:Int[]["name":[1]])

    // repeated param
    doVerify(
      "select * from foo where @a = 1 or @b = 2 or @a = 3",
      "select * from foo where ? = 1 or ? = 2 or ? = 3",
      Str:Int[]["a":[1,3], "b":[2]])

    // escaped mysql user variable
    doVerify(
      "select \\@bar",
      "select @bar",
      Str:Int[][:])
    doVerify(
      "select \\@bar from foo where @a = 1",
      "select @bar from foo where ? = 1",
      Str:Int[]["a":[1]])

    // escaped mysql system variable
    doVerify(
      "select \\@\\@bar",
      "select @@bar",
      Str:Int[][:])
    doVerify(
      "select \\@\\@bar from foo where @a = 1",
      "select @@bar from foo where ? = 1",
      Str:Int[]["a":[1]])

    // postgres operators that start with '@'
    doVerify(
      "select * from foo where @a \\@> 1",
      "select * from foo where ? @> 1",
      Str:Int[]["a":[1]])
    doVerify(
      "select * from foo where @a \\@\\@ 1",
      "select * from foo where ? @@ 1",
      Str:Int[]["a":[1]])

    // quoted string
    doVerify(
      "select 'abc' from foo where @a = 1",
      "select 'abc' from foo where ? = 1",
      Str:Int[]["a":[1]])
    doVerify(
      "select '@x \\@y \\@ \\\\@>' from foo where @a = 1",
      "select '@x \\@y \\@ \\\\@>' from foo where ? = 1",
      Str:Int[]["a":[1]])
  }

  private Void doVerify(Str sql, Str expected, Str:Int[] params)
  {
    //echo("------------------------------------------")
    //echo(sql)
    t := Tokenizer(sql)
    verifyEq(t.sql, expected)
    verifyEq(t.params, params)
  }
}
