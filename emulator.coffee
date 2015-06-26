cradle = require 'cradle'
Machine = require './machine'
util = require 'util'
db = new cradle.Connection().database('konzek_oee_log')

Array.prototype.random = -> this[Math.floor Math.random() * this.length]


machines = {}

db.view 'machines/machines', (err, doc) ->
  return console.log err if err
  machines = (new Machine(row.value) for row in doc.rows)
  start()

# random interval function
ri = (min, max) -> (min + Math.random() * (max-min)) * 1000

# start machines after some time
start = ->
  for machine in machines
    machine.on 'all', put_event
    machine.on 'stop', (e) ->
      setTimeout (machine)->
        machine.start()
      , ri(0,9), machine

    setTimeout (machine)->
      machine.start()
    , ri(3, 8), machine


put_event = (e) ->
  timestamp = Date.now()

  db.save "#{e.machine._id}.event.#{timestamp}.#{e.event}", {
    'machine': e.machine._id
    'event': e.event
    'timestamp': timestamp
  }, (err, res) ->
    if err
      console.log err
    else
      console.log "#{res.headers.status} PUT #{JSON.stringify res.headers.location}"

# stop machines when exiting
process.on "SIGINT", ->
  console.log '\nexiting in 5s…'
  for machine in machines
    machine.stop()

  setTimeout process.exit, 5000






