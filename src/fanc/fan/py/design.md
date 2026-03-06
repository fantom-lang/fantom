This is a "living" document covering many aspects of the design and implementation
for the mapping from Fantom to Python.

---

## Table of Contents

1. [Getting Started](#getting-started) - Usage and build integration
2. [Porting Native Code](#porting-native-code) - Adding Python natives to a pod
3. [Design](#design) - How Fantom constructs map to Python
   - [Python Classes](#python-classes)
   - [Fields](#fields) / [Static Fields](#static-fields)
   - [Enums](#enums)
   - [Funcs and Closures](#funcs-and-closures)
   - [Primitives](#primitives)
   - [List and Map Architecture](#list-and-map-architecture)
   - [Import Architecture](#import-architecture)
   - [Type Metadata](#type-metadata-reflection)
   - [Generated Code Conventions](#generated-code-conventions)
   - [ObjUtil Helper Methods](#objutil-helper-methods)
   - [Exception Mapping](#exception-mapping)
4. [Naming](#naming) - Identifier conventions (snake_case, escaping)
5. [Python-Specific Considerations](#python-specific-considerations) - GIL, overloading, type hints
6. [Performance Optimizations](#performance-optimizations) - Runtime caching strategies

---

## How to Read This Document

**If you want to understand what Python code gets generated:**
- Start with [Design](#design) for the core patterns (classes, fields, closures)
- See [Naming](#naming) for how identifiers are transformed (snake_case, escaping)
- Check [Generated Code Conventions](#generated-code-conventions) for internal naming patterns

**If you want to understand the runtime:**
- [ObjUtil Helper Methods](#objutil-helper-methods) documents the contract between transpiled code and runtime
- [List and Map Architecture](#list-and-map-architecture) explains collection design
- [Performance Optimizations](#performance-optimizations) covers caching strategies

**If you're debugging generated code:**
- [Generated Code Conventions](#generated-code-conventions) explains patterns like `_closure_N`, `_switch_N`
- [Import Architecture](#import-architecture) explains why imports are structured the way they are
- [Exception Mapping](#exception-mapping) shows how catch clauses are generated

**If you're adding Python support to a pod:**
- Start with [Getting Started](#getting-started) for build integration
- See [Porting Native Code](#porting-native-code) for the process
- Reference [Design](#design) for patterns to follow

**Key Insight:** The transpiler generates Python code that calls `ObjUtil` and `Func` methods.
The [ObjUtil Helper Methods](#objutil-helper-methods) section documents this contract - if a
method is listed there, the transpiler generates calls to it and the runtime must implement it.

---

# Getting Started

The Python implementation of the `sys` pod is in `src/sys/py/fan/`. Unlike JavaScript
which bundles into a single file, Python uses individual `.py` files that match Python's
module import system.

The Python transpiler lives in the `fanc` pod at `src/fanc/fan/py/`. It generates Python
code from Fantom source and outputs to `gen/py/`.

## fanc py (Python Transpiler)

The Python transpiler is invoked via `fanc py <pod>`. It serves the same purpose as
`compilerEs` for JavaScript, but emits Python 3 code.

```bash
# Transpile testSys pod to Python
fanc py testSys

# Transpile haystack pod
fanc py haystack
```

Generated code is output to `<work_dir>/gen/py/fan/<podName>/` (where `work_dir` is
typically `fan_home`, determined by `Env.cur.workDir`).

## Build Integration (pyDirs/pyFiles)

The Python transpiler is integrated into Fantom's build system using the same pattern as
JavaScript's `jsDirs`:

### BuildPod.fan
Pods declare native Python directories in their `build.fan`:

```fantom
class Build : BuildPod
{
  pyDirs = [`py/`]  // Directory containing Python natives
}
```

### CompilerInput.fan
The `pyFiles` field passes resolved native directories to the compiler:

```fantom
class CompilerInput
{
  Uri[]? pyFiles  // Resolved Python native directories
}
```

### PythonCmd.fan
The transpiler reads `pyFiles` from the compiler input:

```fantom
// Uses compiler.input.pyFiles to find native directory
pyFiles := compiler?.input?.pyFiles
```

### Native Directory Locations

| Pod | Native Directory | build.fan |
|-----|------------------|-----------|
| sys | `src/sys/py/fan/` | (special handling) |
| concurrent | `src/concurrent/py/` | `pyDirs = [\`py/\`]` |
| util | `src/util/py/` | `pyDirs = [\`py/\`]` |
| crypto | `src/crypto/py/` | `pyDirs = [\`py/\`]` |

The sys pod uses `py/fan/` to match its source structure. Other pods use `py/` directly.

## Native Code Merging

When transpiling, the Python transpiler:
1. Checks if a hand-written native file exists in the pod's `py/` directory
2. If found, copies the native file and appends type metadata from the transpiled output
3. If not found, uses the fully transpiled output

This allows hand-written runtime code (like `Actor.py`, `List.py`) to coexist with
transpiled code, similar to how JavaScript natives work.

## Standard Build (Packaging into Pods)

To package Python natives into `.pod` files (for distribution):

```bash
fan src/sys/py/build.fan compile        # Package natives into sys.pod
fan src/concurrent/py/build.fan compile # Package into concurrent.pod
fan src/util/py/build.fan compile       # Package into util.pod
```

This packages Python natives inside `.pod` files at `/py/fan/<podName>/`, matching the
JavaScript pattern of `/esm/` and `/cjs/` directories.

# Porting Native Code

If you have a pod with native Python implementations, follow these steps:

1. Create a `/py/` directory in the root of your pod (peer to any existing `/js/` or `/es/`)
2. For `sys` pod specifically, create `/py/fan/` subdirectory (matches import path)
3. Port native code into this directory following the patterns below
4. Use the existing code in `sys/py/fan/` or `concurrent/py/` as reference

Native files are named to match the Fantom type they implement (e.g., `List.py` for `sys::List`).

## Native `__init__.py` Merging

Each pod gets a generated `__init__.py` containing a lazy loader with a `_types` dict
that `Pod.types()` uses for type discovery. Some pods also have a hand-written
`__init__.py` in their native directory with module initialization code (import caching,
eager imports, etc.).

When a native `__init__.py` exists, the transpiler **merges** it with the generated
lazy loader: native content is prepended, generated content is appended. This preserves
both the native infrastructure and the `_types` registry.

**Pods with native `__init__.py`:**

| Pod | Purpose |
|-----|---------|
| sys | Import caching optimization, module class fix for submodule shadowing, eager base type imports |
| concurrent | Eager imports of native types |
| util | Eager imports of native types |
| inet | Eager imports of native types |

**Rules for native `__init__.py`:**
- Keep module initialization code that genuinely needs to run at import time
- Do NOT put monkey-patches for transpiled types here -- fix the transpiler or runtime instead
- The `_types` dict and `__getattr__` lazy loader are always appended by the transpiler

# Design

This section details the design decisions and implementation patterns for Python code.

## Python Classes

All Fantom types are implemented as Python classes extending `Obj`.

Fantom:
```fantom
class Foo { }
```

Python (simplified):
```python
from fan.sys.Obj import Obj

class Foo(Obj):
    def __init__(self):
        super().__init__()
```

**Note:** The example above is simplified for clarity. Actual generated files include
additional imports (`sys_module`, `ObjUtil`, pod namespace), a static `make()` factory
method, and type metadata registration at the end. See [Import Architecture](#import-architecture)
below for details on how imports are structured to avoid circular dependencies while
maintaining a clean API.

## Fields

All Fantom fields are generated with private storage using the `_fieldName` convention.
The compiler generates a combined getter/setter method using Python's optional parameter pattern.

Fantom:
```fantom
class Foo
{
  Int a := 0
  Int b := 1 { private set }
  private Int c := 2
}
```

Python:
```python
class Foo(Obj):
    def __init__(self):
        super().__init__()
        self._a = 0
        self._b = 1
        self._c = 2

    # Public getter/setter with type hints
    def a(self, _val_: 'int' = None) -> 'int':
        if _val_ is None:
            return self._a
        else:
            self._a = _val_

    # Public getter only
    def b(self) -> 'int':
        return self._b

    # No method for _c (private getter/setter)
```

Usage:
```python
f = Foo()
f.a(100)       # Set
print(f.a())   # Get: 100
```

Note: Unlike JavaScript's `#private` fields, Python uses the `_fieldName` convention by
agreement rather than enforcement.

## Static Fields

Static fields use class-level storage with static getter methods. Lazy initialization
follows the same pattern as JavaScript to handle circular dependencies.

Fantom:
```fantom
class Foo
{
  static const Int max := 100
}
```

Python:
```python
class Foo(Obj):
    _max = None

    @staticmethod
    def max():
        if Foo._max is None:
            Foo._static_init()
        return Foo._max

    @staticmethod
    def _static_init():
        if hasattr(Foo, '_static_init_in_progress') and Foo._static_init_in_progress:
            return
        Foo._static_init_in_progress = True
        Foo._max = 100
        Foo._static_init_in_progress = False
```

## Enums

Enums follow a factory pattern with lazy singleton initialization. Enum classes extend
`sys::Enum` (not `Obj` directly).

Fantom:
```fantom
enum class Color { red, green, blue }
```

Python:
```python
class Color(Enum):
    _vals = None

    @staticmethod
    def red():
        return Color.vals().get(0)

    @staticmethod
    def green():
        return Color.vals().get(1)

    @staticmethod
    def blue():
        return Color.vals().get(2)

    @staticmethod
    def vals():
        if Color._vals is None:
            # For non-sys pods, uses sys.List prefix
            Color._vals = sys.List.to_immutable(sys.List.from_list([
                Color._make_enum(0, "red"),
                Color._make_enum(1, "green"),
                Color._make_enum(2, "blue")
            ]))
        return Color._vals

    @staticmethod
    def _make_enum(_ordinal, _name):
        inst = object.__new__(Color)
        inst._ordinal = _ordinal
        inst._name = _name
        return inst

    def ordinal(self):
        return self._ordinal

    def name(self):
        return self._name
```

## Funcs and Closures

Fantom closures are generated as Python lambdas wrapped in `Func.make_closure()` to provide
Fantom's Func API (`bind()`, `params()`, `returns()`, etc.).

Fantom:
```fantom
list.each |item, i| { echo(item) }
```

Python:
```python
List.each(list, Func.make_closure({
    "returns": "sys::Void",
    "params": [{"name": "item", "type": "sys::Obj"}, {"name": "i", "type": "sys::Int"}]
}, (lambda item=None, i=None: print(item))))
```

For simple single-expression closures, the lambda is inlined. For multi-statement closures,
a named function is emitted before the usage point.

Unlike JavaScript where closures are invoked directly (`f(args)`), Python closures through
`Func.make_closure()` are also callable directly - the wrapper implements `__call__`.

### Closure Immutability

When a closure needs to be made immutable (typically for Actor message passing), the runtime
must create a "snapshot" of all captured values. This is handled by `Func.to_immutable()`.

The transpiler analyzes each closure and sets an `immutable` case in the closure spec:
- `"always"` - Closure captures only const types (already immutable)
- `"never"` - Closure captures non-const types like `InStream` (cannot be made immutable)
- `"maybe"` - Closure captures types that can be made immutable at runtime

For the `"maybe"` case, `to_immutable()` uses Python's `types.CellType` (Python 3.8+) to
create new closure cells with immutable copies of captured values:

```python
# Runtime code in Func.to_immutable()
import types

# Get the original function's closure cells
for i, cell in enumerate(original_func.__closure__):
    val = cell.cell_contents
    immutable_val = ObjUtil.to_immutable(val)  # Snapshot the value
    new_cell = types.CellType(immutable_val)   # Create new cell
    immutable_cells.append(new_cell)

# Create new function with new closure cells
new_func = types.FunctionType(
    original_func.__code__,
    original_func.__globals__,
    original_func.__name__,
    original_func.__defaults__,
    tuple(immutable_cells)  # Attach new cells!
)
```

This ensures that when a closure is sent to an Actor:
1. Each captured variable gets its own frozen copy
2. The original variables in the sending thread are unaffected
3. No race conditions can occur on shared mutable state

For closures using default parameter capture (`_outer=self` pattern), the same approach
rebinds the `__defaults__` tuple with immutable copies.

**Python version compatibility:** The `types.CellType` approach requires Python 3.8+. For
older Python versions or closures without `__closure__`, the runtime falls back to rebinding
`__defaults__` (for default parameter captures) or simply marking the closure as immutable
if it has no captures. See `Func.to_immutable()` in `src/sys/py/fan/Func.py` for the full
implementation.

## Primitives

Python's type system differs significantly from JavaScript's. Fantom primitives map as follows:

| Fantom | Python | Notes |
|--------|--------|-------|
| `Int` | `int` | Python int is arbitrary precision |
| `Float` | `float` | IEEE 754 double |
| `Bool` | `bool` | `True`/`False` |
| `Str` | `str` | Unicode string |
| `Decimal` | `float` | Uses Python float (not decimal.Decimal) |

Since Python primitives don't have methods, instance method calls on primitives are converted
to static method calls:

Fantom:
```fantom
x.toStr
s.size
```

Python:
```python
Int.to_str(x)
Str.size(s)
```

**Important:** `List` and `Map` are **NOT** primitives. They use normal instance method
dispatch like any other Fantom class. This matches the JavaScript transpiler's design.

The `ObjUtil` class provides dispatch for methods that may be called on any type (`equals`,
`compare`, `hash`, `typeof`, etc.).

## List and Map Architecture

**List** extends `Obj` and implements Python's `MutableSequence` ABC:
- Uses `self._values` for internal storage (not inheriting from Python list)
- All methods are instance methods: `list.each(f)`, `list.map_(f)`, etc.
- `isinstance(fantom_list, list)` returns `False`
- Supports Python protocols: `len()`, `[]`, `in`, iteration

**Map** extends `Obj` and implements Python's `MutableMapping` ABC:
- Uses `self._map` for internal storage (not inheriting from Python dict)
- All methods are instance methods: `map.get(k)`, `map.each(f)`, etc.
- `isinstance(fantom_map, dict)` returns `False`
- Supports Python protocols: `len()`, `[]`, `in`, iteration

Fantom:
```fantom
list.each |item| { echo(item) }
map.get("key")
```

Python:
```python
list.each(lambda item: print(item))
map.get("key")
```

## Import Architecture

Python's import system requires careful handling to avoid circular `ImportError` exceptions.
The transpiler uses a **hybrid approach** combining lazy loader modules, namespace imports,
and targeted direct imports.

### Pod-Level Lazy Loaders

Each pod gets a generated `__init__.py` that lazily imports types on first access:

```python
# fan/testSys/__init__.py (auto-generated)
import importlib

_cache = {}
_loading = set()  # Prevent circular import loops

_types = {
    'BoolTest': 'BoolTest',
    'IntTest': 'IntTest',
    # ... all types in pod
}

def __getattr__(name):
    """Module-level __getattr__ for lazy type loading (Python 3.7+)."""
    if name in _cache:
        return _cache[name]
    if name in _loading:
        return None  # Circular import protection

    _loading.add(name)
    try:
        module = importlib.import_module(f'fan.testSys.{name}')
        cls = getattr(module, name)
        _cache[name] = cls
        return cls
    finally:
        _loading.discard(name)
```

This allows code to reference types via `testSys.BoolTest` without importing all types
at module initialization time.

### Import Structure per File

Each generated Python file has this import structure:

```python
# 1. System path setup
import sys as sys_module
sys_module.path.insert(0, '.')

# 2. Type hints import
from typing import Optional, Callable, List as TypingList, Dict as TypingDict

# 3. Pod namespace import (for non-sys pods)
from fan import sys

# 4. Direct imports for class definition
from fan.sys.Obj import Obj              # Base class
from fan.sys.ObjUtil import ObjUtil      # Always needed
from fan.somePod.SomeMixin import SomeMixin  # Mixins

# 5. Dependent pods as namespaces
from fan import concurrent
from fan import haystack

# 6. Exception types for catch clauses (Python requires class in local scope)
from fan.myPod.MyException import MyException
```

### Namespace-Qualified Type References

In expressions, sys types are accessed via the `sys.` namespace prefix:

```python
# List literal
sys.List.from_literal([1, 2, 3], 'sys::Int')

# Map literal
sys.Map.from_literal(['a'], [1], 'sys::Str', 'sys::Int')

# Type literal
sys.Type.find('sys::Bool')

# Static method call
sys.Int.from_str("42")
```

The transpiler automatically adds `sys.` prefix when:
- The current type is NOT in the sys pod
- The target type IS in the sys pod

This eliminates the need for 30+ direct imports of sys types at the top of each file.

### Same-Pod Type References

For types in the same pod, dynamic imports avoid circular dependencies:

```python
# Direct reference would cause circular import:
# from fan.testSys.ObjWrapper import ObjWrapper  # BAD

# Dynamic import at point of use:
__import__('fan.testSys.ObjWrapper', fromlist=['ObjWrapper']).ObjWrapper
```

**Performance Note:** This pattern can result in millions of `__import__()` calls during
heavy operations like xeto namespace creation. See [__import__() Caching](#__import__-caching)
in Performance Optimizations for the runtime cache that makes this pattern efficient.

### Cross-Pod Type References

Cross-pod types use the namespace import pattern:

```python
# Pod imported as namespace at top of file
from fan import haystack

# Used in expressions
haystack.Coord.make(lat, lng)
```

### Exception Types in Catch Clauses

Python's `except` clause requires the exception class in local scope - namespace
references don't work:

```python
# This DOES NOT work in Python:
try:
    ...
except sys.ParseErr:  # SyntaxError: invalid syntax
    ...

# Must have direct import:
from fan.sys.ParseErr import ParseErr
try:
    ...
except ParseErr:  # Works
    ...
```

The transpiler scans for catch clauses and generates direct imports for any exception
types used. This is the one case where AST scanning is still required.

### Why This Design?

The import architecture balances several constraints:

1. **Avoid circular imports** - Lazy loaders and dynamic imports prevent initialization loops
2. **Minimize import lines** - Namespace imports instead of 30+ direct imports
3. **Python language requirements** - Exception classes must be in local scope
4. **Match JavaScript pattern** - Similar to JS pod bundling conceptually
5. **Support reflection** - Type metadata uses lazy string resolution

## Type Metadata (Reflection)

Each transpiled type registers metadata for Fantom's reflection system using `af_()` for
fields and `am_()` for methods. **Type signatures are stored as strings and lazily resolved
on first access** to avoid circular imports during module initialization:

```python
# Type metadata registration - note: type signatures are STRINGS
from fan.sys.Param import Param
_t = Type.find('testSys::Foo')
_t.af_('name', 1, 'sys::Str', {})  # 'sys::Str' is a string, not Type.find()
_t.am_('doSomething', 1, 'sys::Void', [Param('arg', 'sys::Int', False)], {})

# Type resolution happens lazily when reflection is used:
# - Method.returns() resolves the return type string on first call
# - Field.type() resolves the field type string on first call
# - Param.type() resolves the param type string on first call
```

### Why Lazy Resolution?

When Python imports a module, it executes all top-level code immediately. If `am_()` called
`Type.find()` during module initialization, it would trigger cascading imports:

```
Str.py loads -> am_() calls Type.find('sys::Int[]') -> Int.py loads ->
  am_() calls Type.find('sys::Float') -> Float.py loads ->
    am_() calls Type.find('sys::Decimal') -> ... circular crash
```

By storing type signatures as strings and resolving them lazily on first access, the module
initialization completes without triggering cross-type imports. This matches the JavaScript
transpiler's approach and is critical for the runtime to load without circular import errors.

## Generated Code Conventions

The transpiler generates several internal names and patterns. These are implementation
details but important for understanding generated code during debugging or review.

### Variable Naming Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| `_closure_N` | Multi-statement closure functions | `def _closure_0(x=None): ...` |
| `_switch_N` | Switch condition cache variable | `_switch_0 = condition` |
| `_safe_` | Safe navigation lambda parameter | `(lambda _safe_: ... if _safe_ is not None else None)(target)` |
| `_val_` | Field setter parameter | `def name(self, _val_=None):` |
| `_old_x` | Post-increment/decrement temp | `((_old_x := x, x := x + 1, _old_x)[2])` |
| `_self` | Outer self in multi-statement closures | `def _closure_0(..., _self=self):` |
| `_outer` | Outer self in inline lambdas | `lambda x, _outer=self: ...` |

### Sentinel Values

| Value | Purpose | Location |
|-------|---------|----------|
| `"_once_"` | Uninitialized once field marker | `_fieldName_Store = "_once_"` |

### Internal Methods

| Method | Purpose |
|--------|---------|
| `_static_init()` | Initialize static fields (lazy) |
| `_static_init_in_progress` | Re-entry guard for static init |
| `_ctor_init()` | Initialize instance fields (for named ctors) |
| `_make_enum(ordinal, name)` | Create enum instance |
| `_ctorName_body(...)` | Named constructor body |

### Why Closures Are Extracted

Python lambdas cannot contain statements - only single expressions. When a Fantom closure
contains multiple statements, local variable declarations, or control flow, the transpiler
extracts it to a named `def` function emitted before the usage point:

```python
# Multi-statement closure: |x| { y := x + 1; return y * 2 }
# Cannot be: lambda x: (y := x + 1, y * 2)  # Invalid - walrus in tuple doesn't work right

# Instead, extracted as:
def _closure_0(x=None, _self=self):
    y = x + 1
    return y * 2

# Used as:
list.map_(_closure_0)
```

The closure is emitted immediately before the statement that first uses it, ensuring
captured variables are in scope.

## ObjUtil Helper Methods

The transpiler generates calls to `ObjUtil` methods for operations that don't map directly
to Python syntax or require Fantom-specific semantics. These must be implemented in the
`sys` runtime (PR2).

### Comparison Methods

| Method | Purpose | Fantom | Generated Python |
|--------|---------|--------|------------------|
| `ObjUtil.equals(a, b)` | NaN-aware equality | `a == b` | `ObjUtil.equals(a, b)` |
| `ObjUtil.compare(a, b)` | Fantom comparison | `a <=> b` | `ObjUtil.compare(a, b)` |
| `ObjUtil.compare_lt(a, b)` | Less than | `a < b` | `ObjUtil.compare_lt(a, b)` |
| `ObjUtil.compare_le(a, b)` | Less or equal | `a <= b` | `ObjUtil.compare_le(a, b)` |
| `ObjUtil.compare_gt(a, b)` | Greater than | `a > b` | `ObjUtil.compare_gt(a, b)` |
| `ObjUtil.compare_ge(a, b)` | Greater or equal | `a >= b` | `ObjUtil.compare_ge(a, b)` |
| `ObjUtil.compare_ne(a, b)` | Not equal | `a != b` | `ObjUtil.compare_ne(a, b)` |
| `ObjUtil.same(a, b)` | Identity comparison | `a === b` | `ObjUtil.same(a, b)` |

**Why not Python operators?** Fantom's `==` uses `equals()` which handles NaN correctly
(NaN == NaN is true in Fantom). Python's `is` operator has interning issues with literals.

### Arithmetic Methods

| Method | Purpose | Why Needed |
|--------|---------|------------|
| `ObjUtil.div(a, b)` | Truncated integer division | Python `//` uses floor division (rounds toward -inf), Fantom uses truncated (toward zero) |
| `ObjUtil.mod(a, b)` | Truncated modulo | Same floor vs truncated difference |

Example: `-7 / 4` in Fantom = -1 (truncated), but `-7 // 4` in Python = -2 (floor).

### Type Methods

| Method | Purpose |
|--------|---------|
| `ObjUtil.typeof(obj)` | Get Fantom Type of any object |
| `ObjUtil.is_(obj, type)` | Fantom `is` type check |
| `ObjUtil.as_(obj, type)` | Fantom `as` safe cast |
| `ObjUtil.coerce(obj, type)` | Fantom type coercion |
| `ObjUtil.to_immutable(obj)` | Make object immutable |
| `ObjUtil.is_immutable(obj)` | Check if immutable |

### Expression Helpers

| Method | Purpose | Use Case |
|--------|---------|----------|
| `ObjUtil.setattr_return(obj, name, val)` | Assignment as expression | `return x = 5` -> `return ObjUtil.setattr_return(self, '_x', 5)` |
| `ObjUtil.throw_(err)` | Raise as expression | Used in lambdas: `lambda: ObjUtil.throw_(Err())` |
| `ObjUtil.trap(obj, name, args)` | Dynamic call | `obj->method(args)` -> `ObjUtil.trap(obj, 'method', [args])` |

### Increment/Decrement Helpers

| Method | Purpose |
|--------|---------|
| `ObjUtil.inc_field(obj, name)` | Pre-increment field: `++x` |
| `ObjUtil.inc_field_post(obj, name)` | Post-increment field: `x++` |
| `ObjUtil.dec_field(obj, name)` | Pre-decrement field: `--x` |
| `ObjUtil.dec_field_post(obj, name)` | Post-decrement field: `x--` |
| `ObjUtil.inc_index(container, key)` | Pre-increment index: `++list[i]` |
| `ObjUtil.inc_index_post(container, key)` | Post-increment index: `list[i]++` |
| `ObjUtil.dec_index(container, key)` | Pre-decrement index: `--list[i]` |
| `ObjUtil.dec_index_post(container, key)` | Post-decrement index: `list[i]--` |

### Closure Variable Wrapper

| Method | Purpose |
|--------|---------|
| `ObjUtil.cvar(val)` | Wrap closure-captured variable for mutation |

When a local variable is captured by a closure AND modified, the Fantom compiler generates
a wrapper class. The transpiler converts these to `ObjUtil.cvar()` calls which return a
mutable container object.

## Exception Mapping

Catch clauses map Fantom exceptions to Python native exceptions. When catching a Fantom
exception type, the transpiler also catches the corresponding Python native exception
to ensure interoperability.

| Fantom Exception | Python Native | Generated Catch |
|------------------|---------------|-----------------|
| `sys::Err` | `Exception` | `except Exception` |
| `sys::IndexErr` | `IndexError` | `except (IndexErr, IndexError)` |
| `sys::ArgErr` | `ValueError` | `except (ArgErr, ValueError)` |
| `sys::IOErr` | `IOError` | `except (IOErr, IOError)` |
| `sys::UnknownKeyErr` | `KeyError` | `except (UnknownKeyErr, KeyError)` |

### Exception Wrapping

When catching `sys::Err` (which catches all Python exceptions), the runtime wraps native
Python exceptions to ensure they have Fantom's `Err` API (`.trace()`, `.msg()`, etc.):

```python
try:
    some_code()
except Exception as err:
    err = sys.Err.wrap(err)  # Ensures .trace() method exists
    # ... handle err
```

### Exceptions Not Yet Mapped

The following Fantom exceptions don't have Python native equivalents and are caught
directly:

- `sys::ParseErr` - No direct Python equivalent
- `sys::CastErr` - Could map to `TypeError` but semantics differ
- `sys::NullErr` - Could map to `TypeError` for None access
- `sys::NotImmutableErr` - Fantom-specific
- `sys::ReadonlyErr` - Fantom-specific
- `sys::UnsupportedErr` - Could map to `NotImplementedError`

# Naming

All class names are preserved when going from Fantom to Python.

## Snake_Case Conversion

Method and field names are converted from camelCase to snake_case for a Pythonic API:

| Fantom | Python |
|--------|--------|
| `toStr` | `to_str` |
| `fromStr` | `from_str` |
| `isEmpty` | `is_empty` |
| `findAll` | `find_all` |
| `containsKey` | `contains_key` |
| `XMLParser` | `xml_parser` |
| `utf16BE` | `utf16_be` |

The conversion is handled by `PyUtil.toSnakeCase()` and applied through `escapeName()`.

## Reserved Word Escaping

Names that conflict with Python keywords or builtins get a trailing underscore `_`:

**Keywords:** `class`, `def`, `return`, `if`, `else`, `for`, `while`, `import`, `from`,
`is`, `in`, `not`, `and`, `or`, `True`, `False`, `None`, `lambda`, `global`, `nonlocal`,
`pass`, `break`, `continue`, `raise`, `try`, `except`, `finally`, `with`, `as`, `assert`,
`yield`, `del`, `elif`, `match`, `case`

**Builtins:** `type`, `hash`, `id`, `list`, `map`, `str`, `int`, `float`, `bool`, `abs`,
`all`, `any`, `min`, `max`, `pow`, `round`, `set`, `dir`, `oct`, `open`, `vars`, `print`

```
# Fantom
Void class(Str is) { ... }
Int hash() { ... }
Bool any(|V| f) { ... }

# Python
def class_(self, is_):
    ...
def hash_(self):
    ...
def any_(self, f):
    ...
```

Internal methods and fields used for compiler support use double-underscore prefix patterns
like `_static_init`, `_ctor_init`, etc. These should be considered private implementation
details.

# Python-Specific Considerations

## The GIL

Python's Global Interpreter Lock (GIL) means true parallelism isn't possible with threads.
The `concurrent` pod's Actor model implementation uses Python's `concurrent.futures` but
won't achieve the same parallelism as JVM or JavaScript runtimes.

**Free-Threaded Python (3.13+):** Starting with Python 3.13 (PEP 703), CPython offers an
experimental free-threaded build that disables the GIL entirely. This can be enabled at
runtime with `python3 -X gil=0` or by setting the `PYTHON_GIL=0` environment variable.
The `concurrent` pod's implementation already uses proper threading primitives
(`threading.Lock`, `threading.RLock`, `concurrent.futures.ThreadPoolExecutor`) throughout
Actor, ActorPool, ConcurrentMap, and the Atomic types, so **no code changes are required**
to benefit from true parallelism under the free-threaded build. CPU-bound actor message
processing will achieve real multi-core parallelism when the GIL is disabled. Note that
some third-party C extensions may not yet be compatible with free-threaded mode, so users
should verify their full dependency chain before enabling it in production.

## No Method Overloading

Python doesn't support method overloading by signature. Fantom constructors with different
signatures are handled via factory methods (`make`, `make1`, etc.) that all delegate to a
single `__init__`.

## Type Hints

The transpiler generates Python type hints for all public APIs:

```python
def from_str(s: 'str', checked: 'bool' = None) -> 'Optional[Number]':
    ...

def unit(self, _val_: 'Optional[Unit]' = None) -> 'Optional[Unit]':
    ...

def to_float(self) -> 'float':
    ...
```

Type mapping:
| Fantom | Python Type Hint |
|--------|------------------|
| `Bool` | `'bool'` |
| `Int` | `'int'` |
| `Float` | `'float'` |
| `Str` | `'str'` |
| `Void` | `None` |
| `Type?` | `'Optional[Type]'` |
| `Str[]` | `'List[str]'` |
| `[Str:Int]` | `'Dict[str, int]'` |
| `|Int->Bool|` | `'Callable[[int], bool]'` |

All type hints use forward references (strings) to avoid import order issues. Required
imports are added to each generated file:

```python
from typing import Optional, Callable, List as TypingList, Dict as TypingDict
```

**Note:** Runtime type checks still use `ObjUtil.is_()` and `ObjUtil.as_()` - type hints
are for IDE autocomplete and static analysis, not runtime enforcement.

## None vs null

Fantom's `null` maps directly to Python's `None`. Nullable types (`Str?`) don't have special
representation - any variable can hold `None`.

# Performance Optimizations

Unlike JavaScript where the V8 JIT compiler handles most performance concerns, Python's
interpreted nature requires explicit runtime optimizations. These were identified through
profiling (`cProfile`) of the test suites and xeto namespace creation.

The optimizations follow a consistent pattern: identify hot paths through profiling,
cache computed results keyed by immutable signatures, and trade small amounts of
persistent memory (~100KB total) for significant CPU savings.

## Type.find() Cache-First Pattern

`Type.find()` is called millions of times during test execution (19M+ calls in testXeto).
The optimization ensures cache hits are as fast as possible:

```python
@staticmethod
def find(qname, checked=True):
    # CRITICAL: Check cache FIRST before any imports
    # This saves ~0.6us per call (8.3x faster than doing import first)
    cached = Type._cache.get(qname)
    if cached is not None:
        return cached

    # Imports only needed for cache misses and error handling
    from .Err import ArgErr, UnknownTypeErr, UnknownPodErr
    # ... rest of lookup logic
```

**Why this matters:** Python's `from .Err import ...` statement has ~0.6us overhead per call,
even when the modules are already in `sys.modules`. Moving the cache check before imports
reduces cache hit time from 0.66us to 0.12us (5.4x faster).

**Memory impact:** Zero - just reordered existing code.

## Func.make_closure() Param Caching

Closures are created millions of times per test run (4.2M+ in testXeto). Each closure
specification includes parameter metadata that previously created new `Param` objects
every time:

```python
# Module-level cache
_param_cache = {}  # (name, type_sig) -> Param

@staticmethod
def make_closure(spec, func):
    # ... parse spec ...
    for p in spec.get('params', []):
        name = p['name']
        type_sig = p['type']
        cache_key = (name, type_sig)

        # Check cache first
        cached = Func._param_cache.get(cache_key)
        if cached is not None:
            params.append(cached)
            continue

        # Create and cache on miss
        param = Param(name, Type.find(type_sig), False)
        Func._param_cache[cache_key] = param
        params.append(param)
```

**Why this matters:** Closures with the same parameter signature (e.g., `|Int->Bool|`)
share cached `Param` objects instead of creating 4.2M short-lived objects.

**Memory impact:** ~50-100 KB (100-200 unique signatures × ~500 bytes/entry).
Actually reduces GC pressure by avoiding millions of allocations/deallocations.

## __import__() Caching

The transpiler generates `__import__('fan.pod.Type', fromlist=['Type']).Type` for same-pod
type references to avoid circular imports (see [Import Architecture](#import-architecture)).
During heavy operations like xeto namespace creation, this results in 3.6 million
`__import__()` calls.

**Implementation:** `src/sys/py/fan/__init__.py`

The optimization intercepts `__import__()` for `fan.*` modules:

```python
# Pseudocode - see __init__.py for full implementation
cache_key = (module_name, tuple(fromlist))
if cache_key in _fan_import_cache:
    return _fan_import_cache[cache_key]
result = original_import(...)
_fan_import_cache[cache_key] = result
return result
```

**Why this matters:** Python's `__import__()` has overhead even for cached modules.
Caching the fully-resolved result (module + fromlist attribute) eliminates repeated
lookups. Xeto namespace creation drops from ~25s to ~6s (75% faster).

**Memory impact:** ~10KB (245 unique module/fromlist combinations).

**Design notes:**
- Cache stored in `builtins` to survive module reloading during test runs
- Only caches `fan.*` modules with explicit `fromlist` (transpiler pattern)
- Triggered early via `import fan.sys` in `haystack/__init__.py`

## Performance Results

These optimizations together deliver 28-32% speedup on testXeto:

| Test Suite | Before | After | Improvement |
|------------|--------|-------|-------------|
| testXeto::AxonTest | 83.5s | 59.7s | 28% faster |
| testXeto::ValidateTest | 45.8s | 31.3s | 32% faster |

Xeto namespace creation specifically:

| Operation | Before | After | Improvement |
|-----------|--------|-------|-------------|
| create_namespace(['sys','ph']) | ~25s | ~6s | 75% faster |

**Design principles:**
1. Optimize the hottest paths first (Type.find, closure creation, __import__)
2. Cache objects keyed by immutable signatures, not call count
3. Trade ~100KB memory for avoiding millions of allocations
4. Keep caches bounded by unique signatures in codebase
