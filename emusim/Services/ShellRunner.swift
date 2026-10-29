import Foundation

nonisolated struct ShellError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

enum ShellRunner {
    // Run a command, wait for it to finish, return stdout.
    @discardableResult
    static func run(_ path: String, _ args: [String]) async throws -> String {
        try await Task.detached {
            let process = try makeProcess(path, args)
            let out = Pipe(), err = Pipe()
            process.standardOutput = out
            process.standardError = err
            try process.run()
         
            let stdout = out.fileHandleForReading.readDataToEndOfFile()
            let stderr = err.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw failure(path, process.terminationStatus, String(decoding: stderr, as: UTF8.self))
            }
            return String(decoding: stdout, as: UTF8.self)
        }.value
    }

    // Start a command without waiting, throw if it fails in the first few seconds.
    static func launch(_ path: String, _ args: [String], grace: Duration = .seconds(3)) async throws {
        let process = try makeProcess(path, args)
        let log = FileManager.default.temporaryDirectory.appending(path: "emusim-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: log.path(percentEncoded: false), contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        process.standardOutput = handle
        process.standardError = handle
        try process.run()

        let deadline = ContinuousClock.now + grace
        while process.isRunning, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(200))
        }
        guard !process.isRunning, process.terminationStatus != 0 else { return }
        throw failure(path, process.terminationStatus, (try? String(contentsOf: log, encoding: .utf8)) ?? "")
    }

    // Check the binary exists before building the Process.
    nonisolated private static func makeProcess(_ path: String, _ args: [String]) throws -> Process {
        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw ShellError(message: "Executable not found: \(path)")
        }
        let process = Process()
        process.executableURL = URL(filePath: path)
        process.arguments = args
        return process
    }

    // Use the command output as the error message, or the exit status if it's empty.
    nonisolated private static func failure(_ path: String, _ status: Int32, _ output: String) -> ShellError {
        let output = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return ShellError(message: output.isEmpty ? "\(path) exited with status \(status)" : output)
    }
}
