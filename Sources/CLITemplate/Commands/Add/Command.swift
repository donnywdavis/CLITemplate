import ArgumentParser
import Foundation

extension CLITemplate.Add {
    struct Command: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "command",
            abstract: "Add the barebones files and configuration for a new command."
        )

        // MARK: - Command Arguments

        @Argument(help: "Command name in camel case with an uppercase first letter.")
        private var name: String

        @Option(
            name: .long,
            help: "The sub command to create the new command in."
        )
        private var subCommand: String?

        @OptionGroup
        private var root: RootPath

        @Flag(
            name: .customLong("async"),
            help: "Declare the command as an async command."
        )
        private var isAsync = false

        // MARK: - Private Properties

        private var cliTemplatePath: String {
            "\(root.path)/Sources/CLITemplate"
        }

        private var commandsDirectory: String {
            "\(cliTemplatePath)/Commands"
        }

        // MARK: - Public API

        func validate() throws {
            guard name.isEmpty == false else {
                throw ValidationError("The name cannot be empty.")
            }
        }

        func run() async throws {
            if subCommand?.isEmpty == false {
                try createSubCommand()
            }
            try createCommand()
        }

        // MARK: - Private API

        private func createCommand() throws {
            let subCommand = self.subCommand ?? ""

            let commandPath = subCommand.isEmpty
                ? "\(commandsDirectory)/\(name).swift"
                : "\(commandsDirectory)/\(subCommand)/\(name).swift"

            FileManager.default.createFile(
                atPath: commandPath,
                contents: name.commandCode(isAsync: isAsync, subCommand: subCommand).data(using: .utf8)
            )

            let subCommandPath = subCommand.isEmpty
                ? "\(cliTemplatePath)/CLITemplate.swift"
                : "\(commandsDirectory)/\(subCommand)/\(subCommand).swift"
            
            try FileManager.default.addSubcommand(
                "\(name).self,",
                toFile: subCommandPath
            )

            if subCommand.isEmpty {
                print("Created command \(name).")
            } else {
                print("Created command \(name) in \(subCommand).")
            }
        }

        private func createSubCommand() throws {
            guard
                let subCommand
            else {
                return
            }

            let subCommandPath = "\(commandsDirectory)/\(subCommand)"
            let filePath = "\(subCommandPath)/\(subCommand).swift"

            guard
                FileManager.default.fileExists(atPath: "\(subCommandPath)/\(subCommand).swift") == false
            else {
                return
            }

            try? FileManager.default.createDirectory(
                atPath: subCommandPath,
                withIntermediateDirectories: false
            )

            FileManager.default.createFile(
                atPath: filePath,
                contents: subCommand.subCommandCode().data(using: .utf8)
            )
            
            try FileManager.default.addSubcommand(
                "\(subCommand).self,",
                toFile: "\(cliTemplatePath)/CLITemplate.swift"
            )

            print("Created sub command \(subCommand).")
        }
    }
}

private extension String {
    func commandCode(
        isAsync: Bool,
        subCommand: String?
    ) -> String {
        let extensionName = if let subCommand, subCommand.isEmpty == false {
            "CLITemplate.\(subCommand)"
        } else {
            "CLITemplate"
        }
        let parsableCommand = isAsync ? "AsyncParsableCommand" : "ParsableCommand"
        
        let commandName = self
            .replacing(#/([a-z0-9])([A-Z])/#) { "\($0.output.1)-\($0.output.2)" }
            .replacing(#/([A-Z]+)([A-Z][a-z])/#) { "\($0.output.1)-\($0.output.2)" }
            .lowercased()

        return """
        import ArgumentParser
        import Foundation
        
        extension \(extensionName) {
            struct \(self): \(parsableCommand) {
                static let configuration = CommandConfiguration(
                    commandName: "\(commandName)",
                    abstract: "This should be a description of the command."
                )
                
                // MARK: - Arguments
                
                @OptionGroup
                private var root: RootPath
                
                // MARK: - Public API
                
                func run() \(isAsync ? "async " : "")throws {
                }
            }
        }
        """
    }

    func subCommandCode() -> String {
        """
        import ArgumentParser
        import Foundation
        
        extension CLITemplate {
            struct \(self): ParsableCommand {
                static let configuration = CommandConfiguration(
                    commandName: "",
                    abstract: "",
                    subcommands: [
                    ]
                )
            }
        }
        """
    }
}
