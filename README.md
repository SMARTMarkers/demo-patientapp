Patient App Demonstration
=====================


## Guide to Building and Running an iOS app built with [SMART Markers][sm]

## Step1: Import SMART Markers framework into your project directory.

## Step2: Configure FHIR endpoints and Initialize

After importing the framework. we initialize a FHIR client `Client`

Paste the following code in `AppDelegate.swift`. This is where the `Client` instance is retained for other classes to use

```swift

lazy var fhir: FHIRManager! = {

	// Obtained form SMART Sandbox: https://launch.smarthealthit.org
	let fhir_endpoint = "launch.smarthealthit.org/v/r4/sim/eyJrIjoiMSIsImIiOiJiODVkN2UwMC0zNjkwLTRlMmEtODdhMC1mM2QyZGZjOTA4YjMifQ/fhir"

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
```
## Step 3: SMART Authorization sequence

In the app's main page, which is the  `MainViewController`, add a variable to the FHIR manager that we initialized in the previous step, in `AppDelegate. 

A button method `loginAction()` is where we add the SMART Authorization routine that is embedded within SMARTMarkers's `FHIRManager` module. After authorization, as we receive the Patient context, we update the UI with the patient name. The framework resovles the most appropriate name from the `FHIR Patient` Resource.

```swift
manager.authorize { [weak self] (success, userName, error) in
	if success {
		if let patientName = userName {
			self?.title = patientName
		}
	}
	else {
		if let error = error {
			self?.showMsg(msg: "Authorization Failed.\n\(error.asOAuth2Error.localizedDescription)")
		}
	}
}
```

## Step 4: Get all Requests and Reports for the Patient

In the app's main page, which is the  `MainViewController`, add a variable to the FHIR manager that we initialized in the previous step, in `AppDelegate` and use it to fetch all the PGHD `Requests` and `Reports` for user that logged in, which is a Patient


In __refreshPage()__ method, we use a TaskController class to fetch all requests sent to this server, the FHIR resource type is ServiceRequest for that patient using the server instance.  We make sure that we have a patient (in the form of a resource) and an authorized server.

We get back a set of TaskControllers, and within each controller, there is a request, an instrument and historical reports that were submitted specifically for this request.

There are some basic methods that sort the controllers as per their duedate and completion status and finally the list of tasks is handed over to the table for interface change.

```swift
guard let patient = manager.patient else { return }
self.title = "Loading.."

TaskController.Requests(requestType: ServiceRequest.self,
						for: patient,
						server: manager.main.server,
						instrumentResolver: self) { [weak self] (controllers, error) in
	DispatchQueue.main.async {
		if let controllers = controllers {
			self?.tasks = self?.sort(controllers)
		}
		if nil != error { print(error! as Any) }
		self?.markStandby()
	}
}
```

###### Till now, we handled FHIR configuration, login/authorization and pulling in all the requests, the PGHD instrument and reports.

Next: Lets now take on task and write code to:

## Step 5: Explore a Single Task

For this task, I'd like to display its metadata, which means its identifier, request date, the person who requested it. Also need to know the PGHD instrument requested and if there any previous results that were submited.  Everything resides in a single `TaskController` class. I have some text space and a table. 

5.1: Metadata in `viewDidLoad()`

```swift
title = "REQ: #" + (task.request?.rq_identifier ?? "-")
graphView.title = task.instrument?.sm_title ?? task.request?.rq_title ?? "-"
graphView.subTitle = (task.request?.rq_categoryCode ?? "CODE: --")
reload()
```
5.2: Reports in table `cellForRow()`

```swift
let result = reports![indexPath.row]
cell.textLabel?.text = "\(result.rp_date.shortDate): \(result.rp_description ?? "--")"
cell.detailTextLabel?.text = result.rp_observation ?? nil
```

5.3: If I want to know more about a particular report, the framework has some built in Viewers to just readily use

```swift
if let viewer = report.rp_viewController {
	self.show(viewer, sender: nil)
}
```





#### Step 7: Add a PGHD session generator

In `DetailViewController`, add the following to `sessionAction()`


```swift

	var sessionController : SessionController?


	sessionController = SessionController([task],
									  patient: manager.patient!, 
									  server: manager.main.server)

	 
	 sessionController?.prepareController(callback: { (controller, error) in
		 
		 if let controller = controller {
			 controller.view.tintColor = .red
			 self.present(controller, animated: true, completion: nil)
		 }
		 
		 else if let error = error {
			 self.showMsg(msg: "Error occurred when creating a session\n\(error.localizedDescription)")
		 }
		 
	 })
	 
	 sessionController?.onConclusion = { [weak self] session in
		 
		 self?.reload()
	 }
```

Lets also not forget some error handling. We want to know possible reasons why we could not start a session, maybe the Questionnaire could not be resolved, or perhaps may have been deleted. Apps can have their own way of handling these potential issues.

```swift
extension DetailViewController : SessionControllerDelegate {
    
    
    func sessionEnded(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?) {
    
        if let error = error {
            print(error as Any)
            print(reason.rawValue)
        }
        reload()
    }
    
    func sessionShouldBegin(_ session: SessionController, taskViewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason, error: Error?) -> Bool {
        
        return true
    }
}
```


#### Step 7: Add a submission module

Remember, these results, in the event that the FHIR server is not receive data, as is the case today with EHRs, a different purposeful FHIR server can be created and used in the __Submissions__ module


-----------------------------------------------------------------

More information

### A Health app for Patient Generated Health Data

This is a standalone patient facing iOS app built on the [SMART on FHIR][sf] open specification and powered by the [SMART Markers][sm] [framework] to receive and respond to practitioner's _requests_ with PGHD data generated through survey like modules in-app. Built using Swift for iOS.

### PGHD Instruments

The app relies on the SMART Markers framework's supported PGHD instruments to create a data generating user session. Many types of instruments are supported out of the box with more being actively developed. Some examples include: FHIR Questionnaire encoded surveys, [PROMIS][promis] CAT surveys, activity data, sensor based activity tests and more. [Check here][ilist] for a complete list.


Functionality
-------------

1. Users can login to their SMART enabled health system
2. Fetch all practitioner dispatched _requests_ for data
3. Users generate or aggregate health data as per the request and/or the Instrument requested
4. Users submit data to their health systems through the app.


Configuration
------------
0. You will need Xcode version 11.3 and Swift 5.0 and a `FHIR Server` endpoints and optionally their SMART credentials.
1. Clone repository: `$ git clone --recursive https://github.com/smartmarkers/demo-patientapp`
2. Make sure SMARTMarkers and its submodules are downloaded
1. Add SMARTMarkers.xcodeproj, ResearchKit.xcodeproj, SMART.xcodeproj to the application's project workspace
4. Compile ResearchKit and SMARTMarkers.xcodeproj
5. Go to Project Settings -> General Tab and add the three frameworks and HealthKit to the `Frameworks, Libraries, and Embedded Content`.
6. Build and run the app


You will need a SMART on FHIR endpoint to get started
```swift
extension FHIRManager {

    /**
     SMART Sandbox Credentials take from Config.xcconfig via App's
     - REPLACE Settings or create a new Client for other FHIR Servers
     */
    class func SMARTSandbox() -> FHIRManager {

        let infoDict = Bundle.main.infoDictionary!
        guard var baseURI = infoDict["FHIR_BASE_URL"] as? String else {
            fatalError("Need FHIR Endpoint")
        }
        if !baseURI.hasPrefix("http") {
            baseURI = "https://" + baseURI
        }

        let settings = [
            "client_name"   : "easipro-clinic",
            "client_id"     : "easipro-clinic-id",
            "redirect"      : "smartmarkers-home://smartcallback",
            "scope"         : "openid profile user/*.* launch"
        ]
        let smart_baseURL = URL(string: baseURI)!
        let client = Client(baseURL: smart_baseURL, settings: settings)
        client.authProperties.granularity = .tokenOnly

        //Initalize PROMIS FHIR server client with base uri, id, secret
        let promis = PROMISClient(..)
        return FHIRManager(main: client, promis: promis)
    }
}

  /*
  Initialize FHIRManager
  Can be done in AppDelegate
  */

lazy var fhir: FHIRManager! = {
        return FHIRManager.SMARTSandbox()
    }()


// Catch callback for SMART authorization
func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if fhir.main.awaitingAuthCallback {
            return fhir.main.didRedirect(to: url)
        }

        return false
    }
```

SMART Markers
-------------
This app was built on top of the SMART Markers framework but with its own custom interface and user experience designed specifically for PROMIS instruments and has now expanded to include various instruments enabled by the framework. [ResearchKit][rk] and [SwiftSMART][sw] are used as its submodules


[sm]: https://github.com/smartmarkers/smartmarkers-ios
[sf]: https://docs.smarthealthit.org
[promis]: https://healthmeasures.net
[ilist]: https://github.com/SMARTMarkers/smartmarkers-ios/tree/master/Sources/Instruments
[rk]: https://researchkit.org
[sw]: https://github.com/smart-on-fhir/Swift-SMART


