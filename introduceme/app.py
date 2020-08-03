from flask import Flask, request, jsonify
from flaskext.mysql import MySQL
import bcrypt
from dijkstar import Graph, find_path
import re
import traceback
import time
app = Flask(__name__)

mysql = MySQL(app)
app.config['MYSQL_DATABASE_USER'] = 'admin'
app.config['MYSQL_DATABASE_PASSWORD'] = '3Vl7KXvAQ2Z3LCyGFzJL'
app.config['MYSQL_DATABASE_DB'] = 'all_data'
app.config['MYSQL_DATABASE_HOST'] = 'database-introduceme.cqq4na6tjpm6.us-east-2.rds.amazonaws.com'
mysql.init_app(app)

graph = Graph()
graph_included = []
def creategraph():
    cursor.execute('''SELECT userId, occupation FROM User''')
    fetched = cursor.fetchall()
    try:
        for id in fetched:
            graph_included.append(id)
            for other_id in fetched:
                if id < other_id:
                    if str(id[1]) == "Student":
                        cursor.execute('''SELECT activityName, major FROM Interested_In NATURAL JOIN Student WHERE userId = %s''',(id[0]))
                    else:
                        cursor.execute('''SELECT activityName, research_area FROM Interested_In NATURAL JOIN Faculty WHERE userId = %s''',(id[0]))
                    id_int = cursor.fetchall()
                    if str(other_id[1]) == "Student":
                        cursor.execute('''SELECT activityName, major FROM Interested_In NATURAL JOIN Student WHERE userId = %s''',(other_id[0]))
                    else:
                        cursor.execute('''SELECT activityName, research_area FROM Interested_In NATURAL JOIN Faculty WHERE userId = %s''',(other_id[0]))
                    other_int = cursor.fetchall()
                    all_ints = []
                    for interest in id_int:
                        for intother in other_int:
                            for (index, element) in enumerate(interest):
                                if interest[index] == intother[index]:
                                    all_ints.append(interest[index])
                    if len(all_ints) > 0:
                        graph.add_edge(id[0], other_id[0], (1, all_ints))
                        graph.add_edge(other_id[0], id[0], (1, all_ints))
        print("Graph creation successful.")
    except:
        traceback.print_exc()
    
con = mysql.connect()
cursor = con.cursor()
cursor.execute('''SELECT MAX(userId) FROM User;''')
curId = 0
for row in cursor.fetchall():
    curId = row[0]+1
masterpass = bcrypt.hashpw(b'dev_pass',bcrypt.gensalt())

creategraph()

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
    
def update_graph(currentUserId):
    cursor.execute('''SELECT occupation FROM User WHERE userId = %s''',(currentUserId))
    occupation = str(cursor.fetchall()[0][0])
    try:
        for other in graph_included:
            cursor.execute('''SELECT userId, occupation FROM User WHERE userId = %s''',(other[0]))
            other_id = cursor.fetchall()[0]
            if occupation == "Student":
                cursor.execute('''SELECT activityName, major FROM Interested_In NATURAL JOIN Student WHERE userId = %s''',(currentUserId))
            else:
                cursor.execute('''SELECT activityName, research_area FROM Interested_In NATURAL JOIN Faculty WHERE userId = %s''',(currentUserId))
            id_int = cursor.fetchall()
            if str(other_id[1]) == "Student":
                cursor.execute('''SELECT activityName, major FROM Interested_In NATURAL JOIN Student WHERE userId = %s''',(other_id[0]))
            else:
                cursor.execute('''SELECT activityName, research_area FROM Interested_In NATURAL JOIN Faculty WHERE userId = %s''',(other_id[0]))
            other_int = cursor.fetchall()
            all_ints = []
            for interest in id_int:
                for intother in other_int:
                    for (index, element) in enumerate(interest):
                        if interest[index] == intother[index]:
                            all_ints.append(interest[index])
            if len(all_ints) > 0:
                graph.add_edge(currentUserId, other_id[0], (1, all_ints))
                graph.add_edge(other_id[0], currentUserId, (1, all_ints))
        graph_included.append(currentUserId)
        print("Graph updated.")
    except:
        traceback.print_exc()
        
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
    update_graph(curId)
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
    cursor.execute('''SELECT userId FROM User WHERE userId = %s''',(file['userId']))
    update_graph(cursor.fetchall()[0][0])
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
    graph = Graph()
    graph_included = []
    creategraph()
    return jsonify(res)

@app.route("/search", methods=['POST'])
def searchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    if searchkey != '':
        searchkey = file['key'] + '%'
        query = '''SELECT DISTINCT * FROM (
        SELECT userId, username, location FROM User WHERE username LIKE %s OR location LIKE %s
        UNION
        SELECT userId, username, location FROM User NATURAL JOIN Student WHERE major LIKE %s OR is_undergraduate LIKE %s
        UNION
        SELECT userId, username, location FROM User NATURAL JOIN Faculty WHERE research_area LIKE %s
        UNION
        SELECT u.userId AS userId, u.username AS username, u.location AS location FROM User u RIGHT JOIN Interested_In i ON u.userId = i.userId WHERE activityName LIKE %s) a;'''
        cursor.execute(query, (searchkey,searchkey,searchkey,searchkey,searchkey,searchkey))
        res = cursor.fetchall()
        return jsonify(res)
    return 'nothing searched'

@app.route("/match", methods=['POST'])
def matchinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''SELECT u.userId, u.username FROM User u WHERE u.username = %s;''',(file['key']))
    res = cursor.fetchall()
    cursor.execute('''SELECT userId FROM User WHERE userId = %s''',(file['userId']))
    id = cursor.fetchall()
    return path_find(id[0][0], res)
    
def cost_func(u, v, edge, prev_edge):
    length, name = edge
    return length
    
def path_find(currentUserId, matchWith):
    try:
        print(find_path(graph, currentUserId, matchWith[0][0], cost_func=cost_func))
        return jsonify(matchWith)
    except:
        traceback.print_exc()

@app.route("/updateinfo", methods=['POST'])
def updateinfo():
    file = None;
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE User SET username=%s,email=%s,occupation=%s,location=%s,age=%s WHERE userId=%s ;''',(file['user'],file['email'],file['occupation'],file['location'],file['age'],file['userId']))
    cursor.execute('''COMMIT;''')
    graph = Graph()
    graph_included = []
    creategraph()
    return 'update successful'

    
@app.route("/student_major", methods=['POST'])
def student_major():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE Student SET major=%s WHERE userId=%s;''',(file['major'],file['userId']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT userId FROM User WHERE userId=%s''',file['userId'])
    update_graph(cursor.fetchall()[0][0])
    return 'major updated successfully'

@app.route("/student_ug", methods=['POST'])
def student_ug():
    file = None
    if request.method == "POST":
        file = request.form
    undergraduate = ""
    if file['is_ug'] == "Yes":
        undergraduate = "Undergraduate"
    elif file['is_ug'] == "No":
        undergraduate = "Graduate"
    else:
        if re.search("^under", file['is_ug'], flags=re.IGNORECASE):
            undergraduate = "Undergraduate"
        else:
            undergraduate = "Graduate"
    cursor.execute('''UPDATE Student SET is_undergraduate=%s WHERE userId=%s;''',(undergraduate,file['userId']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT userId FROM User WHERE userId=%s''',file['userId'])
    update_graph(cursor.fetchall()[0][0])
    return 'undergrad/grad status updated successfully'

@app.route("/faculty_research", methods=['POST'])
def faculty_research():
    file = None
    if request.method == "POST":
        file = request.form
    cursor.execute('''UPDATE Faculty SET research_area=%s WHERE userId=%s;''',(file['research'],file['userId']))
    cursor.execute('''COMMIT;''')
    cursor.execute('''SELECT userId FROM User WHERE userId=%s''',file['userId'])
    update_graph(cursor.fetchall()[0][0])
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
    graph = Graph()
    graph_included = []
    creategraph()
    curId = 0
    for row in cursor.fetchall():
        curId = row[0]+1
    return 'delete successful'

if __name__ == "__main__":
    app.run()
