md = require('markdown').markdown

editLinks = (tree) ->
  tree.forEach (e) ->
    if e.href?
      e.target = '_blank'
    else if Array.isArray e
      editLinks e
  tree

mark_down_message = (text) ->
  md.renderJsonML md.toHTMLTree editLinks md.parse text

module.exports = mark_down_message
