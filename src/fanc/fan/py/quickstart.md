# Python Transpiler - Quick Start

Build and test the Fantom-to-Python transpiler in 4 steps.

**Requirements:** Fantom build environment, Python 3.12+

---

## Python Environment

Python 3.12 or later is required. The `py` test runner discovers Python in this order:

1. `FAN_PYTHON` environment variable (if set, uses that path directly)
2. `uv python find` (if [uv](https://docs.astral.sh/uv/) is installed)
3. `pyenv which python` (if pyenv is installed)
4. `python3` on PATH (macOS/Linux) or `python` on PATH (Windows)

If your default `python3` is 3.12+, no configuration is needed. Otherwise:

```bash
export FAN_PYTHON=/path/to/python3.12
```

The test runner checks the version at startup and prints a clear error if it's too old.

---

## Build and Run

### 1. Build the transpiler

```bash
bin/fan src/fanc/build.fan
```

### 2. Build the test runner

```bash
bin/fan src/py/build.fan
```

### 3. Transpile pods to Python

```bash
bin/fanc py sys testSys util
```

Output goes to `gen/py/` under `Env.cur.workDir` (the first entry in your PathEnv path, or FAN_HOME if not using PathEnv). The transpiler automatically resolves dependencies (`concurrent` is pulled in by `testSys`).

**Important:** Each `fanc py` invocation regenerates the output directory. Transpile all pods you need in a single command.

**Note:** You may see `ERROR: invalid fanc.cmd nodeJs::JsCmd` -- this is non-fatal. It happens when `fanc` tries to register all transpiler commands and `nodeJs.pod` isn't built. The Python transpiler runs fine regardless.

### 4. Run tests

```bash
bin/py test testSys::BoolTest
```

```
-- Run: testSys::BoolTest.testIdentity
   Pass: testSys::BoolTest.testIdentity [25]
-- Run: testSys::BoolTest.testDefVal
   Pass: testSys::BoolTest.testDefVal [2]
...
***
*** All tests passed! [1 types, 7 methods, 111 verifies]
***
```

Run a single method:
```bash
bin/py test testSys::BoolTest.testDefVal
```

Run an entire pod:
```bash
bin/py test testSys
```

---

## Transpiling Additional Pods

```bash
# Foundation pods (with inet, web, crypto, email)
bin/fanc py sys testSys util concurrent inet web crypto email

# Run all testSys tests
bin/py test testSys
```

The transpiler resolves and transpiles dependencies automatically.

---

## What Gets Generated

`fanc py <pod>` produces Python source in `gen/py/fan/<podName>/`:

- **Pure Fantom types** -- fully transpiled to Python classes
- **Types with natives** -- hand-written Python file merged with transpiled metadata
- **Extra natives** -- utility files (e.g., `ObjUtil.py`) copied directly
- **Lazy loader `__init__.py`** -- module-level `__getattr__` for lazy imports

Each pod with Python natives declares them in `build.fan`:
```fantom
pyDirs = [`py/`]
```

The transpiler reads these via `compiler.input.pyFiles` and merges them with transpiled output.

---

## File Layout

```
src/fanc/fan/py/          # Transpiler source
  PythonCmd.fan            # Entry point (fanc py <pod>)
  PyTypePrinter.fan        # Class/type generation
  PyExprPrinter.fan        # Expression generation
  PyStmtPrinter.fan        # Statement generation
  PyPrinter.fan            # Base printer
  PyUtil.fan               # Utilities and operator maps
  design.md                # Technical reference
  quickstart.md            # This file

src/sys/py/fan/            # sys pod natives (79 files)
src/sys/py/fanx/           # Serialization module (5 files)
src/concurrent/py/         # concurrent pod natives (12 files)
src/util/py/               # util pod natives (7 files)
src/inet/py/               # inet pod natives (9 files)
src/web/py/                # web pod natives (5 files)
src/crypto/py/             # crypto pod natives (2 files)

src/py/                    # py pod -- Python CLI tools
  fan/Main.fan             # CLI entry point (command dispatch)
  fan/PyCmd.fan            # Base command (Python discovery, version check)
  fan/cmd/TestCmd.fan      # Test runner (util::TestRunner)
  fan/cmd/FanCmd.fan       # Run Fantom main programs (py fan <pod>)
  fan/cmd/HelpCmd.fan      # Help and command listing
  fan/cmd/InitCmd.fan      # Initialize Python environment
```

See `design.md` for the full technical reference on how Fantom constructs map to Python.
