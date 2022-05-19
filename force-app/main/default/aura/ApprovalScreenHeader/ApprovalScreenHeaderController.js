({
  init: function (component, event, helper) {
    console.log("Approval Screen Header init");
    let action = component.get("c.getApprovalDetails");
    action.setParams({ recordId: component.get("v.recordId") });
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        let returnVal = JSON.parse(response.getReturnValue());
        console.log("this is the returnVal for ApprovalScreenHeader");
        console.log(returnVal);
        component.set("v.status", returnVal.Status);
        component.set("v.submitter", returnVal.Submitter);
        component.set("v.dateSubmitted", returnVal.DateSubmitted);
        component.set("v.oppId", returnVal.oppId);
        component.set("v.userRole", returnVal.Role);

        // let approvalType = returnVal.ApprovalName.includes('Pricing') ? 'pricingReview' : 'submitUw';
        component.set("v.approvalName", returnVal.ApprovalName);
        if(returnVal.ApprovalName.split("_").some(v => v=== "IC")) {
          component.set("v.isIcApproval", true);
        }
        if (returnVal.Verified === "true") {
          helper.toggleHide(component, "approval-buttons");
        }
      } else {
        console.error(response.getError());
      }
    });
    $A.enqueueAction(action);
  },

  openApproval: function (component, event, helper) {
    component.set("v.modalTitle", "Approve Deal");
    $A.util.removeClass(component.find("approveButton"), "slds-hide");
    $A.util.removeClass(component.find("recordFields"), "slds-hide");
    document.querySelector(".slds-modal").classList.add("slds-fade-in-open");
    document
      .querySelector(".slds-backdrop")
      .classList.add("slds-backdrop_open");
  },

  openRejection: function (component, event, helper) {
    component.set("v.modalTitle", "Reject Deal");
    $A.util.removeClass(component.find("rejectButton"), "slds-hide");
    document.querySelector(".slds-modal").classList.add("slds-fade-in-open");
    document
      .querySelector(".slds-backdrop")
      .classList.add("slds-backdrop_open");
  },

  closeModal: function (component, event, helper) {
    $A.util.addClass(component.find("approveButton"), "slds-hide");
    $A.util.addClass(component.find("rejectButton"), "slds-hide");
    $A.util.addClass(component.find("recordFields"), "slds-hide");
    document.querySelector(".slds-modal").classList.remove("slds-fade-in-open");
    document
      .querySelector(".slds-backdrop")
      .classList.remove("slds-backdrop_open");
  },

  approve: function (component, event, helper) {
    let opp = { sobjectType: "Opportunity", Id: component.get("v.oppId") };
    if (!$A.util.isUndefinedOrNull(component.find("fields"))) {
      let fields = component.find("fields");
      if (!$A.util.isArray(fields)) {
        fields = [fields];
      }
      fields.forEach((field) => {
        opp[field.get("v.fieldName")] = field.get("v.value");
      });
    }

    //console.log(opp);

    let action = component.get("c.approveDeal");
    action.setParams({
      recordId: component.get("v.recordId"),
      userRole: component.get("v.userRole"),
      oppId: component.get("v.oppId"),
      comments: component.get("v.comments"),
      opp: opp,
      approvalName: component.get("v.approvalName")
    });

    console.log("---params---");
    console.log({
      recordId: component.get("v.recordId"),
      userRole: component.get("v.userRole"),
      oppId: component.get("v.oppId"),
      comments: component.get("v.comments"),
      opp: opp,
      approvalName: component.get("v.approvalName")
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        console.log("success");
        // display success message
        component.set("v.response", "You have approved the deal.");
      } else {
        console.error(JSON.stringify(response.getError()));
        // display error message
        let errorMessage = response.getError()[0];
        if(errorMessage.pageErrors) {
          errorMessage = errorMessage.pageErrors[0]
        };
        component.set(
          "v.response",
          "There has been an error. " +
            errorMessage.message +
            " Please contact your administrator with this error message."
        );
      }
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
      recordId: component.get("v.recordId"),
      oppId: component.get("v.oppId"),
      comments: component.get("v.comments"),
      userRole: component.get("v.userRole")
    });
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        console.log("success");
        // display success message
        component.set("v.response", "You have rejected the deal.");
      } else {
        console.error(JSON.stringify(response.getError()));
        // display error message
        let errorMessage = response.getError()[0];
        if(errorMessage.pageErrors) {
          errorMessage = errorMessage.pageErrors[0]
        };
        component.set(
          "v.response",
          "There has been an error. " +
            errorMessage.message +
            " Please contact your administrator with this error message."
        );
      }
      helper.toggleHide(component, "inputText");
      helper.toggleHide(component, "responseMessage");
      $A.util.addClass(component.find("rejectButton"), "slds-hide");
      $A.util.removeClass(component.find("okButton"), "slds-hide");
    });
    $A.enqueueAction(action);
  },

  toggleGLC: function (component, event, helper) {
    component.set("v.glcModalOpen", !component.get("v.glcModalOpen"));
  },

  // closeGLC : function(component)

  glcApproval: function (component, event, helper) {
    //

    $A.util.toggleClass(component.find("glcSpinner"), "slds-hide");
    component.find("glcApprovalButton").set("v.disabled", true);

    let comments = component.find("glcComments").get("v.value");
    let action = component.get("c.submitGLCApproval");
    action.setParams({
      recordId: component.get("v.recordId"),
      oppId: component.get("v.oppId"),
      comments: comments
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
        window.location.href = "/lightning/n/Pricing_Reviews_In_Progress";
      } else {
        console.error(JSON.stringify(response.getError()));
        let errorMessage = response.getError()[0];
        if(errorMessage.pageErrors) {
          errorMessage = errorMessage.pageErrors[0]
        };
        // display error message
        component.set(
          "v.response",
          "There has been an error. " +
            errorMessage.message +
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
  },

  redirect: function (component, event, helper) {
    //window.location.href = '/one/one.app#/sObject/'+ component.get('v.oppId') +'/view';

    let approvalName = component.get("v.approvalName");

    if (approvalName.includes("Pricing")) {
      window.location.href = "/lightning/n/Pricing_Reviews_In_Progress";
    } else {
      window.location.href =
        "/lightning/r/Opportunity/" + component.get("v.oppId") + "/view";
    }
  }

  
});