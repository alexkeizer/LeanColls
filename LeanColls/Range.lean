/-
Copyright (c) 2022 James Gallicchio.

Authors: James Gallicchio
-/

import LeanColls.List
import LeanColls.AuxLemmas

namespace LeanColls

/-! # Range

Represents the first `n` natural numbers, e.g. [0, n).
-/
structure Range where
  n : Nat

namespace Range

instance : Membership Nat Range where
  mem x r := x < r.n

/-! ## Range folds

We define folds over ranges in both directions. Noting that
`toList n = [0, 1, ..., n]`, the directions correspond to
`List.foldl` and `List.foldr`.
-/

def foldr (f : Nat → β → β) (acc : β) : Range → β
| ⟨0⟩ => acc
| ⟨n+1⟩ => foldr f (f n acc) ⟨n⟩

def foldl (f : β → Nat → β) (acc : β) : Range → β
| ⟨0⟩ => acc
| ⟨n+1⟩ => f (foldl f acc ⟨n⟩) n

def foldr' (r : Range) (f : (i : Nat) → i ∈ r → β → β) (acc : β) : β :=
  match r with
  | ⟨0⟩ => acc
  | ⟨n+1⟩ =>
    have hn : n < n+1 := Nat.lt_succ_self _
    have hi : ∀ {i}, i < n → i < n+1 := Nat.le_step
    foldr' ⟨n⟩ (λ i h acc => f i (hi h) acc) (f n hn acc)

def foldl' (r : Range) (f : β → (i : Nat) → i ∈ r → β) (acc : β) : β :=
  match r with
  | ⟨0⟩ => acc
  | ⟨n+1⟩ =>
    have hn : n < n+1 := Nat.lt_succ_self _
    have hi : ∀ {i}, i < n → i < n+1 := Nat.le_step
    f (foldl' ⟨n⟩ (λ acc i h => f acc i (hi h)) acc) n hn

def foldl'' (r : Range) (motive : (i : Nat) → Sort u)
  (f : (i : Nat) → i ∈ r → motive i → motive i.succ)
  (init : motive 0)
  : motive r.n
  :=
  let rec aux (n : Nat) (motive : (i : Nat) → Sort u)
    (f : (i : Nat) → i ∈ Range.mk n → motive i → motive i.succ)
    (i : Nat)
    (h_i : i ≤ n)
    (acc : motive i)
    : motive n
    :=
    if h : i = n then
      h ▸ acc
    else
      have : i < n := Nat.lt_of_le_of_ne h_i h
      aux n motive f i.succ this (f i this acc)
  aux r.n motive f 0 (Nat.zero_le _) init
  termination_by aux n _ _ i _ _ => n - i

/- ## Simp lemmas -/

@[simp]
theorem foldl'_zero (f : β → (i : _) → _) (acc)
  : foldl' ⟨0⟩ f acc = acc
  := by unfold foldl'; simp

/- ## Utility functions -/

def toList (r : Range) : List Nat :=
  foldr (· :: ·) [] r

/- ## Fold correctness proofs -/

theorem foldr_cons_eq_append
  : foldr (· :: ·) acc r = foldr (· :: ·) [] r ++ acc
  := by
  cases r; case mk n =>
  induction n generalizing acc with
  | zero => simp [foldr]
  | succ n ih =>
    simp [foldr]
    rw [@ih [n], @ih (n :: acc), List.append_assoc]
    simp

@[simp]
theorem toList_succ (n)
  : toList ⟨n+1⟩ = toList ⟨n⟩ ++ [n]
  := by
  simp [toList, foldr]
  apply foldr_cons_eq_append

theorem foldr_correct (r : Range)
  : r.foldr f acc = (toList r).foldr f acc
  := by
  cases r; case mk n =>
  induction n generalizing acc with
  | zero => simp [foldr]
  | succ n ih => simp [foldr, List.foldr_append, ih]

theorem toList_eq_canonicalToList (r : Range)
  : toList r = canonicalToList r.foldl
  := by
  cases r; case mk n =>
  simp [toList, canonicalToList]
  induction n with
  | zero =>
    simp [foldr, foldl]
  | succ n ih => 
    simp [foldr, foldl, ←ih]
    apply foldr_cons_eq_append

theorem foldl_correct (r : Range)
  : r.foldl f acc = (toList r).foldl f acc
  := by
  rw [toList_eq_canonicalToList]
  simp [canonicalToList]
  cases r; case mk n =>
  induction n with
  | zero => simp [foldl, List.foldl]
  | succ n ih =>
    simp [foldl, List.foldl_append, List.foldl, ih]

theorem foldl_step (n)
  : foldl f init ⟨n+1⟩ = foldl (fun acc x => f acc x.succ) (f init 0) ⟨n⟩
  := by
  induction n generalizing f init with
  | zero      => simp [foldl]
  | succ n ih =>
    simp [foldl]
    congr
    apply ih

theorem foldl'_step (n) {f : (x : _) → _}
  : foldl' ⟨n+1⟩ f init = foldl' ⟨n⟩ (fun acc x h => f acc x.succ (Nat.succ_le_succ h)) (f init 0 (Nat.zero_lt_succ _))
  := by
  induction n generalizing init with
  | zero      =>
    unfold foldl'
    simp
    unfold foldl'
    simp
  | succ n ih =>
    unfold foldl'
    simp [ih]

theorem foldr'_eq_foldl'_mapped (r) {f : (x : _) → _}
  : foldr' r f init = foldl' r (fun acc x h =>
    f (r.n - x - 1) (by
      simp [Membership.mem, Nat.sub_sub]
      apply Nat.sub_lt (Nat.lt_of_le_of_lt (Nat.zero_le _) h)
      apply Nat.succ_le_succ (Nat.zero_le _)
      )
      acc) init
  := by
  cases r; case mk n =>
  simp
  induction n generalizing init with
  | zero =>
    unfold foldr'
    unfold foldl'
    simp
  | succ n ih =>
    unfold foldr'
    simp
    rw [foldl'_step]
    rw [ih]
    simp
    congr
    funext acc x
    simp [Nat.succ_sub_succ]

theorem foldr_eq_foldl_mapped (r)
  : foldr f init r = foldl (fun acc x => f (r.n - x - 1) acc) init r
  := by
  cases r; case mk n =>
  simp
  induction n generalizing init with
  | zero =>
    simp [foldr, foldl]
  | succ n ih =>
    rw [foldl_step]
    simp [foldr, foldl, ih]
    congr
    funext acc x
    simp [Nat.succ_sub_succ]

theorem reverse_toList_eq_map_toList (r : Range)
  : r.toList.reverse = r.toList.map (fun i => r.n - i - 1)
  := by
  conv =>
    rhs
    simp [toList]
    rw [foldr_eq_foldl_mapped, foldl_correct]
  match r with
  | ⟨n⟩ =>
  simp
  suffices ∀ k, k ≤ n → List.reverse (toList ⟨k⟩) =
    List.map (fun i => n - i - 1)
      (List.foldl (fun acc x => (n - x - 1) :: acc) []
        (toList ⟨k⟩))
    from this n (Nat.le_refl _)
  intro k h_k
  induction k with
  | zero => simp
  | succ n ih =>
  simp [List.foldl_append]
  constructor
  case left =>
    rw [←Nat.sub_dist (y := n), Nat.sub_sub_self h_k, Nat.succ_sub_one]
  case right =>
    apply ih
    exact Nat.le_of_lt h_k

theorem memCorrect (x : Nat) (c : Range)
  : x ∈ c ↔ x ∈ canonicalToList (fun {β} => c.foldl)
  := by
  cases c; case mk n =>
  simp [Foldable.fold]
  induction n with
  | zero =>
    simp [canonicalToList, foldl]
    apply Nat.not_lt_zero
  | succ n ih =>
    conv => lhs; simp [Membership.mem]
    conv => rhs; simp [canonicalToList, foldl]
    constructor <;> intro h
    case mp =>
      cases Nat.eq_or_lt_of_le <| Nat.le_of_succ_le_succ h
      case inl h =>
        simp [h]
      case inr h =>
        apply Or.inl <| ih.mp h
    case mpr =>
      cases h
      case inl h =>
        apply Nat.le_step <| ih.mpr h
      case inr h =>
        simp [h]

theorem foldl'_correct {β : Type u} (r : Range) {f : β → (i : Nat) → i ∈ r → β} {acc : β}
    {L : List Nat} (hL : L = canonicalToList r.foldl)
  : r.foldl' f acc = L.foldl' (fun acc x h => f acc x ((memCorrect _ _).mpr (hL.subst h))) acc
  := by
  rw [←toList_eq_canonicalToList] at hL
  cases r; case mk n hL =>
  induction n generalizing L with
  | zero =>
    simp [toList, foldr] at hL
    cases hL
    unfold foldl'
    simp [List.foldl']
  | succ n ih =>
    simp at hL
    simp [foldl']
    rw [ih (L := toList ⟨n⟩) _ rfl]
    conv => rhs; rw [List.foldl'_eq_subtypeByMem_foldl]
    cases hL
    rw [List.subtypeByMem_append]
    rw [List.foldl'_eq_subtypeByMem_foldl]
    simp [foldl, List.foldl_map, List.foldl, List.foldl_append]
    simp [toList_eq_canonicalToList]

theorem foldr'_correct {β : Type u} (r : Range) {f} {acc : β}
  {L} (hL : L = canonicalToList r.foldl)
  : r.foldr' f acc =
    L.foldr'
      (fun x h acc => f x
        ((memCorrect _ _ ).mpr (hL.subst h))
        acc)
      acc
  := set_option pp.all false in by
  cases r; case mk n =>
  cases hL
  rw [List.foldr'_rw _ _ _ _ (toList_eq_canonicalToList _).symm]
  induction n generalizing β acc with
  | zero => unfold foldr'; simp [List.foldr']
  | succ n ih =>
    rw [List.foldr'_rw _ _ _ _ (toList_succ _)]
    rw [List.foldr'_eq_subtypeByMem_foldr]
    rw [List.subtypeByMem_append]
    simp [List.map_append, List.foldr_append]
    rw [List.map_of_subtypeByMem_eq_map']
    rw [List.foldr_of_map']
    simp
    unfold foldr'
    simp [List.foldr']
    rw [ih]


/- ## csimp lemmas -/

theorem foldl''.aux_step {n} {f : (_ : _) → _ → _ → _} {i : Nat} (h : i ≤ n) {acc : motive i}
  : foldl''.aux (n+1) motive f i (Nat.le_step h) acc =
    f n (Nat.lt_succ_self _) (
      foldl''.aux (n) motive (fun i h acc => f i (Nat.le_step h) acc) i h acc)
  := by
  suffices ∀ j (_ : j ≤ n) i (h_i : i = n - j) acc,
    foldl''.aux (n+1) motive f i (h_i ▸ Nat.le_step (Nat.sub_le _ _)) acc =
    f n (Nat.lt_succ_self _) (
      foldl''.aux (n) motive (fun i h acc => f i (Nat.le_step h) acc) i (h_i ▸ Nat.sub_le _ _) acc)
    from this (n-i) (Nat.sub_le _ _) i (Nat.sub_sub_self h).symm acc
  intro j h i h_i acc
  induction j generalizing i acc with
  | zero =>
    simp at h_i
    cases h_i
    unfold aux
    simp
    split
    case inl h => cases h
    unfold aux
    simp
  | succ j ih =>
    conv => lhs; unfold aux
    conv => rhs; unfold aux
    have : i < n := by
      cases h_i
      apply Nat.sub_lt_of_pos_le _ _ (Nat.zero_lt_succ _) h
    have i_nsucc : i ≠ n+1 :=
      Nat.ne_of_lt (Nat.le_step this)
    have i_n : i ≠ n :=
      Nat.ne_of_lt this
    simp [i_nsucc, i_n]
    apply ih
    exact Nat.le_of_lt h
    cases h_i
    rw [Nat.sub_succ]
    rw [Nat.succ_pred]
    apply Ne.symm; apply Nat.ne_of_lt
    apply Nat.lt_sub_of_add_lt
    simp
    exact h

@[simp]
theorem foldl''_zero {f : (_ : _) → _ → _ → _}
  : foldl'' ⟨0⟩ motive f init = init
  := by
  unfold foldl''
  unfold foldl''.aux
  simp

@[simp]
theorem foldl''_step {n} {f : (_ : _) → _ → _ → _}
  : foldl'' ⟨n+1⟩ motive f init =
    f n (Nat.lt_succ_self _) (
      foldl'' ⟨n⟩
        motive
        (f := fun i h acc => f i (Nat.le_step h) acc)
        init)
  := by
  simp [foldl'']
  apply foldl''.aux_step

def foldlImpl (f : β → Nat → β) (acc : β) (r : Range) : β :=
  foldl'' r (motive := λ _ => β) (fun i _ acc => f acc i) acc

@[csimp]
theorem foldl_eq_foldlImpl
  : @foldl = @foldlImpl
  := by
  funext β f acc r
  cases r; case mk n =>
  simp [foldlImpl]
  induction n with
  | zero =>
    simp [foldl, foldl'']
    unfold foldl''.aux
    simp
  | succ n ih =>
    simp [foldl]
    rw [ih]

def foldl'Impl (r : Range) (f : β → (i : Nat) → i ∈ r → β) (init : β) : β :=
  foldl'' r (fun _ => β) (fun i h acc => f acc i h) init

@[csimp]
theorem foldl'_eq_foldl'Impl
  : @foldl' = @foldl'Impl
  := by
  funext β r f acc
  cases r; case mk n =>
  simp [foldl'Impl]
  induction n with
  | zero =>
    simp [foldl'']
    unfold foldl''.aux
    simp
  | succ n ih =>
    simp [foldl']
    rw [ih]

/- ## Class instances -/

instance : Foldable'.Correct Range Nat inferInstance where
  fold r := r.foldl
  fold' := foldl'
  memCorrect := memCorrect
  foldCorrect := by simp [Foldable.fold, foldl_correct]
  fold'Correct := by
    intro _ c f acc; simp [Foldable'.fold']; rw [foldl'_correct]; rfl

instance : FoldableOps Range Nat := {
  (default : FoldableOps Range Nat) with
  contains := λ r _ i => i < r.n
  toList := toList
}

instance : Iterable Range Nat where
  ρ := Nat × Nat
  step := λ (i,stop) => if i < stop then some (i, (i.succ, stop)) else none
  toIterator := λ r => (0,r.n)

instance : Iterable' Range Nat inferInstance where
  ρ c := Σ' (i : Nat) (stop : Nat), i ≤ stop ∧ stop = c.n
  step := λ ⟨i,stop,_,h_stop⟩ =>
    if h : i < stop then
      some (⟨i, by rw [h_stop] at h; exact h⟩, ⟨i.succ, stop, h, h_stop⟩)
    else none
  toIterator := λ r => ⟨0,r.n,Nat.zero_le _,rfl⟩

/- ## Lemmas -/

@[simp]
theorem mem_toList_iff {r : Range} {x}
  : x ∈ toList r ↔ x < r.n
  := by rw [toList_eq_canonicalToList, ←memCorrect]; simp [Membership.mem]

theorem size_pos_of_mem {r : Range} {x}
  : x ∈ r → 0 < r.n
  := by
  intro h; apply Nat.lt_of_le_of_lt (Nat.zero_le _) h

@[simp]
theorem length_toList {r : Range}
  : r.toList.length = r.n
  := by cases r; case mk n => induction n; simp; simp; assumption

@[simp]
theorem get_toList {r : Range} {i : Fin r.toList.length}
  : r.toList.get i = i
  := by cases r; case mk n =>
  induction n with
  | zero => simp at i; exact i.elim0
  | succ n ih =>
    suffices ∀ L (_ : L = toList ⟨n.succ⟩) i,
      List.get L i = i
      from this _ rfl i
    intro L hL i
    rw [toList_succ] at hL
    cases i; case mk i hi =>
    simp
    simp [hL] at hi
    cases Nat.eq_or_lt_of_le (Nat.le_of_succ_le_succ hi)
    case inl h =>
      cases h
      cases hL
      rw [List.get_append_right]
      simp
      simp
      simp
    case inr h =>
      cases hL
      rw [List.get_append_left]
      apply ih
      simp
      assumption

theorem map_set_toList {r : Range} {f : Nat → τ}
  : (r.toList.set i j).map f = (r.toList.map f).set i (f j)
  := by
  cases r; case mk n =>
  cases Nat.decLt i n
  case isFalse h =>
    rw [List.set_of_ge_length (toList ⟨n⟩) _ _]
    rw [List.set_of_ge_length (List.map f (toList ⟨n⟩))]
    simp at h ⊢; exact h
    simp at h ⊢; exact h
  case isTrue hi =>
  induction n with
  | zero => simp
  | succ n ih =>
    simp
    cases Nat.decLt i (toList ⟨n⟩).length
    case isFalse h =>
      have : i = n :=
        Nat.le_antisymm
          (Nat.le_of_succ_le_succ hi)
          (by simp at h; exact h)
      cases this
      rw [List.set_append_right]
      rw [List.set_append_right]
      simp [List.set]
      simp
      simp
    case isTrue h =>
      simp at h
      rw [List.set_append_left]
      rw [List.set_append_left]
      simp
      apply ih
      assumption
      simp; assumption
      simp; assumption

theorem set_map'_toList {r : Range} {i} {x : τ} {f}
  : (r.toList.map' f).set i x
    = r.toList.map' (fun j h' =>
      if j = i
      then x
      else f j h'
      )
  := by
  cases r; case mk n =>
  cases Nat.decLt i n
  case isFalse h =>
    rw [List.set_of_ge_length ((toList ⟨n⟩).map' f)]
    next =>
      congr
      funext j hj
      simp at hj
      simp [Nat.ne_of_lt (Nat.lt_of_lt_of_le hj (Nat.le_of_not_lt h))]
    simp at h ⊢; exact h
  case isTrue hi =>
  simp [List.map']
  suffices ∀ f, List.set (List.map f _) _ _
    = List.map (fun ⟨j,h⟩ => if j = i then x else f ⟨j,h⟩) (List.subtypeByMem (toList ⟨n⟩))
    from this _
  intro f
  induction n with
  | zero =>
    simp
  | succ n ih =>
    rw [List.subtypeByMem_rw _ (toList_succ _)]
    simp [List.subtypeByMem_append]
    cases Nat.decLt i n
    case isFalse h =>
      have : i = n :=
        Nat.le_antisymm
          (Nat.le_of_succ_le_succ hi)
          (by simp at h; exact h)
      cases this
      rw [List.set_append_right]
      next =>
        simp [List.set]
        congr
        funext j'
        cases j'; case mk j' hj' =>
        rw [toList_eq_canonicalToList] at hj'
        rw [←memCorrect] at hj'
        simp [Membership.mem] at hj'
        simp [Nat.ne_of_lt hj']
      simp
    case isTrue h' =>
      rw [List.set_append_left]
      simp [(Nat.ne_of_lt h').symm]
      rw [ih]
      simp
      congr
      assumption
      exact fun x h => f ⟨x,by simp; apply Or.inl; simp at h; assumption⟩
      simp; assumption


end Range

/-! # Range.Complex

A more complicated range, defined by a `start`, `step`, and `stop` value.

The sequence proceeds: `start`, `start + step`, `start + 2 * step`, ...

... until the value passes `stop`. For `step > 0`, the values are upper bounded
by `stop`, while for `step < 0` the values are lower bounded by `stop`.

Similar to `Std.Range`, but allows negative values for start/stop/step.
-/
structure Range.Complex where
  start : Int
  stop : Int
  step : Int
  h_step : step ≠ 0

namespace Range.Complex


def fold : (β → Int → β) → β → Range.Complex → β :=
  let rec loopUp {α} (start stop step : Int) (h_step : step > 0)
    (f : α → Int → α) acc i : α :=
    if h:i < stop then
      have : Int.natAbs (stop + step - (i+step))
              < Int.natAbs (stop + step - i)
        := by
        rw [(by rw [Int.sub_eq_add_neg, Int.sub_eq_add_neg, Int.neg_add, Int.add_comm (-i), Int.add_assoc, ←Int.add_assoc step, Int.add_right_neg]; simp
            : stop + step - (i+step) = stop - i)]
        have h1 : stop - i > 0 := by
          apply Int.lt_sub_right_of_add_lt (a := 0)
          simp [h]
        have h2 : stop + step - i > 0 := by
          rw [Int.add_comm, Int.add_sub_assoc, ←Int.add_zero 0]
          apply Int.add_lt_add_of_le_of_lt (Int.le_of_lt h_step) h1
        suffices stop - i < stop + step - i by
          rw [←Int.ofNat_natAbs_eq_of_nonneg _ (Int.le_of_lt h1)] at this
          rw [←Int.ofNat_natAbs_eq_of_nonneg _ (Int.le_of_lt h2)] at this
          simp at this
          assumption
        rw [Int.sub_eq_add_neg,
            Int.sub_eq_add_neg]
        apply Int.add_lt_add_of_lt_of_le
        apply Int.lt_add_of_pos_right _ h_step
        apply Int.le_refl
      loopUp start stop step h_step f (f acc i) (i+step)
    else
      acc
  let rec loopDown {α} (start stop step : Int) (h_step : step < 0)
    (f : α → Int → α) acc i : α :=
    if h:i > stop then
      have : Int.natAbs (stop + step - (i+step))
              < Int.natAbs (stop + step - i)
        := by
        rw [(by rw [Int.sub_eq_add_neg, Int.sub_eq_add_neg, Int.neg_add, Int.add_comm (-i), Int.add_assoc, ←Int.add_assoc step, Int.add_right_neg]; simp
            : stop + step - (i+step) = stop - i)]
        have h1 : stop - i < 0 := by
          apply Int.sub_left_lt_of_lt_add
          simp [h]
        have h2 : stop + step - i < 0 := by
          rw [Int.add_comm, Int.add_sub_assoc, ←Int.add_zero 0]
          apply Int.add_lt_add_of_le_of_lt (Int.le_of_lt h_step) h1
        suffices stop - i > stop + step - i by
          have := Int.neg_lt_neg this
          rw [←Int.ofNat_natAbs_eq_neg_of_nonpos _ (Int.le_of_lt h1)] at this
          rw [←Int.ofNat_natAbs_eq_neg_of_nonpos _ (Int.le_of_lt h2)] at this
          simp at this
          assumption
        rw [Int.sub_eq_add_neg,
            Int.sub_eq_add_neg]
        apply Int.add_lt_add_of_lt_of_le
        conv =>
          rhs
          rw [←Int.add_zero stop]
        apply Int.add_lt_add_left h_step
        apply Int.le_refl
      loopDown start stop step h_step f (f acc i) (i+step)
    else
      acc

  λ f acc ⟨start,stop,step,h_step⟩ =>
    if h_step:step > 0 then
      loopUp start stop step h_step f acc 0
    else
      have h_step : step < 0 := by
        apply Int.lt_iff_le_and_ne.mpr
        constructor
        simp at h_step
        assumption
        assumption
      loopDown start stop step h_step f acc 0
  termination_by
    loopUp i => Int.natAbs (stop + step - i)
    loopDown i => Int.natAbs (stop + step - i)

/-
instance : Membership Nat Range where
  mem x r := x < r.stop ∧ ∃ k, x = r.start + k * r.step

def fold' : (r : Range) → (β → (i : Nat) → i ∈ r → β) → β → β :=
  let rec @[inline] loop {α} (start stop step h_step)
    (f : α → (i : Nat) → i ∈ (⟨start,stop,step,h_step⟩ : Range) → α) acc
    i (h_i : ∃ k, i = start + k * step) : α :=
    if h:i < stop then
      have : stop - (i + step) < stop - i := by
        rw [Nat.sub_dist]
        apply Nat.sub_lt
        exact Nat.zero_lt_sub_of_lt h
        assumption
      have : i ∈ (⟨start,stop,step,h_step⟩ : Range) := ⟨h_step, h, h_i⟩
      loop start stop step h_step f (f acc i this) (i+step) (by
        cases h_i; case intro k h_i =>
        apply Exists.intro (k+1)
        simp [Nat.succ_mul]
        rw [←Nat.add_assoc, h_i]
      )
    else
      acc
  λ ⟨start,stop,step,h_step⟩ f acc =>
    loop start stop step h_step f acc start ⟨0,by simp⟩
  termination_by loop _ _ i _ => stop - i

def last (r : Range) := r.start + ((r.stop - r.start) / r.step) * r.step

theorem mem_last (r : Range) : r.last ∈ r := by
  simp [last, Membership.mem]
  sorry

theorem fold_ind {start stop step : Nat}
  {f : β → (i : Nat) → i ∈ (⟨start,stop,step⟩ : Range) → β}
  {acc : β} {motive : Nat → β → Prop}
  (base : motive 0 acc)
  (ind_step : ∀ i acc, (h : i ∈ (⟨start,stop,step⟩ : Range)) → motive i acc → motive (i+step) (f acc i h))
  : motive n (fold' (⟨start,stop,step⟩ : Range) f acc)
  :=
  let rec loop i (acc : β) (h_i : i ≤ n) (h_acc : motive i acc)
    : motive i () :=
    if h:i < n then by
      unfold fold.loop
      simp [h]
      exact loop i.succ (f acc ⟨i,h⟩) h (step i acc h h_acc)
    else by
      have : i = n := (Nat.eq_or_lt_of_le h_i).elim (id) (False.elim ∘ h)
      unfold fold.loop
      simp [h]
      rw [this] at h_acc
      exact h_acc
  loop 0 acc (Nat.zero_le _) init
  termination_by loop _ _ _i => n - i


instance : Foldable Range Nat where
  fold := fold 

instance : FoldableOps Range Nat := default

instance : Foldable' Range Nat inferInstance where
  fold' := fold'

instance : Iterable Range Nat where
  ρ := Nat
  step := λ i => if h:i < n then some ⟨⟨i,h⟩,i.succ⟩ else none
  toIterator := λ _ => 0
-/

end Range.Complex

end LeanColls