# Rake tasks for updating documentation and running internal tests.

desc 'Generate Jekyll Markdown documentation from conformance test files into docs/tests/.'
task :spec_docs do
  require 'fileutils'
  require_relative 'lib/doc_gen/parser'
  require_relative 'lib/doc_gen/renderer'

  FileUtils.rm_rf('docs/tests')
  paths = Dir['test/site/**/*_spec.rb'] + Dir['test/supervisor/**/*_spec.rb']
  contexts = DocGen::Parser.parse_files(paths)
  DocGen::Renderer.render(contexts, output_dir: 'docs/tests')
  puts "Generated #{contexts.size} top-level context page(s) in docs/tests/"
end

desc 'Run internal unit and integration tests (test/).'
task :test do
  system 'bundle exec sus test'
end
