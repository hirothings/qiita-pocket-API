require 'net/http'
require 'uri'

url = URI.parse('https://qiita-pocket-api.herokuapp.com/articles')
req = Net::HTTP::Post.new(url.path)
res = Net::HTTP.new(url.host, url.port).start do |http|
  http.request(req)
end

puts res.body
