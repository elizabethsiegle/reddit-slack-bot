module Paths_stockbot (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/Users/lizziesiegle/Desktop/programming/hask/stockbot/.stack-work/install/x86_64-osx/ghc-7.10.1/7.10.1/bin"
libdir     = "/Users/lizziesiegle/Desktop/programming/hask/stockbot/.stack-work/install/x86_64-osx/ghc-7.10.1/7.10.1/lib/x86_64-osx-ghc-7.10.1/stock_5MPaQhBVnOjJlwsnURIJIw"
datadir    = "/Users/lizziesiegle/Desktop/programming/hask/stockbot/.stack-work/install/x86_64-osx/ghc-7.10.1/7.10.1/share/x86_64-osx-ghc-7.10.1/stockbot-0.1.0.0"
libexecdir = "/Users/lizziesiegle/Desktop/programming/hask/stockbot/.stack-work/install/x86_64-osx/ghc-7.10.1/7.10.1/libexec"
sysconfdir = "/Users/lizziesiegle/Desktop/programming/hask/stockbot/.stack-work/install/x86_64-osx/ghc-7.10.1/7.10.1/etc"

getBinDir, getLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "stockbot_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "stockbot_libdir") (\_ -> return libdir)
getDataDir = catchIO (getEnv "stockbot_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "stockbot_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "stockbot_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
