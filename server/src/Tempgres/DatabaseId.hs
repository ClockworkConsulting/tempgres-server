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
module Tempgres.DatabaseId
    ( DatabaseId
    , mkDatabaseId
    , sqlIdentifier
    , unquotedIdentifier
    , unsafeMkDatabaseId
    ) where

import Data.Either (fromRight)
import System.Envy (Var(..))

-- Newtype to prevent unsafe construction.
newtype DatabaseId = DatabaseId String
  deriving (Show)
  deriving Var via String

-- Create a new database identifier. This implementation is
-- *extremely* conservative in what is accepts in the input
-- string.
mkDatabaseId :: String -> Either String DatabaseId
mkDatabaseId s = do
  -- Since we don't do any quoting or anything we just need to check
  -- if the string obeys all the rules.
  s' <- first letters s
  s'' <- rest (letters ++ digits) s'
  return $ s'' `seq` DatabaseId s
  where
    rest :: [Char] -> String -> Either String String
    rest _       [ ]                       = Right [ ]
    rest choices (c:cs) | c `elem` choices = rest choices cs
    rest _       (c:_)                     = invalid c

    first :: [Char] -> String -> Either String String
    first _       [ ]                       = Left "Database name cannot be empty"
    first choices (c:cs) | c `elem` choices = Right cs
    first _       (c:_)                     = invalid c

    invalid c = Left $ "Invalid character '" ++ [c] ++ "' in database name '" ++ s ++ "'"

    letters = "abcdefghjiklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
    digits = "0123456789"

-- Unsafe conversion from a String to a DatabaseId.
unsafeMkDatabaseId :: String -> DatabaseId
unsafeMkDatabaseId s =
  fromRight (error "bad default") $ mkDatabaseId s

-- Turn database identifier into an SQL identifier for the
-- database. Will include quotes if necessary.
sqlIdentifier :: DatabaseId -> String
sqlIdentifier (DatabaseId s) = s -- Our whitelist ensures that we do not need any quoting.

-- Turn database identifier into a RAW identifier for the
-- database. Will NOT include quotes!
unquotedIdentifier :: DatabaseId -> String
unquotedIdentifier (DatabaseId s) = s
