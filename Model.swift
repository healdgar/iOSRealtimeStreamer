// Model.swift
import SwiftUI

struct ConversationItem: Identifiable {
    let id: UUID
    let role: String
    let type: String
    var text: String?
    var audio: Data?        // Now a var
    var functionCall: FunctionCall?  // Now a var
    var functionCallOutput: String?  // Now a var
}

struct FunctionCall: Identifiable {
    let id: String
    let name: String
    let arguments: String
}
