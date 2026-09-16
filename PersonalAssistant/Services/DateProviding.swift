import Foundation

/// Abstracts "now", so ViewModels and UseCases that need the current date can be
/// unit tested with a fixed date instead of depending on the wall clock.
/// Also the natural home for future services (NotificationService, VoiceInputService, ...).
protocol DateProviding {
    func now() -> Date
}

struct SystemDateProvider: DateProviding {
    func now() -> Date { .now }
}
