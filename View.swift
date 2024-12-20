// View.swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = RealtimeViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("Status: \(viewModel.connectionStatus)")
                    .font(.headline)
                    .padding()

                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.conversation) { item in
                            MessageView(item: item)
                        }
                    }
                }

                Spacer() // Push the button to the bottom

                Button(action: {
                    viewModel.toggleMute()
                }) {
                    if viewModel.isMuted {
                        Image(systemName: "mic.slash.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Realtime AI")
            .onAppear {
                viewModel.connect()
            }
        }
    }
}

struct MessageView: View {
    var item: ConversationItem

    var body: some View {
        HStack {
            if item.role == "user" {
                Spacer()
                Text(item.text ?? "")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            } else {
                Text(item.text ?? "")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}
