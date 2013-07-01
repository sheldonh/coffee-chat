# Requires that the HTML document include these libraries:
#
#   Requires: knockout, store
#   Optional: jquery (for chat-box resizing)
#             + jquery-ui (for highlight effect)

mark_down_message = require('./mark_down_message')

document.addEventListener 'DOMContentLoaded', ->

  # Firefox: https://bugzilla.mozilla.org/show_bug.cgi?id=614304
  window.addEventListener 'keydown', (e) -> e.preventDefault() if e.keyCode == 27

  socket = io.connect()
  sendPacket = (data) -> socket.emit 'data', data

  documentTitle =
    default: 'Chat'
    blink:  ->
      if document.hasFocus? and !document.hasFocus()
        viewModel.title "...incoming..."
        window.setTimeout (-> viewModel.title documentTitle.default), 500
        window.setTimeout documentTitle.blink, 1000

  viewModel =
    title: ko.observable(documentTitle.default)
    identity: ko.observable()
    members: ko.observableArray()
    messages: ko.observableArray()
    messageAdded: (element, index, data) ->
      element.parentNode.scrollTop = element.parentNode.scrollHeight
      jQuery(element).effect 'highlight' if jQuery?.prototype.effect?
      if data.action is 'say'
        documentTitle.blink() if data.action is 'say'
        soundHandle = document.getElementById('soundHandle')
        soundHandle.src = 'button-3.wav'
        soundHandle.play()
    inputBox: ko.observable()
    input: ko.observable().extend {notify: 'always'}
    inputSubmitted: (form) -> @input text if text if text = @inputBox()?.trim()
    keys: ko.observable().extend {notify: 'always'}
    inputKeyUp: (data, event) -> @keys event.keyCode
    messageTemplate: (message) -> "#{message.action}-message-template"
  ko.applyBindings viewModel, document.getElementsByTagName('html')[0]

  # Just for debugging in browser's JS console
  window.viewModel = viewModel

  # From https://github.com/filamentgroup/jQuery-Pixel-Em-Converter
  # Couldn't get it working as an externel dependency loaded from the HTML page.
  # Consider http://verge.airve.com/ instead.
  $.fn.toEm = (settings) ->
    settings = jQuery.extend({scope: 'body'}, settings)
    that = parseInt(@[0], 10)
    e = jQuery('<div style="display: none; font-size: 1em; margin: 0; padding:0; height: auto; line-height: 1; border:0;">&nbsp;</div>')
    scopeTest = e.appendTo(settings.scope)
    scopeVal = scopeTest.height()
    scopeTest.remove()
    (that / scopeVal).toFixed(8)

  resizeChatBox = ->
    windowPixels = $(window).height()
    windowEms = $(windowPixels).toEm()
    if windowEms > 35
      windowEms = 35
    else if windowEms < 17
      windowEms = 17
    styleHeight = "#{windowEms - 10}em"
    document.getElementById('chat-box').style.height = styleHeight
    if $(window).width() > 767
      document.getElementById('chat-identity-list').style.height = styleHeight
    else
      document.getElementById('chat-identity-list').style.height = "2.3em"

  resizeChatBox()
  window.addEventListener 'resize', resizeChatBox
  window.addEventListener 'orientationchange', resizeChatBox

  document.getElementById('chat-preconnect').style.display = 'none'
  document.getElementById('chat-client').style.display = ''
  document.getElementById('chat-input').focus()

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
        message =
          sender: data.sender
          action: data.action
          data: if data.action is 'say' then mark_down_message data.data else data.data
        viewModel.messages.push message

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

