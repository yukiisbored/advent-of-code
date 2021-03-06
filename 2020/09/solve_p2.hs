#!/usr/bin/env runhaskell

import Data.List (inits, tails)

window :: Int -> [Int] -> Int -> [Int]
window prem xs idx = (drop  (idx - prem) . take idx) xs

check' :: Int -> [Int] -> Int -> Bool
check' prem xs idx = num `elem` pos
  where win = window prem xs idx
        pos = [i + j | i <- win, j <- win, i /= j]
        num = xs !! idx

findKey :: Int -> [Int] -> Int
findKey prem xs = xs !! idx
  where check = check' prem xs
        idx = head $ filter (not . check) [prem..length xs - 1]

segments :: [Int] -> [[Int]]
segments = concatMap tails . inits

main :: IO ()
main = do
  content <- readFile "in.txt"

  let prem = 25

      nums :: [Int]
      nums = map read $ lines content

      key = findKey prem nums

      xs = head . filter (\is -> sum is == key) $ segments nums
      solution = minimum xs + maximum xs


  print solution
