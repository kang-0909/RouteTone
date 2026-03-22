cask "routetone" do
  version "0.1.0"
  sha256 "fd0710b37302f23cddd7c6867a9ab3852293902fc354a81de922cea726f516b7"

  url "https://github.com/kang-0909/RouteTone/releases/download/v#{version}/RouteTone-v#{version}.zip"
  name "RouteTone"
  desc "Keep macOS on your preferred audio input and output devices"
  homepage "https://github.com/kang-0909/RouteTone"

  app "RouteTone.app"
end
