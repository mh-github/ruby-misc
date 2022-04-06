require 'rubygems'
require 'httparty'
require 'open-uri'
require 'nokogiri'
require 'csv'

gems_info_arr = []
ARGV.each do |gemfile|
    puts "Processing #{gemfile}"
    IO.foreach(gemfile) do |line|
        next if line !~ /^\s*gem/
        gem = line.match(/(?<=(['"]))(.*?)(?=\1)/)[0]

        response = HTTParty.get( 'https://rubygems.org/api/v1/gems/' + gem )

        if response.body.nil?
            gems_info_arr << ["#{gem} info not available rubygems.org api"]
            continue
        else
            github_url = response['source_code_uri'] || response['gem_uri'] || ''
        end

        summary = (response['info'] || '').delete("\n")
        if github_url.include? 'github'
            doc     = Nokogiri::HTML(open(github_url))
            p_items = doc.xpath('//article/p[@dir="auto"]').collect {|node| node.text.strip}[1..5]
            desc    = (p_items&.join(" ") || '').delete("\n")
        else
            desc = "Unable to retrieve github repository URL from rubygems.org"
        end

        gems_info_arr << [gem, github_url, summary, desc]
    end
end

puts "Writig to gems-info.csv"
CSV.open('gems-info.csv', 'w') do |csv|
    csv << ['Gem', 'Github URL', 'Summary', 'Description from README.md']
    gems_info_arr.each do |line|
        csv << line
    end
end

puts "Done ..."