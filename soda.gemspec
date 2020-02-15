require_relative "lib/soda/version"

Gem::Specification.new do |spec|
  spec.name     = "soda-core"
  spec.version  = Soda::VERSION
  spec.authors  = ["Noah Portes Chaikin"]
  spec.license  = "MIT"
  spec.summary  = "A flexible job runner for Ruby."

  spec.bindir         = "bin"
  spec.executables    = ["soda"]
  spec.files          = Dir["{lib}/**/*.rb", "bin/*"]

  spec.add_dependency "aws-sdk-sqs", "~> 1.7"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov", "~> 0.17.1"
end
