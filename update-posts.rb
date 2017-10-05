require 'net/http'
require 'uri'

url = URI.parse('https://qiita-pocket-api.herokuapp.com/articles')
req = Net::HTTP::Post.new(url.path)
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
res = http.request(req)
