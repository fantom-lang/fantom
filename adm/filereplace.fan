
class FileReplace
{

  Void replace(File f, Str from, Str to)
  {
    s := f.readAllStr(true)
    if (!s.contains(from)) return
    echo("  Replace $f")
    s = s.replace(from, to)
    f.out.print(s).close
  }

  Void main(Str[] args)
  {
    if (args.size < 4)
    {
      echo("usage: filereplace <from> <to> <dir> <ext>")
      return
    }
    from := args[0]
    to   := args[1]
    dir  := File.os(args[2])
    ext  := args[3]
    dir.walk |File f| { if (f.ext == ext) replace(f, from, to) }
  }

}