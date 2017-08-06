{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
module Ace.Data.Analysis (
    Journey(..)
  , Distance(..)
  , distanceScore

  , Route(..)
  , makeRoute
  , routeDistance

  , PunterClaim(..)
  , takeClaim
  ) where

import           Ace.Data.Core

import           Data.Binary (Binary)
import           Data.Vector.Binary ()
import qualified Data.Vector.Unboxed as Unboxed
import           Data.Vector.Unboxed.Deriving (derivingUnbox)

import           GHC.Generics (Generic)

import           P

import           X.Text.Show (gshowsPrec)


-- | A journey represents any route between two sites.
--
data Journey =
  Journey {
      journeySource :: !SiteId
    , journeyTarget :: !SiteId
    } deriving (Eq, Ord, Generic)

instance Binary Journey

instance Show Journey where
  showsPrec =
    gshowsPrec

derivingUnbox "Journey"
  [t| Journey -> (SiteId, SiteId) |]
  [| \(Journey x y) -> (x, y) |]
  [| \(x, y) -> Journey x y |]

data PunterClaim =
  PunterClaim !PunterId !River
  deriving (Eq, Ord, Show, Generic)

instance Binary PunterClaim

newtype Distance =
  Distance {
      getDistance :: Int
    } deriving (Eq, Ord, Generic, Num)

instance Binary Distance

instance Show Distance where
  showsPrec =
    gshowsPrec

data Route =
  Route {
      getRoute :: Unboxed.Vector SiteId
    } deriving (Eq, Show, Generic)

instance Binary Route

takeClaim :: PunterMove -> Maybe PunterClaim
takeClaim x =
  case x of
    PunterMove _ Pass ->
      Nothing
    PunterMove pid (Claim river) ->
      Just (PunterClaim pid river)

distanceScore :: Distance -> Score
distanceScore x =
  Score (getDistance x * getDistance x)

makeRoute :: Unboxed.Vector SiteId -> Maybe Route
makeRoute xs =
  if Unboxed.length xs > 1 then
    Just $ Route xs
  else
    Nothing

routeDistance :: Route -> Distance
routeDistance =
  Distance . Unboxed.length . getRoute