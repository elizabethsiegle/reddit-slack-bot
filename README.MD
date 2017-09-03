Do you like [Reddit](https://reddit.com) ? Do you like bots? If you answered yes to one, both, or neither of those, then you are in luck. This post will go over how to build a Reddit Slack bot in Haskell.

This is the second Haskell post here on the [Twilio blog](https://twilio.com/blog). So if you haven’t read the first one on setting up your Haskell developer environment, check that out [here](https://www.twilio.com/blog/2017/07/setting-up-your-haskell-developer-environment-with-twilio.html).

## What are Slash Commands?
According to the [Slack API site](https://api.slack.com/slash-commands), messages beginning with “/” are treated differently from other messages: they “enable Slack users to interact with your app directly from Slack” and all send their messages “…to the configured external URL via HTTP POST.”

In this post, we’ll build a custom slash command that shares a trending programming post from Reddit about whatever you pass it as a command. For example, if you typed */redditbot python*, it would return an article about Python.

## What We’ll be Using
- Access to a Slack team that allows you to install apps
- [Ngrok](https://ngrok.com) 
- [Linklater API](https://github.com/hlian/linklater) to build Slack bots in Haskell
- [Reddit API](https://github.com/intolerable/reddit) to get Reddit posts

## Cloning the GitHub repo
Get started by cloning the repo [here](https://github.com/elizabethsiegle/reddit-slack-bot) by entering the following in your terminal:

> git clone git@github.com:elizabethsiegle/reddit-slack-bot.git

> cd reddit-slack-bot

This keeps things simple because otherwise, so many package dependencies would clash and turn into [cabal hell](https://www.reddit.com/r/haskell/comments/2al3vx/how_do_you_avoid_the_cabal_hell/).

Next, fire up another terminal, **cd**
into the directory you cloned the repo into, and let’s open up a Ngrok tunnel.


> ngrok http 3000


We need that location part to pull from the *move-to-stack* fork of Twilio-Haskell which works with the dependencies of all the other packages.

## Get Started with Slack Apps
First, let’s go to https://api.slack.com. Then, click *Your Apps* in the top right-hand corner. You should see a page like the one below, and then click *Create New App*.


Pick a name for your bot and pick one of your Slack channels to deploy the bot to. Many groups now have a channel dedicated to testing bots. That’s one channel you could use. You should see something like this image below, which asks for your app name and a team you’re in (like a hackathon you were in, a class you took, a team you were on, or your company):


Click *Create App*, and then under features on the left-hand side, click on *Webhooks*. Make sure *Activate Incoming Webhooks* is on, and then scroll down and click *Add New Webhook to Team*. 


You should then see a page asking to confirm your identity. Pick the channel you wish to post to, and click *Authorize*.


Copy this webhook URL and paste it into a new file in our project called *hook*.

Sweet! Now, again on the left column of your app’s page, under *Features* go to *Slash Commands*. Click *Create New Command*.

Fill in the text boxes above however you wish. The slash command */redditbot* will be followed by a word that is searched for on Reddit. The bot will search Reddit and return a trending post about the word you searched for. Let’s check if the slash command registered. Save your project, open Slack, go to the team and channel you used above, and try your slash command.


If you don’t see the command auto-complete, then go back to *Create New Command*, check each step, and try again.

## Haskell Code: Building the Slack Bot
Now it’s time to examine some code. You will see a lot of packages and libraries imported into our project at the top of *Main.hs*. Let’s go over the functions our project already has.

First, we have *readSlackFile* which takes in our hook file and formats it into a type we want–in this case, one of *IO Text*. We need to read this file to send our message on Slack. Then *configIO* actually calls the function.

> readSlackFile :: FilePath -> IO Text

> readSlackFile filename =
  T.filter (/= '\n') . T.pack <$> Prelude.readFile filename

> configIO :: IO Config

> configIO =
  Config <$> (readSlackFile "hook")

Then we have *parseText* and *liftMaybe* check that there is a word to search following the slash command. Whatever parseText returns is passed to liftMaybe to return the topic we want to search Reddit for. Our printPost function formats the link to display in the message.


> parseText :: Text -> Maybe Text

> parseText text = case T.strip text of
  "" -> Nothing
  x -> Just x

> liftMaybe :: Maybe a -> IO a

> liftMaybe = maybe mzero return

> printPost :: Post -> T.Text

> printPost post = do
  title post <> "\n" <> (T.pack . show . created $ post) <> "\n" <> "http://reddit.com"<> permalink post <> "\n" <> "Score: " <> (T.pack . show . score $ post)

Next, we have *findQPosts* which takes in the query we return from *liftMaybe* and passes that to *runRedditAnon* from the Reddit API, which gets all the posts from the front page of Reddit. *FindQPosts* searches those for trending posts on a certain topic (in this case, programming).


> findQPosts:: Text -> RedditT IO PostListing
> findQPosts c = search (Just $ R "programming") (Reddit.Options Nothing (Just 0)) Hot c

Now we need to get Reddit posts and create the message that will be posted to Slack. We do this by calling all the functions we just made above. We also use some of Linklater’s functions to check the command and its passed text, search Reddit for the passed text, and format the information as a message for the Slack channel you configured. The returned Slack message @’s your Slack username in the beginning, too.

> messageOfCommandReddit :: Command -> IO Network.Linklater.Message

> messageOfCommandReddit (Command "reddit" user channel (Just text)) = do

> query <- liftMaybe (parseText text)

> posts <- runRedditAnon (findQPosts query)
  
  > case posts of

   > Right posts' -\>
       
  > return (messageOf [FormatAt user, FormatString (T.intercalate "\n\n". Prelude.map 

  > printPost $ contents posts')]) where
      
      > messageOf =
         
    > FormattedMessage(EmojiIcon "gift") "redditbot" channel

This is actually called in *messageOfCommandReddit* which checks if there’s no parameter passed. In that case, we post “Unrecognized Slack request!”

> redditify :: Maybe Command -> IO Text

> redditify Nothing =

 > return "Unrecognized Slack request!"

> redditify(Just command) = do

 > Prelude.putStrLn ("+ Incoming command: " <> show command)
 
 > message <- (messageOfCommandReddit) command
 
 > config <- configIO
 > case (debug, message) of

   > (False,  m) -\> do

     > _ <- say m config
     
     > return ""

   > _ -\>

     > return ""

 > where

   > debug = False

Lastly, our main function uses Linklater’s *slashSimple* method to run on that same port you also call with ngrok. It prints a message out upon successfully running.

> main :: IO ()

> main =  do

> Prelude.putStrLn ("+ Listening on port " <> show port)

> run port (slashSimple redditify)

> where
  
  > port = 3000

To run, go back to your current directory in the terminal and type *stack build*. This could take some time. So let’s check out Reddit or Hacker News in the meantime.


Once that’s complete, type *stack exec redditbot* on the command line in our current directory. In the Slack channel that you configured to handle apps, type in */redditbot ____* where you fill in the underscore with a programming-related topic, like Python, Swift, or Haskell.


If you get a **404_client_error**, then check your ngrok connection and tunnel. It should be open to 3000. If you get a **500_service_error**, then check that the command that is being expected in *messageOfCommandReddit* is the same command that is expected in your Slack app on the Slack website (in this post, it’s “/redditbot”).

If you see a pop-up asking if you want your application to accept incoming network connections, click “allow”.


## Conclusion
Yes, building Slack bots in Haskell is really that easy! Some Haskell APIs that you could use for another bot (or just in general) include:

- [Twilio](https://twilio.com)
- [Clarifai](https://clarifai.com)
- [Hacker News](https://github.com/dmjio/hackernews)
- [Google Calendar](https://github.com/georgeee/haskell-google-calendar-api)
- [Stripe](https://github.com/dmjio/stripe)
- [GitHub](https://github.com/phadej/github)
- [Giphy](https://github.com/passy/giphy-api)
- [Yahoo Finance](https://github.com/cdepillabout/yahoo-finance-api)
Questions? Comments? Find me online:

Email: lsiegle@twilio.com

Twitter: [@lizziepika](https://twitter.com/lizziepika)

GitHub: [elizabethsiegle](https://github.com/elizabethsiegle)