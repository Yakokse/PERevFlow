module PE.SpecValues where

import Utils.Maps
import Utils.Error

import RL.AST
import RL.Values
import RL.Variables

data Level = BTStatic | BTDynamic
  deriving (Eq, Show, Read)

data SpecValue = Dynamic | Static Value
  deriving (Eq, Show, Read, Ord)

type SpecStore = Map Name SpecValue

lub :: Level -> Level -> Level
lub BTStatic BTStatic = BTStatic
lub _ _ = BTDynamic

staticNonOutput :: VariableDecl -> SpecStore -> [Name]
staticNonOutput d s =
  filter (\n -> get n s /= Dynamic) $ nonOutput d

find :: Name -> SpecStore -> EM SpecValue
find n s =
  case lookupM n s of
    Just v -> return v
    _ -> Left $ "Variable \"" ++ n ++ "\" not found during lookup"

find' :: Name -> SpecStore -> EM Value
find' n s =
  case lookupM n s of
    Just (Static v) -> return v
    Just _ -> Left $ "Variable \"" ++ n ++ "\" dynamic during lookup"
    _ -> Left $ "Variable \"" ++ n ++ "\" not found during lookup"

isDynIn :: Name -> SpecStore -> EM ()
isDynIn n s =
  case lookupM n s of
    Just Dynamic -> return ()
    Just _ -> Left $ "Variable \"" ++ n ++ "\" static during lookup"
    _ -> Left $ "Variable \"" ++ n ++ "\" not found during lookup"

toStore :: SpecStore -> Store
toStore = mmap (const toVal) . mfilter (/= Dynamic)

toVal :: SpecValue -> Value
toVal (Static v) = v
toVal _ = error "Dynamic"
