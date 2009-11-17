# Copyright (c) 2005, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0

#
# Env -- setups the environment for admin tasks
#
# @author   Brian Frank
# @creation 23 Dec 05
#
class Env

  # global list of pods under src
  @@all_pods = [ 'sys', 'sysTest', 'compiler', 'build', 'web', 'webServlet', 'fantext', 'fandoc' ]

  # setup a bunch of instance variables
  def initialize()
    @fan_home = ENV["fan_home"]
    @fan_adm  = File.join(@fan_home, "adm")
    @fan_bin  = File.join(@fan_home, "bin")
    @fan_lib = File.join(@fan_home, "lib")
      @fan_lib_java = File.join(@fan_lib, "java")
        @sys_jar   = File.join(@fan_lib_java, "sys.jar")
      @fan_lib_fan  = File.join(@fan_lib, "fan")
      @fan_lib_net  = File.join(@fan_lib, "net")
    @fan_src  = File.join(@fan_home, "src")
      @src_jfan     = File.join(@fan_src, "sys", "java")
      @src_nfan     = File.join(@fan_src, "sys", "dotnet")
      @src_compiler = File.join(@fan_src, "compiler")

    @java_home = ENV["java_home"]
      @javac     = File.join(@java_home, "bin", "javac.exe")
      @jar       = File.join(@java_home, "bin", "jar.exe")
  end

  # dump all the instance variables
  def dump()
    puts "fan_home     = #@fan_home"
    puts "fan_bin      = #@fan_bin"
    puts "fan_lib      = #@fan_lib"
    puts "fan_lib_fan  = #@fan_lib_fan"
    puts "fan_lib_java = #@fan_lib_java"
    puts "fan_lib_net  = #@fan_lib_net"
    puts "fan_src      = #@fan_src"
    puts "src_jfan     = #@src_jfan"
    puts "src_jsfan    = #@src_jsfan"
    puts "src_nfan     = #@src_nfan"
    puts "java_home    = #@java_home"
    puts "javac        = #@javac"
  end

  # recursively delete a directory (of file)
  def nuke(x)
    nukeLog(x, false)
  end

  def nukeLog(x, log)
    return unless File.exists?(x)
    if File.directory?(x)
      Dir.entries(x).each do |f|
        next if f == "." || f == ".."
        f = x + "/" + f
        nuke(f)
      end
      puts("  del [" + x + "]") if log
      Dir.delete(x)
    else
      puts("  del [" + x + "]") if log
      File.delete(x)
    end
  end

  def syscall(cmd)
    r = system(cmd)
    raise ("Failed: " + cmd) unless r
  end


end

