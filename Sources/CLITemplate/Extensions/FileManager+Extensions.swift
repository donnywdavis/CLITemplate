import Foundation

extension FileManager {
    /// Changes the current working directory to the given path, expanding a
    /// leading `~` to the user's home directory and resolving relative paths
    /// against the current working directory.
    /// - Returns: `true` if the directory was changed successfully.
    @discardableResult
    func changeCurrentDirectory(toUnixPath path: String) -> Bool {
        let expandedPath = (path as NSString).expandingTildeInPath
        let base = URL(filePath: currentDirectoryPath, directoryHint: .isDirectory)
        let resolved = URL(filePath: expandedPath, directoryHint: .isDirectory, relativeTo: base)
        return changeCurrentDirectoryPath(resolved.path)
    }
    
    func createFile(atRelativePath path: String, contents data: Data?) throws {
        let originalPath = currentDirectoryPath
        let pathUrl = try URL(string: path) ?? throwError("Not a valid path: \(path)")
        changeCurrentDirectoryPath(pathUrl.deletingLastPathComponent().path)
        defer {
            changeCurrentDirectoryPath(originalPath)
        }
        let didSucceed = createFile(
            atPath: pathUrl.lastPathComponent,
            contents: data
        )
        guard didSucceed else {
            throw GenericError.message("Could not create file at \(path)")
        }
    }
    
    func addSubcommand(_ code: String, toFile path: String) throws {
        try modifyFileContent(at: path) { content in
            var modifiedContent = content
            let range = content
                .matches(of: #/(?<start>subcommands: \[)(?<commands>[\s\S]*?)(?<end>\])/#)
                .first
            
            if let range {
                var commands = range.output.commands
                    .split(separator: "\n")
                    .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                    .filter({ $0.isEmpty == false })
                commands.append(code.trimmingCharacters(in: .whitespacesAndNewlines))
                commands.sort()

                let existingItemIndent = range.output.commands
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .first(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty == false })
                    .map({ String($0.prefix(while: { $0 == " " || $0 == "\t" })) })

                modifiedContent = content.replacing(
                    #/(?<indent>[ \t]*)subcommands: \[[\s\S]*?\]/#
                ) { match in
                    let indent = String(match.output.indent)
                    let itemIndent = existingItemIndent ?? (indent + detectIndentUnit(in: content))
                    let body = commands
                        .map({ "\(itemIndent)\($0)" })
                        .joined(separator: "\n")
                    return """
                    \(indent)subcommands: [
                    \(body)
                    \(indent)]
                    """
                }
            }
            
            return modifiedContent
        }
    }

    /// Infers one indentation unit ("\t" or N spaces) from the first indented
    /// line in the given content, defaulting to four spaces when none is found.
    private func detectIndentUnit(in content: String) -> String {
        for line in content.split(separator: "\n") {
            if line.first == "\t" { return "\t" }
            let spaces = line.prefix(while: { $0 == " " }).count
            if spaces > 0 { return String(repeating: " ", count: spaces) }
        }
        return "    "
    }

    private func modifyFileContent(at path: String, with modification: (String) throws -> String) throws {
        let contentData = try contents(atPath: path) ?? throwError("Could not open file at \(path)")
        let content = String(data: contentData, encoding: .utf8) ?? "File does not contain utf8 text"
        let modifiedContent = try modification(content)
        try createFile(atRelativePath: path, contents: modifiedContent.data(using: .utf8))
    }
}
