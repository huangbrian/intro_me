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
    cursor.execute('''INSERT INTO User(userId,username,email,occupation,location,age) VALUES(%s,%s,%s,%s,%s,%s);''',(curId,file['user'],file['email'],file['occupation'],file['location'],file['age']))
    cursor.execute('''COMMIT;''')
    return str(file)

@app.route("/searchinfo", methods=['POST'])
def searchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''SELECT * FROM User WHERE username = %s;''',(file['user']))
    cursor.execute('''COMMIT;''')
    return str(file)

@app.route("/updateinfo", methods=['POST'])
def updateinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE User WHERE userId=%s SET occupation=%s,location=%s,age=%s;''',(file['userId'],file['occupation'],file['location'],file['age']))
    cursor.execute('''COMMIT;''')
    return str(file)

@app.route("/deleteinfo", methods=['POST'])
def deleteinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''DELETE FROM User WHERE userId=%s;''',(file['userId']))
    cursor.execute('''COMMIT;''')
    return str(file)

if __name__ == "__main__":
    app.run()
