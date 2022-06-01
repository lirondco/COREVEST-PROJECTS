({
    init: function(component, event, helper) {
      var actionRT = component.get("c.getRecordType");
  
      actionRT.setParams({
        recordId: component.get("v.recordId"),
        sobjectType: "Opportunity"
      });
  
      actionRT.setCallback(this, function(response) {
        var state = response.getState();
  
        if (state === "SUCCESS") {
          //
          let recordType = response.getReturnValue();
          const recTypesToChange = ["Acquired_Bridge_Loan_Active", "Acquired_Bridge_Loan", "Table_Funded_CRE_Loan", "Table_Funded_CRE_Loan_Active"];
          if (recTypesToChange.includes(recordType)) {
            recordType = "LOC_Loan";
          }
          component.set("v.recordType", recordType);
        } else if (state === "ERROR") {
          //
        }
      });
  
      $A.enqueueAction(actionRT);
  
      var action = component.get("c.getPropertyPicklists");
      action.setParams({
        dealId: component.get("v.recordId")
      });
  
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          //console.log(JSON.parse(response.getReturnValue()));
          var picklistValues = [];
          picklistValues.push({
            value: "",
            label: ""
          });
  
          picklistValues = picklistValues.concat(
            JSON.parse(response.getReturnValue())
          );
  
          component.set("v.propertyOptions", picklistValues);
  
          //var select = component.find('propertySelect');
          //console.log(select);//.set('v.options', picklistValues);
        } else if (state === "ERROR") {
          console.log("error");
        }
      });
  
      $A.enqueueAction(action);
  
      var action2 = component.get("c.getAdvancePicklists");
      action2.setParams({
        dealId: component.get("v.recordId")
      });
  
      action2.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          //console.log(JSON.parse(response.getReturnValue()));
          var picklistValues = [];
          picklistValues.push({
            value: "",
            label: ""
          });
  
          picklistValues = picklistValues.concat(
            JSON.parse(response.getReturnValue())
          );
  
          component.set("v.advanceOptions", picklistValues);
          console.log("advances ", picklistValues);
          //var select = component.find('propertySelect');
          //console.log(select);//.set('v.options', picklistValues);
        } else if (state === "ERROR") {
          console.log("error");
        }
      });
  
      $A.enqueueAction(action2);
    },
  
    propertyIdChange: function(component, event, helper) {
      console.log(component.get("v.propertyId"));
  
      var select = event.getSource();
  
      console.log(select.get("v.value"));
    },
  
    advanceIdChange: function(component, event, helper) {
      //console.log(component.get('v.propertyId'));
      //var select = event.getSource();
      //console.log(select.get('v.value'));
      // console.log(component.get('v.advanceId'));
      // if($A.util.isEmpty(component.get('v.advanceId'))){
      // 	component.set('v.advanceUploaderFacet', []);
      // }else{
      // 	$A.createComponent(
      // 		"c:BridgeDocumentUploader",
      // 		{
      // 			"recordId": component.get('v.advanceId'),
      // 			"sobjectType":"Advance__c",
      // 			"recordType": "LOC Loan"
      // 		},
      // 		function(uploader, status, errorMessage){
      // 			if(status === 'SUCCESS'){
      // 				var body = [];
      // 				body.push(uploader);
      // 				component.set('v.advanceUploaderFacet', uploader);
      // 			}
      // 		}
      // 	);
      // }
    },
  
    handleActive: function(component, event, helper) {
      var tab = event.getSource();
  
      console.log(tab.get("v.id"));
  
      if (tab.get("v.id") == "dealSingle") {
        component.set("v.dealBulkSelected", false);
      } else if (tab.get("v.id") == "dealBulk") {
        component.set("v.dealSingleSelected", false);
      } else if (tab.get("v.id") == "propertySingle") {
        component.set("v.propertyBulkSelected", false);
      } else if (tab.get("v.id") == "propertyBulk") {
        component.set("v.propertySingleSelected", false);
      }
  
      component.set("v." + tab.get("v.id") + "Selected", true);
    },
  
    handleSelect: function(component, event, helper) {
      var tab = event.getSource();
      console.log(tab.get("v.id"));
  
      component.set("v.dealSelected", false);
      component.set("v.propertySelected", false);
  
      component.set("v." + tab.get("v.id") + "Selected", true);
    }
  });