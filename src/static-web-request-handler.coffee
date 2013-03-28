fs = require 'fs'
path = require 'path'

class StaticWebRequestHandler
  constructor: (@root, @host) ->

  handle: (req, res) =>
    url = if req.url is '/' then '/index.html' else req.url
    source = path.join(@root, url)
    if source.indexOf("#{@root}/") == 0 or !@hostHeaderOk req, @host
      fs.readFile source, (error, data) =>
        if not error
          @reply res, 200, @contentType(url), data
        else
          @reply res, 404, 'text/plain', "Object not found\n"
    else
      @reply res, 403, 'text/plain', "Forbidden\n"

  hostHeaderOk: (req, okHost) ->
    if okHost?
      requestHost = req.headers.host
      requestHost = match[1] if match = req.headers.host?.match /^(.+):\d+$/
      requestHost is okHost
    else true

  contentType: (url) ->
    if matched = url.match /\.(\w+)$/
      switch matched[1]
        when 'css' then 'text/css'
        when 'html' then 'text/html'
        when 'js' then 'application/javascript'
        else 'text/plain'

  reply: (res, code, contentType, body) ->
    res.writeHead code, {'Content-Type': contentType}; res.end body

exports.StaticWebRequestHandler = StaticWebRequestHandler
