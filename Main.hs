{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE PatternGuards #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}
module Main where


import Data.ByteString.Lazy.Char8
import Data.ByteString.Lazy.Char8()
import GHC.Types (IO (..))
import Control.Monad
import Control.Exception.Base
import Data.Char(toUpper)
import Data.Maybe
import Data.Monoid ((<>))
import Data.Bool
import Prelude
import Network.HTTP.Client
import Network.HTTP.Client.TLS (getGlobalManager)
import Network.Linklater
import Control.Monad.Trans.Maybe
import Data.Aeson
import Servant.Common.Req

import qualified Data.Text as T
import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Trans.Maybe (MaybeT, runMaybeT)
import           Data.Aeson (encode)
import           Data.Text (Text, pack)
import Network.HTTP.Types
import Network.TLS
import Network.Wai.Handler.Warp (run)
import Network.Wreq
import Network.Wreq.Types
import Network.Wreq.Lens

import Network.HTTP.Types.Status (statusCode)
import Network.HTTP.Base
import Servant.Client (ClientEnv(ClientEnv), runClientM)
import Reddit
import Reddit.Types.Post
import Reddit.Types.SearchOptions (Order (..))
import Twilio
import Twilio.Calls as Calls
import Twilio.Messages
import Control.Monad.IO.Class (liftIO)
import System.Environment (getEnv, setEnv)
import Control.Lens hiding ((.=))

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

printPost :: Post -> T.Text
printPost post = do
  title post <> "\n" <> (T.pack . show . created $ post) <> "\n" <> "http://reddit.com"<> permalink post <> "\n" <> "Score: " <> (T.pack . show . score $ post)

--searches for Hot programming posts given input (ie haskell)
findQPosts:: Text -> RedditT IO PostListing
findQPosts c = search (Just $ R "programming") (Reddit.Options Nothing (Just 0)) Hot c

--gets Reddit posts, and creates the message that will be 
--posted to Slack. 
messageOfCommandReddit :: Command -> IO Network.Linklater.Message
messageOfCommandReddit (Command "reddit" user channel (Just text)) = do
  query <- liftMaybe (parseText text)
  posts <- runRedditAnon (findQPosts query)
  case posts of
    Right posts' ->
       return (messageOf [FormatAt user, FormatString (T.intercalate "\n\n". Prelude.map printPost $ contents posts')]) where
        messageOf =
          FormattedMessage(EmojiIcon "gift") "redditbot" channel
          
--calls *messageOfCommandReddit*, which actually posts the 
--message to Slack after running *stack build*, then *stack 
--exec redditbot*, and then opening up a Ngrok tunnel at the same port.
redditify :: Maybe Command -> IO Text
redditify Nothing =
  return "Unrecognized Slack request!"

redditify(Just command) = do
  Prelude.putStrLn ("+ Incoming command: " <> show command)
  message <- (messageOfCommandReddit) command
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

help :: IO ()
help = runTwilio' (getEnv "ACCOUNT_SID")
                  (getEnv "AUTH_TOKEN") $ do
  -- Print Calls.
  calls <- Calls.get
  liftIO $ Prelude.putStrLn (show calls)
  liftIO $ print calls

  --Send a Message.
  let body = PostMessage "+16505647814" "+13213237917" "dysFUNCTIONAL programming" --num to text, then twilio num
  message <- Twilio.Messages.post body
  liftIO $ print message
main :: IO ()
main =  do
	help
	Prelude.putStrLn ("+ Listening on port " <> show port)
	run port (slashSimple redditify)
	where 
		port = 3000

                    
