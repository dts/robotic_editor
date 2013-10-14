# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'robotic_editor/version'

Gem::Specification.new do |spec|
  spec.name          = "robotic_editor"
  spec.version       = RoboticEditor::VERSION
  spec.authors       = ["Daniel Staudigel"]
  spec.email         = ["dstaudigel@gmail.com"]
  spec.description   = %q{Robotic_editor automatically formats WYSIWYG text to better fit a website's style.}
  spec.summary       = %q{A gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency "nokogiri"
end
