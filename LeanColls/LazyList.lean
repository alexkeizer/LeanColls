/-
Copyright (c) 2022 James Gallicchio.

---
This file was modified from source code released by
Microsoft Corporation under the Apache 2.0 license available at
<https://www.apache.org/licenses/>.

Original copyright notice:

Copyright (c) 2019 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
---

Authors: Leonardo de Moura, James Gallicchio
-/

import LeanColls.Classes

inductive LazyList (α : Type u)
| nil : LazyList α
| cons (hd : α) (tl : LazyList α) : LazyList α
| delayed (t : Thunk (LazyList α)) : LazyList α

namespace LazyList
variable {α : Type u} {β : Type v} {δ : Type w}

/-!
Standard technique for LazyList. Necessary because LazyList is a
nested inductive, but we never actually want to have different motives
for the nested types.

Remark: Lean used well-founded recursion behind the scenes to define LazyList.ind
-/
theorem ind {α : Type u} {motive : LazyList α → Sort v}
        (nil : motive LazyList.nil)
        (cons : (hd : α) → (tl : LazyList α) → motive tl → motive (LazyList.cons hd tl))
        (delayed : (t : Thunk (LazyList α)) → motive t.get → motive (LazyList.delayed t))
        (t : LazyList α) : motive t :=
  match t with
  | LazyList.nil => nil
  | LazyList.cons h t => cons h t (ind nil cons delayed t)
  | LazyList.delayed t => delayed t (ind nil cons delayed t.get)

instance : Inhabited (LazyList α) :=
⟨nil⟩

@[inline] protected def pure : α → LazyList α
| a => cons a nil


/-
Length of a list is number of actual elements
in the list, ignoring delays
-/
def length : LazyList α → Nat
| nil        => 0
| cons _ as  => length as + 1
| delayed as => length as.get

def toList : LazyList α → List α
| nil        => []
| cons a as  => a :: toList as
| delayed as => toList as.get

attribute [simp] length toList

@[simp] theorem length_toList : (l : LazyList α) → l.toList.length = l.length
| nil => rfl
| cons a as => by simp [length_toList as]
| delayed as => by simp [length_toList as.get]

def force : LazyList α → Option (α × LazyList α)
| delayed as => force as.get
| nil        => none
| cons a as  => some (a,as)

theorem toList_force_none {l : LazyList α}
  : force l = none ↔ l.toList = List.nil
  := by
    induction l using ind
    simp [force]
    simp [force]
    simp [force]; assumption

theorem toList_force_some {l : LazyList α}
  : force l = some (x,xs) → l.toList = List.cons x xs.toList
  := by
    induction l using ind generalizing x xs
    simp [force]
    case cons =>
      simp [force]
      intro h
      simp [h]
      apply congr_arg
    case delayed th ih =>
      simp [force]
      intro h
      exact ih h

def head? (l : LazyList α) : Option α := l.force.map (Prod.fst)

def tail? (l : LazyList α) : Option (LazyList α) := l.force.map (Prod.snd)


def isEmpty (l : LazyList α) : Bool := l.length = 0

def append : LazyList α → LazyList α → LazyList α
| nil,        bs => bs
| cons a as,  bs => cons a (delayed (append as bs))
| delayed as, bs => append as.get bs

instance : Append (LazyList α) :=
⟨LazyList.append⟩

@[simp] theorem toList_append (l₁ l₂ : LazyList α)
  : (l₁ ++ l₂).toList = l₁.toList ++ l₂.toList
  := by
    induction l₁ using ind
    simp [HAppend.hAppend, Append.append, append, List.append, toList]
    case cons hd tl tl_ih =>
      simp [HAppend.hAppend, Append.append, append] at tl_ih |-
      simp [tl_ih, toList, Thunk.get]
    case delayed t t_ih =>
      simp [HAppend.hAppend, Append.append, append] at t_ih |-
      assumption

@[simp] theorem length_append (l₁ l₂ : LazyList α)
  : (l₁ ++ l₂).length = l₁.length + l₂.length
  := by
  rw [←length_toList, ←length_toList, ←length_toList]
  rw [toList_append]
  exact List.length_append (toList l₁) (toList l₂)

@[simp] def revAppend : LazyList α → LazyList α → LazyList α
| nil,        bs => bs
| cons a as,  bs => revAppend as (cons a bs)
| delayed as, bs => revAppend as.get bs

@[simp] theorem toList_revAppend (l₁ l₂ : LazyList α)
  : (revAppend l₁ l₂).toList = l₁.toList.reverse ++ l₂.toList
  := by
    induction l₁ using ind generalizing l₂
    simp
    case cons hd tl tl_ih =>
      simp [Thunk.get] at tl_ih |-
      have := tl_ih (cons hd l₂)
      rw [this]
      simp [HAppend.hAppend, Append.append, List.append]
    case delayed t t_ih =>
      simp [HAppend.hAppend, Append.append, append] at t_ih |-
      exact t_ih l₂

@[simp] theorem length_revAppend (l₁ l₂ : LazyList α)
  : (revAppend l₁ l₂).length = l₁.length + l₂.length
  := by
  rw [←length_toList, ←length_toList, ←length_toList]
  rw [toList_revAppend, List.length_append, List.length_reverse]

def reverse (l : LazyList α) := revAppend l nil

@[simp] theorem toList_reverse (l : LazyList α) : l.reverse.toList = l.toList.reverse
  := by simp [reverse]

@[simp] theorem length_reverse (l : LazyList α) : l.reverse.length = l.length
  := by simp [reverse]

def interleave : LazyList α → LazyList α → LazyList α
| nil,        bs => bs
| cons a as,  bs =>
  cons a (delayed (interleave bs as))
| delayed as, bs =>
  interleave as.get bs
termination_by _ as bs => sizeOf (as,bs)

@[specialize] def map (f : α → β) : LazyList α → LazyList β
| nil        => nil
| cons a as  => cons (f a) (delayed (map f as))
| delayed as => map f as.get

@[specialize] def map₂ (f : α → β → δ) : LazyList α → LazyList β → LazyList δ
| nil, _ => nil
| _, nil => nil
| cons a as, cons b bs =>
  cons (f a b) (delayed (map₂ f as bs))
| delayed as, bs =>
  map₂ f as.get bs
| as, delayed bs => map₂ f as bs.get
termination_by _ as bs => sizeOf (as,bs)

@[inline] def zip : LazyList α → LazyList β → LazyList (α × β) :=
  map₂ Prod.mk

def join : LazyList (LazyList α) → LazyList α
| nil        => nil
| cons a as  => a ++ delayed (join as)
| delayed as => join as.get

@[inline] protected def bind (x : LazyList α) (f : α → LazyList β) : LazyList β :=
join (x.map f)

def take : Nat → LazyList α → List α
| 0, _ => []
| _, nil => []
| i+1, cons a as => a :: take i as
| i+1, delayed as => take (i+1) as.get

@[specialize] def filter (p : α → Bool) : LazyList α → LazyList α
| nil          => nil
| (cons a as)  => if p a then cons a (delayed (filter p as)) else filter p as
| (delayed as) => filter p as.get

instance : Monad LazyList where
  pure := @LazyList.pure
  bind := @LazyList.bind
  map := @LazyList.map

instance : Alternative LazyList where
  failure := nil
  orElse  := fun as bs => LazyList.append as (delayed (Thunk.mk bs))

def fold (f : α → τ → α) (acc : α)
: LazyList τ → α
| nil        => acc
| cons a as  =>
  fold f (f acc a) as
| delayed as => fold f acc (as.get)

instance : LeanColls.Foldable (LazyList τ) τ where
  fold l f a := fold f a l

instance : LeanColls.Iterable (LazyList τ) τ where
  ρ := LazyList τ
  step := LazyList.force
  toIterator := id

@[specialize] partial def iterate (f : α → α) : α → LazyList α
| x => cons x (delayed (iterate f (f x)))

@[specialize] partial def iterate₂ (f : α → α → α) : α → α → LazyList α
| x, y => cons x (delayed (iterate₂ f y (f x y)))


partial def cycle : LazyList α → LazyList α
| xs => xs ++ delayed (cycle xs)

def inits : LazyList α → LazyList (LazyList α)
| nil        => cons nil nil
| cons a as  => cons nil (delayed (map (fun as => cons a as) (inits as)))
| delayed as => inits as.get

private def addOpenBracket (s : String) : String :=
if s.isEmpty then "[" else s

def approxToStringAux [ToString α] : Nat → LazyList α → String → String
| _,   nil,        r => (if r.isEmpty then "[" else r) ++ "]"
| 0,   _,          r => (if r.isEmpty then "[" else r) ++ ", ..]"
| n+1, cons a as,  r => approxToStringAux n as ((if r.isEmpty then "[" else r ++ ", ") ++ toString a)
| n,   delayed as, r => approxToStringAux n as.get r

def approxToString [ToString α] (as : LazyList α) (n : Nat := 10) : String :=
as.approxToStringAux n ""

instance [ToString α] : ToString (LazyList α) :=
⟨approxToString⟩

end LazyList


private unsafe def List.toLazyUnsafe {α : Type u} (xs : List α) : LazyList α :=
  unsafeCast xs

@[implemented_by List.toLazyUnsafe]
def List.toLazy {α : Type u} : List α → LazyList α
| []     => LazyList.nil
| (h::t) => LazyList.cons h (toLazy t)


def fib : LazyList Nat :=
LazyList.iterate₂ (·+·) 0 1

def tst : LazyList String := do
  let x ← [1, 2, 3].toLazy
  let y ← [2, 3, 4].toLazy
  -- dbgTrace (toString x ++ " " ++ toString y) $ λ _,
  guard (x + y > 5)
  return (toString x ++ " + " ++ toString y ++ " = " ++ toString (x+y))

open LazyList

def iota (i : UInt32 := 0) : LazyList UInt32 :=
iterate (·+1) i

partial def sieve : LazyList UInt32 → LazyList UInt32
| nil          => nil
| (cons a as)  => cons a (delayed (sieve (filter (fun b => b % a != 0) as)))
| (delayed as) => sieve as.get

partial def primes : LazyList UInt32 :=
sieve (iota 2)

#eval show IO Unit from do
  let n := 10
  IO.println $ tst.isEmpty ;
  -- IO.println $ [1, 2, 3].toLazy.cycle,
  -- IO.println $ [1, 2, 3].toLazy.cycle.inits,
  -- IO.println $ ((iota.filter (λ v, v % 5 == 0)).approx 50000).foldl (+) 0,
  IO.println $ (primes.take 2000).foldl (·+·) 0
  -- IO.println $ tst.head,
  -- IO.println $ fib.interleave (iota.map (+100)),
  -- IO.println $ ((iota.map (+10)).filter (λ v, v % 2 == 0)),
  return ()