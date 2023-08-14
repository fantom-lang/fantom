const __require = (typeof require !== 'undefined') ? require : null;

//{{include}}

try {
//{{envDirs}}
  {{tempPod}}.Main.main();
} catch (err) {
  console.log('ERROR: ' + err + '\n');
  console.log(err.stack);
  if (err == undefined) print('Undefined error\n');
  else if (err.trace) err.trace();
  else
  {
    var file = err.fileName;   if (file == null) file = 'Unknown';
    var line = err.lineNumber; if (line == null) line = 'Unknown';
    sys.Env.cur().out().printLine(err + ' (' + file + ':' + line + ')\n');
  }
}