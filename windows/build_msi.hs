{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE CPP, ScopedTypeVariables #-}
import Control.Exception
import Control.Monad
import Data.Version (Version, makeVersion, showVersion)
import Distribution.Package
import Distribution.PackageDescription
import Distribution.PackageDescription.Parsec
#if MIN_VERSION_Cabal(3,8,0)
import Distribution.Simple.PackageDescription (readGenericPackageDescription)
#endif
import qualified Distribution.Types.Version as Cabal
import Distribution.Verbosity
import qualified System.Info as SysInfo
import System.Process

getGitHash :: IO (Maybe String)
getGitHash =
  liftM (Just . takeWhile (/='\n')) (readProcess "git" ["rev-parse", "--short", "HEAD"] "")
  `catch` \(_::SomeException) -> return Nothing

getVersion :: FilePath -> IO Version
getVersion cabalFile = do
  pkg <- readGenericPackageDescription silent cabalFile
  let cabalVersion = pkgVersion $ package $ packageDescription $ pkg
  return $ makeVersion $ Cabal.versionNumbers cabalVersion

main :: IO ()
main = do
  gitHashMaybe <- getGitHash
  version <- getVersion "../CPL.cabal"
  let suffix_githash =
        case gitHashMaybe of
          Nothing -> ""
          Just gitHash -> "_" ++ gitHash
      msiFileName = "CPL-" ++ showVersion version ++ suffix_githash ++ "-" ++ SysInfo.os ++ "-" ++ SysInfo.arch ++ ".msi"
      arch =
        case SysInfo.arch of
          "x86_64" -> "x64"
          "i386" -> "x86"
          s -> s
  callProcess "candle" $ ["-arch", arch, "CPL.wxs"]
  callProcess "light" ["-ext", "WixUIExtension", "-out", msiFileName, "CPL.wixobj"]
  return ()
