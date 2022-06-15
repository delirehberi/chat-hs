{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Text (Text)
import qualified Network.WebSockets as WS
import qualified Data.Text as T
import qualified Data.Text.IO as T 
import Data.Char
import Control.Monad(forM_, forever)
import Control.Concurrent (MVar,newMVar, readMVar,modifyMVar,modifyMVar_)
import Control.Monad.IO.Class (MonadIO(liftIO))
import Control.Exception (finally)




type Client = (Text, WS.Connection)

type ServerState = [Client]

newServerState :: ServerState
newServerState = []

numClients :: ServerState -> Int
numClients = length

clientExists :: Client -> ServerState -> Bool
clientExists client = any ( (== fst client) . fst )

addClient :: Client -> ServerState -> ServerState
addClient client clients = client : clients 

removeClient :: Client -> ServerState -> ServerState
removeClient client = filter ((/= fst client) . fst) 

broadcast :: Text -> ServerState -> IO () 
broadcast message clients = do 
    T.putStrLn message 
    forM_ clients $ \(_,conn) -> WS.sendTextData conn message 

application :: MVar ServerState -> WS.ServerApp
application state pending = do
    conn <- WS.acceptRequest pending 
    WS.forkPingThread conn 30
    msg <- WS.receiveData conn 
    clients <- liftIO $ readMVar state
    case msg of
        _ | not (prefix `T.isPrefixOf` msg) -> WS.sendTextData conn ("Wrong Announcement"::Text) 
          | any ($ fst client) [T.null, T.any isPunctuation, T.any isSpace] -> WS.sendTextData conn ("Name cannot" `mappend` "contain punctuation or whitespace, and " `mappend` "cannot be empty" :: Text)
          | clientExists client clients -> WS.sendTextData conn ("User already exists" :: Text)
          | otherwise -> flip finally disconnect $ do
            liftIO $ modifyMVar_ state $ \s -> do
                let s' = addClient client s 
                WS.sendTextData conn $ "Welcome! Users: " `mappend` T.intercalate ", " (map fst s) 
                broadcast (fst client `mappend` " joined") s' 
                return s'
            talk conn state client 
         where 
            prefix = "Hi! I am "
            client = (T.drop (T.length prefix) msg, conn) 
            disconnect = do
                s <- modifyMVar state $ \s ->
                    let s' = removeClient client s in return (s',s') 
                broadcast (fst client `mappend` " disconnected") s
talk :: WS.Connection -> MVar ServerState -> Client -> IO () 
talk conn state (user, _) = forever $ do
    msg <- WS.receiveData conn 
    liftIO $ readMVar state >>= broadcast (user `mappend` ": " `mappend` msg)

main :: IO ()
main = do
    state <- newMVar newServerState 
    putStrLn "9160 is listening for ws"
    WS.runServer "0.0.0.0" 9160 $ application state
