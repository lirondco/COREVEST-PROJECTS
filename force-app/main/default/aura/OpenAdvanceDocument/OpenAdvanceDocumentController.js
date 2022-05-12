({
  init: function (component, event, helper) {
    let queryString = "";
    let recordId = component.get("v.recordId");
    let sobjectType = component.get("v.sObjectName");

    if (sobjectType == "Opportunity") {
      queryString = `SELECT Id, StageName, RecordType.DeveloperName, Product_Sub_Type__c,LOC_Loan_Type__c, Type `; // Trivikram- Added LOC_Loan_Type__c
      queryString += `FROM Opportunity WHERE Id = '${recordId}'`;
    } else if (sobjectType == "Advance__c") {
      queryString = `SELECT Id, Deal__c, Deal__r.StageName, Deal__r.RecordType.DeveloperName, Deal__r.Product_Sub_Type__c, Deal__r.LOC_Loan_Type__c, Deal__r.Type `; // Trivikram- Added Deal__r.LOC_Loan_Type__c
      queryString += `FROM Advance__c WHERE Id = '${recordId}'`;
    }

    helper.generateAssignmentSetOptions(component);

    component.find("util").query(queryString, (result) => {
      let filterFields = {};
      if (sobjectType == "Opportunity") {
        filterFields["StageName"] = result[0].StageName;
        filterFields["RecordType"] = result[0].RecordType.DeveloperName;
        filterFields["ProductSubType"] = result[0].Product_Sub_Type__c;
        filterFields["ProductType"] = result[0].LOC_Loan_Type__c; // Trivikram
        component.set("v.dealId", result[0].Id);
      } else if (sobjectType == "Advance__c") {
        filterFields["StageName"] = result[0].Deal__r.StageName;
        filterFields["RecordType"] = result[0].Deal__r.RecordType.DeveloperName;
        filterFields["ProductSubType"] = result[0].Deal__r.Product_Sub_Type__c;
        filterFields["ProductType"] = result[0].Deal__r.LOC_Loan_Type__c; // Trivikram
        component.set("v.dealId", result[0].Deal__c);
      }

      component.set("v.filterFields", filterFields);
    });
  },
  generate: function (component, event, helper) {
    debugger;
    let val = component.find("documentType").get("v.value");
    //console.log("documentType ==>"+val);
    if (!$A.util.isEmpty(val)) {
      
      helper.setStaticResourceName(component, val);
      if (val == "State Level Security Instruments") {
        val = component.find("state").get("v.value");
        if (!$A.util.isEmpty(val)) {
          helper.generateDocx(component, val);
        }
      } else if (val == "Assignments") {
        val = component.find("assignments").get("v.value");
        if (!$A.util.isEmpty(val) && val != "Assignment Sets") {
          helper.generateDocx(component, val);
        } else if (!$A.util.isEmpty(val) && val == "Assignment Sets") {
          helper.setStaticResourceName(component, val);
          val = component.find("assignmentSets").get("v.value");
          if (!$A.util.isEmpty(val)) {
            helper.generateDocx(component, val);
          }
        }
      } else if (val.substring(0, 4) == "docx") {
        helper.generateDocx(component, val.substring(5));
      } else if (val == "Bridge IC Memo") {
        helper.createBridgeICMemoCmp(component, event);
      } else if (val == "Funding Memo") {
        helper.createSABICMemoCmp(component, event);
      } else if (val == "Loan Approval Request Form") {
        helper.createLoanApprovalRequestFormCmp(component, event);
      }
        else {
        window.open(val, "_blank");
      }
    }
  },
  evaluateAssignment: function(component, event, helper) {
    component.set("v.showAssignmentSets", component.find("assignments").get("v.value") == "Assignment Sets");
  },
  cancel: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  }
});