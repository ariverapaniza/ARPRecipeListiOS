//
//  MyLoginView.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 23/6/2024.
//

import SwiftUI
import PhotosUI
import Firebase

struct LoginView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    @State var createNewAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    var body: some View {
        VStack(spacing: 10){
            Text("Welcome to ARP Recipe List")
                .font(.largeTitle.bold())
                .tint(.green) // DID NOT CHANGE THE COLOUR OF THE TEXT
                .hAlign(.leading)
            Text("Please Sign In")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .green.opacity(0.9))
                    .padding(.top,30)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .green.opacity(0.9))
                
                Button {
                    
                } label: {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.green)
                }
                .padding(.top, 10)
                
                Button("Forgot Password?", action: loginUser)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.green)
                    .hAlign(.trailing)
                    .padding(.top, 10)
            }
            
            HStack{
                Text("Need an account?")
                    .foregroundColor(.black)
                
                Button("Register"){
                    createNewAccount.toggle()
                }
                .fontWeight(.bold)
                .foregroundColor(.green)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .fullScreenCover(isPresented: $createNewAccount) {
            RegisterView()
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    func loginUser(){
        Task{
            do{
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
            }catch{
                await setError(error)
            }
        }
    }
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct RegisterView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @State var fullName: String = ""
    @State var aboutYou: String = ""
    @State var userProfPicData: Data?
    @Environment(\.dismiss) var dismiss
    @State var showPicPicker: Bool = false
    @State var photoPickItem: PhotosPickerItem?
    var body: some View {
        VStack(spacing: 10){
            Text("Welcome to ARP Recipe List")
                .font(.largeTitle.bold())
                .tint(.green) // DID NOT CHANGE THE COLOUR OF THE TEXT
                .hAlign(.leading)
            
            Text("Please Register")
                .font(.title3)
                .hAlign(.leading)
            
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false){
                    HelperPView()
                }
                HelperPView()
            }
                

                
            HStack{
                Text("Have an account?")
                    .foregroundColor(.black)
                    
                Button("Login"){
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.green)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .photosPicker(isPresented: $showPicPicker, selection: $photoPickItem)
        .onChange(of: photoPickItem){ oldValue, newValue in
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        await MainActor.run(body: {
                            userProfPicData = imageData
                        })
                    }catch{}
                }
            }
        }
    }
    @ViewBuilder
    func HelperPView()->some View {
        VStack(spacing: 12) {
            ZStack{
                if let userProfPicData,let image = UIImage(data: userProfPicData){
                    Image(uiImage:image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("NoProfilePic")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showPicPicker.toggle()
            }
            .padding(.top, 25)
            
            TextField("Username", text: $username)
                .textContentType(.emailAddress)
                .border(1, .green.opacity(0.9))
                //.padding(.top,30)
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .green.opacity(0.9))
                //.padding(.top,30)
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .green.opacity(0.9))
            
            TextField("Full Name", text: $fullName)
                .textContentType(.emailAddress)
                .border(1, .green.opacity(0.9))
                //.padding(.top,30)
            
            TextField("About You (Optional)", text: $aboutYou, axis: .vertical)
                .frame(minHeight: 100, alignment: .top)
                .textContentType(.emailAddress)
                .border(1, .green.opacity(0.9))
                //.padding(.top,30)
            Button {
                
            } label: {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.green)
            }
            .padding(.top, 10)
        }

    }
}
    
    struct LoginView_Previews: PreviewProvider {
        static var previews: some View {
            LoginView()
        }
    }
    
    extension View {
        func hAlign(_ alignment: Alignment)->some View{
            self
                .frame(maxWidth: .infinity,alignment: alignment)
        }
        
        func vAlign(_ alignment: Alignment)->some View{
            self
                .frame(maxHeight: .infinity,alignment: alignment)
        }
        
        func border(_ width: CGFloat,_ color: Color)->some View {
            self
                .padding(.horizontal,15)
                .padding(.vertical,10)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(color, lineWidth: width)
                }
        }
        
        func fillView(_ color: Color)->some View {
            self
                .padding(.horizontal,15)
                .padding(.vertical,10)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(color)
                }
        }
    }
    

