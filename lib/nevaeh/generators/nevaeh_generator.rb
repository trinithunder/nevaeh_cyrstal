class NevaehGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)
  
  def test
    say "Just seeing if this works as I think it should", :green
  end
  
  def so
    say "So I guess this works if we get here huh", :red
  end
end
