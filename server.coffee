express    = require('express')
pg         = require('pg')
yaml       = require('js-yaml')
fs         = require('fs')
SNSClient  = require('aws-snsclient')
winston    = require('winston')

winston.add(winston.transports.File, { filename: '/app/log/ses_json.log' })
winston.remove(winston.transports.Console)

require('console-stamp')(console, '[yyyy-mm-dd HH:MM:ss.l Z]')

db_config = yaml.safeLoad(fs.readFileSync('/app/database.yml', 'utf8'))
auth = yaml.safeLoad(fs.readFileSync('/app/auth.yml', 'utf8'))

sns_client = SNSClient auth, (err, message)->
  report  = JSON.parse(message.Message)
  winston.info(report)

  email   = report.mail.destination[0]
  email   = if email.indexOf("<") > -1 then email.match(/<(.+)>/)[1] else email
  if email?
    if report['notificationType'] == 'Complaint' or report['bounce']['bounceType'] == 'Permanent'
      pg.connect "postgres://#{db_config['production']['username']}:#{db_config['production']['password']}@#{db_config['production']['host']}/#{db_config['production']['database']}", (err, client, done)->
        if err
          console.error("Could not connect to Panoptes database")
          console.error err.stack
        else
          client.query 'UPDATE users SET valid_email = false WHERE email = $1',[email], (err,result)->
            if (err)
              console.error "Tried and failed to unsubscribe #{email}"
              console.error err.stack
            else
              console.log "Unsubscribed #{email} (#{report['notificationType']}); changed #{result.rowCount} rows"
            done()
    else
      console.log "Ignoring non-permanent bounce for #{email}"

app = express()

app.get '/', (req, res)->
  res.status(200).end()

app.post '/unsub', sns_client

server = app.listen(process.env.PORT || 3000)
