{-# LANGUAGE OverloadedStrings, DeriveDataTypeable, ScopedTypeVariables #-}

module Glue.CachingSpec where

import Data.Typeable
import Glue.Caching
import Test.Hspec
import Data.IORef
import Test.QuickCheck
import Control.Exception.Base hiding (throw, throwIO)
import Control.Exception.Lifted
import qualified Data.HashMap.Strict as M

data CachingTestException = CachingTestException deriving (Eq, Show, Typeable)
instance Exception CachingTestException

spec :: Spec
spec = do
  describe "cacheWithBasic" $ do
    it "For a second request, the value comes from the cache" $ do
      property $ \(request :: Int, result :: Int) -> do
        ref <- newIORef (0 :: Int)
        let service req = do
                            if req == request then return () else throwIO CachingTestException
                            callCount <- atomicModifyIORef' ref (\c -> (c + 1, c + 1))
                            if callCount > 1 then throwIO CachingTestException else return result
        cache <- newIORef M.empty
        let lookupWith r = fmap (M.lookup r) $ readIORef cache
        let insertWith req resp = atomicModifyIORef' cache (\c -> (M.insert req resp c, ()))
        let cachedService = cacheWithBasic lookupWith insertWith service
        (cachedService request) `shouldReturn` result
        (cachedService request) `shouldReturn` result

