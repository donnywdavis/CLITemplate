import ArgumentParser

@main
struct CLITemplate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        version: Version(major: 1, minor: 0, patch: 0).formatted(.full),
        subcommands: [
            Add.self,
        ]
    )
}
