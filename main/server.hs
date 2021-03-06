{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

import           Ace.Data.Config
import           Ace.Data.Offline
import           Ace.Data.Protocol
import           Ace.Data.Robot
import           Ace.Data.Web
import qualified Ace.IO.Offline.Server as Server
import qualified Ace.Robot.Registry as Robot
import qualified Ace.Web as Web
import qualified Ace.World.Registry as World

import qualified Data.List as List
import qualified Data.Text as Text

import           P

import           System.IO (IO)
import qualified System.IO as IO
import           System.Environment (getArgs, lookupEnv)
import           System.Exit (exitFailure)

import           X.Control.Monad.Trans.Either.Exit (orDie)

main :: IO ()
main =
  getArgs >>= \s ->
    case s of
      (map:executable:_:_:_) -> do
        config <-
          Config
            <$> setting "ENABLE_FUTURES" FutureDisabled FutureDisabled FutureEnabled
            <*> setting "ENABLE_SPLURGES" SplurgeDisabled SplurgeDisabled SplurgeEnabled
            <*> setting "ENABLE_OPTIONS" OptionDisabled OptionDisabled OptionEnabled

        let
          names = (\n -> RobotIdentifier (RobotName $ Text.pack n) (Punter $ Text.pack n)) <$> List.drop 2 s
          bots = catMaybes $ fmap (Robot.pick . identifierName) names

        unless (length bots == length names) $ do
          IO.hPutStrLn IO.stderr $ "Couldn't find a match for all your requested bots [" <> (Text.unpack . Text.intercalate ", " $ (robotName . identifierName) <$> names) <> "]. Available: "
          forM_ Robot.names $ \name -> IO.hPutStrLn IO.stderr $ "  " <> (Text.unpack . robotName) name
          exitFailure

        world <- World.pick $ Text.pack map
        gid <- Web.generateNewId
        void . orDie Server.renderServerError $
          Server.run gid executable names world (ServerConfig config True)
        IO.hPutStrLn IO.stderr . Text.unpack $ "Game: " <> (gameId gid)

      _ -> do
        IO.hPutStr IO.stderr "usage: server MAP EXECUTABLE BOT BOT ..."
        exitFailure


setting :: [Char] -> a -> a -> a -> IO a
setting name dfault disabled enabled =
  with (lookupEnv name) $ \n -> case n of
    Nothing ->
      dfault
    Just "1" ->
      enabled
    Just "t" ->
      enabled
    Just "true" ->
      enabled
    Just "on" ->
      enabled
    _ ->
      disabled
