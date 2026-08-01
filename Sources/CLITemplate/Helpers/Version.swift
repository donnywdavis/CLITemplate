import ArgumentParser

struct Version: ExpressibleByArgument, Codable {

    var isDefaultValue: Bool {
        formatted(.full) == "0.0.0"
    }

    private(set) var major: Int = 0
    private(set) var minor: Int = 0
    private(set) var patch: Int = 0

    init(
        major: Int,
        minor: Int = 0,
        patch: Int = 0
    ) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init(argument: String) {
        let versionValues = argument
            .split(separator: ".")
            .map({ Int($0) })

        guard
            versionValues.count <= 3,
            versionValues.contains(nil) == false
        else {
            return
        }

        versionValues
            .compactMap({ $0 })
            .enumerated()
            .forEach({ index, value in
                switch index {
                case 0:
                    major = value
                case 1:
                    minor = value
                case 2:
                    patch = value
                default:
                    return
                }
            })
    }

    func formatted(_ style: Style) -> String {
        switch style {
        case .full:
            return [major, minor, patch]
                .compactMap(\.description)
                .joined(separator: ".")

        case .majorMinor:
            return [major, minor]
                .compactMap(\.description)
                .joined(separator: ".")

        case .dynamic:
            if patch == 0 {
                return formatted(.majorMinor)
            } else {
                return formatted(.full)
            }
        }
    }
}

extension Version {
    enum Style {
        case full
        case majorMinor
        case dynamic
    }
}
