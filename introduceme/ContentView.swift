//
//  ContentView.swift
//  introduceme
//
//  Created by Brian Huang on 7/19/20.
//  Copyright © 2020 team51. All rights reserved.
//

import SwiftUI

func httpPrepare(request: URLRequest, params: [String:Any]) {
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
            HomeView()
        } else {
            Start(page: self.$page)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var blah: String = ""
    static var previews: some View {
//        ContentView().environmentObject(UserData())
        SignupView(page: self.$blah).environmentObject(UserData())
    }
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
                        .textContentType(.username)
                    TextField(/*@START_MENU_TOKEN@*/"Username"/*@END_MENU_TOKEN@*/, text: $data.user)
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
                        .textContentType(.username)
                    TextField("Location", text: $data.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    TextField("Age", text: $data.age)
                        .textContentType(.username)
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
                                httpPrepare(request: request, params: params)
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

struct SearchView: View {

}

struct UpdateView: View {
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
                        .textContentType(.username)
                    TextField(/*@START_MENU_TOKEN@*/"Username"/*@END_MENU_TOKEN@*/, text: $data.user)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    TextField("Occupation", text: $data.occupation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    TextField("Location", text: $data.location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.username)
                    TextField("Age", text: $data.age)
                        .textContentType(.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            var request = URLRequest(url: URL(string: "http://localhost:5000/updateinfo")!)
                            request.httpMethod = "POST"
                            let params: [String:Any] = [
                                "email":self.data.email,
                                "user":self.data.user,
                                "occupation":self.data.occupation,
                                "location":self.data.location,
                                "age":self.data.age
                            ]
                            request.httpBody = params.percentEncoded() // required before every httpPrepare() call
                            httpPrepare(request: request, params: params)
                            self.page = "home"
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

struct HomeView: View {
    var body: some View {
        Text("Hello World!")
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

