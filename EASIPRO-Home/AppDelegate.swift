//
//  AppDelegate.swift
//  EASIPRO-Home
//
//  Created by Raheel Sayeed on 5/1/18.
//  Copyright © 2018 Boston Children's Hospital. All rights reserved.
//
/*
 Heart Icon: https://www.iconfinder.com/icons/1118211/disease_graph_heart_medical_medicine_icon#size=512
 
 
 */

import UIKit
//Step1
import SMARTMarkers
import ResearchKit
import SMART



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
	// *******************************************************
	// Step2: Configure FHIR endpoints and Initialize

    lazy var fhir: FHIRManager! = {
		
		// Obtained form SMART Sandbox: https://launch.smarthealthit.org
		let fhir_endpoint = "https://launch.smarthealthit.org/v/r4/sim/eyJrIjoiMSIsImIiOiJiODVkN2UwMC0zNjkwLTRlMmEtODdhMC1mM2QyZGZjOTA4YjMifQ/fhir"

		let settings = [
			"client_name"   : "appDemo",
			"client_id"     : "appDemo-id",
			"redirect"      : "smartmarkers-home://smartcallback",
			"scope"         : "openid profile user/*.* launch"
		]

		let client = Client(baseURL: URL(string: fhir_endpoint)!, settings: settings)

		return FHIRManager(main: client, promis: nil)

    }()
    

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if fhir.main.awaitingAuthCallback {
            return fhir.main.didRedirect(to: url)
        }
        
        if url.scheme == "smpro" {
            fhir.callbackManager?.handleRedirect(url: url)
        }
		
		return false
    }
	
	
	// *******************************************************

    
}
