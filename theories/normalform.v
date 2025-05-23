Require Import join imports.

(* Identifying neutral (ne) and normal (nf) terms *)
Fixpoint ne (a : tm) : bool :=
  match a with
  | var_tm _ => true
  | tApp w a b => ne a && nf b
  | tAbs w _ => false
  | tPi w A B => false
  | tJ t a b p => nf t && nf a && nf b && ne p
  | tUniv _ => false
  | tZero => false
  | tSuc _ => false
  | tInd a b c => nf a && nf b && ne c
  | tNat => false
  | tEq a b A => false
  | tRefl => false
  | tSig A B => false
  | tPack a b => false
  | tLet a b => ne a && nf b
  end
with nf (a : tm) : bool :=
  match a with
  | var_tm _ => true
  | tApp w a b => ne a && nf b
  | tAbs w a => nf a
  | tPi w A B => nf A && nf B
  | tJ t a b p => nf t && nf a && nf b && ne p
  | tUniv _ => true
  | tZero => true
  | tSuc a => nf a
  | tInd a b c => nf a && nf b && ne c
  | tNat => true
  | tEq a b A => nf a && nf b && nf A
  | tRefl => true
  | tSig A B => nf A && nf B
  | tPack a b => nf a && nf b
  | tLet a b => ne a && nf b
  end.

Function is_nat_val (a : tm) : bool :=
  match a with
  | tZero => true
  | tSuc a => is_nat_val a
  | _ => ne a
  end.

(* Terms that are weakly normalizing to a neutral or normal form. *)
Definition wn (a : tm) := exists b, a ⇒* b /\ nf b.
Definition wne (a : tm) := exists b, a ⇒* b /\ ne b.

(* All neutral terms are normal forms *)
Lemma ne_nf (a : tm) : ne a -> nf a.
Proof. elim : a =>//; hauto q:on unfold:nf inv:Par. Qed.

(* Weakly neutral implies weakly normal *)
Lemma wne_wn a : wne a -> wn a.
Proof. sfirstorder use:ne_nf. Qed.

(* Normal implies weakly normal *)
Lemma nf_wn v : nf v -> wn v.
Proof. sfirstorder ctrs:rtc. Qed.

(* natural number values are normal *)
Lemma nat_val_nf v : is_nat_val v -> nf v.
Proof. elim : v =>//=. Qed.

Lemma ne_nat_val v : ne v -> is_nat_val v.
Proof. elim : v =>//=. Qed.

(* Neutral and normal forms are stable under renaming *)
Lemma ne_nf_renaming (a : tm) :
  forall (ξ : nat -> nat),
    (ne a <-> ne (a⟨ξ⟩)) /\ (nf a <-> nf (a⟨ξ⟩)).
Proof.
  elim : a; solve [auto; hauto b:on].
Qed.

Lemma nf_refl a b (h: a ⇒ b) : (nf a -> b = a) /\ (ne a -> b = a).
Proof.
elim : a b / h => // ; hauto b:on.
Qed.

(* Normal and neural forms are preserved by parallel reduction. *)
Local Lemma nf_ne_preservation a b (h : a ⇒ b) : (nf a ==> nf b) /\ (ne a ==> ne b).
Proof.
  elim : a b / h => //; hauto lqb:on depth:2.
Qed.

Lemma nf_preservation : forall a b, (a ⇒ b) -> nf a -> nf b.
Proof. sfirstorder use:nf_ne_preservation b:on. Qed.

Lemma ne_preservation : forall a b, (a ⇒ b) -> ne a -> ne b.
Proof. sfirstorder use:nf_ne_preservation b:on. Qed.

Create HintDb nfne.
#[export]Hint Resolve ne_nat_val nf_wn nat_val_nf ne_nf wne_wn ne_preservation nf_preservation : nfne.


(* ------------------ antirenaming ------------------------- *)

(* Next we show that if a renamed term reduces, then
   we can extract the unrenamed term from the derivation. *)
Local Lemma Par_antirenaming (a b0 : tm) (ξ : nat -> nat)
  (h : a⟨ξ⟩ ⇒ b0) : exists b, (a ⇒ b) /\ b0 = b⟨ξ⟩.
Proof.
  move E : (a⟨ξ⟩) h => a0 h.
  move : a ξ E.
  elim : a0 b0 / h.
  - move => + []//. eauto with par.
  - move => + []//. eauto with par.
  - move => w A0 A1 B0 B1 h0 ih0 h1 ih1 [] // /=.
    hauto lq:on ctrs:Par.
  - move => w a0 a1 h ih [] // a ξ ? [].
    hauto lq:on ctrs:Par.
  - move => w a0 a1 b0 b1  + + + + []//.
    hauto q:on ctrs:Par.
  - move => w a a0 b0- b1 ha iha hb ihb []// w' []// w'' t t0 ξ [] *. subst.
    specialize iha with (1 := eq_refl).
    specialize ihb with (1 := eq_refl).
    move : iha => [a [? ?]]. subst.
    move : ihb => [b [? ?]]. subst.
    exists (subst_tm (b..) a).
    split; last by asimpl.
    hauto lq:on ctrs:Par.
  - hauto q:on ctrs:Par inv:tm.
  - move => + + + + []//=.
    qauto l:on ctrs:Par.
  - move => > ++++++ [] //.
    hauto q:on ctrs:Par.
  - move => a0 a1 b h0 ih0 []// a2 b1 c1 ξ.
    case => ? ? hz. subst.
    specialize ih0 with (1 := eq_refl).
    have {hz}-> : c1 = tZero by hauto q:on inv:tm.
    hauto lq:on ctrs:Par.
  - move => ? a1 ? b1 ? c1 ha iha hb ihb hc ihc []// a0 b0 c0 ξ [? ?]. subst.
    case : c0 => // c0 [?]. subst.
    specialize iha with (1 := eq_refl).
    specialize ihb with (1 := eq_refl).
    specialize ihc with (1 := eq_refl).
    move : iha => [a2 [iha ?]].
    move : ihb => [b2 [ihb ?]].
    move : ihc => [c2 [ihc ?]]. subst.
    exists (b2[(tInd a2 b2 c2) .: c2 ..]).
    split; [by auto with par | by asimpl].
  - hauto q:on ctrs:Par inv:tm.
  - hauto inv:tm q:on ctrs:Par.
  - move => a0 b0 A0 a1 b1 A1 h ih h0 ih0 h1 ih1 []//.
    hauto q:on ctrs:Par.
  - move => t0 a0 b0 p0 t1 a1 b1 p1 ++++++++[]//.
    hauto q:on ctrs:Par.
  - move => t0 a b t1 ++[]//+++[]//.
    hauto q:on ctrs:Par.
  - move => > + + + + []//=.
    hauto lq:on ctrs:Par.
  - move => > + + + + []//=.
    hauto lq:on ctrs:Par.
  - move => > + + + + []//=.
    hauto lq:on ctrs:Par.
  - move => ? ? ? a1 b1 c1 > ha iha hb ihb hc ihc []//= []//= a0 b0 c0 ξ [*]. subst.
    specialize iha with (1 := eq_refl).
    specialize ihb with (1 := eq_refl).
    specialize ihc with (1 := eq_refl).
    move : iha => [a2 [iha ?]].
    move : ihb => [b2 [ihb ?]].
    move : ihc => [c2 [ihc ?]]. subst.
    exists (c2[b2 .: a2 ..]).
    split; [by auto with par | by asimpl].
Qed.

Local Lemma Pars_antirenaming (a b0 : tm) (ξ : nat -> nat)
  (h : (a⟨ξ⟩ ⇒* b0)) : exists b, b0 = b⟨ξ⟩ /\ (a ⇒* b).
Proof.
  move E : (a⟨ξ⟩) h => a0 h.
  move : a E.
  elim : a0 b0 / h.
  - hauto lq:on ctrs:rtc.
  - move => a b c h0 h ih a0 ?. subst.
    move /Par_antirenaming : h0.
    hauto lq:on ctrs:rtc, eq.
Qed.

Lemma wn_antirenaming a (ξ : nat -> nat) : wn (a⟨ξ⟩) -> wn a.
Proof.
  rewrite /wn.
  move => [v [rv nfv]].
  move /Pars_antirenaming : rv => [b [hb ?]]. subst.
  sfirstorder use:ne_nf_renaming.
Qed.

(* ------------------------------------------------------------- *)

(* The next set of lemmas are congruence rules for multiple steps
   of parallel reduction. *)

#[local]Ltac solve_s_rec :=
  move => *; eapply rtc_l; eauto;
  hauto lq:on ctrs:Par use:Par_refl.

Lemma S_AppLR w (a a0 b b0 : tm) :
  a ⇒* a0 ->
  b ⇒* b0 ->
  (tApp w a b) ⇒* (tApp w a0 b0).
Proof.
  move => h. move :  b b0.
  elim : a a0 / h.
  - move => a a0 b h.
    elim : a0 b / h.
    + auto using rtc_refl.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_Ind a0 a1 : forall b0 b1 c0 c1,
    a0 ⇒* a1 ->
    b0 ⇒* b1 ->
    c0 ⇒* c1 ->
    (tInd a0 b0 c0) ⇒* (tInd a1 b1 c1).
Proof.
  move => + + + + h.
  elim : a0 a1 /h.
  - move => + b0 b1 + + h.
    elim : b0 b1 /h.
    + move => + + c0 c1 h.
      elim : c0 c1 /h.
      * auto using rtc_refl.
      * solve_s_rec.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_J t0 t1 : forall a0 a1 b0 b1 p0 p1,
    t0 ⇒* t1 ->
    a0 ⇒* a1 ->
    b0 ⇒* b1 ->
    p0 ⇒* p1 ->
    (tJ t0 a0 b0 p0) ⇒* (tJ t1 a1 b1 p1).
Proof.
  move => + + + + + + h.
  elim : t0 t1 /h; last by solve_s_rec.
  move => + a0 a1 + +  + + h.
  elim : a0 a1 /h; last by solve_s_rec.
  move => + + b0 b1 + + h.
  elim : b0 b1 /h; last by solve_s_rec.
  move => + + + p0 p1 h.
  elim : p0 p1 / h; last by solve_s_rec.
  auto using rtc_refl.
Qed.

Lemma S_Let a0 a1 : forall b0 b1,
    a0 ⇒* a1 ->
    b0 ⇒* b1 ->
    tLet a0 b0 ⇒* tLet a1 b1.
Proof.
  move => + + h.
  elim : a0 a1 /h; last by solve_s_rec.
  move => + b0 b1 h.
  elim : b0 b1 /h; last by solve_s_rec.
  auto using rtc_refl.
Qed.

Lemma S_Pi w (a a0 b b0 : tm) :
  a ⇒* a0 ->
  b ⇒* b0 ->
  (tPi w a b) ⇒* (tPi w a0 b0).
Proof.
  move => h.
  move : b b0.
  elim : a a0/h.
  - move => + b b0 h.
    elim : b b0/h.
    + auto using rtc_refl.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_Sig (a a0 b b0 : tm) :
  a ⇒* a0 ->
  b ⇒* b0 ->
  (tSig a b) ⇒* (tSig a0 b0).
Proof.
  move => h.
  move : b b0.
  elim : a a0/h.
  - move => + b b0 h.
    elim : b b0/h.
    + auto using rtc_refl.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_Abs w (a b : tm)
  (h : a ⇒* b) :
  (tAbs w a) ⇒* (tAbs w b).
Proof. elim : a b /h; hauto lq:on ctrs:Par,rtc. Qed.

Lemma S_Eq a0 a1 b0 b1 A0 A1 :
  a0 ⇒* a1 ->
  b0 ⇒* b1 ->
  A0 ⇒* A1 ->
  (tEq a0 b0 A0) ⇒* (tEq a1 b1 A1).
Proof.
  move => h.
  move : b0 b1 A0 A1.
  elim : a0 a1 /h.
  - move => + b0 b1 + + h.
    elim : b0 b1 /h.
    + move => + + A0 A1 h.
      elim : A0 A1 /h.
      * auto using rtc_refl.
      * solve_s_rec.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_Pack (a b a0 b0 : tm) :
  a ⇒* a0 ->
  b ⇒* b0 ->
  (tPack a b) ⇒* (tPack a0 b0).
Proof.
  move => h.
  move : b b0.
  elim : a a0/h.
  - move => + b b0 h.
    elim : b b0/h.
    + auto using rtc_refl.
    + solve_s_rec.
  - solve_s_rec.
Qed.

Lemma S_Suc a b (h : a ⇒* b) : tSuc a ⇒* tSuc b.
Proof.
  elim : a b / h; last by solve_s_rec.
  move => ?; apply rtc_refl.
Qed.

(* ------------------------------------------------------ *)

(* We can construct proofs that terms are weakly neutral
   and weakly normal compositionally. *)

Lemma wne_j (t a b p : tm) :
  wn t -> wn a -> wn b -> wne p -> wne (tJ t a b p).
Proof.
  move => [t0 [? ?]] [a0 [? ?]] [b0 [? ?]] [p0 [? ?]].
  exists (tJ t0 a0 b0 p0).
  hauto lq:on b:on use:S_J.
Qed.

Lemma wne_ind (a b c : tm) :
  wn a -> wn b -> wne c -> wne (tInd a b c).
Proof.
  move => [a0 [? ?]] [b0 [? ?]] [c0 [? ?]].
  exists (tInd a0 b0 c0).
  qauto l:on use:S_Ind b:on.
Qed.

Lemma wne_app w (a b : tm) :
  wne a -> wn b -> wne (tApp w a b).
Proof.
  move => [a0 [? ?]] [b0 [? ?]].
  exists (tApp w a0 b0).
  hauto b:on use:S_AppLR.
Qed.

Lemma wne_let (a b : tm) :
  wne a -> wn b -> wne (tLet a b).
Proof.
  move => [a0 [? ?]] [b0 [? ?]].
  exists (tLet a0 b0).
  hauto b:on use:S_Let.
Qed.

Lemma wn_abs w (a : tm) (h : wn a) : wn (tAbs w a).
Proof.
  move : h => [v [? ?]].
  exists (tAbs w v).
  eauto using S_Abs.
Qed.

Lemma wn_pi w A B : wn A -> wn B -> wn (tPi w A B).
Proof.
  move => [A0 [? ?]] [B0 [? ?]].
  exists (tPi w A0 B0).
  hauto lqb:on use:S_Pi.
Qed.

Lemma wn_sig A B : wn A -> wn B -> wn (tSig A B).
Proof.
  move => [A0 [? ?]] [B0 [? ?]].
  exists (tSig A0 B0).
  hauto lqb:on use:S_Sig.
Qed.

Lemma wn_pack A B : wn A -> wn B -> wn (tPack A B).
Proof.
  move => [A0 [? ?]] [B0 [? ?]].
  exists (tPack A0 B0).
  hauto lqb:on use:S_Pack.
Qed.

Lemma wn_eq a b A : wn a -> wn b -> wn A -> wn (tEq a b A).
Proof.
  rewrite /wn.
  move => [va [? ?]] [vb [? ?]] [vA [? ?]].
  exists (tEq va vb vA).
  split.
  - by apply S_Eq.
  - hauto lqb:on.
Qed.

(* --------------------------------------------------------------- *)

(* This lemma is is like an
   inversion principle for terms with normal forms. If a term applied to a
   variable is normal, then the term itself is normal. *)

Lemma ext_wn w (a : tm) i :
    wn (tApp w a (var_tm i)) ->
    wn a.
Proof.
  move E : (tApp w a (var_tm i)) => a0 [v [hr hv]].
  move : a E.
  move : hv.
  elim : a0 v / hr.
  - hauto q:on inv:tm ctrs:rtc b:on db: nfne.
  - move => a0 a1 a2 hr0 hr1 ih hnfa2.
    move /(_ hnfa2) in ih.
    move => a.
    case : a0 hr0=>// => w' b0 b1.
    elim /Par_inv=>//.
    + hauto q:on inv:Par ctrs:rtc b:on.
    + move => ? w'' a0 a3 b2 b3 ? ? [? ?] ? [? ?]. subst.
      have ? : b3 = var_tm i by hauto lq:on inv:Par. subst.
      suff : wn (tAbs w' a3) by hauto lq:on ctrs:Par, rtc unfold:wn.
      have : wn (subst_tm ((var_tm i) ..) a3) by sfirstorder.
      replace (subst_tm ((var_tm i) ..) a3) with (ren_tm (i..) a3).
      move /wn_antirenaming.
      by apply : wn_abs.
      substify. by asimpl.
Qed.
