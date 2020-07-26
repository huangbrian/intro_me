from flask import Flask, request, jsonify
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
    return jsonify(res)

@app.route("/addusr", methods=['POST'])
def addusr():
    global curId
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''INSERT INTO User(userId,username,email,occupation,location,age) VALUES(%s,%s,%s,%s,%s,%s);''',(curId,file['user'],file['email'],file['occupation'],file['location'],file['age']))
    cursor.execute('''COMMIT;''')
    curId+=1
    return jsonify(id=curId-1)
    
@app.route("/addstudent", methods=['POST'])
def addstudent():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''INSERT INTO Student(userId,major,is_undergraduate) VALUES(%s,%s,%s);''',(file['userId'],file['major'],file['undergrad']))
    cursor.execute('''COMMIT;''')
    return 'student added'
    
@app.route("/addstudent", methods=['POST'])
def addfaculty():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''INSERT INTO Faculty(userId,research_area,is_management) VALUES(%s,%s,%s);''',(file['userId'],file['researcharea'],file['management']))
    cursor.execute('''COMMIT;''')
    return 'faculty added'

@app.route("/getinterests",methods=['POST'])
def getinterests():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''SELECT activityName FROM Interested_In WHERE userId=%s''',(file['userId']))
    res = cursor.fetchall()
    return jsonify(res)

@app.route("/interests",methods=['POST'])
def interests():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''INSERT IGNORE INTO Interested_In(userId,activityName) VALUES(%s,%s);''',(file['userId'],file['activity']))
    cursor.execute('''INSERT IGNORE INTO Activity VALUES(%s);''',(file['activity']))
    cursor.execute('''COMMIT;''')
    return 'interests updated'
    
@app.route("/uninterested",methods=['POST'])
def uninterested():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''DELETE FROM Interested_In WHERE userId=%s AND activityName=%s;''',(file['userId'],file['activity']))
    cursor.execute('''COMMIT;''')
    return 'interest removed'

@app.route("/search", methods=['POST'])
def searchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    searchkey = file['key'] + '%'
    cursor.execute('''SELECT userId,username,location FROM User WHERE username LIKE %s;''',(searchkey))
    res = cursor.fetchall()
    print(str(res))
    return jsonify(res)

@app.route("/updateinfo", methods=['POST'])
def updateinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE User SET username=%s,email=%s,occupation=%s,location=%s,age=%s WHERE userId=%s ;''',(file['user'],file['email'],file['occupation'],file['location'],file['age'],file['userId']))
    cursor.execute('''COMMIT;''')
    return 'update successful'

@app.route("/deleteuser", methods=['POST'])
def deleteinfo():
    global curId
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''DELETE FROM User WHERE userId=%s;''',(file['userId']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT MAX(userId) FROM User;''')
    curId = 0
    for row in cursor.fetchall():
        curId = row[0]+1
    return 'delete successful'

if __name__ == "__main__":
    app.run()
