cask "routetone" do
  version "0.1.1"
  sha256 "52ae2516fafebdb78ab4195fa15fbc40ff94f42960983e4c7706540234f21ac7"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
