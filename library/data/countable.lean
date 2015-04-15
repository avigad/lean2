import data.fintype data.list data.sum data.nat
open option list nat

structure countable [class] (A : Type) :=
(pickle : A → nat) (unpickle : nat → option A) (picklek : ∀ a, unpickle (pickle a) = some a)

open countable

definition countable_fintype [instance] {A : Type} [h₁ : fintype A] [h₂ : decidable_eq A] : countable A :=
countable.mk
  (λ a, find a (elements_of A))
  (λ n, nth (elements_of A) n)
  (λ a, find_nth (fintype.complete a))

definition countable_nat [instance] : countable nat :=
countable.mk (λ a, a) (λ n, some n) (λ a, rfl)

definition countable_option [instance] {A : Type} [h : countable A] : countable (option A) :=
countable.mk
  (λ o, match o with
        | some a := succ (pickle a)
        | none := 0
        end)
  (λ n, if n = 0 then some none else some (unpickle A (pred n)))
  (λ o,
    begin
    cases o with [a],
      begin esimp end,
      begin esimp, rewrite [if_neg !succ_ne_zero, pred_succ, countable.picklek] end
    end)

section sum
variables {A B : Type}
variables [h₁ : countable A] [h₂ : countable B]
include h₁ h₂

definition pickle_sum : sum A B → nat
| (sum.inl a) := 2 * pickle a
| (sum.inr b) := 2 * pickle b + 1

definition unpickle_sum (n : nat) : option (sum A B) :=
if n mod 2 = 0 then
   match unpickle A (n div 2) with
   | some a := some (sum.inl a)
   | none   := none
   end
else
   match unpickle B ((n - 1) div 2) with
   | some b := some (sum.inr b)
   | none   := none
   end

open decidable
theorem unpickle_pickle_sum : ∀ s : sum A B, unpickle_sum (pickle_sum s) = some s
| (sum.inl a) :=
  assert aux : 2 > 0, from dec_trivial,
  begin
    esimp [pickle_sum, unpickle_sum],
    rewrite [mul_mod_right, if_pos (eq.refl 0), mul_div_cancel_left _ aux, countable.picklek]
  end
| (sum.inr b) :=
  assert aux₁ : 2 > 0,       from dec_trivial,
  assert aux₂ : 1 mod 2 = 1, by rewrite [modulo_def],
  assert aux₃ : 1 ≠ 0,       from dec_trivial,
  begin
    esimp [pickle_sum, unpickle_sum],
    rewrite [add.comm, add_mul_mod_self_left aux₁, aux₂, if_neg aux₃, add_sub_cancel_left,
             mul_div_cancel_left _ aux₁, countable.picklek]
  end

definition countable_sum [instance] {A B : Type} [h₁ : countable A] [h₂ : countable B] : countable (sum A B) :=
countable.mk
  (λ s, pickle_sum s)
  (λ n, unpickle_sum n)
  (λ s, unpickle_pickle_sum s)
end sum

section prod
variables {A B : Type}
variables [h₁ : countable A] [h₂ : countable B]
include h₁ h₂

definition pickle_prod : A × B → nat
| (a, b) := mkpair (pickle a) (pickle b)

definition unpickle_prod (n : nat) : option (A × B) :=
match unpair n with
| (n₁, n₂) :=
  match unpickle A n₁ with
  | some a :=
    match unpickle B n₂ with
    | some b := some (a, b)
    | none   := none
    end
  | none   := none
  end
end

theorem unpickle_pickle_prod : ∀ p : A × B, unpickle_prod (pickle_prod p) = some p
| (a, b) :=
  begin
    esimp [pickle_prod, unpickle_prod, prod.cases_on],
    rewrite [unpair_mkpair],
    esimp,
    rewrite [*countable.picklek]
  end

definition countable_product [instance] {A B : Type} [h₁ : countable A] [h₂ : countable B] : countable (A × B) :=
countable.mk
  pickle_prod
  unpickle_prod
  unpickle_pickle_prod
end prod

section list
variables {A : Type}
variables [h : countable A]
include h

definition pickle_list_core : list A → nat
| []     := 0
| (a::l) := mkpair (pickle a) (pickle_list_core l)

theorem pickle_list_core_cons (a : A) (l : list A) : pickle_list_core (a::l) = mkpair (pickle a) (pickle_list_core l) :=
rfl

definition pickle_list (l : list A) : nat :=
mkpair (length l) (pickle_list_core l)

definition unpickle_list_core : nat → nat → option (list A)
| 0        v  := some []
| (succ n) v  :=
  match unpair v with
  | (v₁, v₂) :=
    match unpickle A v₁ with
    | some a :=
      match unpickle_list_core n v₂ with
      | some l := some (a::l)
      | none   := none
      end
    | none   := none
    end
  end

theorem unpickle_list_core_succ (n v : nat) :
  unpickle_list_core (succ n) v =
    match unpair v with
    | (v₁, v₂) :=
      match unpickle A v₁ with
      | some a :=
        match unpickle_list_core n v₂ with
        | some l := some (a::l)
        | none   := none
        end
      | none   := none
      end
    end
:= rfl

definition unpickle_list (n : nat) : option (list A) :=
match unpair n with
| (l, v) := unpickle_list_core l v
end

theorem unpickle_pickle_list_core : ∀ l : list A, unpickle_list_core (length l) (pickle_list_core l) = some l
| []     := rfl
| (a::l) :=
  begin
    rewrite [pickle_list_core_cons, length_cons, add_one (length l), unpickle_list_core_succ],
    rewrite [unpair_mkpair],
    esimp [prod.cases_on],
    rewrite [unpickle_pickle_list_core l],
    rewrite [countable.picklek],
  end

theorem unpickle_pickle_list (l : list A) : unpickle_list (pickle_list l) = some l :=
begin
  esimp [pickle_list, unpickle_list],
  rewrite [unpair_mkpair],
  esimp [prod.cases_on],
  apply unpickle_pickle_list_core
end

definition countable_list [instance] {A : Type} [h : countable A] : countable (list A) :=
countable.mk
  pickle_list
  unpickle_list
  unpickle_pickle_list
end list