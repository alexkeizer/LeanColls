/-
Copyright (c) 2022 James Gallicchio.

Authors: James Gallicchio
-/

import Mathlib.Data.Nat.Basic
import Mathlib.Init.Data.Int.Basic
import Mathlib.Order.Basic
import Mathlib.Data.UInt

namespace Nat
  theorem sub_dist (x y z : Nat) : x - (y + z) = x - y - z := by
    induction z
    simp
    case succ z z_ih =>
    simp [Nat.sub_succ, Nat.add_succ, z_ih]

  theorem sub_lt_of_lt_add {x y z : Nat}
    : x < y + z → x ≥ z → x - z < y
    := by
    intro h h_z
    apply Nat.le_of_add_le_add_right
    rw [succ_add, Nat.sub_add_cancel h_z]
    assumption

  #check Nat.add_comm

  example (x y : Nat) : x ≤ (x + y) := by
    exact le_add_right x y

  theorem add_mul_div {x y z : Nat} (h_x : 0 < x)
    : (x * y + z) / x = y + z / x
    := by
    induction y generalizing z with
    | zero => simp
    | succ y ih =>
      simp only [mul_succ, Nat.add_assoc, (·/·), Div.div]
      rw [Nat.div]
      simp[h_x, Nat.add_comm, Nat.add_assoc, Nat.le_add_right]
      conv in z + x * y => {rw[Nat.add_comm]}
      simp[(·/·), Div.div] at ih
      rw[ih, Nat.add_comm y]
      rfl
      

  theorem mul_div_with_rem_cancel (x : Nat) {q r : Nat} (h_r : r < q)
    : (x * q + r) / q = x
    := by
    induction x with
    | zero =>
      rw [div_eq]
      have : 0 < q := zero_lt_of_lt h_r
      simp [this, Nat.not_le_of_gt h_r]
    | succ x ih =>
      rw [div_eq]
      simp [zero_lt_of_lt h_r]
      have : q ≤ (x + 1) * q + r := by
        simp [succ_mul]
        rw [Nat.add_comm _ q, Nat.add_assoc]
        apply Nat.le_add_right
      simp [this]
      rw [succ_mul, Nat.add_assoc, Nat.add_comm q,
          ←Nat.add_assoc, Nat.add_sub_cancel]
      assumption
  
  theorem le_of_mul_of_div { x y : Nat }
    : x * (y / x) ≤ y
    := by
    apply Nat.le_of_add_le_add_right (b := y % x)
    rw [div_add_mod]
    apply Nat.le_add_right

  /-
  theorem lt_of_mul_lt {x y z : Nat} (h_z : 0 < z)
    : x < y * z → x / z < y
    := by
    intro h
    by_cases x / z < y
    case pos h_res =>
      assumption
    case neg h_res =>
      rw [←div_add_mod x z] at h
      apply False.elim $ Nat.not_le_of_gt h _
      clear h h_z
      rw [Nat.mul_comm]
      suffices z * y ≤ z * (x / z) from
        Nat.le_trans this $ Nat.le_add_right _ (x % z)
      apply Nat.mul_le_mul_left z
      exact Nat.ge_of_not_lt h_res
  -/

  theorem lt_of_lt_le {x y z : Nat} : x < y → y ≤ z → x < z := by
    intro h h'
    induction h'
    assumption
    apply Nat.le_step
    assumption

  theorem min_symm (x y : Nat) : min x y = min y x := by
    exact Nat.min_comm x y

  @[simp]
  theorem min_zero_left {x} : min 0 x = 0 := by
    rw [←Nat.le_zero_eq]
    exact min_le_left _ _

  @[simp]
  theorem min_zero_right {x} : min x 0 = 0 := by
    rw [←Nat.le_zero_eq]
    exact Nat.min_le_right x 0

  def toUSize! (n : Nat) : USize :=
    if n < USize.size then
      n.toUSize
    else
      panic! s!"Integer {n} is to larget for usize"

  theorem mod_lt_of_lt {x y z : Nat}
    : x < y → z > 0 → x % z < y
    := by
    intro h h_z
    match h_y : decide (y ≤ z) with
    | true =>
      have := of_decide_eq_true h_y
      rw [Nat.mod_eq_of_lt (Nat.lt_of_lt_le h this)]
      assumption
    | false =>
      have := of_decide_eq_false h_y
      apply Nat.lt_trans _ (Nat.gt_of_not_le this)
      apply Nat.mod_lt
      assumption

  @[inline]
  def square (n : Nat) := n * n

  theorem square_sqrt_le (n)
    : square (sqrt n) ≤ n
    :=

    match n with
    | 0 | 1 => by simp
    | n+2 => by sorry
    -- let rec iter n (guess) (g_pos : guess > 0) (g_le_n : guess ≤ n)
    --   : square (sqrt.iter n guess) ≤ n
    --   := 
  --     if h : (guess + n / guess) / 2 < guess then by
  --       unfold sqrt.iter
  --       simp [h, square]
  --       sorry
  --       stop
  --       apply (le_div_iff_mul_le g_pos).mp
  --       apply Nat.le_of_add_le_add_left (a := guess)
  --       rw [(by simp [succ_mul] : guess + guess = 2 * guess)]
  --       rw [mul_comm]
  --       apply (le_div_iff_mul_le (by decide)).mp
  --       exact h
  --     else
  --       by 
  --       sorry
  --       stop
  --       have : next < guess := Nat.gt_of_not_le h
  --       have next_pos : next > 0 := by
  --         have : n / guess = succ _ := by
  --           conv => lhs; simp [Div.div, HDiv.hDiv]; unfold Nat.div
  --           simp [g_pos, g_le_n]
  --           rfl
  --         cases guess <;> simp at this
  --         simp [this, succ_add, add_succ]
  --         simp [succ_eq_add_one, add_assoc]
  --         rw [(by decide : 1 + 1 = 2)]
  --         simp [←add_assoc]
  --         apply succ_le_succ (zero_le _)
  --       have next_le_n : next ≤ n := by
  --         simp
  --         apply Nat.div_le_of_le_mul
  --         simp [succ_mul]
  --         apply Nat.add_le_add
  --         assumption
  --         apply Nat.div_le_self
  --       have := iter n next next_pos next_le_n
  --       by unfold sqrt.iter; simp [h, this]
  --   have := iter (n+2) ((n+2)/2)
  --     (by simp; apply succ_le_succ; simp)
  --     (Nat.div_le_self _ _)
  --   by simp [sqrt] at this ⊢; exact this
  -- termination_by iter guess _ _ => guess

  theorem square_succ_sqrt_gt (n)
    : n < square ((sqrt n)+1)
    := by sorry
  --   match n with
  --   | 0 | 1 => by simp
  --   | n+2 =>
  --   let rec iter n (guess) (g_succ_gt_n : square (guess+1) > n)
  --     : n < square (sqrt.iter n guess + 1)
  --     :=
  --     let next := (guess + n / guess) / 2
  --     if h : guess ≤ next then by
  --       unfold sqrt.iter
  --       simp [h, g_succ_gt_n]
  --     else
  --       have : next < guess := Nat.gt_of_not_le h
  --       have : square (next + 1) > n := by
  --         have : square (next + 1) ≤ square guess := by sorry
  --         have : n < square guess := by sorry
  --         sorry
  --       have := iter n next this
  --       by unfold sqrt.iter; simp [h, this]
  --   have := iter (n+2) ((n+2)/2) (by
  --     simp [square]
  --     have : n ≤ 2 * (n / 2) + 1 := by
  --       apply Nat.le_trans (m := 2 * (n / 2) + n % 2)
  --       rw [Nat.div_add_mod]; apply Nat.le_refl
  --       apply Nat.add_le_add; apply Nat.le_refl
  --       apply Nat.le_of_succ_le_succ
  --       simp [(by decide : succ 1 = 2)]
  --       apply Nat.mod_lt
  --       decide
  --     simp [succ_mul, mul_succ] at this ⊢
  --     simp [succ_add, add_succ]
  --     apply succ_le_succ; apply succ_le_succ; apply succ_le_succ
  --     apply Nat.le_trans this
  --     apply succ_le_succ
  --     simp
  --     apply Nat.add_le_add_right
  --     apply Nat.le_add_left)
  --   by simp [sqrt] at this ⊢; exact this
  -- termination_by iter guess _ _ => guess


#eval sqrt 0
#eval (7 + 15 / 7) / 2

end Nat

namespace Fin

@[simp]
def embed_add_right : Fin n → Fin (n+m)
| ⟨i, h⟩ => ⟨i, Nat.lt_of_lt_le h (Nat.le_add_right _ _)⟩

@[simp]
def embed_add_left : Fin n → Fin (m+n)
| ⟨i, h⟩ => ⟨i, Nat.lt_of_lt_le h (Nat.le_add_left _ _)⟩

@[simp]
def embed_succ : Fin n → Fin n.succ
| ⟨i, h⟩ => ⟨i, Nat.lt_of_lt_le h (Nat.le_step $ Nat.le_refl _)⟩

end Fin

namespace Int

theorem ofNat_natAbs_eq_neg_of_nonpos (a : Int) (h : a ≤ 0)
  : ofNat (natAbs a) = -a
  := by
  rw [←Int.natAbs_neg]
  apply Int.ofNat_natAbs_eq_of_nonneg
  apply Int.neg_le_neg h

end Int

namespace USize

theorem usize_bounded : USize.size ≤ UInt64.size := by
  cases usize_size_eq <;> (
    rw [(by assumption : USize.size = _)]
    decide
  )

end USize

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
    simp at ih ⊢
    simp [back?, ih]

  theorem concat_nonempty (L : List τ)
    : L.concat x ≠ []
    := by
    induction L
    simp [concat]
    simp [concat]

  theorem back_some_iff_concat (L : List τ)
    : L.back? = some (ts,t) ↔ L = ts.concat t
    := by
    apply Iff.intro
    case mpr =>
      intro h; rw [h, back_concat]
    case mp =>
    induction ts generalizing L
    case nil =>
      simp [concat]
      intro h
      match L with
      | [] => contradiction
      | [t] => simp [back?] at h; simp [h]
      | _::_::_ => simp [back?] at h
    case cons head tail ih =>
      simp [concat]
      intro h
      match L with
      | [] => contradiction
      | [x] => simp [back?] at h
      | x::y::z =>
        have ihh : back? (y::z) = some (tail, t) := by
          simp [back?] at h
          cases h; case intro l r =>
          simp [back?]
          match h:back? z with
          | none =>
            simp [h] at l r
            simp [l,r]
          | some (ts',t') =>
            simp [h] at l r ⊢
            simp [l,r]
        have := ih _ ihh
        rw [this]; simp; clear this
        unfold back? at h
        simp [ihh] at h
        assumption
  
  @[simp]
  theorem get_of_set_eq (L : List τ) (i : Fin L.length) (x : τ)
    : (L.set i x).get ⟨i, by rw [length_set]; exact i.isLt⟩ = x
    := by
      induction L
      simp at i; exact Fin.elim0 i
      case cons hd tl ih =>
      cases i; case mk i h_i =>
      cases i
      simp [set,get]
      case succ i =>
      simp at h_i
      have h_i := Nat.lt_of_succ_lt_succ h_i
      have := ih ⟨i,h_i⟩
      simp at this
      simp [set,get]
  
  @[simp]
  theorem get_of_set_ne (L : List τ) (i : Nat) (x : τ) (j : Fin L.length)
    : i ≠ j → (L.set i x).get ⟨j, by rw [length_set]; exact j.isLt⟩ = L.get j
    := by
      intro h
      induction L generalizing i
      simp at j; exact Fin.elim0 j
      case cons hd tl ih =>
      cases j; case mk j h_j =>
      cases j
      simp at h
      cases i; contradiction
      simp [set,get]
      case succ j =>
      simp at h_j
      simp
      cases i
      simp [set,get]
      case succ i =>
      simp [set,get]
      simp at h
      have h_j := Nat.lt_of_succ_lt_succ h_j
      have := ih i ⟨j,h_j⟩ h
      exact this
  
  theorem set_of_ge_length (L : List α) (i x) (h : ¬i < L.length)
    : L.set i x = L
    := by
    induction L generalizing i
    simp
    case cons hd tl ih =>
    cases i
    simp at h
    simp at h
    simp
    apply ih
    apply Nat.not_lt_of_le
    apply Nat.le_of_succ_le_succ h
  
  theorem set_append_left (L1 L2 : List α) (i x) (h : i < L1.length)
    : (L1 ++ L2).set i x = L1.set i x ++ L2
    := by
    induction L1 generalizing i with
    | nil => simp at h
    | cons hd tl ih =>
    match i with
    | 0 =>
      simp at h
      simp [set]
    | i+1 =>
      simp at h
      simp [set]
      apply ih
      apply Nat.le_of_succ_le_succ h

  theorem set_append_right (L1 L2 : List α) (i x) (h : L1.length ≤ i)
    : (L1 ++ L2).set i x = L1 ++ L2.set (i - L1.length) x
    := by
    induction L1 generalizing i with
    | nil => simp [set]
    | cons hd tl ih =>
    match i with
    | 0 =>
      simp at h
    | i+1 =>
      simp at h
      simp [set]
      apply ih
      apply Nat.le_of_succ_le_succ h
  
  theorem map_set {L : List τ} {i x} {f : τ → τ'}
    : (L.set i x).map f = (L.map f).set i (f x)
    := by
    induction L generalizing i with
    | nil => simp
    | cons y ys ih =>
      cases i
      simp [set]
      simp [ih]
  
  theorem set_map {L : List τ} (x') (h : x = f x')
    : (L.map f).set i x = (L.set i x').map f
    := by
    induction L generalizing i with
    | nil => simp
    | cons y ys ih =>
      cases i
      simp [set]; assumption
      simp [set, ih]

  def subtypeByMem (L : List α) : List {a // a ∈ L} :=
    let rec aux (rest : List α) (h : ∀ a, a ∈ rest → a ∈ L)
      : List {a // a ∈ L} :=
      match rest, h with
      | [], _ => []
      | (x::xs), h =>
        ⟨x, h _ (List.Mem.head _)⟩ ::
        aux xs (by intros; apply h; apply List.Mem.tail; assumption)
    aux L (by intros; assumption)

  theorem length_subtypeByMemAux (L rest : List α) (h)
    : (List.subtypeByMem.aux L rest h).length = rest.length
    := by
      induction rest
      simp [subtypeByMem.aux]
      case cons hd tl ih =>
      simp [subtypeByMem.aux]
      apply ih

  @[simp]
  theorem length_subtypeByMem (L : List α)
    : L.subtypeByMem.length = L.length
    := by apply length_subtypeByMemAux

  @[simp]
  theorem get_subtypeByMem (L : List α) (i : Fin L.subtypeByMem.length)
    : L.subtypeByMem.get i = L.get ⟨i, by cases i; case mk _ h => simp at h; assumption⟩
    := by
    simp [subtypeByMem]
    suffices ∀ L' hL' i (hi : i < length L'),
      (get (subtypeByMem.aux L L' hL') ⟨i, by
        simp [length_subtypeByMemAux] at hi ⊢
        exact hi⟩).val =
      get L' ⟨i, hi⟩
      from this L (by simp) i (by cases i; case mk _ h => simp at h; assumption)
    intro L' hL' i hi
    induction L' generalizing i with
    | nil =>
      simp [subtypeByMem.aux]
      unfold get
      split <;> split <;> contradiction
    | cons x xs ih =>
      simp [subtypeByMem.aux]
      unfold get
      split
      case h_1 a b c d e f g =>
        simp at f
        cases f; case intro f1 f2 =>
        cases f1
        cases f2
        simp at g
        split
        case h_1 h i j k l m n o =>
          cases n
          rfl
        case h_2 h i j k l m n o =>
          cases n
          cases o
          contradiction
      case h_2 a b c d e f g =>
        simp at f
        cases f; case intro f1 f2 =>
        cases f1
        cases f2
        simp at g
        split
        case h_1 h i j k l m n o =>
          cases n
          cases o
          contradiction
        case h_2 h i j k l m n o =>
          cases n
          cases o
          cases g
          simp at e
          apply ih

  def index_of_mem (L : List α) (x) (h : x ∈ L) : ∃ i, L.get i = x := by
    induction L
    cases h
    case cons hd tl ih =>
    cases h
    apply Exists.intro ⟨0,by apply Nat.succ_le_succ; exact Nat.zero_le _⟩
    simp [get]
    cases ih (by assumption)
    case intro w h =>
    apply Exists.intro w.succ
    simp [get]
    exact h
  
  theorem get_of_take (L : List α) (n i) (h : n ≤ L.length)
    : (L.take n).get i = L.get ⟨i.val, by
        apply Nat.le_trans i.isLt
        simp [length_take]
      ⟩
    := by
    induction L generalizing n
    case nil =>
      cases n <;> (
        simp [length, take] at i
        exact Fin.elim0 i
      )
    case cons hd tl ih =>
    cases n
    case zero =>
      simp [length, take] at i
      exact Fin.elim0 i
    case succ n =>
      cases i; case mk i h_i =>
      cases i
      case zero =>
        simp [get, take]
      case succ i =>
        simp [get, take]
        apply ih
        simp [length] at h
        exact Nat.le_of_succ_le_succ h

  theorem get_map_reverse (f : α → β) {l n}
    : f (get l n) = get (map f l) ⟨n, by simp [n.isLt]⟩
    := by simp


  theorem foldl_acc_cons (L : List τ) (f : _ → _) (x') (acc : List τ')
    : L.foldl (fun acc x => acc ++ f x) (x' :: acc)
      = x' :: L.foldl (fun acc x => acc ++ f x) acc
    := by
    induction L generalizing acc with
    | nil => simp [foldl]
    | cons x xs ih =>
      unfold foldl
      rw [List.cons_append, ih]

  theorem foldl_eq_reverseAux (L : List τ) (acc)
    : L.foldl (fun acc x => x :: acc) acc = L.reverseAux acc
    := by
    induction L generalizing acc with
    | nil => simp [foldl]
    | cons x xs ih =>
      unfold foldl
      apply ih

  theorem foldl_eq_map (L : List τ) (f : τ → τ')
    : L.foldl (fun acc x => acc ++ [f x]) [] = L.map f
    := by
    induction L with
    | nil => simp [foldl]
    | cons x xs ih =>
      unfold foldl
      simp [foldl_acc_cons]
      apply ih

  theorem foldl_eq_filter (L : List τ) (f : τ → Bool)
    : L.foldl (fun acc x => acc ++ if f x then [x] else []) [] = L.filter f
    := by
    induction L with
    | nil => simp [filter, foldl]
    | cons x xs ih =>
      unfold foldl
      apply Eq.symm
      simp [filter]
      split <;> (
        simp [(by assumption : f x = _)]
        simp [foldl_acc_cons]
        apply ih.symm
      )

  theorem foldl_filter (L : List τ) (f : τ → Bool) (foldF) (foldAcc : β)
    : (L.filter f).foldl foldF foldAcc =
      L.foldl (fun acc x => if f x then foldF acc x else acc) foldAcc
    := by
    induction L generalizing foldAcc with
    | nil => simp [foldl]
    | cons x xs ih =>
      unfold filter
      split
      case cons.h_1 h =>
        simp [h, foldl, ih]
      case cons.h_2 h =>
        simp [h, foldl, ih]
  
  theorem foldr_eq_map (L : List τ) (f : τ → τ')
    : L.foldr (f · :: ·) [] = L.map f
    := by induction L <;> simp; assumption
  
  theorem foldr_eq_filter (L : List τ) (f : τ → Bool)
    : L.foldr (fun x acc => if f x then x :: acc else acc) [] = L.filter f
    := by
      induction L <;> simp [filter]
      split <;> split
      case h_1 =>
        simp; assumption
      case h_2 h _ h' =>
        rw [h] at h'; contradiction
      case h_1 =>
        contradiction
      case h_2 =>
        simp; assumption

  theorem foldr_cons_eq_foldl_append (L : List τ) (f : _ → β)
    : L.foldr (f · :: ·) [] = L.foldl (· ++ [f ·]) []
    := by rw [foldr_eq_map, foldl_eq_map]

  theorem mem_of_map_iff (L : List τ) (f : τ → τ')
    : ∀ y, y ∈ L.map f ↔ ∃ x, x ∈ L ∧ f x = y
    := by
    intro y
    induction L with
    | nil => simp
    | cons x xs =>
      simp_all
      constructor
      case mp =>
        intro h; cases h
        case inl h =>
          exact .inl h.symm
        case inr h =>
          exact .inr h
      case mpr =>
        intro h; cases h
        case inl h =>
          exact .inl h.symm
        case inr h =>
          exact .inr h

end List

inductive Vector (α : Type u) : Nat → Type u where
  | nil  : Vector α 0
  | cons : α → Vector α n → Vector α (n+1)

namespace Vector
  def ofList : (L : List τ) → Vector τ L.length
  | [] => nil
  | x::xs => cons x (ofList xs)

  def toList : (V : Vector τ n) → List τ
  | nil => []
  | cons x xs => x :: toList xs

  theorem length_toList (V : Vector τ n)
  : V.toList.length = n
  := by induction V <;> simp [toList]; assumption
end Vector

namespace Function  
  def update' {α α' : Sort u} {β : α → Sort u} (f : (a : α) → β a) (i : α) (x : α') [D : DecidableEq α]
    : (a : α) → update β i α' a
    := λ a =>
    if h:a = i
    then cast (by simp [h, update]) x
    else cast (by simp [h]) (f a)
end Function

def Cached {α : Type _} (a : α) := { b // b = a }

namespace Cached

instance {a : α} : DecidableEq (Cached a) :=
  fun ⟨x, hx⟩ ⟨y, hy⟩ => Decidable.isTrue (by cases hx; cases hy; rfl)

instance {a : α} [Repr α] : Repr (Cached a) where
  reprPrec x := Repr.addAppParen <| "cached " ++ repr x.val

instance {a : α} : Subsingleton (Cached a) :=
  ⟨by intro ⟨x, h⟩; cases h; intro ⟨y, h⟩; cases h; rfl⟩

instance {a : α} : CoeHead (Cached a) α where
  coe x := x.1

def cached (a : α) : Cached a :=
  ⟨a, rfl⟩

def cached' (a : α) (h : a = b) : Cached b :=
  ⟨a, h⟩

instance {a : α} : Inhabited (Cached a) where
  default := cached a

@[simp] theorem cached_val (a : α) (b : Cached a) : (b : α) = a := b.2

end Cached

export Cached (cached)
export Cached (cached')

def time (f : IO α) : IO (Nat × α) := do
  let pre ← IO.monoMsNow
  let ret ← f
  let post ← IO.monoMsNow
  pure (post-pre, ret)
