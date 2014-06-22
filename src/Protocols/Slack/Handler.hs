module Protocols.Slack.Handler (respond) where

-- Haskell platform libraries

import           Control.Monad.IO.Class    (liftIO)
import           System.Environment        (getEnv)
import           Text.Parsec.Char
import           Text.Parsec.Combinator
import           Text.Parsec.Error
import           Text.Parsec.Prim
import           Text.Parsec.String

-- foreign libraries

import           Happstack.Server

-- native libraries

import qualified Protocols.Slack.Request   as SQ
import qualified Protocols.Slack.Response  as SP
import           Hasklets                  (hasklets)
import           Settings

-- public functions

respond :: ServerPart Response
respond = do
    msg <- getDataFn SQ.fromPost
    case msg of
      Left errors -> badRequest . toResponse $ unlines errors
      Right m     -> validateToken m

-- private functions

validateToken :: SQ.Request -> ServerPart Response
validateToken msg = do
    token <- liftIO $ getEnv slackTokenEnvVar
    if token == SQ.secretToken msg
      then craftResponse msg
      else unauthorized $ toResponse "invalid secret token"

craftResponse :: SQ.Request -> ServerPart Response
craftResponse msg =
    case applyHasklets msg of
      Right str -> ok . toResponse $ SP.Response (SQ.userName msg) str
      Left err  -> badRequest . toResponse $ show err

applyHasklets :: SQ.Request -> Either ParseError String
applyHasklets msg = parse parser str str
  where
    parser = do
        optional $ char '@'
        string chatbotName
        optional $ char ':'
        spaces
        choice hasklets
    str = SQ.text msg
