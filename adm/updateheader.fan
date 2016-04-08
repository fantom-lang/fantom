
class UpdateHeader
{

  static Void processFile(File f)
  {
    echo("-- $f")

    lines := f.readAllLines

    // strip existing header
    if (f.ext == "fan")
    {
      if (!lines[0].startsWith("// Copyright") ||
          !lines[1].startsWith("// Licensed") ||
          !lines[2].trim.isEmpty)
      {
        echo("  ERROR: unexpected header")
        errorCount++
        return
      }
      2.times { lines.removeAt(0) }
    }
    // strip existing header
    else
    {
      if (!lines[0].startsWith("/*") ||
          !lines[1].startsWith(" * Copyright") ||
          !lines[2].startsWith(" * Licensed") ||
          !lines[3].startsWith(" */"))
      {
        echo("  ERROR: unexpected header")
        errorCount++
        return
      }
      4.times { lines.removeAt(0) }
    }

    // find existing author/creation
    Int authorIndex := null
    Int creationIndex := null
    for (i:=0; i<lines.size; ++i)
    {
      line := lines[i]
      if (line.contains("@author")) { authorIndex = i }
      if (line.contains("@creation")) { creationIndex = i }
      if (authorIndex != null && creationIndex != null) break
    }
    if (authorIndex == null || creationIndex == null)
    {
      echo("  ERROR: could not find author/creation")
      errorCount++
      return
    }
    author := lines[authorIndex]
    creation := lines[creationIndex]
    3.times { lines.removeAt(authorIndex-1) }

    // parse out author, history
    author = author[author.index("@author") + 7..-1].trim
    creation = creation[creation.index("@creation") + 9..-1].trim

    // map to history
    history1 := [creation, author, "Creation"]
    history2 := [,]
    if (creation.contains("(ported"))
    {
      c1 := creation[0...creation.index("(ported")].trim
      c2 := creation[creation.index("(ported")+8..-2].trim
      why := "Ported from Java to Fan"
      if (c2.contains("-"))
      {
        why += c2[c2.index("-")-1..-1]
        c2 = c2[0...c2.index("-")].trim
        if (c2.size == 8) c2 = " $c2"
      }
      history1[0] = c1
      history2 = [c2, author, why]
    }

    n := 0
    lines.insert(n++, "//")
    lines.insert(n++, "// Copyright (c) 2006, Brian Frank and Andy Frank")
    lines.insert(n++, "// Licensed under the Academic Free License version 3.0")
    lines.insert(n++, "//")
    lines.insert(n++, "// History:")
    lines.insert(n++, "//   ${history1[0]}  ${history1[1]}  ${history1[2]}")
    if (!history2.isEmpty) lines.insert(n++, "//   ${history2[0]}  ${history2[1]}  ${history2[2]}")
    lines.insert(n++, "//")

    // 15.times |Int i| { echo(lines[i]) }

    f.out.print(lines.join("\n")).close

    processed++
    totalLines += lines.size
  }

  static Void process(File f)
  {
    if (f.ext == "fan" || f.ext == "java")
    {
      processFile(f)
    }
    else if (f.isDir)
    {
      f.list.each |File kid| { process(kid) }
    }
  }

  static Void main()
  {
    process(File.make(`/dev/fan/src/`))
    echo("Processed  $processed")
    echo("Errors     $errorCount")
    echo("Lines      $totalLines")
  }

  static Int errorCount := 0
  static Int processed := 0
  static Int totalLines := 0

}