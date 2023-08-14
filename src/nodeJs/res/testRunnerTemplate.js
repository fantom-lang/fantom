const __require = (typeof require !== 'undefined') ? require : null;

//{{include}}

//{{tests}}

let methodCount      = 0;
let totalVerifyCount = 0;
let failures         = 0;
let failureNames     = [];

const testRunner = function(type, method)
{
  let test;
  const doCatchErr = function(err)
  {
    if (err == undefined) print('Undefined error\n');
    else if (err.trace) err.trace();
    else
    {
      let file = err.fileName;   if (file == null) file = 'Unknown';
      let line = err.lineNumber; if (line == null) line = 'Unknown';
      // sys.Env.cur().out().printLine(err + ' (' + file + ':' + line + ')\n');
      console.log(err + ' (' + file + ':' + line + ')\n');
    }
  }

  try
  {
//{{envDirs}}
    test = type.make();
    test.setup();
    test[method]();
    return test.verifyCount$();
  }
  catch (err)
  {
    doCatchErr(err);
    return -1;
  }
  finally
  {
    try { test.teardown(); }
    catch (err) { doCatchErr(err); }
  }
}

tests.forEach(function (test) {
  console.log('');
  test.methods.forEach(function (method) {
    var qname = test.qname + '.' + method;
    var verifyCount = -1;
    console.log('-- Run: ' + qname + '...');
    verifyCount = testRunner(test.type, method);
    if (verifyCount < 0) {
      failures++;
      failureNames.push(qname);
    } else {
      console.log('   Pass: ' + qname + ' [' + verifyCount + ']');
      methodCount++;
      totalVerifyCount += verifyCount;
    }
  });
});

if (failureNames.length > 0) {
  console.log('');
  console.log("Failed:");
  failureNames.forEach(function (qname) {
    console.log('  ' + qname);
  });
  console.log('');
}

console.log('');
console.log('***');
console.log('*** ' +
            (failures == 0 ? 'All tests passed!' : '' + failures + ' FAILURES') +
            ' [' + tests.length + ' tests , ' + methodCount + ' methods, ' + totalVerifyCount + ' verifies]');
console.log('***');
