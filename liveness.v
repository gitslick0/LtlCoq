(****************************************************************************)
(*                                                                          *)
(*                                                                          *)
(*                            Solange Coupet-Grimal                         *)
(*                                                                          *)
(*                                                                          *)
(*         Laboratoire d'Informatique Fondamentale de Marseille             *)
(*                   CMI-Technopole de Chateau-Gombert                      *)
(*                       39, Rue F. Joliot Curie                            *)
(*                       13453 MARSEILLE Cedex 13                           *)
(*                    Solange.Coupet@cmi.univ-mrs.fr                        *)
(*                                                                          *)
(*                                                                          *)
(*                                Coq V7.0                                  *)
(*                             Juillet  2002                                *)
(*                                                                          *)
(****************************************************************************)
(*                                liveness.v                                *)
(****************************************************************************)

Section liveness.

(*SL 17.11.2021 Added Theorem/Lemma names as [ident] after cofix tactics*)

(*Require Export ltl.*)
(*SL 17.11.2021 Require Export didn't work for me*)

Load ltl.

Variables (state label : Set) (transition : label -> relation state)
  (init_state : state -> Prop) (fair : label -> Prop).


Notation Stream := (stream state) (only parsing).
Notation State_formula := (state_formula state) (only parsing).
Notation Stream_formula := (stream_formula state) (only parsing).
Notation Trace := (trace transition) (only parsing).
Notation Fair_step := (fair_step transition fair) (only parsing).
Notation Leads_to := (leads_to transition) (only parsing).
Notation Fairstr := (fairstr transition fair) (only parsing).

(****************************************************************************)

Lemma until_eventually :
 forall (P Q : stream_formula state) (str : stream state),
 until P Q str -> eventually Q str.


intros P Q str H_until.
elim H_until; clear H_until; clear str.
intros str H.
constructor 1; assumption.
intros (*s*) str H_P H_until H_ev.
constructor 2; assumption.
Qed.


Lemma once_eventually :
 forall (P Q : stream_formula state) (str : stream state),
 once_until P Q str -> is_followed P Q str.

unfold once_until in |- *; unfold is_followed in |- *;
 unfold leads_to_via in |- *; unfold implies in |- *.
intros P Q str H_always H_P.
inversion H_always.
apply until_eventually with (P := P).
apply C_always3.
(*rewrite H1;*) assumption.
Qed.

Lemma followed_until :
 forall P : stream_formula state,
 (forall str : stream state, P str \/ ~ P str) ->
 forall str : stream state,
 is_followed P (fun str : stream state => ~ P str) str ->
 until P (fun str : stream state => ~ P str) str.

intros P dec str H_followed; elim (dec str).
intro P_str; unfold is_followed in H_followed.
generalize P_str; generalize H_followed; simple induction 1; try assumption.
intros str' not_P_str' P_str'; absurd (P str'); assumption.
intros (*s*) str' ev_P_str' H_P_until P_str'.
constructor 2; try assumption.
elim (dec (tln str')); intro Pstr'.
apply H_P_until. assumption.
constructor 1; assumption.
constructor 1; assumption.
Qed.


Lemma eventually_until :
 forall (P : stream_formula state) (str : stream state),
 (forall str : stream state, P str \/ ~ P str) ->
 eventually P str -> until (fun str : stream state => ~ P str) P str.

intros P str dec; simple induction 1; clear H str.
intros str H_P; constructor 1; assumption.
intros (*s*) str H_ev H_until.
elim (dec str). intro H_P.
  - constructor 1. assumption.
  - constructor 2; assumption.
Qed.

(* Careful, here I used the stream_eta Axiom. Want to change this in the future if possible.*)
(* No longer used *)

Lemma one_step_leads_to :
 forall P Q : state_formula state,
 (forall s : state, P s -> enabled (fair_step transition fair) s) ->
 leads_to transition P Q ->
 forall str : stream state,
 trace transition str ->
 fairstr transition fair str ->
 state2stream_formula P str ->
 until (state2stream_formula P) (state2stream_formula Q) str.


unfold fairstr in |- *; unfold infinitely_often in |- *;
 unfold leads_to in |- *.
intros P Q H_enabled leads_P_Q str H_trace H_fair H_P; generalize H_trace H_P.
inversion_clear H_fair.
clear H_trace H_P C_always4 (*str*).
elim C_always3; clear C_always3.

(*clear s0 str0;*)clear str. intro str. (*case str. 
clear str;*) intros (*s str*) H_fair H_trace H_P.
  - constructor 2. (*rewrite -> stream_eta. constructor 2.*)
      -- assumption. (*rewrite <- stream_eta. assumption.*)
      -- constructor 1. unfold state2stream_formula in |-*. apply leads_P_Q with (s := hdn str).
          --- auto.
          --- elim H_fair. intros a fair_a H_trans. clear fair_a.
                ---- apply C_trans with (a := a). auto.
                ---- apply H_enabled. auto.
  - unfold state2stream_formula in |- *; simpl in |- *.
    intros (*s1*) str1 H_ind H1 H_trace H_P.
    inversion_clear H_trace.
    inversion C_always3.
      -- constructor 2.
          --- auto.
          --- apply H1; auto. simpl in H0. rewrite <- H0. assumption.
      -- simpl in H. constructor 2; auto. constructor 1. apply leads_P_Q with (s := hdn str1); assumption.
Qed.


Hint Resolve one_step_leads_to.


Lemma always_one_step_leads_to :
 forall P Q : state_formula state,
 (forall s : state, P s -> enabled (fair_step transition fair) s) ->
 leads_to transition P Q ->
 forall str : stream state,
 trace transition str ->
 fairstr transition fair str ->
 once_until (state2stream_formula P) (state2stream_formula Q) str.

unfold once_until in |- *; unfold leads_to_via in |- *.
intros P Q H_enabled leads_P_Q; unfold implies in |- *.
cofix always_one_step_leads_to.
intro str. (*case str; intros s str'; case str'.*)
intros (*t tl*) H_trace H_fair. constructor.
intro H.
apply one_step_leads_to; try assumption.
inversion_clear H_trace; inversion_clear H_fair.
apply always_one_step_leads_to; assumption.
Qed.

End liveness.