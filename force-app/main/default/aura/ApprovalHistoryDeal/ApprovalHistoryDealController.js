({
  init: function (component, event, helper) {
    helper.init(component, event, helper);
  },

  showAll: function (component, event, helper) {
    console.log("clicked!");
    helper.toggleHide(component, "hiddenSteps");
    component.set(
      "v.displayMessage",
      helper.toggleMessage(component.get("v.displayMessage"))
    );
  },

  recallRequest: function (component, event, helper) {
    console.log("clicked recall");
    let action = component.get("c.recallApproval");
    action.setParams({ processId: component.get("v.processId") });
    console.log(component.get("v.processId"));
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state == "SUCCESS") {
        let returnVal = response.getReturnValue();
        component.set("v.responseMessage", returnVal);
        console.log(returnVal);
        document
          .querySelector(".slds-modal")
          .classList.add("slds-fade-in-open");
        document
          .querySelector(".slds-backdrop")
          .classList.add("slds-backdrop_open");
      }
    });
    $A.enqueueAction(action);
  },

  closeModal: function (component, event, helper) {
    document.querySelector(".slds-modal").classList.remove("slds-fade-in-open");
    document
      .querySelector(".slds-backdrop")
      .classList.remove("slds-backdrop_open");
    component.set("v.responseMessage", "");
    $A.get("e.force:refreshView").fire();
    window.location.reload();
  },

  openApprovalHeader: function (component, event, helper) {
    console.log("open approval header");

    let index = event.getSource().get("v.title");
    let label = event.getSource().get("v.label");

    //console.log(index);

    let step = component.get("v.steps")[index];
    console.log(step);
    component.set("v.selectedStepId", step.Process_Id__c);
    component.set("v.approvalType", step.ProcessName__c);
    component.set("v.modalHeader", label);
    // if (label == 'Approve') {
    // 	$A.util.removeClass(component.find('approveButton'), 'slds-hide');
    // 	$A.util.removeClass(component.find('recordFields'), 'slds-hide');
    // } else if (label == 'Reject') {
    // 	$A.util.removeClass(component.find('rejectButton'), 'slds-hide');
    // }

    component.set("v.showApproval", true);

    if (label == "Approve") {
      //$A.util.removeClass(component.find('approveButton'), 'slds-hide');
      //$A.util.removeClass(component.find('recordFields'), 'slds-hide');
    } else if (label == "Reject") {
      //$A.util.removeClass(component.find('rejectButton'), 'slds-hide');
    }
  },

  closeApprovalHeader: function (component, event, helper) {
    component.set("v.selectedStepId", null);
    component.set("v.approvalType", null);

    component.set("v.showApproval", false);
  },

  approve: function (component, event, helper) {
    let opp = { sobjectType: "Opportunity", Id: component.get("v.recordId") };
    if (!$A.util.isUndefinedOrNull(component.find("fields"))) {
      let fields = component.find("fields");
      if (!$A.util.isArray(fields)) {
        fields = [fields];
      }

      fields.forEach((field) => {
        opp[field.get("v.fieldName")] = field.get("v.value");
      });
    }

    console.log(opp);

    let action = component.get("c.approveDeal");
    action.setParams({
      recordId: component.get("v.selectedStepId"),
      userRole: component.get("v.roleName"),
      oppId: component.get("v.recordId"),
      comments: component.get("v.comments"),
      opp: opp,
      approvalName: component.get("v.approvalType")
    });

    console.log("--params--");
    console.log({
      recordId: component.get("v.selectedStepId"),
      userRole: component.get("v.roleName"),
      oppId: component.get("v.recordId"),
      comments: component.get("v.comments"),
      opp: opp,
      approvalName: component.get("v.approvalType")
    });

    //console.log(JSON.parse(JSON.stringify(action)));

    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        console.log("success");
        // display success message
        component.set("v.respMessage", "You have approved the deal.");
      } else {
        console.log(response.getError());
        // display error message
        let errorMessage = '';
        var errors = response.getError();
        if(errors) {
          if(errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
          }
        }
        component.set(
          "v.respMessage",
          "There has been an error. " +
            errorMessage +
            " Please contact your administrator with this error message."
        );
      }
      component.set("v.modalHeader", "Result");
      helper.toggleHide(component, "inputText");
      helper.toggleHide(component, "responseMessage");
      $A.util.addClass(component.find("approveButton"), "slds-hide");
      $A.util.removeClass(component.find("okButton"), "slds-hide");
    });
    $A.enqueueAction(action);
  },

  reject: function (component, event, helper) {
    let action = component.get("c.rejectDeal");
    action.setParams({
      recordId: component.get("v.selectedStepId"),
      oppId: component.get("v.recordId"),
      comments: component.get("v.comments"),
      userRole: component.get("v.roleName")
    });
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        console.log("success");
        // display success message
        component.set("v.respMessage", "You have rejected the deal.");
      } else {
        console.log(response.getError());
        // display error message
        let errorMessage = '';
        var errors = response.getError();
        if(errors) {
          if(errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
          }
        }

        component.set(
          "v.respMessage",
          "There has been an error. " +
            errorMessage +
            " Please contact your administrator with this error message."
        );
      }
      component.set("v.modalHeader", "Result");
      helper.toggleHide(component, "inputText");
      helper.toggleHide(component, "responseMessage");
      $A.util.addClass(component.find("rejectButton"), "slds-hide");
      $A.util.removeClass(component.find("okButton"), "slds-hide");
    });
    $A.enqueueAction(action);
  },

  redirect: function (component, event, helper) {
    component.set("v.selectedStepId", null);
    component.set("v.approvalType", null);

    component.set("v.showApproval", false);

    $A.get("e.force:refreshView").fire();
  },

  toggleGLC: function (component, event, helper) {
    component.set("v.selectedProcessId", event.getSource().get("v.name"));
    component.set("v.glcModalOpen", !component.get("v.glcModalOpen"));
  },
  glcApproval: function (component, event, helper) {
    $A.util.toggleClass(component.find("glcSpinner"), "slds-hide");
    component.find("glcApprovalButton").set("v.disabled", true);

    let comments = component.find("glcComments").get("v.value");
    let action = component.get("c.submitGLCApproval");
    action.setParams({
      recordId: component.get("v.selectedProcessId"),
      oppId: component.get("v.recordId"),
      comments: comments,
      userRole: component.get("v.roleName")
    });
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        // console.log("success");
        // // display success message
        // component.set(
        //   "v.response",
        //   "You have submitted the deal for GLC approval."
        // );
        $A.util.toggleClass(component.find("glcSpinner"), "slds-hide");
        component.find("glcApprovalButton").set("v.disabled", false);
        //window.location.href = "/lightning/n/Pricing_Reviews_In_Progress";
        component.set("v.glcModalOpen", false);
        helper.init(component, event, helper);
      } else {
        console.log(response.getError());
        let errorMessage = '';
        var errors = response.getError();
        if(errors) {
          if(errors[0] && errors[0].message) {
            errorMessage = errors[0].message;
          }
        }
        // display error message
        component.set(
          "v.response",
          "There has been an error. " +
            errorMessage +
            " Please contact your administrator with this error message."
        );

        $A.util.toggleClass(component.find("glcSpinner"), "slds-hide");
        component.find("glcApprovalButton").set("v.disabled", false);
      }
      // helper.toggleHide(component, "inputText");
      // helper.toggleHide(component, "responseMessage");
      // $A.util.addClass(component.find("approveButton"), "slds-hide");
      // $A.util.removeClass(component.find("okButton"), "slds-hide");
    });
    $A.enqueueAction(action);
  }
});