require 'rubygems'
require 'builder'
require 'marc'
require 'time'

def joinsf field, subfields, joinval
  sf = subfields.join "|"
  field.find_all {|s| s.code =~ Regexp.new("(#{sf})") } .map {|x| x.value} .join joinval
end

def subj s
  s.gsub(/\s[\|].\s/, " -- ")
end

def title r
  r['245']['a'] + ', ' + r['245']['f']
end

def contents r
  c = "<p><strong>Call Number: " + r['099']['a'] + "</strong></p>\n"
  c << "<p><strong>Extent: " + r['300']['a'] + " " + r['300']['f'] + "</strong></p>\n"
  c << "<p>\n" + r['520']['a'] + "</p>\n"
  #c << "<p>\n" + r['545']['a'] + "</p>\n"

  c << names(r)
  c << places(r)
  c << subjects(r)
  c << types(r)
  #c << "<p><a href=\"http://www.brooklynhistory.org\">View Finding Aid</a></p>"
end

def names r
  c = "<p><strong>Names:</strong></p>\n<ul>\n"
  r.find_all {|field| field.tag =~ /^(100|110|600|610)/}.each do |f|
    c << "<li>"
    if f.tag === "100"
      c << joinsf(f, ['a','d','e'], ", ")
    elsif f.tag === "110"
      c << joinsf(f, ['a','b','e'], ", ")      
    elsif f.tag === "600"
      c << joinsf(f, ['a','d'], ", ")
    else
      c << joinsf(f, ['a','b','f'], ", ")
    end
    c << "</li>\n"
  end
  c << "</ul>\n"
end

def places r
  c = "<p><strong>Places:</strong></p>\n<ul>\n"
  r.find_all {|field| field.tag === "651"}.each do |f|
    c << "<li>" + subj(f.value) + "</li>\n"
  end
  
  c << "</ul>\n"
end

def subjects r
  c = "<p><strong>Subjects:</strong></p>\n<ul>\n"
  r.find_all {|field| field.tag =~ /^(650|630)/}.each do |f|
    c << "<li>" + subj(f.value) + "</li>\n"
  end
  c << "</ul>\n"
end

def types r
  c = "<p><strong>Types of documents:</strong></p>\n<ul>\n"
  r.find_all {|field| field.tag === "655"}.each do |f|
    c << "<li>" + subj(f.value) + "</li>\n"
  end
  c << "</ul>\n"
end

xml_files = Dir[File.join(ARGV[0], '*.xml')]
t = Time.now

wxr = Builder::XmlMarkup.new(:indent => 1)
wxr.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

id = 1

wxr.rss 'version' => "2.0", 'xmlns:content' => "http://purl.org/rss/1.0/modules/content/", 'xmlns:wfw' => "http://wellformedweb.org/CommentAPI/", 'xmlns:dc' => "http://purl.org/dc/elements/1.1/", 'xmlns:wp' => "http://wordpress.org/export/1.0/" do
  wxr.channel do
    wxr.title "MARC2WXR"
    wxr.link "http://github.com/anarchivist/marc2wxr"
    wxr.description "conversion"
    wxr.pubDate t.rfc822
    wxr.language "en"
    wxr.wp :wxr_version, "1.1"
    wxr.wp :base_site_url, "http://brooklynhistory.org/library/wp"
    wxr.wp :base_blog_url, "http://brooklynhistory.org/library/wp"
    
    xml_files.each do |x|      
      MARC::XMLReader.new(x).each do |r|
        wxr.item do
          wxr.title title(r)
          wxr.link "http://brooklynhistory.org/library/callno/#{r['099']['a']}"
          wxr.pubDate t.rfc822
          wxr.dc :creator, "admin"
          wxr.guid "http://brooklynhistory.org/library/callno/#{r['099']['a']}", "isPermaLink" => "false"
          wxr.description ""
          wxr.content(:encoded) do
            wxr.cdata! contents(r)
          end
          wxr.wp :post_id, id.to_s
          wxr.wp :post_date, t.strftime('%Y-%m-%d %H:%M:%S')
          wxr.wp :post_date_gmt, t.utc.strftime('%Y-%m-%d %H:%M:%S')
          wxr.wp :comment_status, 'closed'
          wxr.wp :ping_status, 'open'
          wxr.wp :status, 'publish'
          wxr.wp :post_parent, '0'
          wxr.wp :post_type, 'post'
          wxr.wp :is_sticky, '0'
        end
      id += 1
      end
    end
  end
end  

puts wxr.target!
