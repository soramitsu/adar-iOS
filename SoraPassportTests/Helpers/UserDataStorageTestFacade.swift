import Foundation
@testable import SoraPassport
import RobinHood
import CoreData

class UserDataStorageTestFacade: StorageFacadeProtocol {
    let databaseService: CoreDataServiceProtocol

    init() {
        let modelName = "UserDataModel"
        let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")

        let configuration = CoreDataServiceConfiguration(modelURL: modelURL!,
                                                         storageType: .inMemory)

        databaseService = CoreDataService(configuration: configuration)
    }

    func createRepository<T, U>(filter: NSPredicate?,
                            sortDescriptors: [NSSortDescriptor],
                            mapper: AnyCoreDataMapper<T, U>) -> CoreDataRepository<T, U>
    where T: Identifiable, U: NSManagedObject {
            return CoreDataRepository(databaseService: databaseService,
                                      mapper: mapper, filter: filter,
                                      sortDescriptors: sortDescriptors)
    }
}
