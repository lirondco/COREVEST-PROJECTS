({
  init: function(component, event, helper) {
    console.log("init started");
    let recordId = component.get("v.recordId");
    let action = component.get("c.validateRecord");
    action.setParams({ recordId: recordId });
    action.setCallback(this, function(response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        console.log("success");
        let returnVal = JSON.parse(response.getReturnValue());
        console.log("this is what we get back");
        console.log(returnVal);
        if (returnVal.otherMessage && returnVal.otherMessage.length > 0) {
          // document.querySelector('#missing-fields').innerHTML = returnVal.otherMessage;
          component.set("v.errorMessage", returnVal.otherMessage);
          // helper.toggleHide(component, 'errorMessage');
        } else {
          helper.parseData(returnVal, function(error) {
            console.log("this is the error");
            console.log(error);
            if (error.length > 0) {
              // document.querySelector('#missing-fields').innerHTML = error;
              component.set("v.errorMessage", [error]);
              // helper.toggleHide(component, 'errorMessage');
            } else {
              document.querySelector("#missing-fields").innerHTML = "";
              component.set("v.errorMessage", []);
              helper.toggleHide(component, "successMessage");
              helper.toggleHide(component, "submitButton");
              if (returnVal.oppName) {
                component.set("v.recordName", returnVal.oppName);
              }
              if (returnVal.recordType) {
                component.set("v.recordType", returnVal.recordType);
              }

              if (
                !$A.util.isEmpty(returnVal.isDisplayGLC) &&
                !$A.util.isUndefined(returnVal.isDisplayGLC)
              ) {
                component.set("v.isDisplayGLC", returnVal.isDisplayGLC);
              }
            }
          });
        }
        helper.doQueryPricingCount(component, helper);
      } else {
        console.log(response.getError());
      }
    });
    $A.enqueueAction(action);
  },

  submitApproval: function(component, event, helper) {
    component.find("submitButton").set("v.disabled", true);
    if (
      component.get("v.isDisplayGLC") == true &&
      ($A.util.isEmpty(component.get("v.resolution")) ||
        $A.util.isUndefined(component.get("v.resolution")))
    ) {
      //component.set("v.errorMessage", ['Resolution field is required.']);
      component.set("v.toastMessage", "Resolution field is required.")
      component.set("v.toastTitle", "Missing field value");
      component.set("v.toastType", "error");
      component.find("submitButton").set("v.disabled", false);
      helper.showToast(component);
      return;
    } else if (component.get("v.requireComments") == true && $A.util.isEmpty(component.get("v.comments"))) {
      component.set("v.toastMessage", "Comments are required for deals that have been previously submitted for pricing.")
      component.set("v.toastTitle", "Missing Comments");
      component.set("v.toastType", "error");
      component.find("submitButton").set("v.disabled", false);
      helper.showToast(component);
      return;
    } else {
      console.log("submitting for approval");
      let action = component.get("c.startApproval");
      action.setParams({
        recordId: component.get("v.recordId"),
        recordName: component.get("v.recordName"),
        comments: component.get("v.comments"),
        resolution: component.get("v.resolution"),
        recordType: component.get("v.recordType")
      });
      action.setCallback(this, function(response) {
        let state = response.getState();
        if ("SUCCESS" === state) {
          console.log("success");
          let returnVal = response.getReturnValue();
          document.querySelector("#result-message").textContent = returnVal;
          helper.toggleHide(component, "successMessage");
          helper.toggleHide(component, "result");
          helper.toggleHide(component, "cancelButton");
          // helper.toggleHide(component, "submitButton");
          helper.toggleHide(component, "okButton");
          console.log(returnVal);
        } else {
          console.log("approval failed");
        }
      });
      $A.enqueueAction(action);
    }
  },

  closeModal: function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  },

  closeWindow: function(component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  }
});