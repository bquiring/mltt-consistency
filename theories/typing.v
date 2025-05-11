Require Import imports join.

Definition context := list tm.

Inductive lookup : nat -> context -> tm -> Prop :=
  | here : forall {A Γ}, lookup 0 (A :: Γ) (A ⟨shift⟩)
  | there : forall {n A Γ B},
      lookup n Γ A -> lookup (S n) (B :: Γ) (A ⟨shift⟩).

Definition lookup_good_renaming ξ Γ Δ :=
  forall i A, lookup i Γ A -> lookup (ξ i) Δ A⟨ξ⟩.

Derive Inversion lookup_inv with (forall i Γ A, lookup i Γ A).

Reserved Notation "Γ ⊢ a ∈ A" (at level 70).
Reserved Notation "⊢ Γ" (at level 70).

Inductive Wt : context -> tm -> tm -> Prop :=
| T_Var Γ i A :
  ⊢ Γ ->
  lookup i Γ A ->
  (* ------ *)
  Γ ⊢ (var_tm i) ∈ A

| T_Pi Γ w i A B :
  Γ ⊢ A ∈ (tUniv i) ->
  (A :: Γ) ⊢ B ∈ (tUniv i) ->
  (* --------------------- *)
  Γ ⊢ (tPi w A B) ∈ (tUniv i)

| T_Abs Γ w A a B i :
  Γ ⊢ (tPi w A B) ∈ (tUniv i) ->
  (A :: Γ) ⊢ a ∈ B ->
  (* -------------------- *)
  Γ ⊢ (tAbs w a) ∈ (tPi w A B)

| T_App Γ w a A B b :
  Γ ⊢ a ∈ (tPi w A B) ->
  Γ ⊢ b ∈ A ->
  (* -------------------- *)
  Γ ⊢ (tApp w a b) ∈ (B [ b.. ])

| T_Conv Γ a A B i :
  Γ ⊢ a ∈ A ->
  Γ ⊢ B ∈ (tUniv i) ->
  A <: B ->
  (* ----------- *)
  Γ ⊢ a ∈ B

| T_Zero Γ :
  ⊢ Γ ->
  (* --------- *)
  Γ ⊢ tZero ∈ tNat

| T_Suc Γ a :
  Γ ⊢ a ∈ tNat ->
  ⊢ Γ ->
  (* --------- *)
  Γ ⊢ tSuc a ∈ tNat

| T_Ind Γ a b c A i :
  tNat :: Γ ⊢ A ∈ tUniv i ->
  Γ ⊢ a ∈ A [tZero..] ->
  A :: tNat :: Γ ⊢ b ∈ A[tSuc (var_tm 0) .: S >> var_tm]⟨S⟩ ->
  Γ ⊢ c ∈ tNat ->
  (* ------------ *)
  Γ ⊢ tInd a b c ∈ (A [c..])

| T_Nat Γ i :
  ⊢ Γ ->
  (* ----------- *)
  Γ ⊢ tNat ∈ (tUniv i)

| T_Univ Γ i :
  ⊢ Γ ->
  (* ------------ *)
  Γ ⊢ (tUniv i) ∈ (tUniv (S i))

| T_Refl Γ a A:
  ⊢ Γ ->
  Γ ⊢ a ∈ A ->
  (* ------ *)
  Γ ⊢ tRefl ∈ (tEq a a A)

| T_Eq Γ a b A i j :
  Γ ⊢ a ∈ A ->
  Γ ⊢ b ∈ A ->
  Γ ⊢ A ∈ (tUniv j) ->
  (* ----------------------- *)
  Γ ⊢ (tEq a b A) ∈ (tUniv i)

| T_J Γ t a b p A i j C : 
  Γ ⊢ a ∈  A ->
  Γ ⊢ b ∈ A ->
  Γ ⊢ A ∈ (tUniv j) ->
  Γ ⊢ p ∈ (tEq a b A) ->
  (tEq (ren_tm shift a) (var_tm 0) (ren_tm shift A) :: A :: Γ) ⊢ C ∈ (tUniv i) ->
  Γ ⊢ t ∈ (C [tRefl .: a ..]) ->
  Γ ⊢ (tJ t a b p) ∈ (C [p .: b..])

| T_Sig Γ i A B :
  Γ ⊢ A ∈ (tUniv i) ->
  (A :: Γ) ⊢ B ∈ (tUniv i) ->
  (* --------------------- *)
  Γ ⊢ (tSig A B) ∈ (tUniv i)

| T_Pack Γ a A b B i :
  Γ ⊢ a ∈ A ->
  Γ ⊢ b ∈ B[a..] ->
  Γ ⊢ tSig A B ∈ tUniv i ->
  (* -------------------- *)
  Γ ⊢ tPack a b ∈ tSig A B

| T_Let Γ a b A B C i j :
  Γ ⊢ A ∈ tUniv j ->
  A :: Γ ⊢ B ∈ tUniv j ->
  Γ ⊢ a ∈ tSig A B ->
  B :: A :: Γ ⊢ b ∈ C[(tPack (var_tm 1) (var_tm 0)) .: (shift >> shift >> var_tm)] ->
  tSig A B :: Γ ⊢ C ∈ tUniv i ->
  (* ----------------------- *)
  Γ ⊢ tLet a b ∈ C[a ..]

with Wff : context -> Prop :=
| Wff_nil :
(* ----------------- *)
  ⊢ nil
| Wff_cons Γ A i :
  ⊢ Γ ->
  Γ ⊢ A ∈ tUniv i ->
(* ----------------- *)
  ⊢ A :: Γ
where 
  "Γ ⊢ a ∈ A" := (Wt Γ a A) and "⊢ Γ" := (Wff Γ).


Scheme wt_ind := Induction for Wt Sort Prop
    with wff_ind := Induction for Wff Sort Prop.

Combined Scheme wt_mutual from wt_ind, wff_ind.
