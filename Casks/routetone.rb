cask "routetone" do
  version "0.1.1"
  sha256 "76b30092575f29b58b97745aefa0e1ddd1a25762fc90e80e26bb37b36f2b5ec8"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
