cask "routetone" do
  version "0.1.3"
  sha256 "3ca3829d2cd03a26d92dadceb56e61a8ac854324a64b856e2a6ba756c01cc3f4"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}-r1.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
