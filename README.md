SMART Markers Patient App Demonstration
=====================


This app would be for Patients where they are be able to receive and respond to requests from their care-team by generating and submitting results, right from  their device, and, all– in the FHIR Format. While this is an iOS version, we also have a React-Native version for Android and the Web built on similar principles.

# INSTALLATION

1. `$ git clone --recursive https://github.com/SMARTMarkers/demo-patientapp`
2. Get SMART on FHIR Server endpoints from `https://launch.smarthealthit.org`. Select `Patient Standalone Launch` as the launch type. FHIR Version: `R4`. And finally select one patient from the drop down list. __Finally__, copy the `FHIR Server Url` to be configured in the app`

----------------------------------

## (1) Import SMART Markers framework into the  project directory, and, as a module in project files------  this is a simple one liner.

-----------------------------------

## (2) Configure and intialize FHIR client– a submodule of SMARTMarkers. 

```swift

lazy var fhir: FHIRManager! = {
    
    // Obtained form SMART Sandbox: https://launch.smarthealthit.org
    let fhir_endpoint = "https://launch.smarthealthit.org/v/r4/sim/eyJrIjoiMSIsImIiOiJmYzIwMGZhMi0xMmM5LTQyNzYtYmE0YS1lMDYwMWQ0MjRlNTUifQ/fhir"

    let settings = [
        "client_name"   : "appDemo",
        "client_id"     : "appDemo-id",
        "redirect"      : "smartmarkers-home://smartcallback",
        "scope"         : "openid profile user/*.* launch"
    ]

    let client = Client(baseURL: URL(string: fhir_endpoint)!, settings: settings)
    client.authProperties.granularity = .tokenOnly
    return FHIRManager(main: client, promis: PROMISClient.New())

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

## (3) With that in place, we can now add some code that initiates user authentication.

```swift
let fhr = (UIApplication.shared.delegate as! AppDelegate).fhir
return fhr


manager?.authorize { [weak self] (success, userName, error) in
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

## (4) Assuming login was successful, we now want to fetch all the PGHD related data


```swift
guard let patient = manager?.patient else { return }
self.title = "Loading.."

TaskController.Requests(requestType: ServiceRequest.self,
                        for: patient,
                        server: manager!.main.server,
                        instrumentResolver: self) { [weak self] (taskcontrollers, error) in
    DispatchQueue.main.async {
        // Update the UI
        if let taskcontrollers = taskcontrollers {
            self?.tasks = self?.sort(taskcontrollers)
        }
        if nil != error { print(error! as Any) }
        self?.markStandby()
    }
}

```

-----------------------------------


## (5) Lets now take a deeper look at one Request and its data in a different View - `DetailViewController`

Lets add some code for show request metadata.
#### 5.1: Metadata in `viewDidLoad()`
```swift
title = "REQ: #" + (task.request?.rq_identifier ?? "-")
graphView.title = task.instrument?.sm_title ?? task.request?.rq_title ?? "-"
graphView.subTitle = (task.request?.rq_categoryCode ?? "CODE: --")
```
I'd like to show its identifier, request date, and the terminology code if any.

We also want to list  any results that were submited previously, as part of this request  
```swift
let result = reports![indexPath.row]
cell.textLabel?.text = "\(result.rp_date.shortDate): \(result.rp_description ?? "--")"
cell.detailTextLabel?.text = result.rp_observation ?? nil
```

#### 5.3: If I want to further explore the FHIR resource, the framework has built in Viewers that can be readily reused.

```swift
let report = reports![indexPath.row]
if let viewer = report.rp_viewController {
    self.show(viewer, sender: nil)
}
```


#### (6) Finally, some code that initiates a data generating session for the instrument. 


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

### And now, we are now good to go, lets build and run. 






-----------------------------------------------------------------

# More information

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


SMART Markers
-------------
This app was built on top of the SMART Markers framework but with its own custom interface and user experience designed specifically for PROMIS instruments and has now expanded to include various instruments enabled by the framework. [ResearchKit][rk] and [SwiftSMART][sw] are used as its submodules


[sm]: https://github.com/smartmarkers/smartmarkers-ios
[sf]: https://docs.smarthealthit.org
[promis]: https://healthmeasures.net
[ilist]: https://github.com/SMARTMarkers/smartmarkers-ios/tree/master/Sources/Instruments
[rk]: https://researchkit.org
[sw]: https://github.com/smart-on-fhir/Swift-SMART


