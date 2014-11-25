express = require('express')
mysql      = require('mysql')

connection = mysql.createConnection
  host:     process.env["ZOONIVERSE_HOME_DB"]
  user:     process.env["ZOONIVERSE_HOME_USER"]
  password: process.env["ZOONIVERSE_HOME_PASSWORD"]
  database: "zoonvierse_home"

connection.connect (err)->
  if err
    console.error("count not connect to zoonivers home")
    console.error err.stack

app = express()

app.post '/unsub', (req, res)->
  report  = req.body
  console.log  report

  if report.delivered?
    res.status(200).end()

  email   = report.mail.destination[0]
  if email?
    connection.query 'UPDATE users set valid_email = false where email = ?',[email], (err,res)->
      if (err)
        console.error "tried and failed to unsubscribe #{email}"
        res.status(404).end()
      else
        res.status(200).end()


server = app.listen(process.env.PORT || 3000)
