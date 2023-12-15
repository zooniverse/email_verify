var express    = require('express');
var pg         = require('pg');
var yaml       = require('js-yaml');
var fs         = require('fs');
var SNSClient  = require('aws-snsclient');
var winston    = require('winston');

const logFile = new winston.transports.File({ filename: './log/ses_json.log' });
winston.add(logFile);

require('console-stamp')(console, '[yyyy-mm-dd HH:MM:ss.l Z]');

var db_config = yaml.load(fs.readFileSync('./database.yml', 'utf8'));
var auth = yaml.load(fs.readFileSync('./auth.yml', 'utf8'));
var production_config = db_config.production;

var pg_pool = new pg.Pool({
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
    client.query('UPDATE users SET valid_email = false WHERE email = $1',[email], function (err, result) {
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
    // https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html#bounce-types
    if (report.notificationType === 'Complaint' || report.bounce.bounceType == 'Permanent') {
      console.log("Unsubscribed " + email + "(" + report.notificationType + "); changed 0 rows");

    // Temporarily pause db updates
      // pg_pool.connect(function (err, client, done) {
        // updatePanoptes(err, client, done, email, report);
      // });
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
