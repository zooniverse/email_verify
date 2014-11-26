express = require('express')
mysql      = require('mysql')
yaml       = require('js-yaml')
fs         = require('fs')
bodyParser = require('body-parser')

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
  report  = req.body
  console.log req.ips
  console.log  report

  if report.delivered?
    res.status(200).end()

  email   = report.mail.destination[0]
  if email?
    connection.query 'UPDATE users set valid_email = false where email = ?',[email], (err,result)->
      if (err)
        console.error "tried and failed to unsubscribe #{email}"
        res.status(500).end()
      else
        console.log "Unsubscribed #{email}"
        res.status(200).end()


server = app.listen(process.env.PORT || 3000)
