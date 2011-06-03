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
      c << joinsf(f, ['a','e'], ", ")
    elsif f.tag === "110"
      c << joinsf(f, ['a','b','e'], ", ")      
    elsif f.tag === "600"
      c << f['a']
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

records = MARC::XMLReader.new(ARGV[0])

wxr = Builder::XmlMarkup.new(:indent => 1)
wxr.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

wxr.rss 'version' => "2.0", 'xmlns:content' => "http://purl.org/rss/1.0/modules/content/", 'xmlns:wfw' => "http://wellformedweb.org/CommentAPI/", 'xmlns:dc' => "http://purl.org/dc/elements/1.1/", 'xmlns:wp' => "http://wordpress.org/export/1.0/" do
  wxr.channel do
    wxr.title "MARC2WXR"
    wxr.link "http://github.com/anarchivist/marc2wxr"
    wxr.language "en-us"
    wxr.ttl "40"
    wxr.description "conversion"
    wxr.wp :wxr_version, "1.1"

    records.each do |r|
      wxr.item do
        wxr.title title(r)
        wxr.content(:encoded) do
          wxr.cdata! contents(r)
        end 
        wxr.pubDate Time.now.rfc822
        wxr.guid "http://brooklynhistory.org/library/callno/#{r['099']['a']}", "isPermaLink" => "false"
        author = "admin"
        wxr.author author
        wxr.dc :creator, author
        # for category in a.categories
        #           wxr.category category.name
        #         end
        #         for tag in a.tags
        #           wxr.category tag.display_name
        #         end
        # wxr.wp :post_id, a.id
        wxr.wp :post_date, Time.now.rfc822
        # wxr.wp :comment_status, 'closed'
        # wxr.wp :ping_status, 'closed'
        # wxr.wp :post_name, a.permalink
        wxr.wp :status, 'publish'
        wxr.wp :post_parent, '0'
        wxr.wp :post_type, 'post'
      end
    end
  end
end  

puts wxr.to_s
