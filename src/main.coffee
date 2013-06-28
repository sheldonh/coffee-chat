StaticWebRequestHandler = require './static-web-request-handler'

fs = require('fs')
requestHandler = new StaticWebRequestHandler('web', process.env.LIMIT_HOST)
key = fs.readFileSync('./key.pem').toString()
cert = fs.readFileSync('./cert.pem').toString()
webServer = require('https').createServer({key: key, cert: cert}, requestHandler.handle)
io = require('socket.io').listen webServer

class ChatService
  constructor: ->
    @guest_counter = 0
    @identities = {}

  connect: (id, callback) ->
    identity = "guest#{++@guest_counter}"
    @identities[identity] = id
    callback identity

  disconnect: (id, callback) ->
    for candidate of @identities
      if @identities[candidate] is id
        delete @identities[candidate]
        callback candidate

  receive: (id, data, reply, broadcast) ->
    data = {sender: @sender_identity(id), action: data.action, data: data.data}
    switch data.action
      when 'identify'
        if data.data.match /^guest\d+/i
          reply {action: 'error', data: "Please don't identify as a guest."}
        else if data.data is @sender_identity(id)
          reply {action: 'error', data: "You are already #{data.data}."}
        else if @have_identity data.data
          reply {action: 'error', data: "The identity #{data.data} is already in use."}
        else
          @identities[data.data] = id
          delete @identities[data.sender]
          broadcast data
      when 'say'
        broadcast data
      when 'members'
        everyone_except_sender = (Object.keys @identities).filter (x) -> x isnt data.sender
        reply {action: 'members', data: everyone_except_sender}

  have_identity: (id) ->
    Object.keys(@identities).some (taken) -> id.toLowerCase() is taken.toLowerCase()

  sender_identity: (id) ->
    (x for x of @identities when @identities[x] is id)[0]

service = new ChatService()

# Service protocol muddled up with websockets
io.sockets.on 'connection', (socket) ->
  service.connect socket.id, (initial_identity) ->
    if process.env.GOOGLE_UA?
      socket.emit 'data', {action: 'google-ua', data: process.env.GOOGLE_UA}
    socket.emit 'data', {action: 'welcome', data: initial_identity}
    socket.broadcast.emit 'data', {sender: initial_identity, action: 'connect'}

  socket.on 'data', (data) ->
    broadcast = (accepted) -> io.sockets.emit 'data', accepted
    reply = (response) -> socket.emit 'data', response
    service.receive socket.id, data, reply, broadcast

  socket.on 'disconnect', -> service.disconnect socket.id, (parting_identity) ->
    io.sockets.emit 'data', {sender: parting_identity, action: 'disconnect'}

webServer.listen(443)
