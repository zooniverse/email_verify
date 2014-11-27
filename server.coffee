express = require('express')
mysql      = require('mysql')
yaml       = require('js-yaml')
fs         = require('fs')
bodyParser = require('body-parser')

require('console-stamp')(console, '[yyyy-mm-dd HH:MM:ss.l Z]')

db_config = yaml.safeLoad(fs.readFileSync('/app/database.yml', 'utf8'))

connection = mysql.createConnection
  host:     db_config['production']['host']
  user:     db_config['production']['username']
  password: db_config['production']['password']
  database: db_config['production']['database']

connection.connect (err)->
  if err
    console.error("Could not connect to Zooniverse Home database")
    console.error err.stack

app = express()
app.use(bodyParser.json({ type: 'text' }))
app.enable('trust proxy')

app.get '/', (req, res)->
  res.status(200).end()

app.post '/unsub', (req, res)->
  report  = JSON.parse(req.body['Message'])

  if report.delivered?
    res.status(200).end()

  email   = report.mail.destination[0]
  if email?
    if report['bounce']['bounceType'] == 'Permanent'
      connection.query 'UPDATE users SET valid_email = false WHERE email = ?',[email], (err,result)->
        if (err)
          console.error "Tried and failed to unsubscribe #{email}"
          res.status(500).end()
        else
          console.log "Unsubscribed #{email}"
          res.status(200).end()
    else
      console.log "Ignoring non-permanent bounce for #{email}"
      res.status(200).end()


server = app.listen(process.env.PORT || 3000)
