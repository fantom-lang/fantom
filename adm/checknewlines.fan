
class CheckNewlines
{

  Str[] exts := ["fan", "java", "cs", "fandoc", "props", "fog", "js" ]

  Void check(File f)
  {
    if (f.ext == null) return
    if (!exts.contains(f.ext)) return

    notUtf8 := false
    Str? s := null
    Str[]? lines := null
    try
    {
      s = f.readAllStr(false)
    }
    catch (IOErr e)
    {
      echo("File not UTF-8: $f")
      in := f.in { charset = Charset.fromStr("ISO-8859-1") }
      lines = in.readAllLines
      notUtf8 = true
    }

    if (notUtf8 || s.containsChar('\r'))
    {
      echo("Fix newlines: $f")
      if (lines == null) lines = f.readAllLines
      out := f.out
      lines.each |line, i|
      {
        if (line.any |ch| { ch > 128 }) echo("  Non-ASCII: ${i+1}: $line")
        out.print(line.trimEnd).print("\n")
      }
      out.close
    }

    if (s != null && s.containsChar('\t')) echo("CONTAINS TABS: $f")
  }

  Void main() { (Sys.homeDir).walk(&check) }

}