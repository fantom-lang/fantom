
// utility to force a path to a directory
const toDir = function(f) {
  if (os.platform() == "win32") {
    // change to posix-style path
    f = f.split(path.sep).join(path.posix.sep);
  }
  // ensure ends with a trailing '/' for a directory
  if (!f.endsWith("/")) f = f + "/";
  return f;
};

// check if we are using PathEnv
const checkPathEnv = async function() {
  const util = await import('./util.js');
  let dir = sys.File.os("./").normalize();
  while (dir)
  {
    let fanFile = dir.plus("fan.props");
    if (fanFile.exists())
    {
      let pathEnv = util.PathEnv.makeProps(fanFile);
      sys.Env.cur(pathEnv);
      break
    }

    dir = dir.parent();
  }
}

// Supported options:
// - polyfill: list of libraries to polyfill. The following libraries
//   are supported:
//   - 'ws': polyfill the WebSocket class. The 'ws' package from NPM must
//   be available in the node path.
const boot = async function(opts={}) {
  const {Env, File,} = sys;
    const __dirname = path.dirname(url.fileURLToPath(import.meta.url));

  // find Fantom home dir
  const node_path = path.resolve(url.fileURLToPath(import.meta.url), "../..");
  let fan_home = opts["FAN_HOME"] ?? process.env["FAN_HOME"];
  if (!fan_home) {
    // default fan_home is the same as node_path
    fan_home = node_path;
  }
  else fan_home = path.resolve(fan_home);
  fan_home = toDir(fan_home);

  // init sys.BootEnv
  Env.cur().__homeDir = File.os(fan_home);
  Env.cur().__workDir = File.os(fan_home);
  Env.cur().__tempDir = File.os(toDir(path.resolve(fan_home, "temp")));
  Env.cur().__loadVars({
    "node.version": process.versions.node,
    "node.path": node_path
  });

  await checkPathEnv();

  // handle polyfills
  for (const lib of (opts["polyfill"] ?? [])) {
    const f = polyfills[lib];
    if (f) await f();
  }

  // import all pods
  const modules = __dirname;
  for (const fan_module of fs.readdirSync(modules)) {
    if (path.extname(fan_module) == ".ts") continue;
    if (fan_module.startsWith("fan_")) continue;
    if (fan_module.startsWith("test")) continue;
    if (fan_module == "fantom.js" || fan_module == "sys.js") continue;
    try { await import(`./${fan_module}`); } catch (err) { /* ignore */ }
  }

  return sys;
};

const polyfills = {
  "ws": async function() {
    try {
      const {WebSocket} = await import('ws');
      globalThis.WebSocket = WebSocket;
    } catch (err) {
      console.log(`WARN: 'ws' package not available`);
    }
  }
};
