{-
    tempgres, REST service for creating temporary PostgreSQL databases.
    Copyright (C) 2014-2020 Bardur Arantsson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-}
module Tempgres.Mutex
    ( Mutex
    , mkMutex
    , withMutex
    ) where

import Control.Exception (bracket_)
import Control.Concurrent.QSem (QSem, newQSem, waitQSem, signalQSem)

-- Mutex type
newtype Mutex = Mutex QSem

-- Creates a mutex based on semaphores. The mutex takes the form a
-- function which can be called with an IO action to perform that
-- action in a critical section.
mkMutex :: IO Mutex
mkMutex = do
  semaphore <- newQSem 1
  return $ Mutex semaphore

-- Run a computation in a critical section.
withMutex :: Mutex -> IO a -> IO a
withMutex (Mutex semaphore) action =
  bracket_ (waitQSem semaphore) (signalQSem semaphore) action
