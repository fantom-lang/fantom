//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Sep 06  Brian Frank  Creation
//

**
** CheckErrorsTest
**
class CheckErrorsTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  Void testTypeFlags()
  {
    // parser stage
    verifyErrors(
     "abstract mixin A {}
      final mixin B {}
      abstract enum C { none }
      const final enum D { none }
      public public class E {}
      abstract internal abstract class F {}
      const mixin G {}
      ",
       [
         1,  10, "The 'abstract' modifier is implied on mixin",
         2,   7, "Cannot use 'final' modifier on mixin",
         3,  10, "Cannot use 'abstract' modifier on enum",
         4,  13, "The 'const' modifier is implied on enum",
         4,  13, "The 'final' modifier is implied on enum",
         5,   8, "Repeated modifier",
         6,  19, "Repeated modifier",
         7,   7, "Cannot use 'const' modifier on mixin",
       ])

    // check errors stage
    verifyErrors(
     "new class A {}
      private class B {}
      protected class C {}
      virtual static class D {}
      native class E {}
      readonly class F {}
      once class G {}
      public internal class H {}
      abstract final class I {}
      ",
       [
         1,  5, "Cannot use 'new' modifier on type",
         2,  9, "Cannot use 'private' modifier on type",
         3, 11, "Cannot use 'protected' modifier on type",
         4, 16, "Cannot use 'static' modifier on type",
         4, 16, "Cannot use 'virtual' modifier on type",
         5,  8, "Cannot use 'native' modifier on type",
         6, 10, "Cannot use 'readonly' modifier on type",
         7,  6, "Cannot use 'once' modifier on type",
         8, 17, "Invalid combination of 'public' and 'internal' modifiers",
         9, 16, "Invalid combination of 'abstract' and 'final' modifiers",
       ])
  }

  Void testTypeAbstractSlots()
  {
    // errors
    verifyErrors(
     "class A { abstract Void x()  }
      class B { abstract Void x(); abstract Void y(); }
      class C : B {}
      class D : A { abstract Void y(); }
      class E : B, X { override Void a() {} override Void x() {} }
      mixin X { abstract Void a(); abstract Void b(); }
      ",
       [
         1,  1, "Class 'A' must be abstract since it contains abstract slots",
         2,  1, "Class 'B' must be abstract since it contains abstract slots",
         3,  1, "Class 'C' must be abstract since it inherits but doesn't override '$podName::B.x'",
         3,  1, "Class 'C' must be abstract since it inherits but doesn't override '$podName::B.y'",
         4,  1, "Class 'D' must be abstract since it inherits but doesn't override '$podName::A.x'",
         4,  1, "Class 'D' must be abstract since it contains abstract slots",
         5,  1, "Class 'E' must be abstract since it inherits but doesn't override '$podName::X.b'",
         5,  1, "Class 'E' must be abstract since it inherits but doesn't override '$podName::B.y'",
       ])
  }

  Void testTypeMisc()
  {
    // check inherit stage
    verifyErrors(
     "class A { Type type }
      class B { Type type() { return Str# } }
      ",
       [
         1, 11, "Must specify override keyword to override 'sys::Obj.type'",
         2, 11, "Must specify override keyword to override 'sys::Obj.type'",
       ])

    // check errors stage
    verifyErrors(
     "class A { override Type type }
      class B { override Type type() { return Str# } }
      ",
       [
         1, 11, "Cannot override Obj.type()",
         2, 11, "Cannot override Obj.type()",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Test protection scopes
//////////////////////////////////////////////////////////////////////////

  Void testProtectionScopes()
  {
    // first create a pod with internal types/slots
    compile(
     "class Public
      {
        virtual public    Void mPublic()    {}
        virtual protected Void mProtected() {}
        virtual internal  Void mInternal()  {}
                private   Void mPrivate()   {} // can't mix virtual+private

        static public    Void msPublic()    {}
        static protected Void msProtected() {}
        static internal  Void msInternal()  {}
        static private   Void msPrivate()   {}

        virtual public    Int fPublic
        virtual protected Int fProtected
        virtual internal  Int fInternal
                private   Int fPrivate   // can't mix virtual+private

        public            Int fPublicProtected { protected set }
        readonly public   Int fPublicReadonly
        protected         Int fProtectedInternal { internal set }
      }

      internal class InternalClass
      {
        Void m() {}
      }

      internal mixin InternalMixin
      {
      }
      ")

    p := pod.types[0]
    ic := pod.types[1]
    im := pod.types[2]

    // CheckInherit step
    verifyErrors(
     "using $p.pod.name

      class C00 : Public {}
      class C01 : InternalClass {}
      class C02 : InternalMixin {}
      mixin C03 : InternalMixin {}
      ",
    [
      4, 1, "Class 'C01' cannot access internal scoped class '$ic'",
      5, 1, "Type 'C02' cannot access internal scoped mixin '$im'",
      6, 1, "Type 'C03' cannot access internal scoped mixin '$im'",
    ])

    // Inherit step
    verifyErrors(
     "using $p.pod.name

      class C01 : Public { override Void figgle() {} }
      class C02 : Public { Str toStr() { return null } }
      class C03 : Public { override Void mPublic() {} }    // ok
      class C04 : Public { override Void mProtected() {} } // ok

      class C05 : Public { override Void mInternal() {} }
      class C06 : Public { override Void mPrivate() {} }
      ",
    [
      3, 22, "Override of unknown virtual slot 'figgle'",
      4, 22, "Must specify override keyword to override 'sys::Obj.toStr'",

      // TODO: internal/privates never make it this far to tell you its a scope problem...
      8, 22, "Override of unknown virtual slot 'mInternal'",
      9, 22, "Override of unknown virtual slot 'mPrivate'",
    ])

    // CheckErrors step
    verifyErrors(
     "using $p.pod.name

      class C04 : Public { Void f() { mPublic; x := fPublic } } // ok
      class C05 : Public { Void f() { mProtected; x := fProtected } } // ok
      class C06 { Void f(Public p) { p.mProtected  } }
      class C07 { Void f(Public p) { p.mInternal  } }
      class C08 { Void f(Public p) { p.mPrivate  } }
      class C09 { Void f() { Public.msProtected  } }
      class C10 { Void f() { Public.msInternal  } }
      class C11 { Void f() { Public.msPrivate  } }

      class C13 { Obj f(Public p) { return p.fPublic } } // ok
      class C14 : Public { Obj f(Public p) { return p.fProtected} } // ok
      class C15 { Obj f(Public p) { return p.fPublicProtected } } // ok
      class C16 { Obj f(Public p) { return p.fPublicReadonly } } // ok
      class C17 : Public { Obj f(Public p) { return p.fProtectedInternal } } // ok

      class C19 { Obj f(Public p) { return p.fProtected } }
      class C20 { Obj f(Public p) { return p.fProtectedInternal } }
      class C21 { Obj f(Public p) { return p.fInternal } }
      class C22 { Obj f(Public p) { return p.fPrivate } }

      class C24 { Void f(Public p) { p.fPublic = 7 } }  // ok
      class C25 : Public { Void f(Public p) { p.fProtected = 7 } } // ok
      class C26 : Public { Void f(Public p) { p.fPublicProtected = 7 } } // ok
      class C27 { Void f(Public p) { p.fProtected = 7 } }
      class C28 { Void f(Public p) { p.fInternal = 7 } }
      class C29 { Void f(Public p) { p.fPrivate = 7 } }
      class C30 { Void f(Public p) { p.fPublicProtected = 7; p.fPublicProtected++ } }
      class C31 { Void f(Public p) { p.fPublicReadonly = 7; p.fPublicReadonly++ } }
      class C32 : Public { Void f(Public p) { p.fProtectedInternal = 7; p.fProtectedInternal++ } }
      ",
    [
      5, 34, "Protected method '${p}.mProtected' not accessible",
      6, 34, "Internal method '${p}.mInternal' not accessible",
      7, 34, "Private method '${p}.mPrivate' not accessible",
      8, 31, "Protected method '${p}.msProtected' not accessible",
      9, 31, "Internal method '${p}.msInternal' not accessible",
     10, 31, "Private method '${p}.msPrivate' not accessible",

     18, 40, "Protected field '${p}.fProtected' not accessible",
     19, 40, "Protected field '${p}.fProtectedInternal' not accessible",
     20, 40, "Internal field '${p}.fInternal' not accessible",
     21, 40, "Private field '${p}.fPrivate' not accessible",

     26, 34, "Protected field '${p}.fProtected' not accessible",
     27, 34, "Internal field '${p}.fInternal' not accessible",
     28, 34, "Private field '${p}.fPrivate' not accessible",
     29, 34, "Protected setter of field '${p}.fPublicProtected' not accessible",
     29, 58, "Protected setter of field '${p}.fPublicProtected' not accessible",
     30, 34, "Private setter of field '${p}.fPublicReadonly' not accessible",
     30, 57, "Private setter of field '${p}.fPublicReadonly' not accessible",
     31, 43, "Internal setter of field '${p}.fProtectedInternal' not accessible",
     31, 69, "Internal setter of field '${p}.fProtectedInternal' not accessible",
    ])
  }

  Void testClosureProtectionScopes()
  {
    // verify closure get access to external class privates
    compile(
     "class Foo : Goo
      {
        private static Int x() { return 'x' }
        static Int testX()
        {
          f := |->Int| { return x }
          return f.call0
        }

        protected static Int y() { return 'y' }
        static Int testY()
        {
          f := |->Int|
          {
            g := |->Int| { return y  }
            return g.call0
          }
          return f.call0
        }

        static Int testZ()
        {
          f := |->Int| { return z }
          return f.call0
        }
      }

      class Goo
      {
        protected static Int z() { return 'z' }
      }")

     t := pod.types[1]
     verifyEq(t.name, "Foo")
     verifyEq(t.method("testX").call0, 'x')
     verifyEq(t.method("testY").call0, 'y')
     verifyEq(t.method("testZ").call0, 'z')
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Void testFieldFlags()
  {
    // parser stage
    verifyErrors(
     "abstract class Foo
      {
        readonly readonly Str f01
        Str f02 { override get { return f02 } }
        Str f03 { internal override get { return f03 } }
        Str f04 { override set {} }
      }
      ",
       [
         3,  12, "Repeated modifier",
         4,  13, "Cannot use modifiers on field getter",
         5,  13, "Cannot use modifiers on field getter",
         6,  13, "Cannot use modifiers on field setter except to narrow protection",
       ])

    // check errors stage
    verifyErrors(
     "abstract class Foo : Bar
      {
        // new Str f00 - parser actually catches this
        final Str f01
        native Str f02 // ok
        once Str f03

        public protected Str f04
        public private Str f05
        public internal Str f06
        protected private Str f07
        protected internal Str f08
        internal private Str f09

        Str f10 { public protected set {} }
        Str f11 { public private  set {} }
        Str f12 { public internal  set {} }
        Str f13 { protected private  set {} }
        Str f14 { protected internal  set {} }
        Str f15 { internal private  set {} }

        private Str f20 { public set {} }
        private Str f21 { protected set {} }
        private Str f22 { internal set {} }
        internal Str f23 { public set {} }
        internal Str f24 { protected set {} }
        protected Str f25 { public set {} }
        protected Str f26 { internal set {} } // ok

        const abstract Str f30
        //const override Str f31 TODO
        const virtual  Str f32

        virtual private Str f33

        native abstract Str f35
        const native Str f36
        native static Str f37
      }

      class Bar
      {
        virtual Str f31
      }
      ",
       [
         4,  3, "Cannot use 'final' modifier on field",
         6,  3, "Cannot use 'once' modifier on field",

         8,  3, "Invalid combination of 'public' and 'protected' modifiers",
         9,  3, "Invalid combination of 'public' and 'private' modifiers",
        10,  3, "Invalid combination of 'public' and 'internal' modifiers",
        11,  3, "Invalid combination of 'protected' and 'private' modifiers",
        12,  3, "Invalid combination of 'protected' and 'internal' modifiers",
        13,  3, "Invalid combination of 'private' and 'internal' modifiers",

        15,  3, "Invalid combination of 'public' and 'protected' modifiers",
        16,  3, "Invalid combination of 'public' and 'private' modifiers",
        17,  3, "Invalid combination of 'public' and 'internal' modifiers",
        18,  3, "Invalid combination of 'protected' and 'private' modifiers",
        19,  3, "Invalid combination of 'protected' and 'internal' modifiers",
        20,  3, "Invalid combination of 'private' and 'internal' modifiers",

        22,  3, "Setter cannot have wider visibility than the field",
        23,  3, "Setter cannot have wider visibility than the field",
        24,  3, "Setter cannot have wider visibility than the field",
        25,  3, "Setter cannot have wider visibility than the field",
        26,  3, "Setter cannot have wider visibility than the field",
        27,  3, "Setter cannot have wider visibility than the field",

        30,  3, "Invalid combination of 'const' and 'abstract' modifiers",
        //30,  3, "Invalid combination of 'const' and 'override' modifiers", TODO
        32,  3, "Invalid combination of 'const' and 'virtual' modifiers",

        34,  3, "Invalid combination of 'private' and 'virtual' modifiers",

        36,  3, "Invalid combination of 'native' and 'abstract' modifiers",
        37,  3, "Invalid combination of 'native' and 'const' modifiers",
        38,  3, "Invalid combination of 'native' and 'static' modifiers",
        38,  3, "Static field 'f37' must be const",
       ])
  }

  Void testFields()
  {
    verifyErrors(
     "mixin MixIt
      {
        Str a
        virtual Int b
        abstract Int c { get { return @c } }
        abstract Int d { set { @d = val } }
        abstract Int e { get { return @e } set { @e = val } }
        const Int f := 3
        abstract Int g := 5
      }

      abstract class Foo
      {
        abstract Int c { get { return @c } }
        abstract Int d { set { @d = val } }
        abstract Int e { get { return @e } set { @e = val } }
        abstract Int f := 3
      }
      ",
       [
         3,  3, "Mixin field 'a' must be abstract",
         4,  3, "Mixin field 'b' must be abstract",
         5,  3, "Abstract field 'c' cannot have getter or setter",
         6,  3, "Abstract field 'd' cannot have getter or setter",
         7,  3, "Abstract field 'e' cannot have getter or setter",
         8,  3, "Mixin field 'f' must be abstract",
         9, 21, "Abstract field 'g' cannot have initializer",

        14,  3, "Abstract field 'c' cannot have getter or setter",
        15,  3, "Abstract field 'd' cannot have getter or setter",
        16,  3, "Abstract field 'e' cannot have getter or setter",
        17, 21, "Abstract field 'f' cannot have initializer",
       ])
  }

  Void testConst()
  {
    // Parser step
    verifyErrors(
     "const class Foo
      {
        const static Int a { get { return 3 } }
        const static Int b { set {  } }
        const static Int c { get { return 3 } set { } }

        const Int d { get { return 3 } }
        const Int e { set {  } }
        const Int f { get { return 3 } set { } }
      }
      ",
       [
         3, 24, "Const field 'a' cannot have getter",
         4, 24, "Const field 'b' cannot have setter",
         5, 24, "Const field 'c' cannot have getter",
         5, 41, "Const field 'c' cannot have setter",

         7, 17, "Const field 'd' cannot have getter",
         8, 17, "Const field 'e' cannot have setter",
         9, 17, "Const field 'f' cannot have getter",
         9, 34, "Const field 'f' cannot have setter",
       ])

    // CheckErrors step
    verifyErrors(
     "const class Foo : Bar
      {
        static Int a := 3

        const static Int b := 3
        static { b = 5 }
        static Void goop() { b = 7; b += 3; b++ }

        //const static Int c { get { return 3 } }
        //const static Int d { set {  } }
        //const static Int e { get { return 3 } set { } }

        const Int f := 3
        new make() { f = 5 }
        Void wow() { f = 7; f++; }
        static Void bow(Foo o) { o.f = 9; o.f += 2 }

        //const Int g { get { return 3 } }
        //const Int h { set {  } }
        //const Int i { get { return 3 } set { } }

        private Str j
        private const StrBuf k
        const Buf[] l
        const Str:Buf m
        const Buf:Int n
        const Num:Duration ok1
        const Num:Str[][] ok2

        once Int p() { return 3 }
      }

      class Bar {}
      class Roo : Foo {}
      enum Boo { none;  private Int x }

      const class Outside : Foo
      {
        new make() { f = 99 }
        static { b++ }
      }

      class With
      {
        static Foo fooFactory() { return Foo.make }
        static With withFactory() { return make }
        Obj a() { return Foo { f = 99 } }       // ok
        Obj b() { return Foo.make { f = 99 } }  // ok
        Obj c() { return With { xxx = [1,2] } }  // ok
        Obj d() { return make { xxx = [1,2] } }  // ok
        Obj e() { return fooFactory { f = 99 } }
        Obj f() { return withFactory { xxx = [1,2] } }
        Obj g() { return make { xxx = [1,2] } }
        Obj h(With s) { return s { xxx = [1,2] } }
        Obj i() { return this { xxx = [1,2] } }
        Obj j() { return make { goop = 99 } }
        static { Foo.b = 999 }

        const Int[] xxx
        static const Int goop := 9
      }

      const abstract class Ok
      {
        abstract Int a
        native Str b
        Int c { get { return 3 } set {} }
        static const Obj d
        static const Obj[] e
        static const Obj:Obj f
      }
      ",
       [
         3,  3, "Static field 'a' must be const",

         7, 24, "Cannot set const static field 'b' outside of static initializer",
         7, 31, "Cannot set const static field 'b' outside of static initializer",
         7, 39, "Cannot set const static field 'b' outside of static initializer",

        15, 16, "Cannot set const field 'f' outside of constructor",
        15, 23, "Cannot set const field 'f' outside of constructor",
        16, 30, "Cannot set const field 'f' outside of constructor",
        16, 39, "Cannot set const field 'f' outside of constructor",

        23,  3, "Const field 'k' has non-const type 'sys::StrBuf'",
        24,  3, "Const field 'l' has non-const type 'sys::Buf[]'",
        25,  3, "Const field 'm' has non-const type '[sys::Str:sys::Buf]'",
        26,  3, "Const field 'n' has non-const type '[sys::Buf:sys::Int]'",

         1,  7, "Const class 'Foo' cannot subclass non-const class '$podName::Bar'",
        22,  3, "Const class 'Foo' cannot contain non-const field 'j'",
        30,  3, "Const class 'Foo' cannot contain once method 'p'",

        34,  1, "Non-const class 'Roo' cannot subclass const class '$podName::Foo'",
        35, 19, "Const class 'Boo' cannot contain non-const field 'x'",

        39, 16, "Cannot set const field '$podName::Foo.f'",
        40, 12, "Cannot set const field '$podName::Foo.b'",

        51, 33, "Cannot set const field '$podName::Foo.f'",
        52, 34, "Cannot set const field 'xxx' outside of constructor",
        54, 30, "Cannot set const field 'xxx' outside of constructor",
        55, 27, "Cannot set const field 'xxx' outside of constructor",
        56, 27, "Cannot access static field 'goop' on instance",
        56, 27, "Cannot set const static field 'goop' outside of static initializer",
        57, 16, "Cannot set const field '$podName::Foo.b'",
       ])
  }

  Void testFieldStorage()
  {
    verifyErrors(
     "class Foo : Root
      {
        Int m00() { return @r00 }
        Int m01() { return this.@r00 }

        Int f00 { get { return f00 } }
        Int f01 { set { f01 = val } }
        Int f02 { get { return f02 } set { f02 = val } }

        override Int r01 { set { @r01 = val } }
      }

      class Root
      {
        Int r00
        virtual Int r01
      }
      ",
       [
         3, 22, "Field storage for '$podName::Root.r00' not accessible",
         4, 27, "Field storage for '$podName::Root.r00' not accessible",

         6, 26, "Cannot use field accessor inside accessor itself - use '@' operator",
         7, 19, "Cannot use field accessor inside accessor itself - use '@' operator",
         8, 26, "Cannot use field accessor inside accessor itself - use '@' operator",
         8, 38, "Cannot use field accessor inside accessor itself - use '@' operator",

        10, 28, "Field storage of inherited field '$podName::Root.r01' not accessible (might try super)",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  Void testMethodFlags()
  {
    // parser stage
    verifyErrors(
     "abstract class Foo
      {
        abstract internal abstract Void m01()
        abstract virtual Void m02()
        override virtual Void m03() {}
      }
      ",
       [
         3, 21, "Repeated modifier",
         4,  3, "Abstract implies virtual",
         5,  3, "Override implies virtual",
       ])

    // check errors stage
    verifyErrors(
     "abstract class Foo : Whatever
      {
        final Void m00() {}
        const Void m01() {}
        readonly Void m02() {}

        public protected Void m10() {}
        public private Void m11() {}
        public internal Void m12() {}
        protected private Void m13() {}
        protected internal Void m14() {}
        internal private Void m15() {}

        new override m22() {}
        new virtual m23() {}
        abstract native Void m24()
        static abstract Void m25()
        static override Void m26() {}
        static virtual Void m27() {}

        private virtual Void m28() {}
      }

      abstract class Bar
      {
        new abstract m20 ()
        new native m21()

        new once m30() {}
        once static Int m31() { return 3 }
        abstract once Int m32()
      }

      abstract class Whatever
      {
        virtual Void m22() {}
        virtual Void m26() {}
      }

      mixin MixIt
      {
        once Int a() { return 3 }
      }

      ",
       [
         3,  3, "Cannot use 'final' modifier on method",
         4,  3, "Cannot use 'const' modifier on method",
         5,  3, "Cannot use 'readonly' modifier on method",

         7,  3, "Invalid combination of 'public' and 'protected' modifiers",
         8,  3, "Invalid combination of 'public' and 'private' modifiers",
         9,  3, "Invalid combination of 'public' and 'internal' modifiers",
        10,  3, "Invalid combination of 'protected' and 'private' modifiers",
        11,  3, "Invalid combination of 'protected' and 'internal' modifiers",
        12,  3, "Invalid combination of 'private' and 'internal' modifiers",

        14,  3, "Invalid combination of 'new' and 'override' modifiers",
        15,  3, "Invalid combination of 'new' and 'virtual' modifiers",
        16,  3, "Invalid combination of 'abstract' and 'native' modifiers",
        17,  3, "Invalid combination of 'static' and 'abstract' modifiers",
        18,  3, "Invalid combination of 'static' and 'override' modifiers",
        19,  3, "Invalid combination of 'static' and 'virtual' modifiers",

        21,  3, "Invalid combination of 'private' and 'virtual' modifiers",

        26,  3, "Invalid combination of 'new' and 'abstract' modifiers",
        27,  3, "Invalid combination of 'new' and 'native' modifiers",

        29,  3, "Invalid combination of 'new' and 'once' modifiers",
        30,  3, "Invalid combination of 'static' and 'once' modifiers",
        31,  3, "Invalid combination of 'abstract' and 'once' modifiers",

        42,  3, "Mixins cannot have once methods",
       ])
  }

  Void testMethods()
  {
    // errors
    verifyErrors(
     "class A { new make(Str n) {}  }
      class B { private new make() {} }
      class C : A { }
      class D : B { }
      class E : A { new makeIt() {} }
      class F : B { new makeIt() {} }
      mixin G { new make() {} }
      class H { Void f(Int a := 3, Int b) {} }
      ",
       [
         3,  1, "Must call super class constructor in 'make'",
         4,  1, "Must call super class constructor in 'make'",
         5, 15, "Must call super class constructor in 'makeIt'",
         6, 15, "Must call super class constructor in 'makeIt'",
         7, 11, "Mixins cannot have constructors",
         8, 30, "Parameter 'b' must have default",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Statements
//////////////////////////////////////////////////////////////////////////

  Void testStmt()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        static Obj m03() { if (0) return 1; return 2; }
        static Obj m04() { throw 3 }
        static Str m05() { return 6 }
        static Obj m06() { for (;\"x\";) m03(); return 2 }
        static Obj m07() { while (\"x\") m03(); return 2 }
        static Void m08() { break; continue }
        static Void m09() { Str x := 4.0f }
        static Void m10() { try { m03 } catch (Str x) {} }
        static Void m11() { try { m03 } catch (IOErr x) {} catch (IOErr x) {} }
        static Void m12() { try { m03 } catch (Err x) {} catch (IOErr x) {} }
        static Void m13() { try { m03 } catch (Err x) {} catch {} }
        static Void m14() { try { m03 } catch {} catch {} }
        static Void m15() { switch (Weekday.sun) { case 4: return } }
        static Void m16() { switch (2) { case 0: case 0: return } }
        static Void m17() { switch (Weekday.sun) { case Weekday.sun: return; case Weekday.sun: return } }

        static Void m19() { try { return } finally { return } }
        static Int m20() { try { return 1 } finally { return 2 } }
        static Obj m21() { try { try { return m03 } finally { return 8 } } finally { return 9 } }
        static Obj m22() { try { try { return m03 } finally { return 8 } } finally {} }
        static Obj m23() { try { try { return m03 } finally { } } finally { return 9 } }
        static Void m24() { while (true) { try { echo(3) } finally { break } } }
        static Void m25() { while (true) { try { echo(3) } finally { continue } } }
        static Void m26() { for (;;) { try { try { m03 } finally { break } } finally { continue } } }
      }",
       [3, 26, "If condition must be Bool, not 'sys::Int'",
        4, 28, "Must throw Err, not 'sys::Int'",
        5, 29, "Cannot return 'sys::Int' as 'sys::Str'",
        6, 28, "For condition must be Bool, not 'sys::Str'",
        7, 29, "While condition must be Bool, not 'sys::Str'",
        8, 23, "Break outside of loop (break is implicit in switch)",
        8, 30, "Continue outside of loop",
        9, 32, "'sys::Float' is not assignable to 'sys::Str'",
        10, 42, "Must catch Err, not 'sys::Str'",
        11, 54, "Already caught 'sys::IOErr'",
        12, 52, "Already caught 'sys::IOErr'",
        13, 52, "Already caught 'sys::Err'",
        14, 44, "Already caught 'sys::Err'",
        15, 51, "Incomparable types 'sys::Int' and 'sys::Weekday'",
        16, 49, "Duplicate case label",
        17, 85, "Duplicate case label",

        19, 48, "Cannot leave finally block",
        20, 49, "Cannot leave finally block",
        21, 57, "Cannot leave finally block",
        21, 80, "Cannot leave finally block",
        22, 57, "Cannot leave finally block",
        23, 71, "Cannot leave finally block",
        24, 64, "Cannot leave finally block",
        25, 64, "Cannot leave finally block",
        26, 62, "Cannot leave finally block",
        26, 82, "Cannot leave finally block",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Expressions
//////////////////////////////////////////////////////////////////////////

  Void testExpr()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        new make() { return }
        static Obj m00() { return 1f..2 }
        static Obj m01() { return 2..[,] }
        static Obj m02() { return !4 }
        static Obj m03() { return 4 && true }
        static Obj m04() { return 0ns || [,] }
        static Void m05(Str x) { x = true }
        Void m06() { this.make }
        Void m07() { this.m00 }
        static Void m08(Str x) { m07; Foo.m07() }
        Void m09(Str x) { this.sf.size }
        static Void m10(Str x) { f.size; Foo.f.size }
        static Void m11(Str x) { this.m06; super.hash() }
        static Obj m12(Str x) { return 1 ? 2 : 3 }
        static Bool m14(Str x, Int y) { return x === y }
        static Bool m15(Str x, Int y) { return x !== y }
        static Bool m16(Str x) { return x == m10(\"\") }
        static Bool m17(Str x) { return x != x.size }
        static Bool m18(Int x) { return x < 2f }
        static Bool m19(Int x) { return x <= Weekday.sun }
        static Bool m20(Int x) { return x > \"\" }
        static Bool m21(Int x) { return x >= m10(\"\") }
        static Int m22(Int x) { return x <=> 2f }
        static Obj m23(Str x) { return (Num)x }
        static Obj m24(Str x) { return x is Num}
        static Obj m25(Str x) { return x isnot Type }
        static Obj m26(Str x) { return x as Num }
        static Obj m27() { return Bar.make }
        static Obj m28() { return \"x=\$v\" }
        static Obj m29() { return 5 + v }
        static Obj m30() { return 5 + 8ns }

        static Void v() {}

        Str f
        const static Str sf
      }

      abstract class Bar
      {
      }",
       [4, 29, "Range must be Int..Int, not 'sys::Float..sys::Int'",
        5, 29, "Range must be Int..Int, not 'sys::Int..sys::Obj?[]'",
        6, 29, "Cannot apply '!' operator to 'sys::Int'",
        7, 29, "Cannot apply '&&' operator to 'sys::Int'",
        8, 29, "Cannot apply '||' operator to 'sys::Duration'",
        8, 36, "Cannot apply '||' operator to 'sys::Obj?[]'",
        9, 32, "'sys::Bool' is not assignable to 'sys::Str'",
       10, 21, "Cannot call constructor 'make' on instance",
       11, 21, "Cannot call static method 'm00' on instance",
       12, 28, "Cannot call instance method 'm07' in static context",
       12, 37, "Cannot call instance method 'm07' in static context",
       13, 26, "Cannot access static field 'sf' on instance",
       14, 28, "Cannot access instance field 'f' in static context",
       14, 40, "Cannot access instance field 'f' in static context",
       15, 28, "Cannot access 'this' in static context",
       15, 38, "Cannot access 'super' in static context",
       16, 34, "Ternary condition must be Bool, not 'sys::Int'",
       17, 42, "Incomparable types 'sys::Str' and 'sys::Int'",
       18, 42, "Incomparable types 'sys::Str' and 'sys::Int'",
       19, 35, "Incomparable types 'sys::Str' and 'sys::Void'",
       20, 35, "Incomparable types 'sys::Str' and 'sys::Int'",
       21, 35, "Incomparable types 'sys::Int' and 'sys::Float'",
       22, 35, "Incomparable types 'sys::Int' and 'sys::Weekday'",
       23, 35, "Incomparable types 'sys::Int' and 'sys::Str'",
       24, 35, "Incomparable types 'sys::Int' and 'sys::Void'",
       25, 34, "Incomparable types 'sys::Int' and 'sys::Float'",
       26, 34, "Inconvertible types 'sys::Str' and 'sys::Num'",
       27, 34, "Inconvertible types 'sys::Str' and 'sys::Num'",
       28, 34, "Inconvertible types 'sys::Str' and 'sys::Type'",
       29, 34, "Inconvertible types 'sys::Str' and 'sys::Num'",
       30, 33, "Calling constructor on abstract class",
       31, 33, "Invalid args plus(sys::Obj?), not (sys::Void)",
       32, 29, "Invalid args plus(sys::Int), not (sys::Void)",
       33, 29, "Invalid args plus(sys::Int), not (sys::Duration)",
       ])
  }

  Void testNotAssignable()
  {
    // errors
    verifyErrors(
     "class Foo
      {

        Void m00(Int a) { 3 = a }
        Void m01(Int a) { 3 += a }
        Void m02(Int a) { i = a }
        Void m03(Int a) { i += a }
        Void m04(Int a) { i++ }
        Void m05(Foo a) { this = a }
        Void m06(Foo a) { super = a }
        Void m07(Foo a) { this += a }
        Void m08(Foo a) { this++ }

        Int i() { return 3 }
        Foo plus(Foo a) { return this }
        Void increment() {}
      }",
       [
         4, 21, "Left hand side is not assignable",
         5, 21, "Target is not assignable",
         6, 21, "Left hand side is not assignable",
         7, 21, "Target is not assignable",
         8, 21, "Target is not assignable",
         9, 21, "Left hand side is not assignable",
        10, 21, "Left hand side is not assignable",
        11, 21, "Target is not assignable",
        12, 21, "Target is not assignable",
       ])
  }

  Void testInvalidArgs()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        static Obj m00() { return 3.increment(true) }
        static Obj m01() { return 3.plus }
        static Obj m02() { return 3.plus(3ns) }
        static Obj m03() { return 3.plus(4, 5) }
        static Obj m04() { return sys::Str.spaces }
        static Obj m05() { return sys::Str.spaces(true) }
        static Obj m06() { return sys::Str.spaces(1, 2) }
        static Obj m07() { return \"abcb\".index(\"b\", true) }
        static Void m08() { m := |Int a| {}; m(3ns) }
        static Void m09() { m := |Str a| {}; m() }
        static Void m10() { m := &Int.plus;  m() }
        static Void m11() { (&2.plus)(true) }
        static Void m12() { (&2.plus)(3, 5) }
      }",
       [3, 31, "Invalid args increment(), not (sys::Bool)",
        4, 31, "Invalid args plus(sys::Int), not ()",
        5, 31, "Invalid args plus(sys::Int), not (sys::Duration)",
        6, 31, "Invalid args plus(sys::Int), not (sys::Int, sys::Int)",
        7, 38, "Invalid args spaces(sys::Int), not ()",
        8, 38, "Invalid args spaces(sys::Int), not (sys::Bool)",
        9, 38, "Invalid args spaces(sys::Int), not (sys::Int, sys::Int)",
       10, 36, "Invalid args index(sys::Str, sys::Int), not (sys::Str, sys::Bool)",
       11, 40, "Invalid args |sys::Int|, not (sys::Duration)",
       12, 40, "Invalid args |sys::Str|, not ()",
       13, 40, "Invalid args |sys::Int, sys::Int|, not ()",
       14, 32, "Invalid args |sys::Int|, not (sys::Bool)",
       15, 32, "Invalid args |sys::Int|, not (sys::Int, sys::Int)",
       ])
  }

  Void testExprInClosure()
  {
    // errors
    verifyErrors(
     "class Foo                                               // 1
      {                                                       // 2
        Void m00a() { |,| { this.make }.call0 }               // 3
        Void m00b() { |,| { |,| { this.make }.call0 }.call0 } // 4
        Void m01a() { |,| { this.m02a }.call0 }               // 5
        Void m01b() { |,| { |,| { this.m02a }.call0 }.call0 } // 6
        static Void m02a() { |,| { m00a; Foo.m00a() }.call0 } // 7
        static Void m02b() { |,| { |,| { m00a; Foo.m00a() }.call0 }.call0 } // 8
        Void m03a(Str x) { |,| { this.sf.size }.call0 }       // 9
        Void m03b(Str x) { |,| { |,| { this.sf.size }.call0 }.call0 } // 10
        static Void m04a(Str x) { |,| { f.size; Foo.f.size }.call0 }
        static Void m04b(Str x) { |,| { |,| { f.size; Foo.f.size }.call0 }.call0 }

        Str f
        const static Str sf
      }",

       [3, 28, "Cannot call constructor 'make' on instance",
        4, 34, "Cannot call constructor 'make' on instance",
        5, 28, "Cannot call static method 'm02a' on instance",
        6, 34, "Cannot call static method 'm02a' on instance",
        7, 30, "Cannot call instance method 'm00a' in static context",
        7, 40, "Cannot call instance method 'm00a' in static context",
        8, 36, "Cannot call instance method 'm00a' in static context",
        8, 46, "Cannot call instance method 'm00a' in static context",
        9, 33, "Cannot access static field 'sf' on instance",
       10, 39, "Cannot access static field 'sf' on instance",
       11, 35, "Cannot access instance field 'f' in static context",
       11, 47, "Cannot access instance field 'f' in static context",
       12, 41, "Cannot access instance field 'f' in static context",
       12, 53, "Cannot access instance field 'f' in static context",
       ])
  }

  Void testAbstractSupers()
  {
    verifyErrors(
     "class Foo : Base, A
      {
        override Int x { get { return super.x } set { A.super.x = val } }
        override Void n() { super.n }
        override Void m() { A.super.m() }
      }

      abstract class Base
      {
        abstract Int x
        abstract Void n()
      }

      mixin A
      {
        abstract Int x
        abstract Void m()
      }
      ",
       [
         3, 33, "Cannot use super to access abstract field '$podName::Base.x'",
         3, 49, "Cannot use super to access abstract field '$podName::A.x'",
         4, 23, "Cannot use super to call abstract method '$podName::Base.n'",
         5, 23, "Cannot use super to call abstract method '$podName::A.m'",
       ])
  }

  Void testNotStmt()
  {
    // Parser level errors
    verifyErrors(
     "class Foo
      {
        Void x(Int i, Str s, Obj o)
        {
          i + Int;
        }
      }",
       [5, 9, "Unexpected type literal",])

    // CheckErrors level errors
    verifyErrors(
     "class Foo
      {
        Void x(Int i, Str s, Obj o)
        {
          true;
          3;
          i + 2;
          f;
          this.f;
          (Int)o;
          o is Int;
          o as Int;
          i == 4 ? 0ns : 1ns;
          |,| {};
          i == 2;
          i === 2;
        }

        Str f
      }",

       [
         5,  5, "Not a statement",
         6,  5, "Not a statement",
         7,  5, "Not a statement",
         8,  5, "Not a statement",
         9, 10, "Not a statement",
        10,  5, "Not a statement",
        11,  5, "Not a statement",
        12,  5, "Not a statement",
        13,  5, "Not a statement",
        14,  5, "Not a statement",
        15,  5, "Not a statement",
        16,  5, "Not a statement",
       ])
  }

  Void testSafeNav()
  {
    // CheckErrors level errors
    verifyErrors(
     "class Foo
      {
        Void func()
        {
          x?.i = 5
          x?.x.i = 5
          x?.x?.i = 5
          y()?.i = 5
          x?.i += 5
          nn?.y
          temp := nn?.i
        }

        Foo? y() { return this }
        Foo? get(Int x) { return null }
        Void set(Int x, Int y) {}
        Foo? x
        Foo nn
        Int i
      }",

       [
         5,  8, "Null-safe operator on left hand side of assignment",
         6,  8, "Null-safe operator on left hand side of assignment",
         7, 11, "Null-safe operator on left hand side of assignment",
         7,  8, "Null-safe operator on left hand side of assignment",
         8, 10, "Null-safe operator on left hand side of assignment",
         9,  8, "Null-safe operator on left hand side of assignment",
        10,  5, "Cannot use null-safe call on non-nullable type '$podName::Foo'",
        11, 13, "Cannot use null-safe access on non-nullable type '$podName::Foo'",
       ])
  }

  Void testNullableNullLiteral()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        Int m00() { return null }
        Void m01(Obj x) { x = null }
        Void m02() { Int x := null }
        Void m03() { m01(null) }
      }",
       [
         3, 22, "Cannot return 'null' as 'sys::Int'",
         4, 25, "'null' is not assignable to 'sys::Obj'",
         5, 25, "'null' is not assignable to 'sys::Int'",
         6, 16, "Invalid args m01(sys::Obj), not (null)",
       ])
  }

//////////////////////////////////////////////////////////////////////////
// Collection Literals
//////////////////////////////////////////////////////////////////////////

  Void testListLiterals()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        Obj m00() { return [3] }    // ok
        Obj m01() { return [null] } // ok
        Obj m02() { return Num[\"x\", 4ns, 6] }
        Obj m03() { return Num[null] }
        Obj m04() { return Int[][ [3], [3d] ] }
      }",
       [
         5, 26, "Invalid value type 'sys::Str' for list of 'sys::Num'",
         5, 31, "Invalid value type 'sys::Duration' for list of 'sys::Num'",
         6, 26, "Invalid value type 'null' for list of 'sys::Num'",
         7, 34, "Invalid value type 'sys::Decimal[]' for list of 'sys::Int[]'",
       ])
  }

  Void testMapLiterals()
  {
    // errors
    verifyErrors(
     "class Foo
      {
        Obj m00() { return Int:Num[3:2ns, 2ns:5, 2ns:2ns] }
        Obj m01() { return Int:Int[null:2, 3:null] }
      }",
       [
         3, 32, "Invalid value type 'sys::Duration' for map type '[sys::Int:sys::Num]'",
         3, 37, "Invalid key type 'sys::Duration' for map type '[sys::Int:sys::Num]'",
         3, 44, "Invalid key type 'sys::Duration' for map type '[sys::Int:sys::Num]'",
         3, 48, "Invalid value type 'sys::Duration' for map type '[sys::Int:sys::Num]'",
         4, 30, "Invalid key type 'null' for map type '[sys::Int:sys::Int]'",
         4, 40, "Invalid value type 'null' for map type '[sys::Int:sys::Int]'",
       ])
  }

}