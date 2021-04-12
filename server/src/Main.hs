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
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main ( main ) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (async, withAsync, waitCatch)
import Control.Exception (bracket)
import Control.Monad (void, replicateM)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.String (fromString)
import Data.Text.Lazy qualified as TL
import Database.PostgreSQL.Simple (Connection, ConnectInfo(..), Only(..))
import Database.PostgreSQL.Simple qualified as P
import Network.Wai.Handler.Warp (setPort, setHost, defaultSettings)
import System.IO (stderr, hPutStrLn)
import System.Random (randomRIO)
import Web.Scotty (ScottyM, Options(..), scottyOpts, post, text)
import Tempgres.Mutex
import Tempgres.Configuration
import Tempgres.DatabaseId

-- Perform an operation with an open connection to the database.
-- The connection will automatically be closed after the operation
-- completes, regardless of whether it completes successfully or
-- not (e.g. if there's an exception).
withConnection :: Configuration -> (Connection -> IO a) -> IO a
withConnection Configuration{..} action = bracket (P.connect connectInfo) P.close action
  where
    connectInfo = ConnectInfo
      { connectHost = cfgDatabaseHost
      , connectPort = cfgDatabasePort
      , connectUser = cfgAdminUser
      , connectPassword = cfgAdminPass
      , connectDatabase = unquotedIdentifier cfgDatabase
      }

-- Create a random valid PostgreSQL identifier.
mkRandomIdent :: IO String
mkRandomIdent = do
  h <- chooseElement letters
  t <- replicateM 32 $ chooseElement lettersAndDigits
  return (h:t)
  where
    letters = "abcdefhijklmnopqrstuvwxyz"
    digits = "0123456789"
    lettersAndDigits = letters ++ digits
    chooseElement t = do
      i <- randomRIO (0, length t - 1)
      return $ t !! i

-- Create temporary database ID.
mkTemporaryDatabaseId :: IO (Either String DatabaseId)
mkTemporaryDatabaseId = fmap mkDatabaseId $ fmap ("temp_" ++) mkRandomIdent

-- Create temporary database and return its name.
createTemporaryDatabase :: Configuration -> DatabaseId -> IO ()
createTemporaryDatabase configuration@Configuration{..} databaseId = do
  -- Connect to the administrative database.
  withConnection configuration $ \connection -> do
    -- Create the temporary database.
    void $ P.execute_ connection $ createSql
    putStrLn $ "Created temporary database: " ++ sqlDatabaseId
    -- Spawn a thread to kill the database after a certain delay.
    void $ async $ do
      threadDelay $ cfgDurationSeconds * 1000000
      dropDatabase configuration databaseId
  where
    createSql = fromString $
      "CREATE DATABASE " ++ sqlDatabaseId ++
      "  WITH TEMPLATE " ++ (sqlIdentifier cfgTemplateDatabase) ++
      "          OWNER \"" ++ cfgClientUser ++ "\""

    sqlDatabaseId = sqlIdentifier databaseId

dropDatabase :: Configuration -> DatabaseId -> IO ()
dropDatabase configuration databaseId =
  -- Since this is running in a separate thread we need explicit
  -- exception handling to avoid silent exceptions.
  withAsync doDropDatabase waitCatch >>= \case
    Left exc -> hPutStrLn stderr $ "Exception occurred while creating temporary database: " ++ show exc
    Right _  -> return ()
  where
    doDropDatabase = withConnection configuration $ \connection -> do
      -- We need to block new connections to the temporary database; otherwise
      -- a reconnect during the destruction could foil our attempt to drop.
      void $ P.execute_ connection blockConnectionsSql
      -- Now we can kill the backends, i.e. terminate all the connections. No
      -- new connections can be created because of the previous block.
      P.forEach_ connection terminateConnectionsSql $ \(Only (_::Bool)) -> return ()
      -- Finally, we can drop.
      void $ P.execute_ connection dropSql
      -- Logging
      putStrLn $ "Dropped temporary database: " ++ sqlDatabaseId

    dropSql = fromString $
        "DROP DATABASE " ++ sqlDatabaseId

    blockConnectionsSql = fromString $
        "UPDATE pg_database \
        \   SET datallowconn = FALSE \
        \ WHERE datname = '" ++ sqlDatabaseId ++ "'"

    terminateConnectionsSql = fromString $
        "SELECT pg_terminate_backend(pid) \
        \  FROM pg_stat_activity \
        \ WHERE pid <> pg_backend_pid() \
        \   AND datname = '" ++ sqlDatabaseId ++ "'"

    sqlDatabaseId = sqlIdentifier databaseId

-- Handle a create request, returns the database ID.
handleCreateRequest :: MonadIO m => Configuration -> Mutex -> m DatabaseId
handleCreateRequest configuration mutex = do
  -- Generate a name for temporary database.
  liftIO mkTemporaryDatabaseId >>= \case
    Left err ->
      error err -- We're generating the name ourselves, so no error
                -- handling needed.
    Right databaseId -> do
      -- Create the temporary database.
      liftIO $ withMutex mutex $ createTemporaryDatabase configuration databaseId
      return databaseId

-- REST interface
routes :: Configuration -> Mutex -> ScottyM ()
routes configuration@Configuration{..} mutex = do
  -- Add all the routes.
  post "/" $ do
    databaseId <- handleCreateRequest configuration mutex
    text $ TL.unlines
      [ TL.pack $ cfgClientUser
      , TL.pack $ cfgClientPass
      , TL.pack $ cfgPublishedAddressHost
      , TL.pack $ show $ cfgPublishedAddressPort
      , TL.pack $ unquotedIdentifier databaseId
      ]

main :: IO ()
main = do
  -- Load configuration from environment.
  loadConfiguration >>= \case
    Left msg -> hPutStrLn stderr msg
    Right configuration -> do
      -- Build options for Warp.
      let warpSettings =
            setPort (cfgListenPort configuration) $
            setHost (fromString $ cfgListenHost configuration) $
            defaultSettings
          options = Options { verbose = 1
                            , settings = warpSettings
                            }
      -- Mutex to prevent multiple "create" requests from being
      -- processed simultaneously; PostgreSQL cannot handle
      -- "cloning" a template concurrently.
      mutex <- mkMutex
      -- Force immediate creation of a single temporary database; we
      -- do this so that any configuration issues will become obvious
      -- on startup.
      void $ handleCreateRequest configuration mutex
      -- Start the web serving thread
      putStrLn $ "Starting with configuration: " ++ show configuration
      scottyOpts options $ routes configuration mutex
