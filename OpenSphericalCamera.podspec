Pod::Spec.new do |s|
  s.name         = "OpenSphericalCamera"
  s.version      = "2.0.0.beta.1"
  s.summary      = "OpenSphericalCamera API Client in Swift"
  s.description  = <<-DESC
A Swift OpenSphericalCamera API library with Ricoh Theta S extension
                   DESC
  s.homepage     = "https://github.com/tatsu/OpenSphericalCamera"
  s.license      = "MIT"
  s.author       = { "Tatsuhiko Arai" => "tatsu@tatsu.com" }

  s.ios.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/tatsu/OpenSphericalCamera.git", :tag => "#{s.version}" }
  s.source_files  = "OpenSphericalCamera", "OpenSphericalCamera/**/*.swift"
end
