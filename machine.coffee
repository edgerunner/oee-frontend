class Machine
  constructor: (doc) ->
    this[key] = value for key, value of doc

    @callbacks = {
      all:     []
      start:   []
      stop:    []
      make:    []
      discard: []
    }

  ri = (min, max) -> (min + Math.random() * (max-min)) * 1000

  on: (event, callback, parameters...) -> @callbacks[event].push { func: callback, param: parameters }

  emit: (event) ->
    for callback in @callbacks[event].concat(@callbacks['all'])
      callback.func {'event': event, 'machine': this}, callback.param...


  start: ->
    @power = on
    @emit 'start'
    setTimeout @generate, ri(1,5)

  stop: ->
    @power = off
    @emit 'stop'

  generate: =>
    return unless @power

    q = Math.random()
    switch
      when q < 0.05 then @stop()
      when q < 0.15 then @emit 'discard'
      else @emit 'make'

    setTimeout @generate, ri(1,2)





module.exports = Machine

