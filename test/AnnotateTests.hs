module AnnotateTests (tests) where

import Test.Tasty
import Test.Tasty.HUnit

import Utils.Maps

import RL.Values
import RL.AST

import PE.AST2
import PE.SpecValues
import PE.Preprocessing.Division

import PE.Preprocessing.Impl.Annotate

test :: (Show b, Eq b) => TestName -> (a -> b) -> a -> b -> TestTree
test n f i o = testCase n $ f i @?= o

xyStore :: Level -> Level -> Division
xyStore x y = fromList [("x", x), ("y", y)]

tests :: TestTree
tests = testGroup "All Annotation Tests"
  [ expTests
  , patTests
  , stepTests
  , jumpTests
  , fromTests
  ]

jumpTests :: TestTree
jumpTests = testGroup "Jump Tests"
  [ testJump "Exit" allDyn (Exit () :: Jump String ()) Exit'
  , testJump "Goto" allDyn (Goto ("A", ())) (Goto' "A")
  , testJump "If Static" allStat
      (If (Var "x") ("A", ()) ("B", ()))
      (If' BTStatic (Var' BTStatic "x") "A" "B")
  , testJump "If Dynamic" allDyn
      (If (Var "x") ("A", ()) ("B", ()))
      (If' BTDynamic (Var' BTDynamic "x") "A" "B")
  ]
  where
    allStat = xyStore BTStatic  BTStatic
    allDyn  = xyStore BTDynamic BTDynamic
    testJump n d = test n (annotateJump d)

fromTests :: TestTree
fromTests = testGroup "Come-from Tests"
  [ testFrom "Entry" allDyn (Entry () :: ComeFrom String ()) Entry'
  , testFrom "From" allDyn (From ("A", ())) (From' "A")
  , testFrom "Fi Static" allStat
      (Fi (Var "x") ("A", ()) ("B", ()))
      (Fi' BTStatic (Var' BTStatic "x") "A" "B")
  , testFrom "Fi Dynamic" allDyn
      (Fi (Var "x") ("A", ()) ("B", ()))
      (Fi' BTDynamic (Var' BTDynamic "x") "A" "B")
  ]
  where
    allStat = xyStore BTStatic  BTStatic
    allDyn  = xyStore BTDynamic BTDynamic
    testFrom n d = test n (annotateFrom d)

stepTests :: TestTree
stepTests = testGroup "Step Tests"
  [ testStep "Static Update" allStat allStat
      (Update "x" Add (Var "y"))
      (Update' BTStatic "x" Add (Var' BTStatic "y"))
  , testStep "Dynamic Update" allDyn allDyn
      (Update "x" Add (Var "y"))
      (Update' BTDynamic "x" Add (Var' BTDynamic "y"))
  , testStep "Static Update" allStat allStat
      (Assert $ Var "x")
      (Assert' BTStatic $ Var' BTStatic "x")
  , testStep "Dynamic Update" allDyn allDyn
      (Assert $ Var "x")
      (Assert' BTDynamic $ Var' BTDynamic "x")
  , testStep "Skip" allDyn allDyn Skip (Skip' BTStatic)
  , testStep "Replacement Static" allStat allStat
      (Replacement (QVar "x") (QVar "y"))
      (Replacement' BTStatic (QVar' BTStatic "x") (QVar' BTStatic "y"))
  , testStep "Replacement Partial" allStat allDyn
      (Replacement (QVar "x") (QVar "y"))
      (Replacement' BTDynamic (Drop "x") (QVar' BTStatic "y"))
  , testStep "Replacement Dynamic" allDyn allDyn
      (Replacement (QVar "x") (QVar "y"))
      (Replacement' BTDynamic (QVar' BTDynamic "x") (QVar' BTDynamic "y"))
  ]
  where
    allStat = xyStore BTStatic  BTStatic
    allDyn  = xyStore BTDynamic BTDynamic
    testStep n d1 d2 = test n (annotateStep d1 d2)

patTests :: TestTree
patTests = testGroup "Pattern Tests"
  [ testPat "Const" xStat xStat (QConst $ Num 1)
      (QConst' BTStatic $ Num 1) BTStatic
  , testPat "Static var" xStat xStat (QVar "x")
      (QVar' BTStatic "x") BTStatic
  , testPat "Dynamic var" yStat yStat (QVar "x")
      (QVar' BTDynamic "x") BTDynamic
  , testPat "Drop" yStat xStat (QVar "x")
      (Drop "x") BTDynamic
  , testPat "Static Pair" xStat xStat (QPair (QVar "x") (QConst $ Num 4))
      (QPair' BTStatic (QVar' BTStatic "x") (QConst' BTStatic $ Num 4)) BTStatic
  , testPat "Partial Pair" xStat xStat (QPair (QVar "x") (QVar "y"))
      (QPair' BTStatic (QVar' BTStatic "x") (QVar' BTDynamic "y")) BTDynamic
  , testPat "Fully Dyn" xStat xStat (QPair (QVar "y") (QVar "y"))
      (QPair' BTStatic (QVar' BTDynamic "y") (QVar' BTDynamic "y")) BTDynamic
  ]
  where
    xStat   = xyStore BTStatic  BTDynamic
    yStat   = xyStore BTDynamic BTStatic
    testPat n d1 d2 p p' l = test n (annotatePat d1 d2) p (p', l)

expTests :: TestTree
expTests = testGroup "Expression Tests"
  [ testExp "Constant" (Const $ Num 1)
            (Const' BTStatic $ Num 1) BTStatic
  , testExp "Static Variable" (Var "x")
            (Var' BTStatic "x") BTStatic
  , testExp "Dynamic Variable" (Var "y")
            (Var' BTDynamic "y") BTDynamic
  , testExp "Static Binop" (Op Mul (Var "x") (Var "x"))
            (Op' BTStatic Mul (Var' BTStatic "x") (Var' BTStatic "x"))
            BTStatic
  , testExp "Dynamic Binop 1" (Op Mul (Var "x") (Var "y"))
            (Op' BTDynamic Mul (Lift $ Var' BTStatic "x") (Var' BTDynamic "y"))
            BTDynamic
  , testExp "Dynamic Binop 2" (Op Mul (Var "y") (Var "y"))
            (Op' BTDynamic Mul (Var' BTDynamic "y") (Var' BTDynamic "y"))
            BTDynamic
  , testExp "Static Unop" (UOp Not (Var "x"))
            (UOp' BTStatic Not (Var' BTStatic "x")) BTStatic
  , testExp "Dynamic Unop" (UOp Not (Var "y"))
            (UOp' BTDynamic Not (Var' BTDynamic "y")) BTDynamic
  ]
  where
    xStat = xyStore BTStatic BTDynamic
    testExp n i = curry $ test n (annotateExp xStat) i
