require 'scraperwiki'
require 'open-uri'
require 'json'
require 'nokogiri'
require 'date'
# require 'open_uri_redirections'

class IndeedScraper
def initialize(searchterm, location)
@searchterm = searchterm
@location = location
@output = Array.new
end

# Search for jobs
def searchJobs
@searchterm.gsub!(" ", "+")
if @location != nil
@location.gsub!(", ", "%2C+")
@location.gsub!(" ", "+")
url = "http://www.indeed.com.my/jobs?q=" + @searchterm + "&l=" + @location
else
url = "http://www.indeed.com.my/jobs?q=" + @searchterm + "&l="
end
html = Nokogiri::HTML(open(url))
# Handle multiple pages
numresults = html.css("div#searchCount").text.split(" of ")
fresult = numresults[1].to_i/10.0
if fresult != numresults[1].to_i/10
count = fresult +1
else
count = numresults[1].to_i/10
end

# Loop through pages and get results
i = 1
while i <= count
# Parse each listing
html.css("div.row").each do |r|
jobhash = Hash.new
jobhash[:position] = r.css("h2.jobtitle").text.strip.lstrip
ident=r.css("h2")
ident=ident.first['id']
ident.to_s()
ident.gsub!(/.*_/im, "")
jobhash[:company] = r.css("span.company").text.strip.lstrip
jobhash[:location] = r.css('span[itemprop="jobLocation"]').text.strip.lstrip
date = r.css("span[class=date]").text.strip.lstrip
time = Time.now
if r.css("h2.jobtitle").css("a")[0]
jobhash[:url] = "http://indeed.com.my" + r.css("h2.jobtitle").css("a")[0]["href"]
begin
jobhash[:text] = Nokogiri::HTML(open(jobhash[:url])).text
rescue
begin
# jobhash[:text] = Nokogiri::HTML(open(jobhash[:url], :allow_redirections => :all)).text
rescue
end
end
end
@output.push(jobhash)

data={
"jobtitle" => jobhash[:position],
"employer" => jobhash[:company],
"location" => jobhash[:location],
"description" => jobhash[:text],
"date" => date,
"current_time" => time,
"id" => ident,
"url"=> jobhash[:url],
}
# save to database
ScraperWiki::save_sqlite(["id"], data)
end
# Get next page
i += 1
nextstart = (i-1)*10
if @location != nil
url = "http://www.indeed.com.my/jobs?q=" + @searchterm + "&l=" + @location + "&start=" + nextstart.to_s
else
url = "http://www.indeed.com.my/jobs?q=" + @searchterm + "&start=" + nextstart.to_s
end
html = Nokogiri::HTML(open(url))
end
end
# Generates JSON output
def getOutput
JSON.pretty_generate(@output)
end
end

# Scrape Jobs-
# i = IndeedScraper.new("keyword", "location (or nil if no location)")
i = IndeedScraper.new("analytics", "")
i.searchJobs
# puts i.getOutput
