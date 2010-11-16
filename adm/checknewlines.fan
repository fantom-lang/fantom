
class CheckNewlines
{

  Str[] exts := ["fan", "java", "cs", "fandoc", "props", "fog", "js", "css" ]

  Void check(File f)
  {
    if (f.ext == null) return
    if (!exts.contains(f.ext)) return

    s := f.readAllStr
    lines := s.splitLines

    if (s.containsChar('\r') || lines.any{it.endsWith(" ")})
    {
      echo("Fix newlines: $f")
      out := f.out
      lines.each |line| { out.print(line.trimEnd).print("\n") }
      out.close
      numFixed++
    }

    if (s.containsChar('\t')) echo("CONTAINS TABS: $f")
  }

  Void main(Str[] args)
  {
    if (args.isEmpty) throw Err("Usage: checknewlines <dir>")
    root := args.first.toUri.toFile
    if (!root.exists) throw Err("Root dir not found: $root")
    root.walk |file| { check(file) }
    echo("### Fixed $numFixed ###")
  }

  Int numFixed
}