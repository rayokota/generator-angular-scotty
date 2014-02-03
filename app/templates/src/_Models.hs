{-# LANGUAGE TemplateHaskell, QuasiQuotes,
             TypeFamilies, EmptyDataDecls,
             FlexibleContexts, FlexibleInstances, GADTs,
             OverloadedStrings #-}

module Models where

import Data.Time (UTCTime)
import Database.Persist.TH

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
<% _.each(entities, function (entity) { %>
<%= _.capitalize(entity.name) %> json
    <% _.each(entity.attrs, function (attr) { %>
    <%= attr.attrName %> <%= attr.attrImplType %> <% if (attr.required) { %>Maybe<% } %><% }); %>
    deriving Show<% }); %>
|]
