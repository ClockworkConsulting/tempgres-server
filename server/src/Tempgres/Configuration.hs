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
module Tempgres.Configuration
    ( Configuration(..)
    , loadConfiguration
    ) where

import           Data.Word (Word16)
import           GHC.Generics
import           System.Envy
import           Tempgres.DatabaseId (unsafeMkDatabaseId, DatabaseId)

-- | Configuration settings; read from environment variables.
-- Implementation note: The spellings here may be a bit strange,
-- because envy does a translation to environment variable names.
data Configuration = Configuration
    { cfgListenPort :: Int                -- Port to listen to for requests
    , cfgListenHost :: String             -- Host/interface to listen to for requests
    , cfgAdminUser :: String              -- Administrator user's user name
    , cfgAdminPass :: String              -- Administrator user's password
    , cfgPublishedAddressHost :: String   -- PostgreSQL host. The host name is returned
                                          -- without translation in the REST interface,
                                          -- so you'll want to use a FQDN.
    , cfgPublishedAddressPort :: Word16   -- Port that your PostgreSQL instance is listening on.
    , cfgDatabase :: DatabaseId           -- Database the administrator user will connect
                                          -- to when creating/dropping databases. This
                                          -- database MUST exist, but will NOT be modified
                                          -- in any way.
    , cfgDatabasePort :: Word16           -- The local port to use to connect to the database.
    , cfgDatabaseHost :: String           -- The local host name to use to connect to the database.
    , cfgClientUser :: String             -- User which the REST service will return for the
                                          -- test database. The test user will be the owner
                                          -- of all temporary databases that are created.
    , cfgClientPass :: String             -- Password for the test user.
    , cfgTemplateDatabase :: DatabaseId   -- Database to use as a template for the temporary database.
                                          -- It is recommended that you use either a) an empty template,
                                          -- or, b) a snapshot of your production schema from the last
                                          -- production release. The latter is helpful for testing
                                          -- any schema migrations you may have pending for the next
                                          -- release.
    , cfgDurationSeconds :: Int           -- Duration of temporary databases. All existing connections
                                          -- to the temporary database will be killed and the database will
                                          -- be dropped after this amount of time.
    } deriving (Generic, Show)

loadConfiguration :: IO (Either String Configuration)
loadConfiguration = runEnv $ gFromEnvCustom option defaults
  where
    option = defOption
      { dropPrefixCount = 3
      , customPrefix = "TEMPGRES"
      }

    defaults = Just $ Configuration
      { cfgListenPort = 8080
      , cfgListenHost = "*"
      , cfgAdminUser = "tempgres-admin"
      , cfgAdminPass = "tempgres-apass"
      , cfgDatabase = unsafeMkDatabaseId "postgres"
      , cfgDatabasePort = 5432
      , cfgDatabaseHost = "localhost"
      , cfgPublishedAddressHost = "localhost"
      , cfgPublishedAddressPort = 5432
      , cfgClientUser = "tempgres-client"
      , cfgClientPass = "tempgres-cpass"
      , cfgTemplateDatabase = unsafeMkDatabaseId "template1"
      , cfgDurationSeconds = 300
      }
