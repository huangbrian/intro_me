//
//  ContentView.swift
//  introduceme
//
//  Created by Brian Huang on 7/19/20.
//  Copyright © 2020 team51. All rights reserved.
//

import SwiftUI

func httpPrepare(request: URLRequest, params: [String:Any], udata: UserData, display: UserSearchDisplay) {
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
            if let res = json as? [String: Any] {
                udata.uID = res["id"] as! Int
            }
            if let array = json as? [Any] {
                display.ids.removeAll()
                display.names.removeAll()
                for entry in array {
                    if let tup = entry as? [Any] {
                        if(tup.count>1) {
                            display.ids.append(tup[0] as! Int)
                            display.names.append((tup[1] as! String)+", "+(tup[2] as! String))
                        } else {
                            udata.details.append(tup[0] as! String)
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
        if(page == "signup") {
            SignupView(page: self.$page)
        } else if(page == "home") {
            HomeView(page: self.$page)
        } else if(page == "update") {
            UpdateView(page: self.$page)
        } else if(page == "interests") {
            InterestView(page: self.$page)
        } else {
            Start(page: self.$page)
        }
    }
}

struct Start: View {
    @EnvironmentObject var data: UserData
    @Binding var page: String
    var body: some View {
        VStack {
            Spacer()
            Text("IntroMe!")
                .font(.largeTitle)
            Text(page)
            Spacer()
            HStack {
                VStack {
                    TextField(/*@START_MENU_TOKEN@*/"Username"/*@END_MENU_TOKEN@*/, text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    SecureField("Password", text: $data.pass)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {self.page = "signup"}) {
                            Text("Sign Up")
                        } .buttonStyle(GradientBackgroundStyle())
                        Button(action: {}) {
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
    @Binding var page: String
    @State private var passConfirm: String = ""
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
                    TextField("Username", text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    SecureField("Password", text: $data.pass)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    SecureField("Confirm Password", text: $passConfirm)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Occupation", text: $data.occupation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Location", text: $data.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.location)
                    TextField("Age", text: $data.age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            if(self.data.pass == self.passConfirm) {
                                var request = URLRequest(url: URL(string: "http://localhost:5000/addusr")!)
                                request.httpMethod = "POST"
                                let params: [String:Any] = [
                                    "email":self.data.email,
                                    "user":self.data.user,
                                    "occupation":self.data.occupation,
                                    "location":self.data.location,
                                    "age":self.data.age
                                ]
                                request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                                httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
                                self.page = "home"
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
    @Binding var page: String
    @State private var passConfirm: String = ""
    var body: some View {
        VStack {
            Spacer()
            Text("Update Account")
                .font(.title)
            Spacer()
            HStack {
                VStack {
                    TextField("Email", text: $data.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                    TextField("Username", text: $data.user)
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
                            request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                            httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
                            self.page = "home"
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
                            request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                            httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
                            self.page = ""
                        }) {
                            Text("Delete Account")
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

struct HomeView: View {
    @EnvironmentObject var data: UserData
    @State var search: String = ""
    @Binding var page: String
    @ObservedObject var display: UserSearchDisplay = UserSearchDisplay()
    var body: some View {
        VStack {
            HStack {
                Button(action: {self.page = "update"}) {
                    Text("Update Personal Info")
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
                })
//                    .textFieldStyle(BottomLineTextFieldStyle())
            }.padding(.horizontal, 10)
            Divider()
                .frame(height: 1)
                .padding(.horizontal, 10)
            List {
                if display.names.count > 0 {
                    ForEach(Range(0...display.names.count-1),id:\.self) {i in
                        Button(action: {}) {
                            Text(self.display.names[i])
                        }
                    }
                }
            }
            Spacer()
            Button(action: {
                self.page = "interests"
                var request = URLRequest(url: URL(string: "http://localhost:5000/getinterests")!)
                request.httpMethod = "POST"
                let params: [String:Any] = [
                    "userId":self.data.uID
                ]
                request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                self.data.details.removeAll()
                httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
            }) {
                Text("Manage interests")
            }
        }
    }
}

struct InterestView: View {
    @EnvironmentObject var data: UserData
    @State var search: String = ""
    @Binding var page: String
    @State var interest: String = ""
    var body: some View {
        VStack {
            List {
                Section(header: Text("Already interested in")) {
                    if data.details.count > 0 {
                        ForEach(Range(0...data.details.count-1)) {n in
                            HStack {
                                Text(self.data.details[n])
                                Spacer()
                                Button(action: {
                                    self.page = "home"
                                    var request = URLRequest(url: URL(string: "http://localhost:5000/uninterested")!)
                                    request.httpMethod = "POST"
                                    let params: [String:Any] = [
                                        "userId":self.data.uID,
                                        "activity":self.data.details[n]
                                    ]
                                    request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                                    httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
                                }) {
                                    Text("X")
                                }
                            }
                        }
                    }
                }
                
//                if data.occupation == "Student" {
//                    Section(header: Text("What's your major?")) {
//                        TextField("Ex: marketing", text:$data.major)
//                    }
//                } else if data.occupation == "Faculty" {
//                    Section(header: Text("What are you researching?")) {
//                        TextField("Ex: Databases", text:$data.researcharea)
//                    }
//                }
                Section(header: Text("Add your interests")) {
                    TextField("name new interest here", text: $interest)
                }
            }
            Button(action: {
                self.page = "home"
                if(self.interest != "") {
                    var request = URLRequest(url: URL(string: "http://localhost:5000/interests")!)
                    request.httpMethod = "POST"
                    let params: [String:Any] = [
                        "userId":self.data.uID,
                        "activity":self.interest
                    ]
                    request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                    httpPrepare(request: request, params: params, udata: self.data, display: UserSearchDisplay())
                }
            }) {
                Text("Add interest")
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
//        SignupView(page: self.$blah).environmentObject(UserData())
        InterestView(page: self.$blah).environmentObject(UserData())
    }
}
