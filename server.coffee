express = require('express')
mysql      = require('mysql')
yaml       = require('js-yaml')
fs         = require('fs')
SNSClient  = require('aws-snsclient')
winston    = require('winston')

winston.add(winston.transports.File, { filename: '/app/log/ses_json.log' })
winston.remove(winston.transports.Console)

require('console-stamp')(console, '[yyyy-mm-dd HH:MM:ss.l Z]')

db_config = yaml.safeLoad(fs.readFileSync('/app/database.yml', 'utf8'))
auth = yaml.safeLoad(fs.readFileSync('/app/auth.yml', 'utf8'))

pool = mysql.createPool
  host:     db_config['production']['host']
  user:     db_config['production']['username']
  password: db_config['production']['password']
  database: db_config['production']['database']

sns_client = SNSClient auth, (err, message)->
  pool.getConnection (err, connection)->
    if err
      console.error("Could not connect to Zooniverse Home database")
      console.error err.stack
    else
      report  = JSON.parse(message.Message)
      winston.info(report)

      email   = report.mail.destination[0]
      email   = if email.indexOf("<") then email.match(/<(.+)>/)[1] else email
      if email?
        if report['notificationType'] == 'Complaint' or report['bounce']['bounceType'] == 'Permanent'
          connection.query 'UPDATE users SET valid_email = false WHERE email = ?',[email], (err,result)->
            if (err)
              console.error "Tried and failed to unsubscribe #{email}"
            else
              console.log "Unsubscribed #{email} (#{report['notificationType']}); changed #{result.changedRows} rows"
        else
          console.log "Ignoring non-permanent bounce for #{email}"

    connection.release()

app = express()

app.get '/', (req, res)->
  res.status(200).end()

app.post '/unsub', sns_client

server = app.listen(process.env.PORT || 3000)
