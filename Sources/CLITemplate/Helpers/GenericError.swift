import Foundation

func throwError<T>(_ message: String) throws -> T {
    throw GenericError.message(message)
}

enum GenericError: Error {
    case message(String)
}
