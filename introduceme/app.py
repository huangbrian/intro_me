from flask import Flask, request
from flaskext.mysql import MySQL
app = Flask(__name__)

mysql = MySQL(app)
app.config['MYSQL_DATABASE_USER'] = 'admin'
app.config['MYSQL_DATABASE_PASSWORD'] = '3Vl7KXvAQ2Z3LCyGFzJL'
app.config['MYSQL_DATABASE_DB'] = 'all_data'
app.config['MYSQL_DATABASE_HOST'] = 'database-introduceme.cqq4na6tjpm6.us-east-2.rds.amazonaws.com'
mysql.init_app(app)

con = mysql.connect()
cursor = con.cursor()
cursor.execute('''SELECT MAX(userId) FROM User;''')
curId = 0
for row in cursor.fetchall():
    curId = row[0]+1


@app.route("/")
def main():
    cursor.execute('''SELECT * FROM User;''')
#    cursor.execute('''SELECT MAX(userId) FROM User;''')
    res = cursor.fetchall()
    return str(res)

@app.route("/addusr", methods=['POST'])
def addusr():
    file = None;
    if request.method == "POST":
        file = request.form
    print(isinstance(curId,int))
    cursor.execute('''INSERT INTO User(userId,username,email) values(%s,%s,%s);''',(curId,file['user'],file['email']))
    cursor.execute('''COMMIT;''')
    return str(file)

if __name__ == "__main__":
    app.run()
