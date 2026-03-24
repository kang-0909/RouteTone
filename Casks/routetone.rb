cask "routetone" do
  version "0.1.2"
  sha256 "36b0795e096f9b3349ca0be9e85958bed6d8d435c008b25168d1989563045368"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
