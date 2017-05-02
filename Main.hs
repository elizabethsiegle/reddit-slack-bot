{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE PatternGuards #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}

module Main where

import System.IO
import Data.ByteString.Lazy.Char8
import Data.ByteString.Lazy.Char8()
import GHC.Types (IO (..))
import Control.Monad
import Data.Char(toUpper)
import Data.Maybe
import Data.Monoid ((<>))
import Data.Bool
import Prelude
import Network.HTTP.Client.TLS (getGlobalManager)
import Network.HTTP.Client
import Network.Linklater
import Control.Monad.Trans.Maybe
import Data.Aeson
import Servant.Common.Req

import qualified Data.Text as T
import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import           Data.Aeson (encode)
import           Data.Text (Text)
import Network.HTTP.Types
import Network.TLS
import Network.Wai.Handler.Warp (run)
import Network.Wreq

import Network.HTTP.Types.Status (statusCode)
import Network.HTTP.Base
import Servant.Client (ClientEnv(ClientEnv), runClientM)
import Web.Yahoo.Finance.YQL
--       (StockSymbol(StockSymbol), YQLQuery(YQLQuery), getQuotes,
--        yahooFinanceJsonBaseUrl)
----import Network.Yahoo.Finance

import Reddit
import Reddit.Types.Post
import Control.Monad
import Control.Monad.IO.Class
import qualified Data.Text as Text
import qualified Data.Text.IO as Text

readSlackFile :: FilePath -> IO Text
readSlackFile filename =
  T.filter (/= '\n') . T.pack <$> Prelude.readFile filename

configIO :: IO Config
configIO =
  Config <$> (readSlackFile "hook")

parseText :: Text -> Maybe Text
parseText text = case T.strip text of
  "" -> Nothing
  x -> Just x

liftMaybe :: Maybe a -> IO a
liftMaybe = maybe mzero return

messageOfCommandStock :: Command -> IO Network.Linklater.Message
messageOfCommandStock (Command "stock" user channel (Just text)) = do
  manager <- getGlobalManager
  query <- liftMaybe (parseText text)
  res <- runClientM (getQuotes (YQLQuery [StockSymbol query])) (ClientEnv manager yahooFinanceJsonBaseUrl)
  case res of
    Right responseQuotes ->
      return (messageOf [FormatAt user, FormatString (T.pack(show responseQuotes))])
      where 
        messageOf =
          FormattedMessage(EmojiIcon "gift") "stockbot" channel

stockify :: Maybe Command -> IO Text
stockify Nothing =
  return "Unrecognized Slack request!"

stockify (Just command) = do
  Prelude.putStrLn ("+ Incoming command: " <> show command)
  message <- (messageOfCommandStock) command
  config <- configIO
  --putStrLn ("+ Outgoing message: " <> show (message))
  case (debug, message) of
    (False,  m) -> do
      _ <- say m config
      return ""
    _ ->
      return ""
  where
    debug = False

main :: IO ()
main = do
  Prelude.putStrLn ("+ Listening on port " <> show port)
  run port (slashSimple stockify)
    where
      port = 3000
