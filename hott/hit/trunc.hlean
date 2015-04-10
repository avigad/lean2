/-
Copyright (c) 2015 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Module: hit.trunc
Authors: Floris van Doorn

n-truncation of types.

Ported from Coq HoTT
-/

/- The hit n-truncation is primitive, declared in init.hit. -/

import types.sigma

open is_trunc eq equiv is_equiv function prod sum sigma

namespace trunc

  protected definition elim {n : trunc_index} {A : Type} {P : Type}
    [Pt : is_trunc n P] (H : A → P) : trunc n A → P :=
  rec H

  protected definition elim_on {n : trunc_index} {A : Type} {P : Type} (aa : trunc n A)
    [Pt : is_trunc n P] (H : A → P) : P :=
  elim H aa

exit

  variables {X Y Z : Type} {P : X → Type} (A B : Type) (n : trunc_index)

  local attribute is_trunc_eq [instance]

  definition is_equiv_tr [instance] [H : is_trunc n A] : is_equiv (@tr n A) :=
  adjointify _
             (trunc.rec id)
             (λaa, trunc.rec_on aa (λa, idp))
             (λa, idp)

  definition equiv_trunc [H : is_trunc n A] : A ≃ trunc n A :=
  equiv.mk tr _

  definition is_trunc_of_is_equiv_tr [H : is_equiv (@tr n A)] : is_trunc n A :=
  is_trunc_is_equiv_closed n tr⁻¹

  definition untrunc_of_is_trunc [reducible] [H : is_trunc n A] : trunc n A → A :=
  tr⁻¹

  /- Functoriality -/
  definition trunc_functor (f : X → Y) : trunc n X → trunc n Y :=
  λxx, trunc_rec_on xx (λx, tr (f x))
--  by intro xx; apply (trunc_rec_on xx); intro x; exact (tr (f x))
--  by intro xx; fapply (trunc_rec_on xx); intro x; exact (tr (f x))
--  by intro xx; exact (trunc_rec_on xx (λx, (tr (f x))))

  definition trunc_functor_compose (f : X → Y) (g : Y → Z)
    : trunc_functor n (g ∘ f) ∼ trunc_functor n g ∘ trunc_functor n f :=
  λxx, trunc_rec_on xx (λx, idp)

  definition trunc_functor_id : trunc_functor n (@id A) ∼ id :=
  λxx, trunc_rec_on xx (λx, idp)

  definition is_equiv_trunc_functor (f : X → Y) [H : is_equiv f] : is_equiv (trunc_functor n f) :=
  adjointify _
             (trunc_functor n f⁻¹)
             (λyy, trunc_rec_on yy (λy, ap tr !retr))
             (λxx, trunc_rec_on xx (λx, ap tr !sect))

  section
  open prod.ops
  definition trunc_prod_equiv : trunc n (X × Y) ≃ trunc n X × trunc n Y :=
  sorry
  -- equiv.MK (λpp, trunc_rec_on pp (λp, (tr p.1, tr p.2)))
  --          (λp, trunc_rec_on p.1 (λx, trunc_rec_on p.2 (λy, tr (x,y))))
  --          sorry --(λp, trunc_rec_on p.1 (λx, trunc_rec_on p.2 (λy, idp)))
  --          (λpp, trunc_rec_on pp (λp, prod.rec_on p (λx y, idp)))

  -- begin
  --   fapply equiv.MK,
  --     apply sorry, --{exact (λpp, trunc_rec_on pp (λp, (tr p.1, tr p.2)))},
  --     apply sorry, /-{intro p, cases p with (xx, yy),
  --       apply (trunc_rec_on xx), intro x,
  --       apply (trunc_rec_on yy), intro y, exact (tr (x,y))},-/
  --     apply sorry, /-{intro p, cases p with (xx, yy),
  --       apply (trunc_rec_on xx), intro x,
  --       apply (trunc_rec_on yy), intro y, apply idp},-/
  --     apply sorry --{intro pp, apply (trunc_rec_on pp), intro p, cases p, apply idp},
  -- end
  end

  /- Propositional truncation -/

  -- should this live in hprop?
  definition merely [reducible] (A : Type) : Type := trunc -1 A

  notation `||`:max A `||`:0 := merely A
  notation `∥`:max A `∥`:0   := merely A

  definition Exists [reducible] (P : X → Type) : Type := ∥ sigma P ∥
  definition or [reducible] (A B : Type) : Type := ∥ A ⊎ B ∥

  notation `exists` binders `,` r:(scoped P, Exists P) := r
  notation `∃` binders `,` r:(scoped P, Exists P) := r
  notation A `\/` B := or A B
  notation A ∨ B    := or A B

  definition merely.intro   [reducible] (a : A) : ∥ A ∥                            := tr a
  definition exists.intro   [reducible] (x : X) (p : P x) : ∃x, P x                := tr ⟨x, p⟩
  definition or.intro_left  [reducible] (x : X) : X ∨ Y                            := tr (inl x)
  definition or.intro_right [reducible] (y : Y) : X ∨ Y                            := tr (inr y)

  definition is_contr_of_merely_hprop [H : is_hprop A] (aa : merely A) : is_contr A :=
  is_contr_of_inhabited_hprop (trunc_rec_on aa id)

  section
  open sigma.ops
  definition trunc_sigma_equiv : trunc n (Σ x, P x) ≃ trunc n (Σ x, trunc n (P x)) :=
  equiv.MK (λpp, trunc_rec_on pp (λp, tr ⟨p.1, tr p.2⟩))
           (λpp, trunc_rec_on pp (λp, trunc_rec_on p.2 (λb, tr ⟨p.1, b⟩)))
           (λpp, trunc_rec_on pp (λp, sigma.rec_on p (λa bb, trunc_rec_on bb (λb, idp))))
           (λpp, trunc_rec_on pp (λp, sigma.rec_on p (λa b, idp)))

  definition trunc_sigma_equiv_of_is_trunc [H : is_trunc n X]
    : trunc n (Σ x, P x) ≃ Σ x, trunc n (P x) :=
  calc
    trunc n (Σ x, P x) ≃ trunc n (Σ x, trunc n (P x)) : trunc_sigma_equiv
      ... ≃ Σ x, trunc n (P x) : equiv.symm !equiv_trunc
  end

end trunc


  protected definition rec_on {n : trunc_index} {A : Type} {P : trunc n A → Type} (aa : trunc n A)
    [Pt : Πaa, is_trunc n (P aa)] (H : Πa, P (tr a)) : P aa :=
  trunc.rec H aa