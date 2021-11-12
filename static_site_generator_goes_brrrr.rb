
index_page = File.read("birdswell/index.html")

SEP = "<!-- STATIC_SITE_GENERATOR_GO_BRRRRRRR -->"

index_top, index_middle, index_bottom = index_page.split(SEP)

unless index_top.to_s.size > 1
  raise "Index page missing a top"
end
unless index_middle.to_s.size > 1
  raise "Index page missing a middle"
end
unless index_bottom.to_s.size > 1
  raise "Index page missing a bottom"
end

Dir.glob("birdswell/*.html").each do |filepath|
  file_contents = File.read(filepath)
  if file_contents.index(SEP)
    top, middle, bottom = file_contents.split(SEP)

    unless top.to_s.size > 1
      raise "#{filepath} missing a top"
    end
    unless middle.to_s.size > 1
      raise "#{filepath} missing a middle"
    end
    unless bottom.to_s.size > 1
      raise "#{filepath} missing a bottom"
    end    

    File.write(filepath, "#{index_top}#{SEP}#{middle}#{SEP}#{index_bottom}")
  end
end