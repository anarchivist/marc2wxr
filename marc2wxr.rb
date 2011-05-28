require 'date'
require 'marc'
require 'active_support'
require 'builder'

def title r
  r['245']['a'] + ', ' + r['245']['f']
end

def contents r
  c = "<p><strong>Call Number: " + r['099']['a'] + "</strong></p>\n"
  c << "<p><strong>Extent: " + r['300']['a'] + " " + r['300']['f'] + "</strong></p>\n"
  c << "<p>"
  c << r['520']['a']
  c << "</p>"
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

    records.each do |r|
      wxr.item do
        wxr.title title(r)
        wxr.content(:encoded) { |x| x << '<![CDATA[' + a.full_html + ']]>' }
        wxr.pubDate DateTime.now.to_formatted_s(:rfc822)
        wxr.guid "http://brooklynhistory.org/library/callno/#{r['099']['a']}", "isPermaLink" => "false"
        author = a.user.name rescue a.author
        wxr.author author
        wxr.dc :creator, author
        for category in a.categories
          wxr.category category.name
        end
        for tag in a.tags
          wxr.category tag.display_name
        end
        wxr.wp :post_id, a.id
        wxr.wp :post_date, a.published_at.strftime("%Y-%m-%d %H:%M:%S")
        wxr.wp :comment_status, 'closed'
        wxr.wp :ping_status, 'closed'
        wxr.wp :post_name, a.permalink
        wxr.wp :status, 'publish'
        wxr.wp :post_parent, '0'
        wxr.wp :post_type, 'post'
      end
    end
  end
end  
