cradle = require 'cradle'
Machine = require 'machine'
db = new cradle.Connection().database('konzek_oee_log')

Array.prototype.random = -> this[Math.floor Math.random() * this.length]


machines = {}

db.view 'machines/machines', (err, doc) ->
  return console.log err if err
  machines = (row.value for row in doc.rows)
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

  db.save "#{machine._id}.event.#{timestamp}.#{event}", {
    'machine': machine._id
    'event': event
    'timestamp': timestamp
  }, (err, res) ->
    if err
      console.log err
    else
      console.log "#{res.statusCode} #{res.statusMessage} #{JSON.stringify res.headers.location}"

# stop machines when exiting
process.on "SIGINT", ->
  console.log 'exiting in 5s…'
  for machine in machines
    stop machine

  setTimeout process.exit, 5000






