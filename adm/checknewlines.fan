
class CheckNewlines
{

  static Void check(File f)
  {
    if (f.ext != "fan") return
    s := f.readAllStr(false)
    if (s.containsChar('\r'))
      echo("Invalid newlines: $f")
  }

  static Void main() { Sys.homeDir.walk(&check) }

}
