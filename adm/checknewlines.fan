
class CheckNewlines
{

  Str[] exts := ["fan", "java", "cs", "fandoc", "props", "fog" ]

  Void check(File f)
  {
    if (f.ext == null) return
    if (!exts.contains(f.ext)) return
    s := f.readAllStr(false)
    if (s.containsChar('\r'))
    {
      echo("Fix newlines: $f")
      lines := f.readAllLines
      out := f.out
      lines.each |Str line| { out.print(line.trimEnd).print("\n") }
      out.close
    }

    if (s.containsChar('\t')) echo("CONTAINS TABS: $f")
  }

  Void main() { Sys.homeDir.walk(&check) }

}