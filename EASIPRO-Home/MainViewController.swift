//
//  MainViewController.swift
//  EASIPRO-Home
//
//  Created by Raheel Sayeed on 5/1/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMARTMarkers



class MainViewController: UITableViewController {
    
    // Get fhir manager from the appDelegate
    lazy var manager: FHIRManager? = {
        
        // Uncomment the following reference to the FHIR Manager created in AppDelegate
        /*
         let fhr = (UIApplication.shared.delegate as! AppDelegate).fhir
         return fhr
        */
        
    }()
    
    
    public var tasks : [TaskSet]? {
        didSet {
            reloadOnMain()
        }
    }
    

    @IBOutlet weak var btnLogin: UIBarButtonItem!
	

	@IBAction func loginAction(_ sender: Any) {
        
        // *******************************************************
        // Step 3: SMART Authorization Sequence:
   
	}

	@IBAction func refreshPage(_ sender: Any) {
        
        // *******************************************************
        // Step 4: Load all Requests, instruments and historical FHIR submissions
        
        
    }
	
	
	
	
    
    lazy var Today: String = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }()
	
	
	
	
	
	
	
	

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tasks?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks?[section].tasks.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    
        let status = tasks?[section].status
        return (status == TaskSchedule.ActivityStatus.Due.rawValue) ? Today : status?.uppercased()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! MainCell
        let measure = tasks?[indexPath.section].tasks[indexPath.row]
        cell.configure(for: measure!)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func showPatientProfile(_ sender: Any) {
		
        if manager?.patient == nil {
            loginAction(sender)
        }
    }
    
	

	
	func reloadOnMain() {
		DispatchQueue.main.async {
			self.tableView.reloadData()
            if let dueCount = self.tasks?.filter({ $0.status == TaskSchedule.ActivityStatus.Due.rawValue }).first?.tasks.count {
                self.navigationController?.tabBarItem.badgeValue = String(dueCount)
            }
		}
	}
	
	open func markStandby() {
		DispatchQueue.main.async {
			let _title = self.manager?.patient?.humanName ?? "PGHD Requests"
			self.title = _title
			self.tableView.reloadData()
			if self.manager?.patient != nil {
				self.btnLogin.title = ""
			}
		}
	}
	
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if let detailVC = segue.destination as? DetailViewController, segue.identifier == "showDetail" {
			if let indexPath = tableView.indexPathForSelectedRow {
                let task = tasks?[indexPath.section].tasks[indexPath.row]
                detailVC.task = task
			}
		}
	}
    
}




extension MainViewController {
    
    // Sort TaskControllers
    func sort(_ tasks: [TaskController]?) -> [TaskSet]? {
        
        var sets = [TaskSet]()
        let statuses = SMARTMarkers.TaskSchedule.ActivityStatus.allCases
        for status in statuses {
            if let filters = tasks?.filter ({ $0.schedule?.status == status }),
                filters.count > 0 {
                sets.append(TaskSet(tasks: filters, status: status.rawValue))
            }
        }
        
        return sets
    }
}



public struct TaskSet {
    let tasks : [TaskController]
    var status : String
}



extension MainViewController: InstrumentResolver {
    
    
    func resolveInstrument(in controller: TaskController, callback: @escaping ((_ instrument: Instrument?, _ error: Error?) -> Void)) {
        
        if let url = controller.request?.rq_instrumentMetadataQuestionnaireReferenceURL {
            // PROMIS/AssessmentCenter hosted Questionnaire
            if url.absoluteString.contains("https://mss.fsm.northwestern.edu"), let promisServer = manager?.promis?.server {
                let questionnaireId = url.lastPathComponent
                let semaphore = DispatchSemaphore(value: 0)
                Questionnaire.read(questionnaireId, server: promisServer) { (resource, error) in
                    if let questionnaire = resource as? Questionnaire {
                        callback(questionnaire, nil)
                    }
                    else {
                        callback(nil, error)
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            }
            else {
                callback(nil, nil)
            }
        }
        else {
            callback(nil, nil)
        }
    }

    
    
}























import ResearchKit
import SMART
