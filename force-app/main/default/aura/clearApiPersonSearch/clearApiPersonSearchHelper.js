({
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
     
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    checkEntityID: function (component, event, helper) {
        
        var rowsForClearAPI = [];
        rowsForClearAPI = component.get("v.contactIdList");
        
        var action = component.get("c.getEntityId");
        
        action.setParams({ "conRecordID" : rowsForClearAPI });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('SUCCESS:::checkEntityID:');
                var resValue = response.getReturnValue();
                if(resValue == false){
                    let riskButton = component.find('riskButtonId');
                    riskButton.set('v.disabled',true);
                    let personSearchReportButton = component.find('personSearchReportButtonId');
                    personSearchReportButton.set('v.disabled',true);
                    let riskSearchReportButton = component.find('riskSearchReportButtonId');
                    riskSearchReportButton.set('v.disabled',true);
                }else{
                    //let personButton = component.find('personSearchButtonId');
                    //	personButton.set('v.disabled',true);
                }
                
                //helper.hideSpinner(component);
                component.set('v.loading', false);
            } 
            else {
                console.log('checkEntityID::::error');
                console.log(state);
                //helper.hideSpinner(component);
                component.set('v.loading', false);
            }
        });
        $A.enqueueAction(action);
    },
    
    callclearPersonsearchApiHelper: function(component, event, helper){
		//helper.showSpinner(component);
        component.set('v.loading', true);
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
		
            action.setParams({ "id" : el ,"SteetAddressCheck" : component.get('v.SteetAddress'),
                              "CityCheck" : component.get('v.City'),
                             "StateCheck" : component.get('v.State'),
                             "CountryCheck" : component.get('v.Country'),
                             "ZipCheck" : component.get('v.Zip')});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log('SUCCESS');
                     var resMap= response.getReturnValue();
                    //var result = component.get("v.myMap.key1");
                    component.set('v.Message', resMap['message']);
                    //component.set('v.Message','SUCCESS');
                    console.log('resMap:;:',resMap);

                    if(resMap['errorMessage']) {
                        component.set('v.hasError', true);
                        component.set('v.errorMessage', resMap['errorMessage']);
                    }

                    let customErrorMessage;

                    if(resMap['message'] == 'Get the Person Search Report.'){
                        let riskButton = component.find('riskButtonId');
                        riskButton.set('v.disabled',false);
                        let personSearchReportButton = component.find('personSearchReportButtonId');
                        personSearchReportButton.set('v.disabled',false);
                        let riskSearchReportButton = component.find('riskSearchReportButtonId');
                        riskSearchReportButton.set('v.disabled',false);
                    }else if(resMap['message'] == 'Person not found.' || resMap['message'] == 'Error occurred.Please try again.'){
                        component.set('v.isPersonNotFound', true);
                        component.set('v.isPersonSearch', false);
                        component.set('v.Message', 'If your first search does not return any results,try removing some of the address fields to widen the search');
                        customErrorMessage = 'If your first search does not return any results,try removing some of the address fields to widen the search';
                    }

                    if(customErrorMessage) {
                        component.set('v.hasError', true);
                        component.set('v.errorMessage', customErrorMessage);
                    }
                    //helper.hideSpinner(component);
                } 
                else {
                    console.log(state);
                    //helper.hideSpinner(component);
                    component.set('v.hasError', true);
                    component.set('v.errorMessage', 'An unexpected error has occured.');
                }
            });
            $A.enqueueAction(action);
    	});
        
	},

    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})