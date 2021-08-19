var AWS = require('aws-sdk');
const mysql = require('mysql2');

exports.handler = async (event, context) => {

  var secretsManager = new AWS.SecretsManager();
  var secretId = event.arguments[0][4];
  const secret = await secretsManager.getSecretValue({
      SecretId: secretId
      }).promise();

  var secretJson = JSON.parse(secret.SecretString);

  var host = secretJson.host;
  var user = secretJson.username;
  var password = secretJson.password;

  let connectionConfig = {
    host: host,
    user: user,
    password: password
  };

  var pool = await mysql.createPool(connectionConfig);
  var conn = pool.promise();

  var table = event.arguments[0][0];
  var columnName = event.arguments[0][1];
  var columnType = event.arguments[0][2];
  var returnColumnName = event.arguments[0][3];

  var createStmt = 'create temporary table ' + table + '_jointemp (temp_seq int, '+ columnName + ' ' + columnType + '); ';
  await conn.query(createStmt);

  var values = event.arguments.map((x, i) => "("+i+","+x[5]+")");
  var insertStmt = 'insert into ' + table + '_jointemp(temp_seq, '+ columnName +') values ' + values.join(',') + ';';
  await conn.query(insertStmt);

  var selectStmt = 'select t1.' + returnColumnName + ' FROM ' + table + '_jointemp t LEFT OUTER JOIN ' + table + ' t1 on t.'+ columnName +' = t1.'+ columnName + ' order by temp_seq;'  const [results, fields] = await conn.execute(selectStmt);

  var res = {};
  if(results.length > 0){
    res = results.map((row) => row[returnColumnName]);
    }
    var response = JSON.stringify({"results": res});
    conn.end();
  return response;
};
