tm : Type
nat : Type
web : Type

tAbs : web -> (bind tm in tm) -> tm
tApp : web -> tm -> tm -> tm
tPi : web -> tm -> (bind tm in tm) -> tm
tUniv : nat -> tm
tEq : tm -> tm -> tm -> tm
tJ : tm -> tm -> tm -> tm -> tm
tRefl : tm
tZero : tm
tSuc : tm -> tm
tInd : tm -> (bind tm,tm in tm) -> tm -> tm
tNat : tm
tSig : tm -> (bind tm in tm) -> tm
tPack : tm -> tm -> tm
tLet : tm -> (bind tm,tm in tm) -> tm
