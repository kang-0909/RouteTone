cask "routetone" do
  version "0.1.3"
  sha256 "91ab309ea8d91c5fee3bf535d6dad863fd85210f3fefbddd29bdd9470b61cada"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
