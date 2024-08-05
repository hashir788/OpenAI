//
//  ChatResult.swift
//  
//
//  Created by Sergii Kryvoblotskyi on 02/04/2023.
//

import Foundation

public struct ChatResult: Codable, Equatable {

    public struct Choice: Codable, Equatable {
        public typealias ChatCompletionMessage = ChatQuery.ChatCompletionMessageParam

        /// The index of the choice in the list of choices.
        public let index: Int
        /// Log probability information for the choice.
        public let logprobs: Self.ChoiceLogprobs?
        /// A chat completion message generated by the model.
        public let message: Self.ChatCompletionMessage
        /// The reason the model stopped generating tokens. This will be stop if the model hit a natural stop point or a provided stop sequence, length if the maximum number of tokens specified in the request was reached, content_filter if content was omitted due to a flag from our content filters, tool_calls if the model called a tool, or function_call (deprecated) if the model called a function.
        public let finishReason: String?

        public struct ChoiceLogprobs: Codable, Equatable {

            public let content: [Self.ChatCompletionTokenLogprob]?

            public struct ChatCompletionTokenLogprob: Codable, Equatable {

                /// The token.
                public let token: String
                /// A list of integers representing the UTF-8 bytes representation of the token.
                /// Useful in instances where characters are represented by multiple tokens and
                /// their byte representations must be combined to generate the correct text
                /// representation. Can be `null` if there is no bytes representation for the token.
                public let bytes: [Int]?
                /// The log probability of this token.
                public let logprob: Double
                /// List of the most likely tokens and their log probability, at this token position.
                /// In rare cases, there may be fewer than the number of requested `top_logprobs` returned.
                public let topLogprobs: [TopLogprob]

                public struct TopLogprob: Codable, Equatable {

                    /// The token.
                    public let token: String
                    /// A list of integers representing the UTF-8 bytes representation of the token.
                    /// Useful in instances where characters are represented by multiple tokens and their byte representations must be combined to generate the correct text representation. Can be `null` if there is no bytes representation for the token.
                    public let bytes: [Int]?
                    /// The log probability of this token.
                    public let logprob: Double
                }

                public enum CodingKeys: String, CodingKey {
                    case token
                    case bytes
                    case logprob
                    case topLogprobs = "top_logprobs"
                }
            }
        }

        public enum CodingKeys: String, CodingKey {
            case index
            case logprobs
            case message
            case finishReason = "finish_reason"
        }

        public enum FinishReason: String, Codable, Equatable {
            case stop
            case length
            case toolCalls = "tool_calls"
            case contentFilter = "content_filter"
            case functionCall = "function_call"
        }
    }

    public struct CompletionUsage: Codable, Equatable {

        /// Number of tokens in the generated completion.
        public let completionTokens: Int
        /// Number of tokens in the prompt.
        public let promptTokens: Int
        /// Total number of tokens used in the request (prompt + completion).
        public let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case completionTokens = "completion_tokens"
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }

    /// A unique identifier for the chat completion.
    public let id: String
    /// The object type, which is always chat.completion.
    public let object: String
    /// The Unix timestamp (in seconds) of when the chat completion was created.
    public let created: TimeInterval
    /// The model used for the chat completion.
    public let model: String
    /// A list of chat completion choices. Can be more than one if n is greater than 1.
    public let choices: [Choice]
    /// Usage statistics for the completion request.
    public let usage: Self.CompletionUsage?
    /// This fingerprint represents the backend configuration that the model runs with.
    /// Can be used in conjunction with the seed request parameter to understand when backend changes have been made that might impact determinism.
    public let systemFingerprint: String?

    public enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case model
        case choices
        case usage
        case systemFingerprint = "system_fingerprint"
    }
}

extension ChatQuery.ChatCompletionMessageParam {

    public init(from decoder: Decoder) throws {
        let messageContainer = try decoder.container(keyedBy: Self.ChatCompletionMessageParam.CodingKeys.self)
        switch try messageContainer.decode(Role.self, forKey: .role) {
        case .system:
            self = try .system(.init(from: decoder))
        case .user:
            self = try .user(.init(from: decoder))
        case .assistant:
            self = try .assistant(.init(from: decoder))
        case .tool:
            self = try .tool(.init(from: decoder))
        }
    }
}

extension ChatQuery.ChatCompletionMessageParam.ChatCompletionUserMessageParam.Content {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let string = try container.decode(String.self)
            self = .string(string)
            return
        } catch {}
        do {
            let vision = try container.decode([VisionContent].self)
            self = .vision(vision)
            return
        } catch {}
        throw DecodingError.typeMismatch(Self.self, .init(codingPath: [Self.CodingKeys.string, Self.CodingKeys.vision], debugDescription: "Content: expected String || Vision"))
    }
}