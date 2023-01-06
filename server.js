var express    = require('express');
var pg         = require('pg');
var yaml       = require('js-yaml');
var fs         = require('fs');
var SNSClient  = require('aws-snsclient');
var winston    = require('winston');

winston.add(winston.transports.File, { filename: '/app/log/ses_json.log' });
winston.remove(winston.transports.Console);

require('console-stamp')(console, '[yyyy-mm-dd HH:MM:ss.l Z]');

var db_config = yaml.safeLoad(fs.readFileSync('/app/database.yml', 'utf8'));
var auth = yaml.safeLoad(fs.readFileSync('/app/auth.yml', 'utf8'));
var production_config = db_config.production;

var pg_pool = pg.Pool({
    user: production_config.username,
    host: production_config.host,
    password: production_config.password,
    database: production_config.database,
    ssl: true,
})

function unsubscribe(err, result, email, report) {
  if (err) {
    console.error("Tried and failed to unsubscribe", email);
    console.error(err.stack);
  } else {
    console.log("Unsubscribed " + email + "(" + report.notificationType + "); changed " + result.rowCount + " rows");
  }
}

function updatePanoptes(err, client, done, email, report) {
  if (err) {
    console.error("Could not connect to Panoptes database");
    console.error(err.stack);
  } else {
    client.query('UPDATE users SET valid_email = false WHERE email = $1',[email], function (err,result) {
      unsubscribe(err, result, email, report);
      done();
    });
  }
}

var sns_client = SNSClient(auth, function (err, message) {
  var report  = JSON.parse(message.Message);
  winston.info(report);

  var email = report.mail.destination[0];
  email = (email.indexOf("<") > -1) ? email.match(/<(.+)>/)[1] : email;
  if (!!email) {
    if (report.notificationType === 'Complaint' || report.bounce.bounceType == 'Permanent') {
      pg_pool.connect(function (err, client, done) {
        updatePanoptes(err, client, done, email, report);
      });
    } else {
      console.log("Ignoring non-permanent bounce for", email);
    }
  }
});


var app = express();

app.get('/', function (req, res) {
  res.status(200).end();
});
  

app.post('/unsub', sns_client);

var server = app.listen(process.env.PORT || 3000);
