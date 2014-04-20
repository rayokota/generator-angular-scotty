{-# LANGUAGE OverloadedStrings, ScopedTypeVariables, RecordWildCards,
             QuasiQuotes, TemplateHaskell #-}

module Main where

import Prelude hiding (product)

import Control.Monad.IO.Class (liftIO)
import qualified Database.Persist.Postgresql as Db
import Network.HTTP.Types
import Network.Wai.Middleware.RequestLogger
import Network.Wai.Middleware.Static
import Web.Scotty

import Control.Applicative ((<$>), (<*>))

import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Text.Blaze.Html.Renderer.Text (renderHtml)

import Models

runDB = flip Db.runSqlPersistMPool
connStr = "host=localhost dbname=testDB user=testUSER password='' port=5432"

main :: IO()
main = Db.withPostgresqlPool connStr 10 $ \pool -> do
  
  runDB pool $ Db.runMigration migrateAll

  scotty 3000 $ do
    middleware logStdoutDev
    middleware $ staticPolicy (noDots >-> addBase "public")
    get "/" $
      redirect "index.html"
    
    <% _.each(entities, function (entity) { %>
    get "/<%= baseName %>/<%= pluralize(entity.name) %>" $ do
      (<%= pluralize(entity.name) %> :: [Db.Entity <%= _.capitalize(entity.name) %>]) <-
        liftIO $ runDB pool $ Db.selectList [] []
      json <%= pluralize(entity.name) %>

    get "/<%= baseName %>/<%= pluralize(entity.name) %>/:id" $ do
      (id :: Integer) <- param "id"
      let key :: Db.Key <%= _.capitalize(entity.name) %> = Db.Key (Db.PersistInt64 $ fromIntegral id)
      (<%= entity.name %> :: Maybe <%= _.capitalize(entity.name) %>) <-
        liftIO $ runDB pool $ Db.get $ key
      case <%= entity.name %> of
        Just e  -> do setHeader "Access-Control-Allow-Origin" "*"
                      json $ Db.Entity key e 
        Nothing -> status notFound404

    post "/<%= baseName %>/<%= pluralize(entity.name) %>" $ do
      e :: <%= _.capitalize(entity.name) %> <- jsonData
      id <- liftIO $ runDB pool $ Db.insert e
      json $ Db.Entity id e

    put "/<%= baseName %>/<%= pluralize(entity.name) %>/:id" $ do
      (id :: Integer) <- param "id"
      let key :: Db.Key <%= _.capitalize(entity.name) %> = Db.Key (Db.PersistInt64 $ fromIntegral id)
      e :: <%= _.capitalize(entity.name) %> <- jsonData
      (<%= entity.name %> :: Maybe <%= _.capitalize(entity.name) %>) <-
        liftIO $ runDB pool $ Db.get $ key
      case <%= entity.name %> of
        Just _  -> do liftIO $ runDB pool $ Db.replace key $ e
                      json $ Db.Entity key e
        Nothing -> status notFound404

    delete "/<%= baseName %>/<%= pluralize(entity.name) %>/:id" $ do
      (id :: Integer) <- param "id"
      let key :: Db.Key <%= _.capitalize(entity.name) %> = Db.Key (Db.PersistInt64 $ fromIntegral id)
      (<%= entity.name %> :: Maybe <%= _.capitalize(entity.name) %>) <-
        liftIO $ runDB pool $ Db.get $ key
      case <%= entity.name %> of
        Just _  -> do liftIO $ runDB pool $ Db.delete $ key
                      status noContent204
        Nothing -> status notFound404
    <% }); %>

    notFound $ do
      status notFound404
      html $ "<h1>Not found :(</h1>"
