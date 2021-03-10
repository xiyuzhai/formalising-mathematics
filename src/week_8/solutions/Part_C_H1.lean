import week_8.solutions.Part_B_H0
import group_theory.quotient_group

/-

# A crash course in H¹(G,M)

We stick to the conventions that `G` is a group (or even
a monoid, we never use inversion) and that `M` is a `G`-module,
that is, an additive abelian group with a `G`-action.

A key concept here is that of a cocycle, or a twisted homomorphism.
These things were later renamed 1-cocycles when people realised that higher
cocycles existed; today whenever I say "cocycle" I mean 1-cocycle).
A cocycle is a function `f : G → M` satisfying the axiom
`∀ (g h : G), f (g * h) = f g + g • f h`. These things
naturally form an abelian group under pointwise addition
and negation, by which I mean "operate on the target":
`(f₁ + f₂) g = f₁ g + f₂ g`.

Let `Z1 G M` denote the abelian group of cocycles. 
There is a subgroup `B1 G M` of coboundaries, consisting
of the functions `f` for which there exists `m : M`
such that `f g = g • m - m` (note that it is at this point where we
crucially use the fact that `M` is an abelian group and not just an abelian
monoid). One easily checks that all coboundaries are cocycles, and that
coboundaries are a subgroup (you will be doing this below). The
quotient group `H1 G M`, written `H¹(G,M)` by mathematicians, is the main
definition in this file. The first two theorems we shall prove about it here
are that it is functorial (i.e. a map `φ : M →+[G] N` gives
rise to a map `φ.H1_hom : H1 G M →+ H1 G N`), and exact in the
middle (i.e. if `0 → A → B → C → 0` is a short exact sequence
of `G`-modules then the sequence `H1 G A →+ H1 G B →+ H1 G C`
is exact).

In Part D of this week's workshop we will define
a boundary map `H0 G C →+ H1 H A` coming from a short
exact sequence of `G`-modules. In this definition we make
a choice of sign ("do we use `g b - b` or `b - g b`?"). 
The final boss of this course
is verifying the first seven terms of the long exact sequence
of group cohomology associated to a short exact sequence of
G-modules.

Further work would be to verify "inf-res", otherwise known
as the beginning of the long exact
sequence of terms of low degree in the Hochschild-Serre
spectral sequence for group cohomology (i.e.
`0 → H¹(G/N, Aᴺ) → H¹(G, A) → H¹(N, A)` ) and of course one
could go on to define n-cocycles and n-coboundaries (please
get in touch if you're interested in doing this -- I have
ideas about how to set it all up) and to
construct the Hochschild-Serre spectral sequence itself.
I have no doubt that these kinds of results could be turned
into a research paper.

Let's start with a definition of `H1 G M`. First we need
to define cocycles and coboundaries. 
-/

-- 1-cocycles as an additive subgroup of the group `Hom(G,M)`
-- a.k.a. `G → M` of functions from `G` to `M`, with group
-- law induced from `M`.
def Z1_subgroup (G M : Type)
  [monoid G] [add_comm_group M] [distrib_mul_action G M] : add_subgroup (G → M) :=
{ carrier := { f : G → M | ∀ (g h : G), f (g * h) = f g + g • f h },
  zero_mem' := begin
    -- the zero map is a cocycle
    simp,
  end,
  add_mem' := begin
    -- sum of two cocycles is a cocycle.
    -- Note that the `abel` tactic is to additive abelian groups
    -- what the `ring` tactic is to commutative semirings.
    rintros c b hc hb g h,
    simp [hc g h, hb g h],
    abel,
  end,
  neg_mem' := begin
    rintros c hc g h,
    simp [hc g h],
    abel,
  end }

-- Just like `H0 G M`, we promote this term to a type
structure Z1 (G M : Type)
  [monoid G] [add_comm_group M] [distrib_mul_action G M] : Type :=
(to_fun : G → M)
(cocycle_condition : ∀ (g h : G), to_fun (g * h) = to_fun g + g • to_fun h)

-- This is a definition so we need to make an API
namespace Z1

-- let G be a group (or a monoid) and let M be a G-module.
variables {G M : Type}
  [monoid G] [add_comm_group M] [distrib_mul_action G M]

-- add a coercion from a cocycle to the function G → M
instance : has_coe_to_fun (Z1 G M) :=
{ F := λ _, G → M,
  coe := to_fun }

-- add a specification for the coercion

lemma spec (a : Z1 G M) : ∀ (g h : G), a (g * h) = a g + g • a h :=
-- this is the last time we'll see `a.cocycle_condition`: we'll 
-- use `a.spec` from now on because it applies to `⇑a` and not `a.to_fun`.
a.cocycle_condition

-- add an extensionality lemma
@[ext] lemma ext (a b : Z1 G M) (h : ∀ g, a g = b g) : a = b :=
begin
  cases a, cases b, simp, ext g, exact h g,
end

def add (a b : Z1 G M) : Z1 G M :=
{ to_fun := λ g, a g + b g,
  cocycle_condition := begin
    rintros g h,
    simp [a.spec, b.spec],
    abel,    
  end }

instance : has_add (Z1 G M) := ⟨add⟩

@[simp] lemma coe_add (a b : Z1 G M) (g : G) : (a + b) g = a g + b g := rfl

def zero : Z1 G M := 
{ to_fun := λ g, 0,
  cocycle_condition := begin
    simp,
  end
}

instance : has_zero (Z1 G M) := ⟨zero⟩

@[simp] lemma coe_zero (g : G) : (0 : Z1 G M) g = 0 := rfl

def neg (a : Z1 G M) : Z1 G M :=
{ to_fun := λ g, -(a g),
  cocycle_condition := begin
    intros,
    simp [a.spec],
    abel,
  end
}

instance : has_neg (Z1 G M) := ⟨neg⟩

@[simp] lemma coe_neg (a : Z1 G M) (g : G) : (-a) g = -(a g) := rfl

def sub (a b : Z1 G M) : Z1 G M := a + -b

instance : has_sub (Z1 G M) := ⟨sub⟩

-- make the cocycles into a group
instance : add_comm_group (Z1 G M) :=
begin
  refine_struct { 
    add := (+),
    zero := (0 : Z1 G M),
    neg := has_neg.neg,
    sub := has_sub.sub,
    -- ignore this, we have to fill in this proof for technical reasons
    sub_eq_add_neg := λ _ _, rfl };
  -- we now have five goals. Let's use the semicolon trick to work on 
  -- all of them at once. I'll show you what happens to the proof
  -- of associativity, the others are the same mutatis mutandis
  -- (but harder to see)
  -- *TODO* could documentstring commutativity and remark that 
  -- they can see associativity using the cursor.
  -- ⊢ ∀ (a b c : Z1 G M), a + b + c = a + (b + c)
  intros;
  -- ⊢ a + b + c = a + (b + c)
  ext;
  -- ⊢ ⇑(a + b + c) g = ⇑(a + (b + c)) g
  simp;
  -- ⊢ ⇑a g + ⇑b g + ⇑c g = ⇑a g + (⇑b g + ⇑c g)
  abel
  -- general additive abelian group tactic which solves
  -- goals which are (absolute) identities in every abelian group.
  -- Hypotheses are not looked at though. See Chris Hughes' forthcoming
  -- Imperial MSc thesis for a new group theory tactic which is to `abel`
  -- what `nlinarith` is to `ring`.
end

end Z1

namespace distrib_mul_action_hom

-- The Z1 construction is functorial in the module `M`. Let's construct
-- the relevant function, showing that if `φ : M →+[G] N` then
-- composition induces an additive group homomorphism `Z1 G M → Z1 G N`.
-- Just like `H0` we first define the auxiliary bare function, 
-- and then beef it up to an abelian group homomorphism.

variables {G M N : Type} [monoid G] 
  [add_comm_group M] [distrib_mul_action G M]
  [add_comm_group N] [distrib_mul_action G N]

def Z1_hom_underlying_function (φ : M →+[G] N) (f : Z1 G M) : Z1 G N :=
⟨λ g, φ (f g), begin
  -- need to prove that this function obtained by composing the cocycle
  -- f with the G-module homomorphism φ is also a cocycle.
  simp [←φ.map_smul, -map_smul, f.spec]
end⟩

@[norm_cast] 
lemma Z1_hom_underlying_function_coe_comp (φ : M →+[G] N) (f : Z1 G M) (g : G) :
  (Z1_hom_underlying_function φ f g : N) = φ (f g) := rfl--

def Z1_hom (φ : M →+[G] N) : Z1 G M →+ Z1 G N :=
-- to make a term of type `X →+ Y` (a group homomorphism) from a function
-- `f : X → Y` and
-- a proof that it preserves addition we use the following constructor:
add_monoid_hom.mk' 
-- We now throw in the bare function
(Z1_hom_underlying_function φ)
-- (or could try direct definition:)
-- (λ f, ⟨λ g, φ (f g), begin
--   -- need to prove that this function obtained by composing the cocycle
--   -- f with the G-module homomorphism φ is also a cocycle.
--   intros g h,
--   rw ←φ.map_smul,
--   rw f.spec,
--   simp,
-- end⟩)
-- and now the proof that it preserves addition
begin
  intros e f,
  ext g,
  simp [φ.Z1_hom_underlying_function_coe_comp],
end

--def Z1_hom_spec

end distrib_mul_action_hom

-- now some stuff on coboundaries

section B1 -- we'll put it in the root namespace

variables {G M : Type}
  [monoid G] [add_comm_group M] [distrib_mul_action G M]

def is_coboundary (f : G → M) : Prop :=
∃ m, ∀ g, f g = g • m - m 
-- exercise: how do you think Lean works out the types of `g` and `m`
-- in the above definition?
-- Humans do it by correctly guessing `g : G` and `m : M`. Lean does it
-- in another way -- what is it?

-- useful for rewrites
lemma is_coboundary_def (f : G → M) :
  is_coboundary f ↔ ∃ m, ∀ g, f g = g • m - m :=
-- true by definition
iff.rfl

-- let's define `B1 G M` as a subgroup of `Z1 G M`.
def B1 (G M : Type) [monoid G] [add_comm_group M]
  [distrib_mul_action G M] : add_subgroup (Z1 G M) :=
{ carrier := {a | is_coboundary a },
  zero_mem' := begin
    use 0,
    simp,
  end,
  add_mem' := begin
    rintros a b ⟨m, hm⟩ ⟨n, hn⟩,
    use m + n,
    intro g,
    simp [hm g, hn g],
    abel,
  end,
  neg_mem' := begin
    rintros a ⟨m, hm⟩,
    use -m,
    intro g,
    simp [hm g],
  end }

end B1

-- Lean has inbuilt quotients of additive abelian groups by subgroups
@[derive add_comm_group] def H1 (G M : Type) [monoid G] [add_comm_group M]
  [distrib_mul_action G M] : Type :=
quotient_add_group.quotient (B1 G M)

/-

We have just defined `H1 G M` as a quotient group, and told Lean
to figure out (or "derive") the obvious abelian group structure
on it, which it did.

What we need to do now is to show that if `φ : M →+[G] N` is a `G`-module
hom then `φ` induces a map `H1 G M → H1 G N`. To prove this we will
need to figure out how to define maps from and to quotient group structures.
Just like last week, this is simply a matter of learning the API for the
definition `quotient_add_group.quotient`. Here it is:

*TODO* fill in

Now let us make the definition.
-/

namespace distrib_mul_action_hom

variables {G M N : Type}
  [monoid G] [add_comm_group M] [add_comm_group N]
  [distrib_mul_action G M] [distrib_mul_action G N]

-- Let's first define the function `H1 G M → H1 G N` induced by `φ`.
def H1_hom (φ : M →+[G] N) : H1 G M →+ H1 G N :=
-- We use `quotient_add_group.map` to define this map
-- by saying that it is a descent of the map `φ.Z1_hom`
quotient_add_group.map (B1 G M) (B1 G N) φ.Z1_hom
-- We now have to supply the proof that the map on cocycles induces
-- a map on cohomology, i.e. that it sends coboundaries to coboundaries
begin
  intros a ha,
  rw add_subgroup.mem_comap,
  -- I think I need an interface for B1
  sorry
end

open function

variables {P : Type} [add_comm_group P] [distrib_mul_action G P]
-- the big theorem from this part
theorem H1_hom_middle_exact (φ : M →+[G] N) (hφ : injective φ)
  (ψ : N →+[G] P) (hψ : surjective ψ) (he : is_exact φ ψ) : 
  φ.H1_hom.range = ψ.H1_hom.ker :=
begin
  sorry
end

end distrib_mul_action_hom

