#!/usr/bin/env runhaskell

{-# LANGUAGE TemplateHaskell #-}

import Control.Lens (element, set,  (^?), (^.), over, makeLenses, Ixed(ix) )
import Text.Parsec.String (Parser)
import Text.Parsec
    (string, choice,  digit, oneOf, spaces, endBy, eof, many1, parse )
import Data.Maybe (isJust)
import qualified Data.Vector as V
import qualified Data.Set as S

type Op = Int

data Instruction = Nop Op
                    | Jmp Op
                    | Acc Op
                    deriving (Show, Eq)

type Program = V.Vector Instruction

data State = Run
           | CyclicHalt
           | Halt
           deriving (Show, Eq)

data CPU = CPU { _pc      :: Int
               , _acc     :: Int
               , _visited :: S.Set Int
               , _state   :: State
               , _program :: Program }
         deriving (Show)

$(makeLenses ''CPU)

operand :: Parser Int
operand = do
  sign <- oneOf "+-"
  n <- many1 digit

  let num' = read n :: Int
      num = if sign == '-' then -num'
            else num'

  return num

instruction :: Parser Instruction
instruction = do
  ins <- choice (string <$> ["nop", "jmp", "acc"]) <* spaces
  op <- operand

  case ins of
    "nop" -> return $ Nop op
    "jmp" -> return $ Jmp op
    "acc" -> return $ Acc op

assembly :: Parser Program
assembly = V.fromList <$> instruction `endBy` spaces <* eof

initCPU :: Program -> CPU
initCPU prog = CPU { _pc      = 0
                   , _acc     = 0
                   , _visited = S.empty
                   , _state   = Run
                   , _program = prog }

execute :: CPU -> CPU
execute cpu = if continue then (execute . execute' ins)
                               (over visited (S.insert (cpu^.pc)) cpu)
              else set state (if cyclicCheck then CyclicHalt else Halt) cpu
  where ins = cpu^.program^?ix (cpu^.pc)

        cyclicCheck = (cpu^.pc) `S.member` (cpu^.visited)
        continue = not cyclicCheck && isJust ins

        execute' :: Maybe Instruction -> CPU -> CPU
        execute' (Just (Jmp op)) = over pc (+ op)
        execute' (Just (Acc op)) = over pc (+ 1) . over acc (+ op)
        execute' (Just (Nop _))  = over pc (+ 1)
        execute' Nothing         = id

patch :: Instruction -> Instruction
patch (Jmp op) = Nop op
patch (Nop op) = Jmp op
patch a = a

bruteforce :: Program -> CPU
bruteforce prog = head $ [cpu' | i <- [0..(length prog - 1)]
                               , let prog' = over (element i) patch prog
                               , let cpu' = execute $ initCPU prog'
                               , cpu'^.state == Halt]

main :: IO ()
main = do
  let fileName = "in.txt"

  raw <- readFile fileName

  let program' = parse assembly fileName raw

  case program' of
    Left err      -> print err
    Right program -> print (bruteforce program^.acc)
