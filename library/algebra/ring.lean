/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Leonardo de Moura

Structures with multiplicative and additive components, including semirings, rings, and fields.
The development is modeled after Isabelle's library.
-/

import logic.eq logic.connectives data.unit data.sigma data.prod
import algebra.binary algebra.group
open eq eq.ops

variable {A : Type}

/- auxiliary classes -/

structure distrib [class] (A : Type) extends has_mul A, has_add A :=
(left_distrib : ∀a b c, mul a (add b c) = add (mul a b) (mul a c))
(right_distrib : ∀a b c, mul (add a b) c = add (mul a c) (mul b c))

theorem left_distrib [distrib A] (a b c : A) : a * (b + c) = a * b + a * c :=
!distrib.left_distrib

theorem right_distrib [distrib A] (a b c : A) : (a + b) * c = a * c + b * c :=
!distrib.right_distrib

structure mul_zero_class [class] (A : Type) extends has_mul A, has_zero A :=
(zero_mul : ∀a, mul zero a = zero)
(mul_zero : ∀a, mul a zero = zero)

theorem zero_mul [simp] [mul_zero_class A] (a : A) : 0 * a = 0 := !mul_zero_class.zero_mul
theorem mul_zero [simp] [mul_zero_class A] (a : A) : a * 0 = 0 := !mul_zero_class.mul_zero

structure zero_ne_one_class [class] (A : Type) extends has_zero A, has_one A :=
(zero_ne_one : zero ≠ one)

theorem zero_ne_one [s: zero_ne_one_class A] : 0 ≠ (1:A) := @zero_ne_one_class.zero_ne_one A s

/- semiring -/

structure semiring [class] (A : Type) extends add_comm_monoid A, monoid A, distrib A,
    mul_zero_class A

section semiring
  variables [s : semiring A] (a b c : A)
  include s

  theorem one_add_one_eq_two : 1 + 1 = (2:A) :=
  by unfold bit0

  theorem ne_zero_of_mul_ne_zero_right {a b : A} (H : a * b ≠ 0) : a ≠ 0 :=
  suppose a = 0,
  have a * b = 0, by rewrite [this, zero_mul],
  H this

  theorem ne_zero_of_mul_ne_zero_left {a b : A} (H : a * b ≠ 0) : b ≠ 0 :=
  suppose b = 0,
  have a * b = 0, by rewrite [this, mul_zero],
  H this

  local attribute right_distrib [simp]

  theorem distrib_three_right (a b c d : A) : (a + b + c) * d = a * d + b * d + c * d :=
  by simp
end semiring

/- comm semiring -/

structure comm_semiring [class] (A : Type) extends semiring A, comm_monoid A
-- TODO: we could also define a cancelative comm_semiring, i.e. satisfying
-- c ≠ 0 → c * a = c * b → a = b.

section comm_semiring
  variables [s : comm_semiring A] (a b c : A)
  include s

  protected definition algebra.dvd (a b : A) : Prop := ∃c, b = a * c

  definition comm_semiring_has_dvd [instance] [priority algebra.prio] : has_dvd A :=
  has_dvd.mk algebra.dvd

  theorem dvd.intro {a b c : A} (H : a * c = b) : a ∣ b :=
  exists.intro _ H⁻¹

  theorem dvd_of_mul_right_eq {a b c : A} (H : a * c = b) : a ∣ b := dvd.intro H

  theorem dvd.intro_left {a b c : A} (H : c * a = b) : a ∣ b :=
  dvd.intro (by rewrite mul.comm at H; exact H)

  theorem dvd_of_mul_left_eq {a b c : A} (H : c * a = b) : a ∣ b := dvd.intro_left H

  theorem exists_eq_mul_right_of_dvd {a b : A} (H : a ∣ b) : ∃c, b = a * c := H

  theorem dvd.elim {P : Prop} {a b : A} (H₁ : a ∣ b) (H₂ : ∀c, b = a * c → P) : P :=
  exists.elim H₁ H₂

  theorem exists_eq_mul_left_of_dvd {a b : A} (H : a ∣ b) : ∃c, b = c * a :=
  dvd.elim H (take c, assume H1 : b = a * c, exists.intro c (H1 ⬝ !mul.comm))

  theorem dvd.elim_left {P : Prop} {a b : A} (H₁ : a ∣ b) (H₂ : ∀c, b = c * a → P) : P :=
  exists.elim (exists_eq_mul_left_of_dvd H₁) (take c, assume H₃ : b = c * a, H₂ c H₃)

  theorem dvd.refl [simp] : a ∣ a :=
  dvd.intro !mul_one

  theorem dvd.trans {a b c : A} (H₁ : a ∣ b) (H₂ : b ∣ c) : a ∣ c :=
  dvd.elim H₁
    (take d, assume H₃ : b = a * d,
      dvd.elim H₂
        (take e, assume H₄ : c = b * e,
          dvd.intro
            (show a * (d * e) = c, by rewrite [-mul.assoc, -H₃, H₄])))

  theorem eq_zero_of_zero_dvd {a : A} (H : 0 ∣ a) : a = 0 :=
    dvd.elim H (take c, assume H' : a = 0 * c, H' ⬝ !zero_mul)

  theorem dvd_zero [simp] : a ∣ 0 := dvd.intro !mul_zero

  theorem one_dvd [simp] : 1 ∣ a := dvd.intro !one_mul

  theorem dvd_mul_right [simp] : a ∣ a * b := dvd.intro rfl

  theorem dvd_mul_left [simp] : a ∣ b * a :=
  by simp

  theorem dvd_mul_of_dvd_left {a b : A} (H : a ∣ b) (c : A) : a ∣ b * c :=
  dvd.elim H
    (take d,
      suppose b = a * d,
      dvd.intro
        (show a * (d * c) = b * c, by simp))

  theorem dvd_mul_of_dvd_right {a b : A} (H : a ∣ b) (c : A) : a ∣ c * b :=
  !mul.comm ▸ (dvd_mul_of_dvd_left H _)

  theorem mul_dvd_mul {a b c d : A} (dvd_ab : a ∣ b) (dvd_cd : c ∣ d) : a * c ∣ b * d :=
  dvd.elim dvd_ab
    (take e, suppose b = a * e,
      dvd.elim dvd_cd
        (take f, suppose d = c * f,
          dvd.intro
            (show a * c * (e * f) = b * d,
             by simp)))

  theorem dvd_of_mul_right_dvd {a b c : A} (H : a * b ∣ c) : a ∣ c :=
  dvd.elim H (take d, assume Habdc : c = a * b * d, dvd.intro (!mul.assoc⁻¹ ⬝ Habdc⁻¹))

  theorem dvd_of_mul_left_dvd {a b c : A} (H : a * b ∣ c) : b ∣ c :=
  dvd_of_mul_right_dvd (mul.comm a b ▸ H)

  theorem dvd_add {a b c : A} (Hab : a ∣ b) (Hac : a ∣ c) : a ∣ b + c :=
  dvd.elim Hab
    (take d, suppose b = a * d,
      dvd.elim Hac
        (take e, suppose c = a * e,
          dvd.intro (show a * (d + e) = b + c,
                     by rewrite [left_distrib]; substvars)))
end comm_semiring

/- ring -/

structure ring [class] (A : Type) extends add_comm_group A, monoid A, distrib A

theorem ring.mul_zero [simp] [ring A] (a : A) : a * 0 = 0 :=
have a * 0 + 0 = a * 0 + a * 0, from calc
  a * 0 + 0 = a * (0 + 0)   : by simp
        ... = a * 0 + a * 0 : by rewrite left_distrib,
show a * 0 = 0, from (add.left_cancel this)⁻¹

theorem ring.zero_mul [simp] [ring A] (a : A) : 0 * a = 0 :=
have 0 * a + 0 = 0 * a + 0 * a, from calc
  0 * a + 0 = (0 + 0) * a   : by simp
        ... = 0 * a + 0 * a : by rewrite right_distrib,
show 0 * a = 0, from  (add.left_cancel this)⁻¹

definition ring.to_semiring [trans_instance] [s : ring A] : semiring A :=
⦃ semiring, s,
  mul_zero := ring.mul_zero,
  zero_mul := ring.zero_mul ⦄

section
  variables [s : ring A] (a b c d e : A)
  include s

  theorem neg_mul_eq_neg_mul : -(a * b) = -a * b :=
  neg_eq_of_add_eq_zero
    begin
      rewrite [-right_distrib, add.right_inv, zero_mul]
    end

  theorem neg_mul_eq_mul_neg : -(a * b) = a * -b :=
   neg_eq_of_add_eq_zero
     begin
       rewrite [-left_distrib, add.right_inv, mul_zero]
     end

  theorem neg_mul_eq_neg_mul_symm [simp] : - a * b = - (a * b) := eq.symm !neg_mul_eq_neg_mul
  theorem mul_neg_eq_neg_mul_symm [simp] : a * - b = - (a * b) := eq.symm !neg_mul_eq_mul_neg

  theorem neg_mul_neg : -a * -b = a * b :=
  by simp

  theorem neg_mul_comm : -a * b = a * -b :=
  by simp

  theorem neg_eq_neg_one_mul : -a = -1 * a :=
  by simp

  theorem mul_sub_left_distrib : a * (b - c) = a * b - a * c :=
  calc
    a * (b - c) = a * b + a * -c : left_distrib
            ... = a * b - a * c  : by simp

  theorem mul_sub_right_distrib : (a - b) * c = a * c - b * c :=
  calc
    (a - b) * c = a * c  + -b * c : right_distrib
            ... = a * c - b * c   : by simp

  -- TODO: can calc mode be improved to make this easier?
  -- TODO: there is also the other direction. It will be easier when we
  -- have the simplifier.

  theorem mul_add_eq_mul_add_iff_sub_mul_add_eq : a * e + c = b * e + d ↔ (a - b) * e + c = d :=
  calc
    a * e + c = b * e + d ↔ a * e + c = d + b * e : by rewrite {b*e+_}add.comm
      ... ↔ a * e + c - b * e = d : iff.symm !sub_eq_iff_eq_add
      ... ↔ a * e - b * e + c = d : by rewrite sub_add_eq_add_sub
      ... ↔ (a - b) * e + c = d   : by rewrite mul_sub_right_distrib

  theorem mul_add_eq_mul_add_of_sub_mul_add_eq : (a - b) * e + c = d → a * e + c = b * e + d :=
  iff.mpr !mul_add_eq_mul_add_iff_sub_mul_add_eq

  theorem sub_mul_add_eq_of_mul_add_eq_mul_add : a * e + c = b * e + d → (a - b) * e + c = d :=
  iff.mp !mul_add_eq_mul_add_iff_sub_mul_add_eq

  theorem mul_neg_one_eq_neg : a * (-1) = -a :=
    have a + a * -1 = 0, from calc
      a + a * -1 = a * 1 + a * -1 : by simp
             ... = a * (1 + -1)   : left_distrib
             ... = 0              : by simp,
    symm (neg_eq_of_add_eq_zero this)

  theorem ne_zero_and_ne_zero_of_mul_ne_zero {a b : A} (H : a * b ≠ 0) : a ≠ 0 ∧ b ≠ 0 :=
    have a ≠ 0, from
      (suppose a = 0,
        have a * b = 0, by rewrite [this, zero_mul],
        absurd this H),
    have b ≠ 0, from
      (suppose b = 0,
        have a * b = 0, by rewrite [this, mul_zero],
        absurd this H),
    and.intro `a ≠ 0` `b ≠ 0`
end

structure comm_ring [class] (A : Type) extends ring A, comm_semigroup A

definition comm_ring.to_comm_semiring [trans_instance] [s : comm_ring A] : comm_semiring A :=
⦃ comm_semiring, s,
  mul_zero := mul_zero,
  zero_mul := zero_mul ⦄

section
  variables [s : comm_ring A] (a b c d e : A)
  include s

  local attribute left_distrib right_distrib [simp]

  theorem mul_self_sub_mul_self_eq : a * a - b * b = (a + b) * (a - b) :=
  by simp

  theorem mul_self_sub_one_eq : a * a - 1 = (a + 1) * (a - 1) :=
  by simp

  theorem add_mul_self_eq : (a + b) * (a + b) = a*a + 2*a*b + b*b :=
  calc (a + b)*(a + b) = a*a + (1+1)*a*b + b*b : by simp
               ...     = a*a + 2*a*b + b*b     : by rewrite one_add_one_eq_two

  theorem dvd_neg_iff_dvd : (a ∣ -b) ↔ (a ∣ b) :=
  iff.intro
    (suppose a ∣ -b,
      dvd.elim this
        (take c, suppose -b = a * c,
          dvd.intro
            (show a * -c = b,
             by rewrite [-neg_mul_eq_mul_neg, -this, neg_neg])))
    (suppose a ∣ b,
      dvd.elim this
        (take c, suppose b = a * c,
          dvd.intro
            (show a * -c = -b,
             by rewrite [-neg_mul_eq_mul_neg, -this])))

  theorem dvd_neg_of_dvd : (a ∣ b) → (a ∣ -b) :=
  iff.mpr !dvd_neg_iff_dvd

  theorem dvd_of_dvd_neg : (a ∣ -b) → (a ∣ b) :=
  iff.mp !dvd_neg_iff_dvd

  theorem neg_dvd_iff_dvd : (-a ∣ b) ↔ (a ∣ b) :=
  iff.intro
    (suppose -a ∣ b,
      dvd.elim this
        (take c, suppose b = -a * c,
          dvd.intro
            (show a * -c = b, by rewrite [-neg_mul_comm, this])))
    (suppose a ∣ b,
      dvd.elim this
        (take c, suppose b = a * c,
          dvd.intro
            (show -a * -c = b, by rewrite [neg_mul_neg, this])))

  theorem neg_dvd_of_dvd : (a ∣ b) → (-a ∣ b) :=
  iff.mpr !neg_dvd_iff_dvd

  theorem dvd_of_neg_dvd : (-a ∣ b) → (a ∣ b) :=
  iff.mp !neg_dvd_iff_dvd

  theorem dvd_sub (H₁ : (a ∣ b)) (H₂ : (a ∣ c)) : (a ∣ b - c) :=
  dvd_add H₁ (!dvd_neg_of_dvd H₂)
end

/- integral domains -/

structure no_zero_divisors [class] (A : Type) extends has_mul A, has_zero A :=
(eq_zero_or_eq_zero_of_mul_eq_zero : ∀a b, mul a b = zero → a = zero ∨ b = zero)

theorem eq_zero_or_eq_zero_of_mul_eq_zero {A : Type} [no_zero_divisors A] {a b : A}
    (H : a * b = 0) :
  a = 0 ∨ b = 0 :=
!no_zero_divisors.eq_zero_or_eq_zero_of_mul_eq_zero H

theorem eq_zero_of_mul_self_eq_zero {A : Type} [no_zero_divisors A] {a : A} (H : a * a = 0) :
  a = 0 :=
or.elim (eq_zero_or_eq_zero_of_mul_eq_zero H) (assume H', H') (assume H', H')

structure integral_domain [class] (A : Type) extends comm_ring A, no_zero_divisors A,
    zero_ne_one_class A

section
  variables [s : integral_domain A] (a b c d e : A)
  include s

  theorem mul_ne_zero {a b : A} (H1 : a ≠ 0) (H2 : b ≠ 0) : a * b ≠ 0 :=
  suppose a * b = 0,
  or.elim (eq_zero_or_eq_zero_of_mul_eq_zero this) (assume H3, H1 H3) (assume H4, H2 H4)

  theorem eq_of_mul_eq_mul_right {a b c : A} (Ha : a ≠ 0) (H : b * a = c * a) : b = c :=
  have b * a - c * a = 0, from iff.mp !eq_iff_sub_eq_zero H,
  have (b - c) * a = 0, by rewrite [mul_sub_right_distrib, this],
  have b - c = 0, from or_resolve_left (eq_zero_or_eq_zero_of_mul_eq_zero this) Ha,
  iff.elim_right !eq_iff_sub_eq_zero this

  theorem eq_of_mul_eq_mul_left {a b c : A} (Ha : a ≠ 0) (H : a * b = a * c) : b = c :=
  have a * b - a * c = 0, from iff.mp !eq_iff_sub_eq_zero H,
  have a * (b - c) = 0, by rewrite [mul_sub_left_distrib, this],
  have b - c = 0, from or_resolve_right (eq_zero_or_eq_zero_of_mul_eq_zero this) Ha,
  iff.elim_right !eq_iff_sub_eq_zero this

  -- TODO: do we want the iff versions?

  theorem eq_zero_of_mul_eq_self_right {a b : A} (H₁ : b ≠ 1) (H₂ : a * b = a) : a = 0 :=
  have b - 1 ≠ 0, from
    suppose b - 1 = 0, H₁ (!zero_add ▸ eq_add_of_sub_eq this),
  have a * b - a = 0,   by simp,
  have a * (b - 1) = 0, by rewrite [mul_sub_left_distrib, mul_one]; apply this,
    show a = 0, from or_resolve_left (eq_zero_or_eq_zero_of_mul_eq_zero this) `b - 1 ≠ 0`

  theorem eq_zero_of_mul_eq_self_left {a b : A} (H₁ : b ≠ 1) (H₂ : b * a = a) : a = 0 :=
    eq_zero_of_mul_eq_self_right H₁ (!mul.comm ▸ H₂)

  theorem mul_self_eq_mul_self_iff (a b : A) : a * a = b * b ↔ a = b ∨ a = -b :=
  iff.intro
    (suppose a * a = b * b,
      have (a - b) * (a + b) = 0,
        by rewrite [mul.comm, -mul_self_sub_mul_self_eq, this, sub_self],
      have a - b = 0 ∨ a + b = 0, from !eq_zero_or_eq_zero_of_mul_eq_zero this,
      or.elim this
        (suppose a - b = 0, or.inl (eq_of_sub_eq_zero this))
        (suppose a + b = 0, or.inr (eq_neg_of_add_eq_zero this)))
    (suppose a = b ∨ a = -b, or.elim this
      (suppose a = b,  by rewrite this)
      (suppose a = -b, by rewrite [this, neg_mul_neg]))

  theorem mul_self_eq_one_iff (a : A) : a * a = 1 ↔ a = 1 ∨ a = -1 :=
  have a * a = 1 * 1 ↔ a = 1 ∨ a = -1, from mul_self_eq_mul_self_iff a 1,
  by rewrite mul_one at this; exact this

  -- TODO: c - b * c → c = 0 ∨ b = 1 and variants

  theorem dvd_of_mul_dvd_mul_left {a b c : A} (Ha : a ≠ 0) (Hdvd : (a * b ∣ a * c)) : (b ∣ c) :=
  dvd.elim Hdvd
    (take d,
      suppose a * c = a * b * d,
      have b * d = c, from eq_of_mul_eq_mul_left Ha (mul.assoc a b d ▸ this⁻¹),
      dvd.intro this)

  theorem dvd_of_mul_dvd_mul_right {a b c : A} (Ha : a ≠ 0) (Hdvd : (b * a ∣ c * a)) : (b ∣ c) :=
  dvd.elim Hdvd
    (take d,
      suppose c * a = b * a * d,
      have b * d * a = c * a, from by rewrite [mul.right_comm, -this],
      have b * d = c, from eq_of_mul_eq_mul_right Ha this,
      dvd.intro this)
end

namespace norm_num

local attribute bit0 bit1 add1 [reducible]
local attribute right_distrib left_distrib [simp]

theorem mul_zero [mul_zero_class A] (a : A) : a * zero = zero :=
by simp

theorem zero_mul [mul_zero_class A] (a : A) : zero * a = zero :=
by simp

theorem mul_one [monoid A] (a : A) : a * one = a :=
by simp

theorem mul_bit0 [distrib A] (a b : A) : a * (bit0 b) = bit0 (a * b) :=
by simp

theorem mul_bit0_helper [distrib A] (a b t : A) (H : a * b = t) : a * (bit0 b) = bit0 t :=
by rewrite -H; simp

theorem mul_bit1 [semiring A] (a b : A) : a * (bit1 b) = bit0 (a * b) + a :=
by simp

theorem mul_bit1_helper [semiring A] (a b s t : A) (Hs : a * b = s) (Ht : bit0 s + a  = t) :
        a * (bit1 b) = t :=
by simp

theorem subst_into_prod [has_mul A] (l r tl tr t : A) (prl : l = tl) (prr : r = tr)
        (prt : tl * tr = t) :
        l * r = t :=
by simp

theorem mk_cong (op : A → A) (a b : A) (H : a = b) : op a = op b :=
by simp

theorem neg_add_neg_eq_of_add_add_eq_zero [add_comm_group A] (a b c : A) (H : c + a + b = 0) :
        -a + -b = c :=
begin
  apply add_neg_eq_of_eq_add,
  apply neg_eq_of_add_eq_zero,
  simp
end

theorem neg_add_neg_helper [add_comm_group A] (a b c : A) (H : a + b = c) : -a + -b = -c :=
begin apply iff.mp !neg_eq_neg_iff_eq, simp end

theorem neg_add_pos_eq_of_eq_add [add_comm_group A] (a b c : A) (H : b = c + a) : -a + b = c :=
begin apply neg_add_eq_of_eq_add, simp end

theorem neg_add_pos_helper1 [add_comm_group A] (a b c : A) (H : b + c = a) : -a + b = -c :=
begin apply neg_add_eq_of_eq_add, apply eq_add_neg_of_add_eq H end

theorem neg_add_pos_helper2 [add_comm_group A] (a b c : A) (H : a + c = b) : -a + b = c :=
begin apply neg_add_eq_of_eq_add, rewrite H end

theorem pos_add_neg_helper [add_comm_group A] (a b c : A) (H : b + a = c) : a + b = c :=
by simp

theorem sub_eq_add_neg_helper [add_comm_group A] (t₁ t₂ e w₁ w₂: A) (H₁ : t₁ = w₁)
        (H₂ : t₂ = w₂) (H : w₁ + -w₂ = e) : t₁ - t₂ = e :=
by simp

theorem pos_add_pos_helper [add_comm_group A] (a b c h₁ h₂ : A) (H₁ : a = h₁) (H₂ : b = h₂)
        (H : h₁ + h₂ = c) : a + b = c :=
by simp

theorem subst_into_subtr [add_group A] (l r t : A) (prt : l + -r = t) : l - r = t :=
by simp

theorem neg_neg_helper [add_group A] (a b : A) (H : a = -b) : -a = b :=
by simp

theorem neg_mul_neg_helper [ring A] (a b c : A) (H : a * b = c) : (-a) * (-b) = c :=
by simp

theorem neg_mul_pos_helper [ring A] (a b c : A) (H : a * b = c) : (-a) * b = -c :=
by simp

theorem pos_mul_neg_helper [ring A] (a b c : A) (H : a * b = c) : a * (-b) = -c :=
by simp

end norm_num

attribute [simp]
  zero_mul mul_zero
  at simplifier.unit

attribute [simp]
  neg_mul_eq_neg_mul_symm mul_neg_eq_neg_mul_symm
  at simplifier.neg

attribute [simp]
  left_distrib right_distrib
  at simplifier.distrib
