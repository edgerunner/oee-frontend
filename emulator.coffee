http = require "http"
concat = require "concat-stream"

Array.prototype.random = -> this[Math.floor Math.random() * this.length]

defaults = (options) ->
  options.host = '127.0.0.1'
  options.port = 5984
  options.path = "/konzek_oee_log/#{options.path}"
  options.headers ?= {}
  options.headers['Content-Type'] ?= 'application/json'
  return options

machines = {}
http.get "http://127.0.0.1:5984/konzek_oee_log/_design/machines/_view/machines", (res)->
  res.setEncoding('utf8')
  #res.pipe process.stdout
  res.pipe concat (raw)->
    machines = (row.value for row in JSON.parse(raw).rows)

    start()

# random interval function
ri = (min, max) -> (min + Math.random() * (max-min)) * 1000

# random reliability
rr = (reliability) -> Math.random() < reliability

# start machines after some time
start = ->
  for machine in machines
    console.log machine
    setTimeout (machine)->
      machine.running = true
      put_event 'start', machine
      run machine
    , ri(3, 8), machine

run = (machine) ->
  # runner
  machine.interval = setInterval (machine) ->
    if rr 0.9
      put_event 'make', machine
    else
      put_event 'discard', machine
  , ri(1,3), machine

  # stopper
  setTimeout (machine)->
    stop machine
    machine.interval = setTimeout run, ri(1,15), machine # restart
  , ri(20,30), machine

stop = (machine) ->
  machine.running = false
  clearInterval machine.interval
  put_event 'stop', machine

put_event = (event, machine) ->
  timestamp = Date.now()
  req = http.request defaults {
    path: "#{machine._id}.event.#{timestamp}"
    method: 'PUT'
  }

  req.end JSON.stringify {
    'machine': machine._id
    'event': event
    'timestamp': timestamp
  }

  req.on 'response', (res)->
    console.log "#{res.statusCode} #{res.statusMessage} #{JSON.stringify res.headers.location}"

process.on "SIGINT", ->
  console.log 'exiting in 5s…'
  for machine in machines
    stop machine

  setTimeout process.exit, 5000






