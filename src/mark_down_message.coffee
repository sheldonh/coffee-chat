md = require('markdown').markdown

editLinks = (tree) ->
  for e, i in tree
    do (e, i) ->
      if e is 'link'
        tree[i + 1].target = '_blank'
      else if Array.isArray e
        editLinks e
  tree

mark_down_message = (text) ->
  md.renderJsonML md.toHTMLTree editLinks md.parse text

module.exports = mark_down_message
