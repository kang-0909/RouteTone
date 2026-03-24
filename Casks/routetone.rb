cask "routetone" do
  version "0.1.2"
  sha256 "1d33bee958ae9e7b38c15b202ff09c517ca33bfc58cb9a266eeae389af2246f9"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
