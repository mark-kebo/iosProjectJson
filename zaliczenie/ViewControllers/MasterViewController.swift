//
//  MasterViewController.swift
//  zaliczenie
//
//  Created by kprzystalski on 25/12/2019.
//  Copyright © 2019 kprzystalski. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil

    var appDelegate: AppDelegate? = nil
    
    var productsEntity: NSEntityDescription? = nil
    
    var _fetchedResultsController: NSFetchedResultsController<Product>? = nil
        

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem


        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        self.appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        self.managedObjectContext = appDelegate?.persistentContainer.viewContext
            
        self.productsEntity = NSEntityDescription.entity(forEntityName: Constants.entityProductName, in: self.managedObjectContext!)
        parseJson()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
}

extension MasterViewController {
    func parseJson() {
        let url = URL(string: Constants.serverUrl)
        let request = URLRequest(url: url!)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let self = self else { return }
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard data != nil else {
                print("No data")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                if let object = json as? [String:Any] {
                    print(object)
                } else if let object = json as? [Any], let productsEntity = self.productsEntity {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.entityProductName)

                    for element in object as! [Dictionary<String,AnyObject>] {
                        var isElementExist = false
                        let id = element[CoreDataEntities.id] as? Int
                        let productText = element[CoreDataEntities.product] as? String
                        let desc = element[CoreDataEntities.descriptionJSON] as? String
                        let image = element[CoreDataEntities.image] as? String
                        let locationLat = element[CoreDataEntities.location_lat] as? String
                        let locationLong = element[CoreDataEntities.location_long] as? String
                        
                        do {
                            if let result = try self.managedObjectContext?.fetch(fetchRequest) {
                                for object in result {
                                    if let object = object as? NSManagedObject {
                                        if let idCD = object.value(forKey: CoreDataEntities.id) as? Int, idCD == id {
                                            object.setValue(id, forKey: CoreDataEntities.id)
                                            object.setValue(productText, forKey: CoreDataEntities.product)
                                            object.setValue(desc, forKey: CoreDataEntities.descriptionCD)
                                            object.setValue(image, forKey: CoreDataEntities.image)
                                            object.setValue(locationLat, forKey: CoreDataEntities.location_lat)
                                            object.setValue(locationLong, forKey: CoreDataEntities.location_long)
                                            isElementExist = true
                                        }
                                    }
                                }
                            }
                        } catch {
                            print("Can't load core data entities")
                        }
                        if !isElementExist {
                            let product = NSManagedObject(entity: productsEntity, insertInto: self.managedObjectContext)
                            product.setValue(id, forKey: CoreDataEntities.id)
                            product.setValue(productText, forKey: CoreDataEntities.product)
                            product.setValue(desc, forKey: CoreDataEntities.descriptionCD)
                            product.setValue(image, forKey: CoreDataEntities.image)
                            product.setValue(locationLat, forKey: CoreDataEntities.location_lat)
                            product.setValue(locationLong, forKey: CoreDataEntities.location_long)

                            print("Added: \(object)")
                        }
                    }
                    try self.managedObjectContext?.save()
                } else {
                    print("JSON is not valid")
                }
            } catch {
                print("Serialization JSON error")
            }
            
        })
        task.resume()
    }


    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.segueDetailsIdentifier {
            if let indexPath = tableView.indexPathForSelectedRow {
            let object = fetchedResultsController.object(at: indexPath)
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        let event = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withEvent: event)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = fetchedResultsController.managedObjectContext
            context.delete(fetchedResultsController.object(at: indexPath))
                
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func configureCell(_ cell: UITableViewCell, withEvent product: Product) {
        cell.textLabel?.text = product.product
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController<Product> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
                
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: CoreDataEntities.descriptionCD, ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: Constants.fetchedCacheName)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchedResultsController!
    }    

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Product)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withEvent: anObject as! Product)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}
