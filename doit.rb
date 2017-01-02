require 'rubygems'
require 'nokogiri'
require 'excon'
require 'uri'
require 'digest'
require 'fileutils'
require 'pp'

save_to = File.expand_path("../birdswell", __FILE__)
puts save_to
FileUtils.mkdir_p(save_to + "/assets")
paths_to_scrape = ["/", "/products/luscious-swell-guys-long-sleeve"]
paths_already_scrapped = []

save_asset = Proc.new do |src|
  uri = URI.parse(src)
  if uri.host == "cdn.shopify.com"
    filename = uri.path.split("/").last
    new_path = "/assets/" + filename
    full_new_path = save_to + new_path
    unless File.exists?(full_new_path)
      puts "downloading #{src}"
      uri_to_get = URI.parse(src)
      unless uri_to_get.scheme
        uri_to_get.scheme = "http"
      end
      unless uri_to_get.host
        uri_to_get.host = "www.birdswell.com"
      end
      data = Excon.get(uri_to_get.to_s).body
      if filename.match(/\.css$/)
        css_path = uri.path.split("/")[0...-1].join("/")
        data.scan(/url\((.*)\)/).each do |match|
          path_to_fetch_it = URI.parse(src)
          path_to_fetch_it.path = css_path + "/" + match[0]
          save_asset.call(path_to_fetch_it.to_s)
        end
      end
      File.open(full_new_path, "w+"){|fp| fp.write(data)}
    end
    new_path
  else
    uri.path
  end
end

fetch_page = Proc.new do |path|
  begin
    Excon.get("http://www.birdswell.com" + path).body
  rescue => e
    puts e.inspect
    nil
  end
end

while next_path = (paths_to_scrape - paths_already_scrapped).first
  full_save_to = save_to + next_path + "index.html"
  puts "fetching #{next_path}"
  if page_body = Excon.get("http://www.birdswell.com" + next_path).body
    doc = Nokogiri::HTML(page_body)
    doc.xpath("//img").each do |img|
      if img["src"]
        img["src"] = save_asset.call(img["src"])
      end
    end
    doc.xpath("//link").each do |link|
      if link["href"]
        link["href"] = save_asset.call(link["href"])
      end
    end
    doc.xpath("//script").each do |script|
      if script["src"]
        uri = URI.parse(script["src"])
        if uri.host == "cdn.shopify.com"
          script["src"] = save_asset.call(script["src"])
        end
      end
    end
    doc.xpath("//a").each do |a|
      if a["href"]
        uri = URI.parse(a["href"])
        if uri.host.nil? && uri.path.to_s[0] == "/" && !uri.to_s.index("#")
          paths_to_scrape << a["href"]
          a["href"] = a["href"].gsub(/[^\w\/]*/,"")
        end
      end
    end
    path_local = next_path.gsub(/[^\w\/]*/,"")
    FileUtils.mkdir_p(save_to + path_local)
    File.open(save_to + path_local + "/index.html", "w+"){|fp| fp.write(doc.to_s)}

    paths_already_scrapped << next_path

  end
end

