
// utility to force a path to a directory
const toDir = function(f)
{
  if (os.platform() == "win32") {
    // change to posix-style path
    f = f.split(path.sep).join(path.posix.sep);
  }
  // ensure ends with a trailing '/' for a directory
  if (!f.endsWith("/")) f = f + "/";
  return f;
};

const boot = async function(opts={}) {
  const {Env, File,} = sys;

  // find Fantom home dir
  let fan_home = opts["FAN_HOME"] ?? process.env["FAN_HOME"];
  if (!fan_home) {
    // assumes that fantom.js is in <fan_home>/lib/es/esm/
    const __dirname = path.dirname(url.fileURLToPath(import.meta.url));
    fan_home = path.resolve(__dirname, "../../../");
  }
  fan_home = toDir(fan_home);

  // init sys.Env
  Env.cur().__homeDir = File.os(fan_home);
  Env.cur().__workDir = File.os(fan_home);
  Env.cur().__tempDir = File.os(toDir(path.resolve(fan_home, "temp")));

  // import all pods
  const modules = path.resolve(fan_home, "lib/es/esm");
  for (const fan_module of fs.readdirSync(modules)) {
    if (path.extname(fan_module) == ".ts") continue;
    if (fan_module.startsWith("fan_")) continue;
    if (fan_module.startsWith("test")) continue;
    if (fan_module == "fantom.js" || fan_module == "sys.js") continue;
    try { await import(`./${fan_module}`); } catch (err) { /* ignore */ }
  }

  return sys;
};
