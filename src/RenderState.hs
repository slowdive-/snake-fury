
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns #-}


{-|
This module defines the board and the score. It includes not only the rendering of it but also the update logic of each.
-}
module RenderState where

import Data.Array ( (//), listArray, Array, elems )
import Control.Monad ( foldM_ )
import Data.Foldable ( foldl' )
import Debug.Trace(trace)
import qualified Data.ByteString.Builder as B
import Data.ByteString.Builder (Builder)

type Point = (Int, Int)
data CellType = Empty | Snake | SnakeHead | Apple deriving (Show, Eq)

data BoardInfo = BoardInfo {height :: Int, width :: Int} deriving (Show, Eq)
type Board = Array Point CellType
type DeltaBoard = [(Point, CellType)]

data RenderMessage = RenderBoard DeltaBoard | GameOver | Score deriving (Show, Eq)
data RenderState   = RenderState {board :: Board, gameOver :: Bool, score :: Int}

-- | Creates the empty grip from its info
emptyGrid :: BoardInfo -> Board
emptyGrid (BoardInfo h w) = listArray boardBounds emptyCells
    where boardBounds =  ((1, 1), (h, w))
          emptyCells  = replicate (h*w) Empty

-- | Given BoardInfo, init point of snake and init point of apple, builds a board
buildInitialBoard
  :: BoardInfo -- ^ Board size
  -> Point     -- ^ initial point of the snake
  -> Point     -- ^ initial Point of the apple
  -> RenderState
buildInitialBoard bInfo initSnake initApple =
  RenderState b False 0
 where b = emptyGrid bInfo // [(initSnake, SnakeHead), (initApple, Apple)]

-- | Given tye current render state, and a message -> update the render state
updateRenderState :: RenderState -> RenderMessage -> RenderState
updateRenderState (RenderState b gOver s) message =
  case message of
    RenderBoard delta -> RenderState (b // delta) gOver s
    GameOver          -> RenderState b  True s
    Score             -> RenderState b  gOver (s + 1)


updateMessages :: RenderState -> [RenderMessage] -> RenderState
updateMessages = foldl' updateRenderState

-- | Pretry printer Score
ppScore :: Int -> Builder
ppScore n =
  "----------\n" <>
  "Score: " <> B.intDec n  <> "\n" <>
  "----------\n"

-- | Provisional Pretty printer
ppCell :: CellType -> Builder
ppCell Empty     = "- "
ppCell Snake     = "0 "
ppCell SnakeHead = "$ "
ppCell Apple     = "X "


render :: BoardInfo -> RenderState -> Builder
render binf@(BoardInfo h w) (RenderState b gOver s) =
  if gOver
    then ppScore s <> fst (boardToString $ emptyGrid binf)
    else ppScore s <> fst (boardToString b)
  where
    boardToString =  foldl' fprint (mempty, 0)
    fprint (!s, !i) cell =
      if ((i + 1) `mod` w) == 0
        then (s <> ppCell cell <> B.charUtf8 '\n', i + 1 )
        else (s <> ppCell cell , i + 1)