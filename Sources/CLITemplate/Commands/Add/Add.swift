import ArgumentParser
import Foundation

extension CLITemplate {
    struct Add: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add",
            abstract: "Commands to create new components in the project.",
            subcommands: [
                Command.self,
            ]
        )
    }
}
