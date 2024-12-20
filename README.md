# Realtime AI Assistant

This repository contains the `RealtimeViewModel`, `ContentView`, `MessageView`, and supporting models such as `ConversationItem` and `FunctionCall`. Together, these components create a real-time communication framework for interacting with OpenAI's services using WebRTC and SwiftUI.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Setup](#setup)
- [Code Structure](#code-structure)
- [Usage](#usage)
- [UI Overview](#ui-overview)
- [Model Overview](#model-overview)
- [To Dos](#to-dos)
- [Important Notes](#important-notes)
- [License](#license)

## Overview

This project is a Swift-based real-time communication assistant that integrates WebRTC for peer-to-peer connections and OpenAI API for conversational intelligence. It uses SwiftUI for the user interface and provides a flexible data model for managing messages, function calls, and their outputs.

## Features

- **SwiftUI Interface**:
  - Displays connection status, messages, and a microphone toggle.
  - Dynamically updates the conversation in real-time.

- **Realtime AI Communication**:
  - Peer-to-peer WebRTC for audio and data channels.
  - Integration with OpenAI API for conversational interactions.

- **Flexible Data Models**:
  - `ConversationItem`: Represents individual messages with support for text, audio, function calls, and outputs.
  - `FunctionCall`: Encodes information about OpenAI's function call inputs and outputs.

## Setup

### Prerequisites
- Xcode with Swift 5.0 or higher.
- WebRTC via CocoaPods or Swift Package Manager.
- OpenAI API key (not included for security).

### Installation
Follow the instructions in the setup section of the previous README.

## Code Structure

### View.swift
Refer to the updated README for `ContentView` and `MessageView` details.

### ViewModel.swift
The `RealtimeViewModel` drives the application logic, handles WebRTC connections, and integrates with OpenAI APIs. See the previous README for details.

### Model.swift
The `Model.swift` file introduces a flexible data structure for representing and managing conversations:

#### `ConversationItem`
- **Role**: Represents a single message in the conversation.
- **Properties**:
  - `id` (UUID): A unique identifier for each message.
  - `role` (String): Identifies the sender of the message (e.g., "user", "assistant").
  - `type` (String): Specifies the message type (e.g., "text", "audio").
  - `text` (String?): Optional text content for the message.
  - `audio` (Data?): Optional audio data for the message.
  - `functionCall` (FunctionCall?): Optional function call details for the message.
  - `functionCallOutput` (String?): Optional output of a function call.

#### `FunctionCall`
- **Role**: Represents a function call invoked during the conversation.
- **Properties**:
  - `id` (String): A unique identifier for the function call.
  - `name` (String): The name of the function being called.
  - `arguments` (String): The arguments passed to the function.

These models allow for rich representation of conversations and seamless integration of advanced features like audio and function calls.

## Usage

1. **Run the App**:
   - Launch the app, and the `ContentView` initializes the connection via the `RealtimeViewModel`.

2. **Interact with Messages**:
   - The `ConversationItem` model supports text, audio, and function call outputs. Messages dynamically update in the UI.

3. **Invoke Function Calls**:
   - Use the `functionCall` and `functionCallOutput` properties to display or process OpenAI function outputs.

4. **Control Audio**:
   - Toggle the microphone with the SwiftUI-bound button in `ContentView`.

## UI Overview

Refer to the UI Overview in the previous README.

## Model Overview

- **Dynamic Conversations**:
  - Messages support multiple types (`text`, `audio`) and advanced features like function calls.

- **Modular Design**:
  - Models are designed to be extensible, enabling future features such as additional message types or enriched metadata.

## To Dos

The following features are planned for future development:
- **Model Voice Selector**:
  - Implement a user interface to select different AI voices for more personalized interaction.
- **Custom Search Tool**:
  - Develop an integrated tool for enhanced information retrieval and search capabilities within conversations.
- **Custom Memory Tool**:
  - Implement a memory system to store and recall advanced context for conversations, allowing for more meaningful and informed interactions.
- **Framework for Additional APIs**:
  - Build a modular framework to integrate external APIs like Zapier, IFTTT, Twilio, and more for extended functionality and automation.

## Important Notes

- **Temporary API Key**: Replace placeholder API keys in `RealtimeViewModel` for secure integration.
- **Custom Functionality**: Extend the `FunctionCall` and `ConversationItem` models for additional use cases, such as rich text or multimedia messages.
- **Testing**: Use the provided structure to simulate conversations and validate the flow of text, audio, and function calls.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
