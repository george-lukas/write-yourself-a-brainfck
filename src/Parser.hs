module Parser where

import Data.Char (chr, ord)
import Data.Maybe (mapMaybe)
import System.IO (hFlush, stdout)

data BrainfuckCommand = GoRight      -- >
                      | GoLeft       -- <
                      | Increment    -- +
                      | Decrement    -- -
                      | Print        -- .
                      | Read         -- ,
                      | LoopL        -- [
                      | LoopR        -- ]
                      | Comment Char -- anything else
                        
newtype BrainfuckSource = BrainfuckSource [BrainfuckCommand]
                          
instance Show BrainfuckSource where
  show (BrainfuckSource commands) = map bfToChar commands
    where
      bfToChar GoRight       = '>'
      bfToChar GoLeft      = '<'
      bfToChar Increment   = '+'
      bfToChar Decrement   = '-'
      bfToChar Print       = '.'
      bfToChar Read        = ','
      bfToChar LoopL       = '['
      bfToChar LoopR       = ']'
      bfToChar (Comment c) = c
  
data Tape a = Tape [a] -- Left of the pivot element
              a  -- Pivot element
              [a] -- Right of the pivot element
              
instance Functor Tape where
  fmap f (Tape l p r) = Tape (map f l) (f p) (map f r)
  
emptyTape :: Tape Int
emptyTape = Tape zeros 0 zeros
  where
    zeros = repeat 0
    
moveRight :: Tape a -> Tape a
moveRight (Tape ls p (r:rs)) = Tape (p:ls) r rs

moveLeft :: Tape a -> Tape a
moveLeft (Tape (l:ls) p rs) = Tape ls l (p:rs)

parseBrainfuck :: String -> Either String BrainfuckSource
parseBrainfuck = checkSyntax . BrainfuckSource . mapMaybe charToBF
  where
    charToBF '>' = Just GoRight
    charToBF '<' = Just GoLeft
    charToBF '+' = Just Increment
    charToBF '-' = Just Decrement
    charToBF '.' = Just Print
    charToBF ',' = Just Read
    charToBF '[' = Just LoopL
    charToBF ']' = Just LoopR
    charToBF _   = Nothing

checkSyntax :: BrainfuckSource -> Either String BrainfuckSource
checkSyntax bfSource@(BrainfuckSource commands) = verify commands 0 []
  where
    verify :: [BrainfuckCommand] -> Int -> [Int] -> Either String BrainfuckSource
    verify (LoopL:xs) pos l = verify xs (pos+1) (pos:l)
    verify (LoopR:xs) pos l | not (null l) = verify xs (pos+1) (tail l)
    verify (LoopR:_) pos _ = Left $ "Mismatched closing parenthesis at position " ++ show pos
    verify (_:xs) pos l = verify xs (pos+1) l
    verify [] _ [] = Right bfSource
    verify [] _ (pos:_) = Left $ "Mismatched opening parenthesis at position " ++ show pos 

runBrainfuck :: Either String BrainfuckSource -> IO ()
runBrainfuck (Left errorMessage) = error errorMessage
runBrainfuck (Right bfSource) = (run emptyTape . bfSource2Tape) bfSource
  where
    bfSource2Tape (BrainfuckSource []) = error "Empty brainfuck program"
    bfSource2Tape (BrainfuckSource (b:bs)) = Tape [] b bs

run :: Tape Int              -- Data tape
    -> Tape BrainfuckCommand -- Instruction tape
    -> IO ()
run dataTape source@(Tape _ GoRight _) = advance (moveRight dataTape) source
run dataTape source@(Tape _ GoLeft _) = advance (moveLeft dataTape) source
run (Tape l p r) source@(Tape _ Increment _) = advance (Tape l (p+1) r) source
run (Tape l p r) source@(Tape _ Decrement _) = advance (Tape l (p-1) r) source
run dataTape@(Tape _ p _) source@(Tape _ Print _) = do
    putChar (chr p)
    hFlush stdout
    advance dataTape source
run (Tape l _ r) source@(Tape _ Read _) = do
    p <- getChar
    advance (Tape l (ord p) r) source
run dataTape@(Tape _ p _) source@(Tape _ LoopL _)
  -- If the pivot is zero, jump to the
  -- corresponding LoopR instruction
  | p == 0 = seekLoopR 0 dataTape source
  -- Otherwise just ignore the `[` and continue
  | otherwise = advance dataTape source
run dataTape@(Tape _ p _) source@(Tape _ LoopR _)
  | p /= 0 = seekLoopL 0 dataTape source
  | otherwise = advance dataTape source
run dataTape source@(Tape _ (Comment _) _) = advance dataTape source

-- Move the instruction pointer left until a "[" is found.
-- The first parameter ("b" for balance) retains the current
-- bracket balance to find the matching partner. When b is 1,
-- then the found LoopR would reduce the counter to zero,
-- hence we break even and the search is successful.
seekLoopR :: Int                   -- Parenthesis balance
          -> Tape Int              -- Data tape
          -> Tape BrainfuckCommand -- Instruction tape
          -> IO ()
seekLoopR 1 dataTape source@(Tape _ LoopR _) = advance dataTape source
seekLoopR b dataTape source@(Tape _ LoopR _) = seekLoopR (b-1) dataTape (moveRight source)
seekLoopR b dataTape source@(Tape _ LoopL _) = seekLoopR (b+1) dataTape (moveRight source)
seekLoopR b dataTape source = seekLoopR b dataTape (moveRight source)

seekLoopL :: Int                   -- Parenthesis balance
          -> Tape Int              -- Data tape
          -> Tape BrainfuckCommand -- Instruction tape
          -> IO ()
seekLoopL 1 dataTape source@(Tape _ LoopL _) = advance dataTape source
seekLoopL b dataTape source@(Tape _ LoopL _) = seekLoopL (b-1) dataTape (moveLeft source)
seekLoopL b dataTape source@(Tape _ LoopR _) = seekLoopL (b+1) dataTape (moveLeft source)
seekLoopL b dataTape source = seekLoopL b dataTape (moveLeft source)

advance :: Tape Int              -- Data tape
        -> Tape BrainfuckCommand -- Instruction tape
        -> IO ()
advance _ (Tape _ _ []) = return ()
advance dataTape source = run dataTape (moveRight source)
