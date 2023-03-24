//
//  CoreDataManager.swift
//  IMDb Top Movies
//
//  Created by Oleh Stasiv on 23.03.2023.
//

import Foundation
import CoreData

protocol CoreDataManagerProtocol {
    func saveMoviesItems(movies: [Movie], errorCompletion: @escaping(Error?) -> Void)
    func getMoviesItems() -> Result<[Movie], Error>
    func saveImage(id: String, imageUrl: String, data: Data, errorCompletion: @escaping(Error?) -> Void)
    func getImage(id: String) -> Result<Data?, Error>
}

class CoreDataManager: CoreDataManagerProtocol {
    
    static let shared = CoreDataManager()
    
    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "IMDB_Top_Movies")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    lazy var viewContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    func saveContext() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
    
    func saveMoviesItems(movies: [Movie], errorCompletion: @escaping(Error?) -> Void) {
        do {
            let moviesItems = try viewContext.fetch(MovieItem.fetchRequest())
            if moviesItems.isEmpty {
                for movie in movies {
                    let newMovieItem = MovieItem(context: viewContext)
                    newMovieItem.movie = movie
                    saveContext()
                }
            } else {
                for (movieItem, movie) in zip(moviesItems, movies) {
                    if movieItem.id == movie.id {
                        movieItem.movie = movie
                    }
                }
                saveContext()
            }
            return
        } catch {
            errorCompletion(error)
            return
        }
    }
    
    func getMoviesItems() -> Result<[Movie], Error> {
        do {
            let moviesItems = try viewContext.fetch(MovieItem.fetchRequest())
            let movies = moviesItems.map { $0.movie }
            return .success(movies)
        } catch {
            return .failure(error)
        }
    }
    
    func saveImage(id: String, imageUrl: String, data: Data, errorCompletion: @escaping(Error?) -> Void) {
        do {
            let imagesItems = try viewContext.fetch(ImageItem.fetchRequest())
            if imagesItems.isEmpty {
                let imageInstance = ImageItem(context: viewContext)
                imageInstance.image = data
                imageInstance.url = imageUrl
                imageInstance.id = id
            } else {
                for imageItem in imagesItems {
                    if imageItem.id == id {
                        imageItem.image = data
                        imageItem.url = imageUrl
                        imageItem.id = id
                    } else {
                        let imageInstance = ImageItem(context: viewContext)
                        imageInstance.image = data
                        imageInstance.url = imageUrl
                        imageInstance.id = id
                    }
                }
            }
            saveContext()
            return
        } catch {
            errorCompletion(error)
            return
        }
    }
    
    func getImage(id: String) -> Result<Data?, Error> {
        do {
            let images = try viewContext.fetch(ImageItem.fetchRequest())
            let imageItem = images.first(where: { $0.id == id })
            return .success(imageItem?.image)
        } catch {
            return .failure(error)
        }
    }
}
