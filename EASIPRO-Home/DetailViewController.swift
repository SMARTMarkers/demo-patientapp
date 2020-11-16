//
//  DetailViewController.swift
//  EASIPRO-Home
//
//  Created by Raheel Sayeed on 5/2/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//

import UIKit
import SMARTMarkers
import SMART
import ResearchKit

class DetailViewController: UITableViewController {
    
    // Get fhir manager from the appDelegate
    var manager: FHIRManager! = (UIApplication.shared.delegate as! AppDelegate).fhir
    
    public var task: TaskController!
	    
	@IBOutlet weak var graphView: PROLineChart!
	
    @IBOutlet weak var btnSession: RoundedButton!
	
	// Step5:
    
    var reports: [Report]? {
        return task.reports?.reports
    }
    
    convenience init(_task: TaskController) {
        self.init(style: .plain)
        self.task = _task
    }
    
	
    override func viewDidLoad() {
        super.viewDidLoad()
        //Step 5: Metadata:

   
    }
	
	
	func reload() {
		DispatchQueue.main.async {
            if let sorted = self.reports?.filter({ $0.rp_observation != nil}).sorted(by: {$0.rp_date < $1.rp_date }) {
                self.graphView.dataEntries = sorted
            }
            self.tableView.reloadData()
		}
	}
	
	
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reports?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "History"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OCell", for: indexPath)
		
        cell.accessoryType = .disclosureIndicator

		// ******************************************************
		// Step 5.1
  

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        // ******************************************************
        // Step 5.3
        
        tableView.deselectRow(at: indexPath, animated: true)
     
        
 
    }

	

	 
	 var sessionController : SessionController?
	 
	 @IBAction func sessionAction(_ sender: RoundedButton) {
		 
        // *************************************************
        // Step 6: Add a PGHD session generator
        
        

	 }

}

// *************************************************
// Step 6.1: Add Error handling


