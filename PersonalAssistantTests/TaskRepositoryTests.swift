import Foundation
import Testing
@testable import PersonalAssistant

struct TaskRepositoryTests {
    @Test func insertingTaskPersistsIt() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataTaskRepository(context: context)

        let task = TaskItem(title: "Pagar condomínio", priority: .high)
        try repository.insert(task)
        try repository.save()

        let tasks = try repository.fetchAll()
        #expect(tasks.count == 1)
        #expect(tasks.first?.isCompleted == false)
    }

    @Test func completingTaskSetsCompletedAt() throws {
        let context = TestModelContainerFactory.makeContext()
        let repository = SwiftDataTaskRepository(context: context)

        let task = TaskItem(title: "Lavar o carro", priority: .low)
        try repository.insert(task)
        try repository.save()

        try repository.complete(task)
        try repository.save()

        #expect(task.isCompleted)
        #expect(task.completedAt != nil)
    }
}
