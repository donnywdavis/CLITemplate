import ArgumentParser
import Foundation

struct RootPath: ParsableArguments {

    @Option(
        name: [
            .customShort("r"),
            .customLong("root"),
        ],
        help: "The root path."
    )
    var path: String = "."

    // MARK: - Public API

    mutating func validate() throws {
        FileManager.default.changeCurrentDirectory(toUnixPath: path)
        path = FileManager.default.currentDirectoryPath
    }
}
