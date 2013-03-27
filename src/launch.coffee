# Requires that the HTML document include these libraries:
#
#   Requires: knockout, store
#   Optional: jquery + jquery-ui (for highlight effect)

document.addEventListener 'DOMContentLoaded', ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect()
  sendPacket = (data) -> socket.emit 'data', data

  viewModel =
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    messageAdded: (element, index, data) ->
      element.parentNode.scrollTop = element.parentNode.scrollHeight
      jQuery(element).effect 'highlight' if jQuery?.prototype.effect?
    inputBox: ko.observable()
    isInputBoxSelected: ko.observable(true)
    input: ko.observable().extend {notify: 'always'}
    inputSubmitted: (form) -> @input text if text if text = @inputBox()?.trim()
    keys: ko.observable().extend {notify: 'always'}
    inputKeyUp: (data, event) -> @keys event.keyCode
  ko.applyBindings viewModel

  # Just for debugging in browser's JS console
  window.viewModel = viewModel

  document.getElementById('chat-preconnect').style.display = 'none'
  document.getElementById('chat-client').style.display = ''

  userInputProtocol = ->
    inputHistory =
      elements: ko.observableArray()
      idx: ko.observable(1)
      push: (text) -> @elements.push text; @escape()
      up: -> @idx @idx() - 1 unless @idx() is 0
      down: -> @idx @idx() + 1 unless @idx() is @elements().length
      escape: -> @idx @elements().length
      currentSelection: -> if @idx() < @elements().length then @elements()[@idx()] else ''
    inputHistory.selected = ko.computed -> inputHistory.currentSelection()

    inputHistory.selected.subscribe (text) -> viewModel.inputBox text
    viewModel.input.subscribe (text) -> inputHistory.push text
    viewModel.keys.subscribe (keyCode) ->
      switch keyCode
        when 27 then inputHistory.escape()
        when 38 then inputHistory.up()
        when 40 then inputHistory.down()

    # This inputSubmitted subscription annoys me. It straddles user input
    # protocol and server messaging protocol. I think the sendPacket() calls
    # need to move out into serverMessagingProtocol(), and occur in response
    # to events triggered here.

    viewModel.input.subscribe (text) ->
      if match = text.match /^\/nick\s+(.+)/
        sendPacket {action: 'identify', data: match[1]}
      else if text.match /^\//
        viewModel.messages.push {action: 'error', data: "Bad command: #{text}"}
      else
        sendPacket {action: 'say', data: text}
  userInputProtocol()

  serverMessagingProtocol = ->
    socket.on 'data', (data) ->
      # identity widget
      switch data.action
        when 'welcome'
          viewModel.identity data.data
          sendPacket {action: 'identify', data: preferred} if preferred = store.get 'identity'
        when 'identify'
          if data.sender is viewModel.identity()
            viewModel.identity data.data
            store.set 'identity', viewModel.identity()

      # chatbox widget
      if ['welcome', 'connect', 'disconnect', 'identify', 'say', 'error'].indexOf(data.action) >= 0
        viewModel.messages.shift() if viewModel.messages().length >= 1000
        viewModel.messages.push {sender: data.sender, action: data.action, data: data.data}

      # identity list widget
      switch data.action
        when 'welcome' then sendPacket {action: 'members'}
        when 'members' then viewModel.members(data.data)
        when 'connect' then viewModel.members.push data.sender
        when 'disconnect' then viewModel.members.remove data.sender
        when 'identify'
          if (i = viewModel.members.indexOf data.sender) >= 0
            viewModel.members.splice i, 1, data.data

      # Google Analytics
      if data.action is 'google-ua'
        do ->
          window._gaq ?= []
          _gaq = window._gaq
          _gaq.push ['_setAccount', data.data]
          _gaq.push ['_trackPageview']

          ga = document.createElement 'script'
          ga.type = 'text/javascript'
          ga.async = true
          ga.src = "#{if document.location.protocol is 'https:' then 'https://ssl' else 'http://www'}.google-analytics.com/ga.js"
          s = document.getElementsByTagName('script')[0]
          s.parentNode.insertBefore(ga, s)
  serverMessagingProtocol()

