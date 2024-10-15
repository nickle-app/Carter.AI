//
//  ContentView.swift
//  Carter.ai
//
//  Created by robert voelpel on 12.10.24.
//

import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool // true if the message is from the user
}

struct ContentView: View {
    @State private var messages: [Message] = []
    @State private var userInput = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { message in
                    HStack {
                        if message.isUser {
                            Spacer()
                        }
                        Text(message.text)
                            .padding()
                            .background(message.isUser ? Color.blue : Color.gray)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                        
                        if !message.isUser {
                            Spacer()
                        }
                    }
                    .padding(message.isUser ? .leading : .trailing, 50)
                }
            }
            
            HStack {
                TextField("Type a message", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    sendMessage()
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    func sendMessage() {
        let userMessage = Message(text: userInput, isUser: true)
        messages.append(userMessage)
        
        // Clear the input field
        userInput = ""
        
        // Send request to GPT
        getChatGPTResponse(for: userMessage.text) { response in
            let botMessage = Message(text: response, isUser: false)
            messages.append(botMessage)
        }
    }
    
    func getChatGPTResponse(for prompt: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer YOUR_OPENAI_API_KEY", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "text-davinci-003", // You can use other GPT models if needed
            "prompt": prompt,
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let text = choices.first?["text"] as? String {
                DispatchQueue.main.async {
                    completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else {
                DispatchQueue.main.async {
                    completion("Failed to get response")
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("iPhone 15 Pro")
    }
}
