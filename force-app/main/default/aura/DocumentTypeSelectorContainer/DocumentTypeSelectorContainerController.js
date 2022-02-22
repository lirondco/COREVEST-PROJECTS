({
  closeModal: function(component, event, helper) {
    component.set("v.modalOpen", false);
    $A.get("e.force:closeQuickAction").fire();
  },

  save: function(component, event, helper) {
    console.log("save");

    // let sObjectName = component.get("v.sObjectName");
    // if (sObjectName === "Deal_Document__c") {
    //   helper.saveSingle(component);
    // }
    //else if (sObjectName === "Opportunity") {
    helper.saveBulk(component);
    //}
  },

  init: function(component, event, helper) {
    let sobjectType = component.get("v.sObjectName");

    if (sobjectType == "Deal_Document__c") {
      let recordIds = [component.get("v.recordId")];
      component.set("v.recordIds", recordIds);

      //sobjectType =
    }

    if (sobjectType === "Opportunity") {
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
          console.log("picklistValues", picklistValues);
          component.set("v.propertyOptions", picklistValues);
        } else if (state === "ERROR") {
          console.log("error");
        }
      });

      $A.enqueueAction(action);
    }
  },

  propertyIdChange: function(component, event, helper) {
    console.log(component.get("v.propertyId"));

    var select = event.getSource();

    console.log(select.get("v.value"));

    // component.set("v.propertyId", select.get("v.value"));
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