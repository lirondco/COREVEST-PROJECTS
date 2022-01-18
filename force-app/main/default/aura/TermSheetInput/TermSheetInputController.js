({
  init: function(component, event, helper) {
    var today = new Date();
    var isoStr = new Date(today.setDate(today.getDate() + 14)).toISOString();
    var dateArr = isoStr.split(/[-T]/);
    dateArr.pop();
    var dateStr = dateArr.join("-");
    console.log("this is dateStr: " + dateStr);
    component.set("v.fields.Term_Sheet_Expiration_Date__c", dateStr);
    let recordId = component.get("v.recordId");
    let action = component.get("c.findRecordType");
    action.setParams({ recordId: recordId });
    action.setCallback(this, function(response) {
      let state = response.getState();
      if ("SUCCESS" === state) {
        let returnVal = response.getReturnValue();
        console.log("this is the returnVal");
        console.log(returnVal);

        component.set("v.deal", JSON.parse(returnVal["record"][0]));

        console.log(component.get("v.deal"));

        if (
          returnVal.incorrectLoanType &&
          returnVal.incorrectLoanType.length > 0
        ) {
          helper.toggleHide(component, "incorrectLoanType");
          component.set("v.initiated", false);
        } else if (
          (returnVal.MissingFields && returnVal.MissingFields.length > 0) ||
          returnVal.Approved[0] == "false"
        ) {
          console.log("inside wrong condition");
          component.set("v.initiated", false);
          if (returnVal.Approved[0] == "false") {
            // document.querySelector('#approved-status').classList.remove('slds-hide');
            helper.toggleHide(component, "approvedStatus");
          }
          if (returnVal.MissingFields && returnVal.MissingFields.length > 0) {
            helper.toggleHide(component, "missingFields");
            component.set("v.missingFields", returnVal.MissingFields);
            // document.querySelector('#missing-fields').classList.remove('slds-hide');
          }
        } else if (returnVal.RecordType) {
          console.log("inside here");
          component.set("v.recordType", returnVal.RecordType[0]);
          component.set("v.initiated", true);
          console.log(component.get("v.recordType"));
          component.find("submitButton").set("v.disabled", false);

          if (
            returnVal.GenerateDocPermission &&
            returnVal.GenerateDocPermission.length > 0
          ) {
            component.set("v.generateDocPermission", "true");
          }
        }
      } else {
        console.log(response.getError());
      }
    });
    $A.enqueueAction(action);
  },

  handleClick: function(component, event, helper) {
    console.log("clicked1");
    component.find("submitButton").set("v.disabled", true);
    if (null != component.get("v.dateError")) {
      component.set(
        "v.dateError",
        "Please correct the date before submitting."
      );
      return;
    }
    let fields = Object.assign({}, component.get("v.fields"));
    fields["Id"] = component.get("v.recordId");
    if (
      component.get("v.recordType") == "LOC_Loan" ||
      component.get("v.recordType").includes("Bridge")
    ) {
      // fields["Negotiated_by_Counsel__c"] = document
      //   .querySelector('input[name="Negotiated_by_Counsel__c"]')
      //   .checked.toString();
      fields["Negotiated_by_Counsel__c"] = component
        .find("Negotiated_by_Counsel__c")
        .get("v.checked")
        .toString();
      // fields["Include_CO_Broker_Text__c"] = document
      //   .querySelector('input[name="Include_CO_Broker_Text__c"]')
      // .checked.toString();
      fields["Include_CO_Broker_Text__c"] = component
        .find("Include_CO_Broker_Text__c")
        .get("v.checked")
        .toString();
      // fields["Include_3_Months_Min_Interest__c"] = document
      //   .querySelector('input[name="Include_3_Months_Min_Interest__c"]')
      //   .checked.toString();
      fields["Include_3_Months_Min_Interest__c"] = component
        .find("Include_3_Months_Min_Interest__c")
        .get("v.checked")
        .toString();
      // fields["Include_Broker_Fee__c"] = document
      //   .querySelector('input[name="Include_Broker_Fee__c"]')
      //   .checked.toString();
      fields["Include_Broker_Fee__c"] = component
        .find("Include_Broker_Fee__c")
        .get("v.checked")
        .toString();
    }
    if (component.get("v.recordType") == "Term_Loan") {
      // fields["NY_Counsel_Required__c"] = document
      //   .querySelector('input[name="NY_Counsel_Required__c"]')
      //   .checked.toString();
      fields["NY_Counsel_Required__c"] = component
        .find("NY_Counsel_Required__c")
        .get("v.checked")
        .toString();
      // fields["Include_Assumption__c"] = document
      //   .querySelector('input[name="Include_Assumption__c"]')
      //   .checked.toString();
      fields["Include_Assumption__c"] = component
        .find("Include_Assumption__c")
        .get("v.checked")
        .toString();
      // fields["Include_Prop_Sub_Text__c"] = document
      //   .querySelector('input[name="Include_Prop_Sub_Text__c"]')
      //   .checked.toString();
      fields["Include_Prop_Sub_Text__c"] = component
        .find("Include_Prop_Sub_Text__c")
        .get("v.checked")
        .toString();
      // fields["Include_CO_Broker_Text__c"] = document
      //   .querySelector('input[name="Include_CO_Broker_Text__c"]')
      //   .checked.toString();
      fields["Include_CO_Broker_Text__c"] = component
        .find("Include_CO_Broker_Text__c")
        .get("v.checked")
        .toString();
      // fields["Include_Broker_Fee__c"] = document
      //   .querySelector('input[name="Include_Broker_Fee__c"]')
      //   .checked.toString();
      fields["Include_Broker_Fee__c"] = component
        .find("Include_Broker_Fee__c")
        .get("v.checked")
        .toString();
    }
    if (component.get("v.generateDocPermission") == "true") {
      // fields["Generate_Word_Doc"] = document
      //   .querySelector('input[name="Generate_Word_Doc"]')
      //   .checked.toString();
      fields["Generate_Word_Doc"] = component
        .find("Generate_Word_Doc")
        .get("v.checked")
        .toString();
    }
    console.log(fields);

    let action = component.get("c.generateSheet");
    var serverObj = {
      s: JSON.stringify(fields),
      recordType: component.get("v.recordType")
    };
    console.log(serverObj);
    action.setParams(serverObj);
    action.setCallback(this, function(response) {
      let state = response.getState();
      if ("SUCCESS" === state) {
        if (
          component.get("v.generateDocPermission") == "true" &&
          component
            .find("Generate_Word_Doc")
            .get("v.checked")
            .toString() == "true"
        ) {
          let returnVal = response.getReturnValue();
          console.log(returnVal);
          window.location.href = returnVal;
          component.set("v.generatedDoc", true);
        } else {
          let returnVal = response.getReturnValue();
          console.log(returnVal);
          component.set("v.success", true);
        }
      } else {
        console.log(response.getError());
        component.set("v.failure", true);
      }
    });
    $A.enqueueAction(action);
    // supposed to input these fields and generate term sheet
  },

  reload: function(component, event, helper) {
    //console.log("reloading");
    //window.location.reload();
    $A.get("e.force:refreshView").fire();
    $A.get("e.force:closeQuickAction").fire();
  },

  closeModal: function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },

  handleBlur: function(component, event, helper) {
    console.log(event.target.value);
    var todaysDate = new Date();
    var twoWeeksFromNow = new Date();
    twoWeeksFromNow.setDate(todaysDate.getDate() + 14);
    console.log(todaysDate);
    var enteredDate = new Date(event.target.value);
    console.log(enteredDate);
    if (enteredDate > todaysDate && enteredDate <= twoWeeksFromNow) {
      // okay
      console.log("within 14 days");
      component.set("v.dateError", null);
    } else {
      console.log("not within range");
      component.set(
        "v.dateError",
        "Expiration date must be within 14 days of current date."
      );
    }
  },

  closeWindow: function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  }
});