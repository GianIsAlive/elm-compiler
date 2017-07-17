{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Type.Constraint
  ( Constraint(..)
  , (/\), ex, forall
  , exists, existsNumber
  , Scheme(..), SchemeName
  , monoscheme
  )
  where

import qualified Data.Map as Map
import Data.Text (Text)

import qualified Reporting.Annotation as A
import qualified Reporting.Error.Type as Error
import qualified Reporting.Region as R
import Type.Type (Type(VarN), Variable, mkVar, Super(Number))



-- CONSTRAINTS


data Constraint
    = CTrue
    | CSaveEnv
    | CEqual Error.Hint R.Region Type Type
    | CAnd [Constraint]
    | CLet [Scheme] Constraint
    | CInstance R.Region SchemeName Type



-- SCHEMES


type SchemeName = Text


data Scheme =
  Scheme
    { _rigidQuantifiers :: [Variable]
    , _flexibleQuantifiers :: [Variable]
    , _constraint :: Constraint
    , _header :: Map.Map Text (A.Located Type)
    }



-- SCHEME HELPERS


monoscheme :: Map.Map Text (A.Located Type) -> Scheme
monoscheme headers =
  Scheme [] [] CTrue headers



-- CONSTRAINT HELPERS


infixl 8 /\


(/\) :: Constraint -> Constraint -> Constraint
(/\) c1 c2 =
    case (c1, c2) of
      (CTrue, _) -> c2
      (_, CTrue) -> c1
      _ -> CAnd [c1,c2]


-- ex qs constraint == exists qs. constraint
ex :: [Variable] -> Constraint -> Constraint
ex fqs constraint =
    CLet [Scheme [] fqs constraint Map.empty] CTrue


forall :: [Variable] -> Constraint -> Constraint
forall rqs constraint =
    CLet [Scheme rqs [] constraint Map.empty] CTrue


exists :: (Type -> IO Constraint) -> IO Constraint
exists f =
  do  v <- mkVar Nothing
      ex [v] <$> f (VarN v)


existsNumber :: (Type -> IO Constraint) -> IO Constraint
existsNumber f =
  do  v <- mkVar (Just Number)
      ex [v] <$> f (VarN v)
