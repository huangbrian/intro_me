//
//  ContentView.swift
//  introduceme
//
//  Created by Brian Huang on 7/19/20.
//  Copyright © 2020 team51. All rights reserved.
//

import SwiftUI

func httpPrepare(request: URLRequest, params: [String:Any], udata: UserData, display: UserSearchDisplay = UserSearchDisplay()) {
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
            let response = response as? HTTPURLResponse,
            error == nil else {                                              // check for fundamental networking error
            print("error", error ?? "Unknown error")
            return
        }

        guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
            print("statusCode should be 2xx, but is \(response.statusCode)")
            print("response = \(response)")
            return
        }
        
        let responseString = String(data: data, encoding: .utf8)
        print("responseString = \(String(describing: responseString))")
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        DispatchQueue.main.async {
            if responseString == "authentication failed" {
                udata.uID = -2
            }
            if let res = json as? [String: Any] {
                udata.uID = res["id"] as! Int
                if let usr = res["username"] {
                    udata.user = usr as! String
                    udata.occupation = res["occupation"] as! String
                    udata.location = res["location"] as! String
                    udata.age = res["age"] as! String
                    udata.email = res["email"] as! String
                    if udata.occupation == "Student" {
                        udata.major = res["major"] as! String
                        udata.grad = res["isug"] as! String
                    } else if udata.occupation == "Faculty" {
                        udata.researcharea = res["res_area"] as! String
                    }
                    udata.page = "home"
                }
            }
            if let array = json as? [Any] {
                display.ids.removeAll()
                display.names.removeAll()
                for entry in array {
                    if let tup = entry as? [Any] {
                        if(tup.count>1) {
                            display.ids.append(tup[0] as! Int)
                            display.names.append((tup[1] as! String)+", "+(tup[2] as! String))
                        }
                    }
                }
                if(display.ids.count == 0) {
                    udata.details.removeAll()
                    for entry in array {
                        if let interest = entry as? [String] {
                            udata.details.append(interest[0])
                        }
                    }
                }
            }
        }
    }

    task.resume()
}

struct ContentView: View {
    @EnvironmentObject var data: UserData
    @State var page: String = ""
    
    @ViewBuilder
    var body: some View {
        if(data.page == "signup") {
            SignupView()
        } else if(data.page == "home") {
            HomeView()
        } else if(data.page == "acctinfo") {
            UpdateView()
        } else if(data.page == "interests") {
            InterestView()
        } else if(data.page == "updpass") {
            PwdView()
        } else {
            Start()
        }
    }
}

struct Start: View {
    @EnvironmentObject var data: UserData
    @State private var pass: String = ""
    var body: some View {
        VStack {
            Spacer()
            Text("IntroMe!")
                .font(.largeTitle)
            Spacer()
            HStack {
                VStack {
                    TextField("Username", text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    SecureField("Password", text: $pass)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if self.data.uID == -2 {
                        Text("Incorrect username/password")
                            .font(.footnote)
                            .foregroundColor(Color.red)
                    }
                    HStack {
                        Button(action: {self.data.page = "signup"}) {
                            Text("Sign Up")
                        } .buttonStyle(GradientBackgroundStyle())
                        Button(action: {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/signin")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "user":self.data.user,
                                "pass":self.pass
                            ]
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                        }) {
                            Text("Log In")
                        } .buttonStyle(GradientBackgroundStyle())
                    }
                }
                .padding(.horizontal, 80.0)
            }
            Spacer()
            Spacer()
        }
    }
}

struct SignupView: View {
    @EnvironmentObject var data: UserData
    @State private var pass: String = ""
    @State private var passConfirm: String = ""
    @State private var reqtogl: Bool = false
    @State private var pastogl: Bool = false
    var body: some View {
        VStack {
            Spacer()
            Text("IntroMe!")
                .font(.largeTitle)
            Spacer()
            HStack {
                VStack {
                    TextField("Email", text: $data.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                    TextField("Username*", text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    SecureField("Password*", text: $pass)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Confirm Password*", text: $passConfirm)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if pastogl {
                        Text("Passwords do not match")
                            .font(.footnote)
                            .foregroundColor(Color.red)
                    }
                    TextField("Occupation", text: $data.occupation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Location", text: $data.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.location)
                    TextField("Age", text: $data.age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if reqtogl {
                        Text("Please fill in all forms with *")
                            .font(.footnote)
                            .foregroundColor(Color.red)
                    }
                    HStack {
                        Button(action: {
                            if self.pass != self.passConfirm {
                                self.pastogl = true
                            }
                            if self.pass == "" || self.data.user == "" {
                                self.reqtogl = true
                            }
                            else if self.pass == self.passConfirm {
                                var request = URLRequest(url: URL(string: "http://localhost:5000/addusr")!)
                                request.httpMethod = "POST"
                                let params: [String:Any] = [
                                    "email":self.data.email,
                                    "user":self.data.user,
                                    "pass":self.pass,
                                    "occupation":self.data.occupation,
                                    "location":self.data.location,
                                    "age":self.data.age
                                ]
                                request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                                httpPrepare(request: request, params: params, udata: self.data)
                                self.data.page = "home"
                            }
                        }) {
                            Text("Create Account!")
                               
                        } .buttonStyle(GradientBackgroundStyle())
                    }
                }
                .padding(.horizontal, 80.0)
            }
            Spacer()
            Spacer()
        }
    }
}

struct UpdateView: View {
    @EnvironmentObject var data: UserData
    var body: some View {
        VStack {
            HStack {
                Button(action: {self.data.page = "updpass"}) {
                    Text("Update Password")
                }
                Spacer()
                Button(action: {self.data.page = "home"}) {
                    Text("Back to home")
                }
            }
            Spacer()
            Text("Update Account")
                .font(.title)
            Spacer()
            HStack {
                VStack {
                    TextField("Email", text: $data.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                    TextField("Username*", text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    TextField("Occupation", text: $data.occupation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Location", text: $data.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.location)
                    TextField("Age", text: $data.age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/updateinfo")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "email":self.data.email,
                                "user":self.data.user,
                                "occupation":self.data.occupation,
                                "location":self.data.location,
                                "age":self.data.age
                            ]
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
//                            self.data.page = "home"
                        }) {
                            Text("Update Info")
                               
                        } .buttonStyle(GradientBackgroundStyle())
                        Button(action: {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/deleteuser")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "email":self.data.email,
                                "user":self.data.user,
                                "occupation":self.data.occupation,
                                "location":self.data.location,
                                "age":self.data.age
                            ]
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                            self.data.page = ""
                        }) {
                            Text("Delete Account")
                        } .buttonStyle(GradientBackgroundStyle())
                    }
                }
                .padding(.horizontal, 80.0)
            }
            Spacer()
            Spacer()
            Button(action: {
                self.data.logout()
            }) {
                Text("Log out")
            }
        }
    }
}

struct PwdView: View {
    @EnvironmentObject var data: UserData
    @State private var pass: String = ""
    @State private var passConfirm: String = ""
    @State private var updtogl: Bool = false
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {self.data.page = "acctinfo"}) {
                    Text("Back to Account Info")
                }
            }
            Spacer()
            Text("Update Account")
                .font(.title)
            Spacer()
            HStack {
                VStack {
                    TextField("New password", text: $pass)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.location)
                    TextField("Confirm new password", text: $passConfirm)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/updatepwd")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "pass":self.pass,
                                "userId":self.data.uID
                            ]
                            request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                            httpPrepare(request: request, params: params, udata: self.data)
                            self.updtogl = true
                        }) {
                            Text("Update Password")
                        } .buttonStyle(GradientBackgroundStyle())
                    }
                    if self.updtogl {
                        Text("Password updated")
                    }
                }
                .padding(.horizontal, 80.0)
            }
            Spacer()
            Spacer()
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var data: UserData
    @State var search: String = ""
    @ObservedObject var display: UserSearchDisplay = UserSearchDisplay()
    var body: some View {
        VStack {
            HStack {
                Button(action: {self.data.page = "acctinfo"}) {
                    Text("Account Settings")
                }
                .padding(.horizontal, 10)
                Spacer()
                Text("IntroMe")
                    .font(.title).padding(.horizontal, 10)
            }
            HStack {
                Text("Find other users:")
                TextField("Search by name...", text: $search, onCommit: {
                    var request = URLRequest(url: URL(string: "http://localhost:5000/search")!)
                    request.httpMethod = "POST"
                    let params: [String:Any] = [
                        "key":self.search
                    ]
                    request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                    httpPrepare(request: request, params: params, udata: self.data, display: self.display)
                    print("here")
                    print(self.display.names)
                    print("here")
                })
//                    .textFieldStyle(BottomLineTextFieldStyle())
            }.padding(.horizontal, 10)
            Divider()
                .frame(height: 1)
                .padding(.horizontal, 10)
            List {
                if self.display.names.count > 0 {
                    ForEach(Range(0...self.display.names.count-1),id:\.self) {i in
                        Button(action: {}) {
                            Text(self.display.names[i])
                        }
                    }
                }
            }
            Spacer()
            Button(action: {
                self.data.details.removeAll()
                self.data.page = "interests"
                var request = URLRequest(url: URL(string: "http://localhost:5000/getinterests")!)
                request.httpMethod = "POST"
                let params: [String:Any] = [
                    "userId":self.data.uID
                ]
                request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                self.data.details.removeAll()
                httpPrepare(request: request, params: params, udata: self.data)
            }) {
                Text("Manage interests")
            }
        }
    }
}

struct InterestView: View {
    @EnvironmentObject var data: UserData
    @State var search: String = ""
    @State var interest: String = ""
    var body: some View {
        VStack {
            List {
                Section(header: Text("Already interested in")) {
                    if data.details.count > 0 {
                        ForEach(Range(0...data.details.count-1),id: \.self) {n in
                            HStack {
                                Text(self.data.details[n])
                                Spacer()
                                Button(action: {
//                                    self.data.page = "home"
                                    var request = URLRequest(url: URL(string: "http://localhost:5000/uninterested")!)
                                    request.httpMethod = "POST"
                                    let params: [String:Any] = [
                                        "userId":self.data.uID,
                                        "activity":self.data.details[n]
                                    ]
                                    request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                                    httpPrepare(request: request, params: params, udata: self.data)
                                }) {
                                    Text("x")
                                }
                            }
                        }
                    }
                }
                
                if data.occupation == "Student" {
                    Section(header: Text("What's your major?")) {
                        TextField("Ex: marketing", text:$data.major, onCommit: {
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "major":self.data.major
                            ]
                            var request = URLRequest(url: URL(string: "http://localhost:5000/student_major")!)
                            request.httpMethod = "POST"
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                        })
                        TextField("Undergrad or graduate?", text:$data.grad, onCommit: {
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "is_ug":self.data.grad
                            ]
                            var request = URLRequest(url: URL(string: "http://localhost:5000/student_ug")!)
                            request.httpMethod = "POST"
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                        })
                    }
                } else if data.occupation == "Faculty" {
                    Section(header: Text("What are you researching?")) {
                        TextField("Ex: Databases", text:$data.researcharea, onCommit: {
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "research":self.data.researcharea
                            ]
                            var request = URLRequest(url: URL(string: "http://localhost:5000/faculty_research")!)
                            request.httpMethod = "POST"
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                        })
                    }
                }
                Section(header: Text("Add your interests")) {
                    TextField("name new interest here", text: $interest, onCommit: {
                        if(self.interest != "") {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/interests")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "userId":self.data.uID,
                                "activity":self.interest
                            ]
                            request.httpBody = params.percentEncoded()
                            httpPrepare(request: request, params: params, udata: self.data)
                            self.interest = ""
                        }
                    })
                }
            }
            HStack {
//                Button(action: {
//    //                self.data.page = "home"
////                    self.data.details.removeAll()
//                }) {
//                    Text("Add interest")
//                }
                Button(action: {self.data.page = "home"}) {
                    Text("Back")
                }
                Text(self.interest)
            }
        }
    }
}

extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}

struct GradientBackgroundStyle: ButtonStyle {
 
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(40)
            .padding(.horizontal, 10)
    }
}

struct BottomLineTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        VStack() {
            configuration
            Rectangle()
                .frame(height: 0.2, alignment: .bottom)
                .foregroundColor(Color.secondary)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var blah: String = ""
    static var previews: some View {
//        ContentView().environmentObject(UserData())
        SignupView().environmentObject(UserData())
//        InterestView().environmentObject(UserData())
    }
}
