This is a "living" document covering many aspects of the design and implementation
for the mapping from Fantom to ES6 JavaScript.

# Getting Started
So you just cloned this repo. This section provides an overview of the code
organization and the commands you need to run to get started with the JavaScript.
As you read through this document keep in mind that both the "old" way of generating
JS and the new way will co-exist side-by-side for a transition period.

The ES6 implementation of the `sys` pod is in `src/sys/es/`.  The build script in
that directory takes care of packaging all the sys code into a single ESM module
and putting it in `sys.pod`. All ESM modules are stored in pods in the `/esm/` directory.
For `sys` only do we also generate a CommonJS (CJS) implementation as well. It is stored
in the `/cjs/` directory of the `sys.pod`.

## CompilerES

There is a new JavaScript compiler for generating ES code. The pod is called `compilerEs`.
It serves the same purpose as the old `compilerJs` pod, but emits ES6 code and a 
corresponding source map. Currently, the compiler only emits an ESM module for the code.
All generated artifacts are stored in the pod at `/esm/`.

## Standard Build

To build the code run `fan src\buildall.pod`. Remember that we will generate both the old and new JS code
during this transition period. 

You could now run the `testDomkit` pod to see the various domkit widgets renedered in the
browser using the ES6 code:

`fan testDomkit -es`

## compilerEs::NodeRunner

NOTE: this class will eventually be moving to the `nodeJs` pod.

You can use the `compilerEs::NodeRunner` class to run the JS code in the NodeJS environment.
You must have NodeJS installed on your system and available in your PATH.

To run a test suite you would execute:

```
fan copmilerEs::NodeRunner -test <pod>[::<test>[.<method>]]

// Examples
fan compilerEs::NodeRunner -test concurrent
fan compilerEs::NodeRunner -test testSys::UriTest
```

## Node Packaging

You can stage all the ES javascript into the filesystem for running in Node by using the `NodeRunner`.
The full set of steps to accomplish this is

1. `fan src/buildall.fan`
2. `fan compilerEs::NodeRunner -init` This will create the initial node package in `<fan_home>/lib/es/`
and stage the `sys.js` code.
3. `fan src/buildpods.fan js` Run only on the non-bootstrap pods to generate JS code for *all* types
in a pod. It then stages the js and a typescript declaration file (`d.ts`) to the node package
in `<fan_home>/lib/es/`

# Porting Native Code
If you have a pod with native javascript then these are the steps you should take to port your
code.

1. Create a `/es/` directory in the root of your pod (it should be a peer to your existing `/js/`
directory)
1. Port all your native code into this directory. Follow the guideliness in the following
sections for more details on some of the specific implementation patterns you must follow.
This won't be exhaustive in the short-term so you should use the existing code in `sys` or
some of the other core pods (e.g. `concurrent` as a pattern/example)

# Design
This section details some of the design decisions and implementation details for the ES code.

## ES6 Classes

All Fantom types are implemented as ES6 classes.  

Fantom
```fantom
class Foo { }
```
ES6
```javascript
class Foo extends sys.Obj {
  constructor() { super(); }
}
```
Note that in all pods (excluding sys), the compiler will auto-generate `import` statements for all
your pod dependenices using this pattern:
```javascript
import * as <podName> from './<podName>.js';
```
You can then refer to types from another pod in your code as `<podName>.<type>`. Notice
in the example above that the `Foo` class extends `sys.Obj`.

## Fields
All Fantom fields are generated as private in the JavaScript and the compiler will generate a single 
method for getting/setting the field based on the access flags for the getter/setter in Fantom. The 
generated getter/setter will conform to the [Naming](#naming) rules outlined later.

Note that an implication of this design is that *all* fields in Fantom are only accessible
in JavaScript as methods. You never access a javascript field's storage directly.

Fantom
```fantom
class Foo
{
  Int a := 0
  Int b := 1 { private set }
  private Int c := 2
}
```
JavaScript
```javascript
class Foo extends sys.Obj {
  constructor() { 
    super();
    this.#a = 0;
    this.#b = 1;
    this.#c = 2;
  }
  
  #a = 0;
  
  // has public getter/setter
  a(it=undefined) {
    if (it===undefined) return this.#a;
    else this.#a = it;
  }
  
  #b = 0;
  
  // has only public getter
  b() { return this.#b; }
  
  #c = 0;
  // no method generated for #c since it has private getter/setter
}

let f = new Foo();
f.a(100);
console.log(`The value of a is now ${f.a()}`);
```

### Enums

This field design has some specific implications for Enums. All static enum fields are generated
as methods also. See the [fan::Weekday](/src/sys/es/Weekday.js) implementation as an example.
In general, you don't need to be concerend with the implementation details but any native
code that wants to work with Enums needs to understand these conventions.

```javascript
const monday = sys.Weekday.mon()
```

## Funcs and Closures
All Fantom code that expects a closure or Func will be generated to expect a native JavaScript
closure.

For example, the `sys::List.each` method is defined in `List.fan` as
```fantom
  Void each(|V item, Int index| c)
```
and implemented in `List.js` as
```javascript
  each(f) {
    for (let i=0; i<this.#size; ++i)
      f(this.#values[i], i);
  }
```
Notice that the `f` parameter is assumed to be a native javascript function and is invoked
directly (whereas in the old code it would have been `f.call(...)`).

# Naming

All class names are preserved when going from Fantom to JavaScript.

Slot and Parameter names that conflict with built-in JS keywords are "pickled" to end with a `$`. The
list of names that gets pickled can be found in [compilerEs::JsNode](/src/compilerEs/fan/ast/JsNode.fan).

```
# Fantom
Void name(Str var) { ... }

# JavaScript
name$(var$) { ... }
```

As a general rule, any field or method that ends with `$` should be considered "public" API when 
using the JS code natively in an environment like Node or the browser. There are several "internal"
methods and fields that are intended for compiler support and they will be prefixed with two underbars
`__`. They should not be used by consumers of the generated JS code and are subject to change at any time.

```
# JavaScript - these should be considered private
static __registry = {};

__at(a,b,c) { ... }
```

***TODO: We are still in the process of porting all the sys code to use the `__` rule. You may see some
inconsistencies here in the short-term.***




