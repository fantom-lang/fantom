const __require = (m) => {
  const name = m.split('.')[0];
  const fan = this.fan;
  if (typeof require === 'undefined') return name == "fan" ? fan : fan[name];
  try { return require(`${m}`); } catch (e) { /* ignore */ }
}

//{{include}}

//{{envDirs}}

//{{targets}}
// Delegate to standard TestRunner
sys.Type.find("util::TestRunner").method("main").call(targets);
