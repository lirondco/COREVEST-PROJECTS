({
  doInit: function (component, event, helper) {
    //component.set('v.Message','Get Person search data.');
    console.log(":doinit::called");
    component.set("v.loading", true);
    helper.showSpinner(component);

    var rowsForClearAPI = [];
    rowsForClearAPI = component.get("v.contactIdList");
    component.set("v.showClearAPIModal", true);
    console.log("clear api person search");
    var showModel = component.set("v.showClearAPIModal", true);
    console.log("showModel:doinit::", showModel);

    console.log("doInit::rowsForClearAPI::", rowsForClearAPI);

    if (rowsForClearAPI.length == 1) {
      component.set("v.isConfirmDetails", true);
      component.set("v.Message", "Get Person search data.");
      component.set("v.contactID", rowsForClearAPI[0]);
      var contactID = component.get("v.contactID");
      console.log("contactID:::", contactID);
      //helper.showSpinner(component);
      component.set("v.loading", true);

      /*var action = component.get("c.checkConAddressAndBirthDate");
		
			action.setParams({ "conRecordID" : rowsForClearAPI });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
                    console.log('SUCCESS::doInit');
					var resValue = response.getReturnValue();
					if(resValue == '' || resValue == null){
                        helper.checkEntityID(component, event, helper);
					}else{
                        component.set('v.Message', resValue);
						let personButton = component.find('personSearchButtonId');
						personButton.set('v.disabled',true);
                        let riskButton = component.find('riskButtonId');
						riskButton.set('v.disabled',true);
						let personSearchReportButton = component.find('personSearchReportButtonId');
						personSearchReportButton.set('v.disabled',true);
						let riskSearchReportButton = component.find('riskSearchReportButtonId');
						riskSearchReportButton.set('v.disabled',true);
					}
					helper.hideSpinner(component);
				} 
				else {
					console.log(state);
                    component.set('v.Message', 'Something went wrong.Please Try again Later. ');
					helper.hideSpinner(component);
				}
			});
			$A.enqueueAction(action);*/
    } else {
      console.log("else::::");

      component.set("v.isNoPersonSelected", true);
      component.set("v.isPersonNotFound", false);
      component.set("v.Message", "Please select one borrower.");
      let Message = component.get("v.Message");
      console.log("Message::::", Message);
      component.set("v.loading", false);

      /*let personButton = component.find('personSearchButtonId');
			personButton.set('v.disabled',true);
			let riskButton = component.find('riskButtonId');
			riskButton.set('v.disabled',true);
			let personSearchReportButton = component.find('personSearchReportButtonId');
			personSearchReportButton.set('v.disabled',true);
			let riskSearchReportButton = component.find('riskSearchReportButtonId');
			riskSearchReportButton.set('v.disabled',true);*/
    }
  },

  closeCreatePropertyModal: function (component, event, helper) {
    component.set("v.showClearAPIModal", false);
  },

  checkboxcheked: function (component, event, helper) {
    console.log("test:::", event.getSource().get("v.checked"));
    var checked = event.getSource().get("v.checked");
    if (checked == true) {
      var getvalue = event.getSource().get("v.value");
      console.log("getvalue::::", getvalue);
      if (getvalue == "SteetAddress") {
        component.set("v.SteetAddress", true);
      } else if (getvalue == "City") {
        component.set("v.City", true);
      } else if (getvalue == "State") {
        component.set("v.State", true);
      } else if (getvalue == "Country") {
        component.set("v.Country", true);
      } else if (getvalue == "Zip") {
        component.set("v.Zip", true);
      }
    } else {
      var getvalue = event.getSource().get("v.value");
      if (getvalue == "SteetAddress") {
        component.set("v.SteetAddress", false);
      } else if (getvalue == "City") {
        component.set("v.City", false);
      } else if (getvalue == "State") {
        component.set("v.State", false);
      } else if (getvalue == "Country") {
        component.set("v.Country", true);
      } else if (getvalue == "Zip") {
        component.set("v.Zip", false);
      }
    }
    var SteetAddress = component.get("v.SteetAddress");
    console.log("SteetAddress:::", SteetAddress);
    var City = component.get("v.City");
    console.log("City:::", City);
    var State = component.get("v.State");
    console.log("State:::", State);
    var Country = component.get("v.Country");
    console.log("Country:::", Country);
    var Zip = component.get("v.Zip");
    console.log("Zip:::", Zip);
  },

  submitAddressFields: function (component, event, helper) {
    helper.checkEntityID(component, event, helper);
    component.set("v.Message", "Get the Person Search Report.");
    component.set("v.isPersonNotFound", false);
    component.set("v.isPersonSearch", true);
  },

  callclearPersonsearchApi: function (component, event, helper) {
		component.set("v.performErrorCheck", true);
    helper.callclearPersonsearchApiHelper(component, event, helper);

    /*helper.showSpinner(component);
		//component.set("v.setMeOnInit", "controller init magic!");
		
		let personButton = component.find('personSearchButtonId');
		personButton.set('v.disabled',true);
		
        var rowsForClearAPI = [];
        rowsForClearAPI = component.get("v.contactIdList");
        
        console.log('callclearPersonsearchApi::rowsForClearAPI::',rowsForClearAPI);
        
        
		//var id = component.get("v.recordId");
		//var action = component.get("c.getContactDetail");
		rowsForClearAPI.forEach(function (el) {
            console.log('el::::',el);
            var action = component.get("c.getContactDetailforPersonSearch");
		
            action.setParams({ "id" : el ,"SteetAddress" : ''});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('SUCCESS');
                     var resMap= response.getReturnValue();
                    //var result = component.get("v.myMap.key1");
                    component.set('v.Message', resMap['message']);
                    //component.set('v.Message','SUCCESS');
                    console.log('resMap:;:',resMap);
                    if(resMap['message'] == 'Get the Person Search Report.'){
                        let riskButton = component.find('riskButtonId');
                        riskButton.set('v.disabled',false);
                        let personSearchReportButton = component.find('personSearchReportButtonId');
                        personSearchReportButton.set('v.disabled',false);
                        let riskSearchReportButton = component.find('riskSearchReportButtonId');
                        riskSearchReportButton.set('v.disabled',false);
                    }else if(resMap['message'] == 'Person not found.'){
                        component.set('v.isPersonNotFound', true);
                        component.set('v.Message', 'If your first search does not return any results,try removing some of the address fields to widen the search');
                    }
                    helper.hideSpinner(component);
                } 
                else {
                    console.log(state);
                    helper.hideSpinner(component);
                }
            });
            $A.enqueueAction(action);
    	});*/

    /*var action = component.get("c.getContactDetailforPersonSearch");
		
		action.setParams({ "id" : id });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				console.log('SUCCESS');
				 var resMap= response.getReturnValue();
				//var result = component.get("v.myMap.key1");
				component.set('v.Message', resMap['message']);
				//component.set('v.Message','SUCCESS');
				console.log('resMap:;:',resMap);
				if(resMap['message'] == 'Get Response for Person Search.'){
					let riskButton = component.find('riskButtonId');
					riskButton.set('v.disabled',false);
					let personSearchReportButton = component.find('personSearchReportButtonId');
					personSearchReportButton.set('v.disabled',false);
					let riskSearchReportButton = component.find('riskSearchReportButtonId');
					riskSearchReportButton.set('v.disabled',false);
				}
				helper.hideSpinner(component);
			} 
			else {
				console.log(state);
				helper.hideSpinner(component);
			}
		});
		$A.enqueueAction(action);*/
  },
  callclearPersonrisksearchApi: function (component, event, helper) {
    //helper.showSpinner(component);
    component.set("v.loading", true);
		component.set("v.performErrorCheck", true);

    var rowsForClearAPI = [];
    rowsForClearAPI = component.get("v.contactIdList");

    var dealContactIds = [];
    dealContactIds = component.get("v.dealContactIdsList");

    console.log(
      "callclearPersonrisksearchApi:::dealContactIds::::",
      dealContactIds
    );


    // for (let i = 0; i < dealContactIds.length; i++) {

    let el = dealContactIds[0];

    var action = component.get("c.getContactDetailforRiskSearch");
    action.setParams({ id: el });
    action.setCallback(this, function (response) {
      var state = response.getState();
			let errorMessage;
	
      if (state === "SUCCESS") {
        console.log("SUCCESS");
        var resMap = response.getReturnValue();
        //var result = component.get("v.myMap.key1");
        if (!resMap["errorMessage"]) {
          
          errorMessage = resMap["errorMessage"];
					component.set("v.hasError", true);
					component.set("v.errorMessage", errorMessage);

        } else {
          component.set("v.Message", resMap["message"]);
        }
        //component.set('v.Message','SUCCESS');
        //helper.hideSpinner(component);
      } else {
        console.log(state);
        //helper.hideSpinner(component);
        errorMessage = "Unexpected error occured.";
				component.set("v.hasError", true);
				component.set("v.errorMessage", errorMessage);

      }
    });
    $A.enqueueAction(action);
    //}

    /* //component.set("v.setMeOnInit", "controller init magic!");
        var id = component.get("v.recordId");
  		//var action = component.get("c.getContactDetail");
		var action = component.get("c.getContactDetailforRiskSearch");
		
        action.setParams({ "id" : id });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				console.log('SUCCESS');
				 var resMap= response.getReturnValue();
				//var result = component.get("v.myMap.key1");
				component.set('v.Message', resMap['message']);
				//component.set('v.Message','SUCCESS');
				helper.hideSpinner(component);
			} 
			else {
				console.log(state);
				helper.hideSpinner(component);
			}
		});
		$A.enqueueAction(action); */
  },

	evaluateErrors: function (component, event, helper) {
		if (component.get("v.hasError") && component.get("v.errorMessage")) {
			helper.showToast("Error", component.get("v.errorMessage"), "error");
			component.set("v.loading", false);

		} else if (component.get("v.performErrorCheck")) {
			component.set("v.performErrorCheck", false);
			helper.showToast(
				"Success",
				"Request has been completed successfully.",
				"success"
			);
			component.set("v.loading", false);

		}

	},

  callClearRiskReportApi: function (component, event, helper) {
    //helper.showSpinner(component);
    component.set("v.loading", true);
		component.set("v.performErrorCheck", true);
    //component.set("v.setMeOnInit", "controller init magic!");

    //var rowsForClearAPI = [];
    //rowsForClearAPI = component.get("v.contactIdList");

    var dealContactIds = [];
    dealContactIds = component.get("v.dealContactIdsList");

    var dealID = component.get("v.dealRecordId");
    console.log("dealID:::", dealID);

    console.log("callClearRiskReportApi::dealContactIds::", dealContactIds);

    dealContactIds.forEach(function (el) {
      console.log("el::::", el);
      var action = component.get("c.GetReport");

      action.setParams({
        id: el,
        typeofReport: "RiskSearchReport",
        dealRecordId: dealID
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          console.log("SUCCESS");
          var resMap = response.getReturnValue();

					if(resMap["errorMessage"]) {
						component.set("v.hasError", true);
						component.set("v.errorMessage", resMap["errorMessage"]);
					}
          //var result = component.get("v.myMap.key1");
          component.set("v.Message", resMap["message"]);
          //component.set('v.Message','SUCCESS');
          //helper.hideSpinner(component);
        } else {
          console.log(state);
          //helper.hideSpinner(component);
					component.set("v.hasError", true);
					component.set("v.errorMessage", "Unexpected error occured.");
        }
      });
      $A.enqueueAction(action);
    });

    /* var id = component.get("v.recordId");
  		//var action = component.get("c.getContactDetail");
		var action = component.get("c.GetReport");
		
        action.setParams({ "id" : id,"typeofReport":'RiskSearchReport' });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				console.log('SUCCESS');
				 var resMap= response.getReturnValue();
				//var result = component.get("v.myMap.key1");
				component.set('v.Message', resMap['message']);
				//component.set('v.Message','SUCCESS');
				helper.hideSpinner(component);
			} 
			else {
				console.log(state);
				helper.hideSpinner(component);
			}
	  });
	  $A.enqueueAction(action); */
  },

  callClearPersonReportApi: function (component, event, helper) {
    //helper.showSpinner(component);
    component.set("v.loading", true);
		component.set("v.performErrorCheck", true);
    //component.set("v.setMeOnInit", "controller init magic!");

    //var rowsForClearAPI = [];
    //rowsForClearAPI = component.get("v.contactIdList");
    let personSearchReportButton = component.find("personSearchReportButtonId");
    personSearchReportButton.set("v.disabled", true);

    // console.log('callClearPersonReportApi::rowsForClearAPI::',rowsForClearAPI);

    var dealContactIds = [];
    dealContactIds = component.get("v.dealContactIdsList");

    console.log("callClearRiskReportApi::dealContactIds::", dealContactIds);

    var dealID = component.get("v.dealRecordId");
    console.log("dealID:::", dealID);

    dealContactIds.forEach(function (el) {
      console.log("el::::", el);
      var action = component.get("c.GetReport");

      action.setParams({
        id: el,
        typeofReport: "PersonSearchReport",
        dealRecordId: dealID
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          console.log("SUCCESS");
          var resMap = response.getReturnValue();
          //var result = component.get("v.myMap.key1");
					if(resMap['errorMessage']) {
						component.set("v.hasError", true);
						component.set("v.errorMessage", resMap['errorMessage']);
					}

          component.set("v.Message", resMap["message"]);
          //component.set('v.Message','SUCCESS');
          //helper.hideSpinner(component);
         } else {
          console.log(state);
          //helper.hideSpinner(component);
					component.set("v.hasError", true);
					component.set("v.errorMessage", "Unexpected error occured.");
         }
      });
      $A.enqueueAction(action);
    });

    /*  var id = component.get("v.recordId");
  		//var action = component.get("c.getContactDetail");
		var action = component.get("c.GetReport");
		
        action.setParams({ "id" : id,"typeofReport":'PersonSearchReport' });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				console.log('SUCCESS');
				 var resMap= response.getReturnValue();
				//var result = component.get("v.myMap.key1");
				component.set('v.Message', resMap['message']);
				//component.set('v.Message','SUCCESS');
				helper.hideSpinner(component);
			} 
			else {
				console.log(state);
				helper.hideSpinner(component);
			}
		});
		$A.enqueueAction(action); */
  },

  handleOnSubmit: function (component, event, helper) {
    //helper.showSpinner(component);
    component.set("v.loading", true);
    console.log("handleOnSubmit::::");
  },

  handleOnSuccess: function (component, event, helper) {
    //helper.hideSpinner(component);
    component.set("v.loading", false);
    component.set("v.isPersonSearch", true);
    component.set("v.isConfirmDetails", false);
    console.log("handleOnSuccess::::");
    helper.checkEntityID(component, event, helper);
  },

  onBackButton: function (component, event, helper) {
    console.log("onBackButton::::");
    component.set("v.loading", true);
    component.set("v.isConfirmDetails", true);
    component.set("v.isPersonSearch", false);
  },

  handleLoad: function (component, event, helper) {
    console.log("handleLoad::::");
    component.set("v.loading", false);
  }
});
