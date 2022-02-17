({
  init: function (component, event, helper) {
    helper.queryRecord(component);
    helper.queryPropertyAdvances(component);
    helper.queryWires(component);
    helper.compilePermissions(component);
    helper.queryDealNotes(component);
    helper.compilePropertyPermissions(component);
  },

  calculateSubTotals: function (component, event, helper) {
    let inspectionFeeSubtotal = 0;

    component.get("v.propertyAdvances").forEach((pAdv) => {
      inspectionFeeSubtotal += !$A.util.isUndefinedOrNull(
        parseFloat(pAdv.Inspection_Fee__c)
      )
        ? pAdv.Inspection_Fee__c
        : 0;
    });

    let record = component.get("v.record");
    record.Inspection_Fee_Subtotal__c = inspectionFeeSubtotal;
    record.Net_Funding_Subtotal__c =
      record.Approved_Advance_Amount_Total__c -
      (record.Origination_Fee_Subtotal__c +
        record.Advance_Fee_Subtotal__c +
        record.BPO_Appraisal_Fee_Subtotal__c +
        record.Doc_Prep_Fee_Subtotal__c +
        record.BlackSquare_Fee_Total__c +
        record.Daily_Interest_Rate_Subtotal__c +
        record.Inspection_Fee_Subtotal__c);

    component.set("v.record", record);
  },

  saveRecord: function (component, event, helper) {
    $A.util.toggleClass(component.find("spinner"), "slds-hide");
    component.find("save").set("v.disabled", true);
    console.log(component.get("v.record"));
    var record = component.get("v.record");

    var upsertRecord = {
      Advance_Fee_Adjustment__c: record["Advance_Fee_Adjustment__c"],
      Origination_Fee_Adjustment__c: record["Origination_Fee_Adjustment__c"],
      Daily_Interest_Rate_Adjustment__c:
        record["Daily_Interest_Rate_Adjustment__c"],
      BPO_Appraisal_Fee_Adjustment__c:
        record["BPO_Appraisal_Fee_Adjustment__c"],
      Doc_Prep_Fee_Adjustment__c: record["Doc_Prep_Fee_Adjustment__c"],
      sobjectType: "Advance__c",
      BlackSquare_Fee_Adjustment__c: record["BlackSquare_Fee_Adjustment__c"],
      Inspection_Fee_Adjustment__c: record["Inspection_Fee_Adjustment__c"],
      Id: record["Id"]
    };

    var action = component.get("c.upsertRecords");
    action.setParams({
      records: [upsertRecord].concat(component.get("v.propertyAdvances"))
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        //console.log('success');
        $A.util.toggleClass(component.find("spinner"), "slds-hide");
        helper.queryWires(component);
        $A.get("e.force:refreshView").fire();
        component.find("save").set("v.disabled", false);
        $A.get("e.force:showToast")
          .setParams({
            title: "Success!",
            message: "Advances saved",
            type: "success"
          })
          .fire();
      } else if (state === "ERROR") {
        $A.util.toggleClass(component.find("spinner"), "slds-hide");
        console.log("error");
        console.log(response.getError());
        $A.get("e.force:showToast")
          .setParams({
            title: "Error!",
            message: response.getError(),
            type: "error"
          })
          .fire();
        component.find("save").set("v.disabled", false);
      }
    });

    $A.enqueueAction(action);
  },

  handleClick: function (component, event, helper) {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      recordId: event.getSource().get("v.title")
    });
    navEvt.fire();
  },

  delete: function (component, event, helper) {
    console.log("delete clicked");

    var arr = component.find("checkbox") || [];

    if (!$A.util.isArray(arr)) {
      arr = [arr];
    }

    var records = [];
    arr.forEach(function (row) {
      if (row.get("v.value")) {
        records.push({
          Id: row.get("v.name")
        });
      }
    });

    var action = component.get("c.deleteRecords");
    action.setParams({
      records: records
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state == "SUCCESS") {
        console.log("success");
        $A.get("e.force:refreshView").fire();
      } else {
        console.log(response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  refresh: function (component, event, helper) {
    component.find("refresh").set("v.disabled", true);
    var records = component.get("v.propertyAdvances");

    var action = component.get("c.upsertRecords");

    action.setParams({
      records: records
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state == "SUCCESS") {
        //var data = response.getReturnValue();
        //component.set('v.propertyAdvances', records);
        $A.get("e.force:refreshView").fire();
      } else if (state == "ERROR") {
        console.log("error");
      }
    });

    $A.enqueueAction(action);
  }
});