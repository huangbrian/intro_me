//
//  ContentView.swift
//  introduceme
//
//  Created by Brian Huang on 7/19/20.
//  Copyright © 2020 team51. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var data: UserData
    @State var page: String = ""
    
    @ViewBuilder
    var body: some View {
        if(page == "signup") {
            SignupView(page: self.$page)
        } else if(page == "newuser") {
            NewUserView()
        } else if(page == "home") {
            HomeView()
        } else {
            Start(page: self.$page)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
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
                    SecureField("Password", text: $passConfirm)
                        .textContentType(.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Button(action: {
                            if(self.data.pass == self.passConfirm) {
                                self.page = "newuser"
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

struct NewUserView: View {
    var body: some View {
        Form {
            Text("info questions in here")
        }
    }
}

struct HomeView: View {
    var body: some View {
        Text("Hello World!")
    }
}
