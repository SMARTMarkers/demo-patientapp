Patient App Demonstration
=====================

Transcript
---------

What I'd like to do now, is first, show how to build and run a PGHD app for a mobile device  in __less than 10mins__ using SMART Markers

This app would be for Patients where they are be able to receive and respond to requests from their care-team by generating and submitting results, right from  their device, and, all– in the FHIR Format. While this is an iOS version, we also have a React-Native version for Android and the Web built on similar principles.

Lets start with an empty app with only boilerplate code with just  two Views. [Show empty app]

## First, Import SMART Markers framework into the  project directory, and, as a module in project files------  this is a simple one liner.

-----------------------------------

## (2) Next, we need to configure and intialize FHIR client– a submodule of SMARTMarkers. The endpoints used here are to access the  SMART Sandbox  server  hosted by our team. But Developers can replace them with anyother compliant FHIR endpoint.

### Settings are what you usually get from the EHR. As per the SMART App Launch specification. And this is pretty much standard across the board.


```swift

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
    client.authProperties.granularity = .tokenOnly
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
-----------------------------------

## (3) With that in place, we can now add some code that initiates user authentication,  which, after successful completion,  resolves the most appropriate username from the FHIR resource.  In this case, its the Patient resource, hence we get the patient name. I would use the same function if the Practitioner were logging in, and in that case, I'd receive the Practitioner's name

This method, is also part of the SMART lib that is used within the framework and its as simple writing One function.

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

-----------------------------------

## (4) Assuming login was successful, we now want to fetch all the PGHD related `Requests`, the instruments embedded in those requests and any historical `Reports` previously submitted, all appropriately grouped and sorted by thier due dates and completion status.

SMART Markers hides all the quering complexity and exploses APIs todo just that, and, with only, a few lines of code.

```swift
guard let patient = manager.patient else { return }
self.title = "Loading.."

TaskController.Requests(requestType: ServiceRequest.self,
						for: patient,
						server: manager.main.server,
						instrumentResolver: self) { [weak self] (tasks, error) in
	DispatchQueue.main.async {
        // Update the UI
		if let controllers = controllers {
			self?.tasks = self?.sort(controllers)
		}
		if nil != error { print(error! as Any) }
		self?.markStandby()
	}
}
```

-----------------------------------

## (5) Lets now take a deeper look at one Request and its data in a different View

For this request, I'd like to display some metadata, which means its identifier, request date, and the practitioner  who requested it. 

We also want to list  any results that were submited previously, as part of this request  

#### 5.1: Metadata in `viewDidLoad()`

```swift
title = "REQ: #" + (task.request?.rq_identifier ?? "-")
graphView.title = task.instrument?.sm_title ?? task.request?.rq_title ?? "-"
graphView.subTitle = (task.request?.rq_categoryCode ?? "CODE: --")
reload()
```
#### 5.2: Populating Previous Reports IN A LIST `cellForRow()`

```swift
let result = reports![indexPath.row]
cell.textLabel?.text = "\(result.rp_date.shortDate): \(result.rp_description ?? "--")"
cell.detailTextLabel?.text = result.rp_observation ?? nil
```

#### 5.3: If I want to further explore the FHIR resource, the framework has built in Viewers that can be readily reused.

```swift
if let viewer = report.rp_viewController {
	self.show(viewer, sender: nil)
}
```


#### (6) Finally, some code that initiates a data generating session for the instrument. What I mean by that is, if the patient was sent a Questionnaire, then a survey module is created and presented to the user to record responses which results in a new FHIR  QuestionnaireResponse.

All this, is handled by SMART Markers and its submodules behind the scenes. This required an enourmous amout of code to precisely parse FHIR elements and create a representative user interface for patients to respond on. But for developers creating an app,  this is as simple as adding just 15 lines of code

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
Of course, we need some error handling.


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

### And now, we are now good to go, lets build and run.  I'd like to add here that there are many abstraction layers and convinience methods that i did not mention, but alot of it is detailed on our github page. Not every module is absolutely essential to use. For example, there can be a simple app that is dedicated to only  One instrument. Plus Many custom interfaces can be built on top of this framework. 


### That was a quick demo for patients app. Same methods can be used for practitioners app which can aditionally list all avialable instruments and as I said earliar, there are web and android versions too.


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


