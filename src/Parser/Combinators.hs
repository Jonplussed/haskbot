module Parser.Combinators where

import Text.Parsec.String
import Text.Parsec.Char
import Text.Parsec.Combinator
import Text.Parsec.Prim

-- constants

botName :: String
botName = "haskbot"

-- public functions

atBotName :: Parser ()
atBotName = do
    optional $ char '@'
    string botName
    optional $ char ':'

withArgs :: String -> Parser String
withArgs com = do
    try $ string com >> space
    manyTill anyChar eof