module Data.CatQueue

import Data.List.Properties
import Interfaces.Verified

%hide Prelude.List.reverse
%hide Prelude.Strings.reverse
%hide Prelude.Strings.null

%default total
%access public export

data CatQueue a = MkCatQueue (List a) (List a)

data NonEmptyCatQueue : CatQueue a -> Type where
  IsNonEmptyCatQueue : Either (NonEmpty x) (NonEmpty y) ->
                       NonEmptyCatQueue (MkCatQueue x y)

data EmptyCatQueue : CatQueue a -> Type where
  IsEmptyCatQueue : EmptyCatQueue (MkCatQueue [] [])

data SingletonCatQueue : CatQueue a -> Type where
  IsSingletonCatQueueLeft : SingletonCatQueue (MkCatQueue [x] [])
  IsSingletonCatQueueRight : SingletonCatQueue (MkCatQueue [] [x])

--------------------------------------------------------------------------------
-- Implementations
--------------------------------------------------------------------------------

Uninhabited (NonEmptyCatQueue (MkCatQueue [] [])) where
  uninhabited (IsNonEmptyCatQueue (Left IsNonEmpty)) impossible
  uninhabited (IsNonEmptyCatQueue (Right IsNonEmpty)) impossible

Show q => Show (CatQueue q) where
  show (MkCatQueue xs ys) = "MkCatQueue " ++ show xs ++ " " ++ show ys

Eq q => Eq (CatQueue q) where
  (==) (MkCatQueue xs ys) (MkCatQueue zs ws) =
    xs ++ reverse ys == zs ++ reverse ws
  (/=) x y = not (x == y)

Ord q => Ord (CatQueue q) where
  compare (MkCatQueue [] []) (MkCatQueue [] []) = EQ
  compare (MkCatQueue [] []) _ = LT
  compare _ (MkCatQueue [] []) = GT
  compare (MkCatQueue xs ys) (MkCatQueue zs ws) = compare (xs ++ reverse ys) (zs ++ reverse ws)

Semigroup (CatQueue q) where
  (<+>) (MkCatQueue xs ys) (MkCatQueue zs ws) = MkCatQueue xs ((zs ++ reverse ws) ++ ys)

Monoid (CatQueue q) where
  neutral = MkCatQueue [] []

Functor CatQueue where
  map f (MkCatQueue xs ys) = MkCatQueue (map f xs) (map f ys)

Foldable CatQueue where
  foldr f init (MkCatQueue xs ys) = foldr f init (xs ++ reverse ys)
  foldl f init (MkCatQueue xs ys) = foldl f init (xs ++ reverse ys)

VerifiedFunctor CatQueue where
  functorIdentity (MkCatQueue xs ys) =
    rewrite functorIdentity xs in
    rewrite functorIdentity ys in Refl
  functorComposition (MkCatQueue xs ys) g1 g2 =
    rewrite functorComposition xs g1 g2 in
    rewrite functorComposition ys g1 g2 in Refl

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- | Test whether a queue is empty.
-- |
-- | Running time: `O(1)`
null : CatQueue a -> Bool
null (MkCatQueue [] []) = True
null _ = False

-- | Append an element to the end of the queue, creating a new queue.
-- |
-- | Running time: `O(1)`
snoc : CatQueue a -> a -> CatQueue a
snoc (MkCatQueue l r) a = MkCatQueue l (a :: r)

-- | Decompose a queue into a `Tuple` of the first element and the rest of the queue.
-- |
-- | Running time: `O(1)`
-- |
-- | Note that any single operation may run in `O(n)`.
uncons : (q : CatQueue a) -> {auto prf : NonEmptyCatQueue q} -> (a, CatQueue a)
uncons (MkCatQueue [] []) {prf} = absurd prf
uncons (MkCatQueue [] (x :: xs)) = uncons_prf (x :: xs) {prf' = reverseNonEmpty (x :: xs) IsNonEmpty}
  where
    uncons_prf : (l : List a) -> {auto prf : NonEmpty l} -> {prf' : NonEmpty (reverse l)} -> (a, CatQueue a)
    uncons_prf l = assert_total $ uncons (MkCatQueue (reverse l) [])
uncons (MkCatQueue (x :: xs) ys) = (x, (MkCatQueue xs ys))


-- | Decompose a queue into a `Tuple` of the first element and the rest of the queue.
-- |
-- | Running time: `O(1)`
-- |
-- | Note that any single operation may run in `O(n)`.
uncons' : CatQueue a -> Maybe (a, (CatQueue a))
uncons' (MkCatQueue [] []) = Nothing
uncons' (MkCatQueue [] r) = assert_total $ uncons' (MkCatQueue (reverse r) [])
uncons' (MkCatQueue (a :: as) r) = Just (a, (MkCatQueue as r))


--------------------------------------------------------------------------------
-- Properties
--------------------------------------------------------------------------------

snocNotEmpty : (x : a) -> (q : CatQueue a) -> {auto prf : EmptyCatQueue q} -> NonEmptyCatQueue (snoc q x)
snocNotEmpty x q@(MkCatQueue [] []) = the (NonEmptyCatQueue (snoc q x)) (IsNonEmptyCatQueue (Right IsNonEmpty))

singletonNonEmpty : SingletonCatQueue q -> NonEmptyCatQueue q
singletonNonEmpty IsSingletonCatQueueLeft = IsNonEmptyCatQueue (Left IsNonEmpty)
singletonNonEmpty IsSingletonCatQueueRight = IsNonEmptyCatQueue (Right IsNonEmpty)

snocEmptySingleton : (x : a) -> (q : CatQueue a) -> {auto prf : EmptyCatQueue q} -> SingletonCatQueue (snoc q x)
snocEmptySingleton x (MkCatQueue [] []) = IsSingletonCatQueueRight

nonEmptyNotNull : (q : CatQueue a) -> {auto prf : NonEmptyCatQueue q} -> null q = False
nonEmptyNotNull (MkCatQueue [] []) {prf} = absurd prf
nonEmptyNotNull (MkCatQueue (x :: xs) []) = Refl
nonEmptyNotNull (MkCatQueue [] (y :: ys)) = Refl
nonEmptyNotNull (MkCatQueue (x :: xs) (y :: ys)) = Refl

Uninhabited (False = True) where
  uninhabited Refl impossible

nullDecidable : (q : CatQueue a) -> Dec (null q = True)
nullDecidable (MkCatQueue [] []) = Yes Refl
nullDecidable (MkCatQueue (x::xs) []) = No uninhabited
nullDecidable (MkCatQueue [] (x::xs)) = No uninhabited
nullDecidable (MkCatQueue (x::xs) (y::ys)) = No uninhabited
