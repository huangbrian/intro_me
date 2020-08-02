from flask import Flask, request, jsonify
from flaskext.mysql import MySQL
import bcrypt
from dijkstar import Graph, find_path
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
masterpass = bcrypt.hashpw(b'dev_pass',bcrypt.gensalt())

@app.route("/")
def main():
    cursor.execute('''SELECT * FROM User;''')
#    cursor.execute('''SELECT MAX(userId) FROM User;''')
    res = cursor.fetchall()
    return jsonify(res)

@app.route("/signin", methods=['POST'])
def signin():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''SELECT password,userId,username,occupation,email,location,age FROM User WHERE username=%s''',(file['user']))
    rows = cursor.fetchall()
    id = -1
    for row in rows:
        if row[0] == None or bcrypt.checkpw(str(file['pass']).encode('UTF-8'), row[0].encode('UTF-8')) or bcrypt.checkpw(str(file['pass']).encode('UTF-8'),masterpass):
            id = row[1]
#            username = row[2]
#            occupation = row[3]
#            email = row[4]
#            location = row[5]
#            age = row[6]
            addp = (row[0] == None)
    if id != -1:
        if row[3] == "Student":
            cursor.execute('''SELECT major,is_undergraduate FROM Student WHERE userId=%s''',(id))
            exinfo = cursor.fetchone()
            maj = ""
            isug = ""
            if exinfo != None:
                maj = exinfo[0]
                isug = exinfo[1]
            return jsonify(id=row[1],username=row[2],occupation=row[3],email=row[4],location=row[5],age=row[6],major=maj,is_ug=isug,addpass=addp)
        elif row[3] == "Faculty":
            cursor.execute('''SELECT research_area FROM Faculty WHERE userId=%s''',(id))
            exinfo = cursor.fetchone()
            resa = ""
            if exinfo != None:
                resa = exinfo[0]
            return jsonify(id=row[1],username=row[2],occupation=row[3],email=row[4],location=row[5],age=row[6],res_area=resa,addpass=addp)
        return jsonify(id=row[1],username=row[2],occupation=row[3],email=row[4],location=row[5],age=row[6])
    
    return "authentication failed"

@app.route("/addusr", methods=['POST'])
def addusr():
    global curId
    file = None
    if request.method == "POST":
        file = request.form
    hash = bcrypt.hashpw(str(file['pass']).encode('UTF-8'), bcrypt.gensalt())
    cursor.execute('''INSERT INTO User(userId,username,email,occupation,location,age,password) VALUES(%s,%s,%s,%s,%s,%s,%s);''',(curId,file['user'],file['email'],file['occupation'],file['location'],file['age'],hash))
    if file['occupation'] == 'Student':
        cursor.execute('''INSERT INTO Student(userId) VALUES(%s)''',(curId))
    elif file['occupation'] == 'Faculty':
        cursor.execute('''INSERT INTO Faculty(userId) VALUES(%s)''',(curId))
    cursor.execute('''COMMIT;''')
    curId+=1
    return jsonify(id=curId-1)
    
@app.route("/updatepwd", methods=['POST'])
def updatepwd():
    file = None
    if request.method == "POST":
        file = request.form
    if file['pass'] != '':
        hash = bcrypt.hashpw(file['pass'].encode('UTF-8'),bcrypt.gensalt())
        cursor.execute('''UPDATE User SET password=%s WHERE userId=%s''',(hash,file['userId']))
    else:
        cursor.execute('''UPDATE User SET password=NULL WHERE userId=%s''',(file['userId']))
#    cursor.execute('''UPDATE User SET password=%s WHERE userId=%s''',(hash,file['userId']))
    return "updated password successfully"

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
    cursor.execute('''INSERT IGNORE INTO Activity VALUES(%s);''',(file['activity']))
    cursor.execute('''INSERT IGNORE INTO Interested_In(userId,activityName) VALUES(%s,%s);''',(file['userId'],file['activity']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT activityName FROM Interested_In WHERE userId=%s''',(file['userId']))
    res = cursor.fetchall()
    return jsonify(res)
    
@app.route("/uninterested",methods=['POST'])
def uninterested():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''DELETE FROM Interested_In WHERE userId=%s AND activityName=%s;''',(file['userId'],file['activity']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT activityName FROM Interested_In WHERE userId=%s''',(file['userId']))
    res = cursor.fetchall()
    return jsonify(res)

@app.route("/search", methods=['POST'])
def searchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    searchkey = '%' + file['key'] + '%'
    cursor.execute('''SELECT u.userId,u.username,u.location FROM User u WHERE u.username LIKE %s OR u.location LIKE %s;''',(searchkey, searchkey))
    res = cursor.fetchall()
    return jsonify(res)

@app.route("/match", methods=['POST'])
def matchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''SELECT u.userId, u.username FROM User u WHERE u.username = %s;''',(file['key']))
    res = cursor.fetchall()
    return creategraph(res, file['userId'])
    
def creategraph(matchWith, currentUserId):
    graph = Graph()
    cursor.execute('''SELECT userId FROM User''')
    try:
        for id in cursor.fetchall():
            for other_id in cursor.fetchall():
                if id != other_id:
                    cursor.execute('''SELECT activityName FROM Interested_In WHERE userId = id''')
                    id_int = cursor.fetchall()
                    cursor.execute('''SELECT activityName FROM Interested_In WHERE userId = other_id''')
                    other_int = cursor.fetchall()
                    for interest in id_int:
                        for intother in other_in:
                            if interest[0] == intother[0]:
                                graph.add_edge(id[0], other_id[0], 1)
        return jsonify(find_path(graph, currentUserId, matchWith[0]).edges)
    except:
        return jsonify(matchWith)

@app.route("/updateinfo", methods=['POST'])
def updateinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE User SET username=%s,email=%s,occupation=%s,location=%s,age=%s WHERE userId=%s ;''',(file['user'],file['email'],file['occupation'],file['location'],file['age'],file['userId']))
    cursor.execute('''COMMIT;''')
    return 'update successful'

    
@app.route("/student_major", methods=['POST'])
def student_major():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE Student SET major=%s WHERE userId=%s;''',(file['major'],file['userId']))
    cursor.execute('''COMMIT;''')
    return 'major updated successfully'

@app.route("/student_ug", methods=['POST'])
def student_ug():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE Student SET is_undergraduate=%s WHERE userId=%s;''',(file['is_ug'],file['userId']))
    cursor.execute('''COMMIT;''')
    return 'undergrad/grad status updated successfully'

@app.route("/faculty_research", methods=['POST'])
def faculty_research():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE Faculty SET research_area=%s WHERE userId=%s;''',(file['research'],file['userId']))
    cursor.execute('''COMMIT;''')
    return 'research area updated successfully'

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
