Transcript
---------

### Hello everyone, my name is Raheel Sayeed, I am a fellow at ComputationalHealth Informatics Program at Boston Children's Hospital and Harvard Medical School. I am going to be demonstrating SMART Markers: A SMART on FHIR framework to standardize collection of patient generated health data

----------

### I have nothing to disclose

-------------------------------------------------------------------
----------  SMART Markers Intro

###  SMART Markers  is a software framework that allows developers to rapidly build custom apps for bringing patient generated data like patient reported outcomes, activity, device sensor data to the point of care using interoperable and reusable technologies.

-------------------------------------------------------------------
----------- PGHD

### Briefly about the data I am refering to, it is a health metric that is directly generated and obtained from the patient without a clinican's potentially subjective interpretation.

Some examples are HRQoL surveys, Functional Knee scores, PROMIS measures

Our goal thus is, to bring this data to the point of care.

-------------------------------------------------------------------
----------- smart

### I'd like to briefly touch on the **CORE Technology** that makes a "vendor agonostic" appraoch possible -SMART-on-FHIR
- that allows independent 3rdparty apps to securely access EHR data.
- and this effectively turns  EHRs: "Platforms for Health apps",
- Most EHRs today already support this standard.`
- Theres actually an gallery of apps... that work in the EHR.



-------------------------------------------------------------------
----------- interoper architecture

Lets take an overview of what an interoperable architecture looks like. Mainly its got a SMART on FHIR compatible EHR. There is an PGHD instrument metadata registry within the EHR and I'll come to that in a bit. 

At point of care, in clinics or waiting rooms: ther are Apps for pracitioners that dispatch data requests to the patient that run within the context of the EHR. 

And on the other side there is a patient facing app, that generates data and reports back to their health system.

Needless to say, that, all data transmitted, is FHIR

SMART Markers is a framework that can be used to make these apps.. very fast!

------------------------------------------------------------------
-------------instrument repository

The purpose of having a computable registry of instruments hosted in an EHR is to allow different apps to have a list of preapproved data-types that can be requested from the patients.

It is basically a set of FHIR resources. Each instrument is an identifier for the data type thats being requested. for example surveys encoded as FHIR Questionnaires or adaptive questionnaire for  PROMIS measures, or an ontological Code that identifies the data type– such as LOINC codes for Heart rate, step count, Blood pressure, etc... 

While this is not necessary, having a registry like this makes  PGHD capturing--- an institution-vide service. 

###  


