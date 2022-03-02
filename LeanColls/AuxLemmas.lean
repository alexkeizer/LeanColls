/-
Copyright (c) 2021 James Gallicchio.

Authors: James Gallicchio
-/

namespace Nat
  theorem sub_dist (x y z : Nat) : x - (y + z) = x - y - z := by
    induction z
    simp
    case succ z z_ih =>
    simp [Nat.sub_succ, Nat.add_succ, z_ih]
end Nat

namespace List
  def front? : List τ → Option (τ × List τ)
  | [] => none
  | t::ts => some (t,ts)

  @[simp]
  theorem front_cons (ts : List τ)
    : (ts.cons t).front? = some (t,ts)
    := by
    cases ts
    repeat {simp [front?]}

  def back? : List τ → Option (List τ × τ)
  | [] => none
  | t::ts => some (match ts.back? with | none => ([],t) | some (ts',t') => (t::ts',t'))

  @[simp]
  theorem back_concat (ts : List τ)
    : (ts.concat t).back? = some (ts,t)
    := by
    induction ts
    simp [back?]
    case cons t' ts' ih =>
    simp [back?, ih]

  @[simp]
  theorem concat_append (L₁ L₂ : List τ)
    : (L₁ ++ L₂).concat x = L₁ ++ L₂.concat x
    := by
    induction L₁
    simp
    case cons h t ih =>
    simp [concat]
    exact ih

  @[simp]
  theorem map_concat (L : List τ) (f : τ → α)
    : (L.concat x).map f = (L.map f).concat (f x)
    := by
    induction L
    simp [concat,map]
    case cons h t ih =>
    simp [concat,map]
    exact ih

  @[simp]
  theorem join_concat (L : List (List τ))
    : (L.concat x).join = L.join ++ x
    := by
    induction L
    simp [concat,join]
    case cons h t ih =>
    simp [ih,concat,join,List.append_assoc]
end List

class Monoid (M) where
  mId : M
  mApp : M → M → M
  h_idl : ∀ v, mApp mId v = v
  h_idr : ∀ v, mApp v mId = v
  h_assoc : ∀ v1 v2 v3, mApp (mApp v1 v2) v3 = mApp v1 (mApp v2 v3)

namespace Monoid

instance [Monoid M] : Append M where
  append := Monoid.mApp

@[simp]
theorem mApp_assoc [Monoid M] : ∀ (v1 v2 v3 : M), v1 ++ v2 ++ v3 = v1 ++ (v2 ++ v3) := Monoid.h_assoc

instance : Monoid Nat where
  mId := 0
  mApp := Nat.add
  h_idl := by simp
  h_idr := by simp
  h_assoc := Nat.add_assoc

end Monoid


def Cached {α : Type _} (a : α) := { b // b = a }

namespace Cached

instance {a : α} : DecidableEq (Cached a) :=
  fun ⟨x, hx⟩ ⟨y, hy⟩ => Decidable.isTrue (by cases hx; cases hy; rfl)

instance {a : α} : Repr (Cached a) where
  reprPrec x := Repr.addAppParen "cached _"

instance {a : α} : Subsingleton (Cached a) :=
  ⟨by intro ⟨x, h⟩; cases h; intro ⟨y, h⟩; cases h; rfl⟩

instance {a : α} : CoeHead (Cached a) α where
  coe x := x.1

def cached (a : α) : Cached a :=
  ⟨a, rfl⟩

instance {a : α} : Inhabited (Cached a) where
  default := cached a

@[simp] theorem cached_val (a : α) (b : Cached a) : (b : α) = a := b.2

end Cached

export Cached (cached)

def time (f : IO α) : IO (Nat × α) := do
  let pre ← IO.monoMsNow
  let ret ← f
  let post ← IO.monoMsNow
  pure (post-pre, ret)
