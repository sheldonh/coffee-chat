assert = require 'assert'

describe "The truth", ->
  it "is true", ->
    assert true is true
  it "isn't false", ->
    assert true isnt false
