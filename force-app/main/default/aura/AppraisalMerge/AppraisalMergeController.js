({
  init: function (component, event, helper) {
    console.log("init");
    helper.checkPermission(component);
    // helper.checkProfile(component);
    let action = component.get("c.initMergeScreen");

    action.setParams({
      recordId: component.get("v.recordId")
    });

    action.setCallback(this, (response) => {
      let state = response.getState();

      if (state === "SUCCESS") {
        let merges = response.getReturnValue();
        console.log("--merges--");
        console.log(merges);

        let wrappers = [];

        let deletedIds = [];

        let bulkDelete = false;

        for (let merge of merges) {
          merge[0].checked = true;
          wrappers.push({
            merges: merge,
            checked: false
          });
        }

        //console.log(wrappers);
        component.set("v.wrappers", wrappers);
        component.set("v.deletedIds", deletedIds);
        component.set("v.bulkDelete", bulkDelete);

        //$A.util.toggleClass(component.find("spinner"), "slds-hide");
        $A.util.addClass(component.find("spinner"), "slds-hide");
      } else if (state === "ERROR") {
        console.log("--error--");

        console.log(response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  merge: function (component, event, helper) {
    $A.util.toggleClass(component.find("spinner"), "slds-hide");
    component.find("merge").set("v.disabled", true);
    let properties = [];
    let wrappers = component.get("v.wrappers").filter((merge) => merge.checked);

    //console.log(wrappers);

    wrappers.forEach((wrapper) => {
      let propertyId = wrapper.merges[0].propertyId;
      // console.log(propertyId);

      // console.log(component.find(propertyId));

      wrapper.merges.forEach((merge) => {
        console.log(merge.checked);

        if (merge.checked) {
          let property = { sobjectType: "Property__c", Id: merge.propertyId };
          merge.fields.forEach((field) => {
            if ($A.util.isUndefinedOrNull(field.appraisalValue)) {
              // if (
              //   merge.productOrdered != "ClearVal Plus (Interior PCI)" &&
              //   merge.productOrdered != "ClearVal Plus (Exterior PCI)" &&
              //   merge.productOrdered != "Internal In-House Appraisal"
              // ) {
              //   property[field.propertyAPIFieldName] = null;
              // }
            } else if (field.propertyFieldType != field.appraisalFieldType) {
              if (field.appraisalFieldType == "BOOLEAN") {
                property[field.propertyAPIFieldName] = field.appraisalValue
                  ? "Yes"
                  : "No";

                property[field.propertyAPIFieldName];
              } else if (
                field.appraisalFieldType == "DOUBLE" &&
                field.propertyFieldType == "STRING"
              ) {
                property[field.propertyAPIFieldName] =
                  field.appraisalValue + "";
              } else {
                property[field.propertyAPIFieldName] = field.appraisalValue;
              }
            } else {
              property[field.propertyAPIFieldName] = field.appraisalValue;

              if (field.propertyAPIFieldName == "Appraised_Value_Amount__c") {
                property["BPO_Appraisal_Value__c"] = field.appraisalValue;
              }
            }
          });
          property.Appraisal_Uploaded__c = true;

          if (property.Appraisal_Form__c == "FNM1004D") {
            var mergeProperty = {
              sobjectType: "Property__c",
              Id: property.Id,
              Appraisal_Uploaded__c: true,
              BPO_Appraisal_Date__c: property.BPO_Appraisal_Date__c
              //Appraised_Value_Amount__c: property.Appraised_Value_Amount__c
            };

            property = mergeProperty;
          }

          properties.push(property);
        }
      });
    });

    console.log(properties);

    if (properties.length > 0) {
      // if (false) {
      component.find("util").upsert(
        properties,
        $A.getCallback((result) => {
          $A.enqueueAction(component.get("c.init"));
          component.find("merge").set("v.disabled", false);
        }),
        $A.getCallback((error) => {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Error",
            message: error[0].message,
            duration: " 5000",
            type: "error",
            mode: "sticky"
          });
          toastEvent.fire();
          component.find("merge").set("v.disabled", false);
          $A.util.toggleClass(component.find("spinner"), "slds-hide");
        })
      );
    } else {
      $A.util.toggleClass(component.find("spinner"), "slds-hide");
      component.find("merge").set("v.disabled", false);
    }

    // let action = component.get('c.mergeAppraisals');

    // action.setParams({
    // 	merges: merges
    // })

    // action.setCallback(this, function(response){
    // 	let state = response.getState();

    // 	if(state === 'SUCCESS'){
    // 		console.log(JSON.parse(response.getReturnValue()));
    // 	}else if(state === 'ERROR'){
    // 		console.log(response.getError());
    // 	}
    // });

    // if(merges.length > 0){
    // 	$A.enqueueAction(action);
    // }
  },

  radioChanged: function (component, event, helper) {
    console.log(event.getSource());
    let radio = event.getSource();
    let propertyId = radio.get("v.name");
    let appraisalId = radio.get("v.title");

    console.log(propertyId);
    console.log(appraisalId);

    let wrappers = component.get("v.wrappers");
    wrappers.forEach((wrapper) => {
      if (wrapper.merges[0].propertyId == propertyId) {
        wrapper.merges.forEach((merge) => {
          if (merge.appraisalId == appraisalId) {
            merge.checked = true;
          } else {
            merge.checked = false;
          }
        });
      }
    });

    component.set("v.wrappers", wrappers);
  },

  checkAll: function (component, event, helper) {
    console.log("checked");
    let checkbox = event.getSource();
    let checked = checkbox.get("v.checked");

    let wrappers = component.get("v.wrappers");
    wrappers.forEach((wrapper) => {
      wrapper.checked = checked;
    });

    component.set("v.wrappers", wrappers);
  },
  export: function (component, event, helper) {
    let recordId = component.get("v.recordId");
    //let reportUrl =

    let wrappers = component.get("v.wrappers");
    console.log(wrappers);

    let appraisals = [];
    wrappers.forEach((wrapper) => {
      let forms = new Set();
      wrapper.merges.forEach((merge) => {
        let formId = merge.formId ? merge.formId : "";
        let appraisal = {
          Id: merge.appraisalId,
          sobjectType: "Appraisal__c",
          Include_In_Report__c: false
        };
        if (!forms.has(formId)) {
          appraisal.Include_In_Report__c = true;
          forms.add(formId);
        }

        appraisals.push(appraisal);
      });
    });

    console.log(appraisals);

    if (!$A.util.isEmpty(appraisals)) {
      component.find("util").upsert(appraisals, (response) => {
        let reportUrl =
          "/lightning/r/Report/00O0a000005KMpYEAW/view?fv0=" + recordId;
        window.open(reportUrl);
      });
    }
  },

  toggleBulkDelete: function (component, event, helper) {
    let isToggled = component.find("togglebulk").get("v.checked");
    let deletedIds = component.get("v.deletedIds");
    if (deletedIds.length > 0 && !isToggled) {
      let objectsToDelete = deletedIds.map(id => ({
        sobjectType: "Appraisal__c",
        Id: id
      }));
      component
        .find("util")
        .delete(
          objectsToDelete,
          (response) => {
            console.log("delete success");
            $A.enqueueAction(component.get("c.init"));
          }
        );
    }
    component.set("v.bulkDelete", isToggled);
  },

  openDeleteModal: function (component, event, helper) {
    console.log("delete");
    console.log(event.getSource().get("v.title"));
    let isBulkDeleteToggled = component.get("v.bulkDelete");

    if (isBulkDeleteToggled) {
      let deletedIds = component.get("v.deletedIds");
      let appraisalId = event.getSource().get("v.title");
      let wrappers = component.get("v.wrappers");
      wrappers.forEach((wrapper, idx) => {
        wrapper.merges = wrapper.merges.filter(
          (merge) => merge.appraisalId !== appraisalId
        );
        if (wrapper.merges.length < 1) {
          wrappers.splice(idx, 1);
        }
      });

      deletedIds.push(appraisalId);
      component.set("v.wrappers", wrappers);
      component.set("v.deletedIds", deletedIds);
    } else {
      var modal = component.find("modal");
      var backdrop = component.find("modal-backdrop");
      $A.util.addClass(modal, "slds-fade-in-open");
      $A.util.removeClass(modal, "slds-modal__close");
      $A.util.addClass(backdrop, "slds-backdrop--open");

      component
        .find("deleteButton")
        .set("v.title", event.getSource().get("v.title"));
    }
  },

  closeDeleteModal: function (component, event, helper) {
    var modal = component.find("modal");
    var backdrop = component.find("modal-backdrop");
    $A.util.removeClass(modal, "slds-fade-in-open");
    $A.util.addClass(modal, "slds-modal__close");
    $A.util.removeClass(backdrop, "slds-backdrop--open");
  },

  delete: function (component, event, helper) {
    console.log("delete");
    console.log(event.getSource().get("v.title"));
    const appraisalId = event.getSource().get("v.title");
    $A.util.removeClass(component.find("spinner"), "slds-hide");
    var modal = component.find("modal");
    var backdrop = component.find("modal-backdrop");
    $A.util.removeClass(modal, "slds-fade-in-open");
    $A.util.addClass(modal, "slds-modal__close");
    $A.util.removeClass(backdrop, "slds-backdrop--open");
    component
      .find("util")
      .delete(
        [{ sobjectType: "Appraisal__c", Id: appraisalId }],
        (response) => {
          console.log("delete success");
          $A.enqueueAction(component.get("c.init"));
        }
      );
  }
});