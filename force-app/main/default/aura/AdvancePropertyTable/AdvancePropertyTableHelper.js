({
  queryRecord: function (component) {
    var action = component.get("c.getRecord");
    action.setParams({ i: component.get("v.recordId") });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        var record = JSON.parse(response.getReturnValue());
        if ($A.util.isEmpty(record["Advance_Fee_Adjustment__c"])) {
          record["Advance_Fee_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["Origination_Fee_Adjustment__c"])) {
          record["Origination_Fee_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["Daily_Interest_Rate_Adjustment__c"])) {
          record["Daily_Interest_Rate_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["BPO_Appraisal_Fee_Adjustment__c"])) {
          record["BPO_Appraisal_Fee_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["Doc_Prep_Fee_Adjustment__c"])) {
          record["Doc_Prep_Fee_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["BlackSquare_Fee_Adjustment__c"])) {
          record["BlackSquare_Fee_Adjustment__c"] = 0;
        }
        if ($A.util.isEmpty(record["Inspection_Fee_Adjustment__c"])) {
          record["Inspection_Fee_Adjustment__c"] = 0;
        }

        delete record["attributes"];

        record["sobjectType"] = "Advance__c";
        console.log(record);
        component.set("v.record", JSON.parse(JSON.stringify(record)));
        if(!!record["Broker_Fee_Paid_By_Whom__c"] && record["Broker_Fee_Paid_By_Whom__c"].toLowerCase() == "corevest") {
          component.set("v.brokerFeeLabel", "Broker Fee Paid by CoreVest");
        } else if (!!record["Broker_Fee_Paid_By_Whom__c"] && record["Broker_Fee_Paid_By_Whom__c"].toLowerCase() == "escrow") {
          component.set("v.brokerFeeLabel", "Broker Fee Paid on HUD");
        } else {
          component.set("v.brokerFeeLabel", "Broker Fee");
        }
      } else if (state === "ERROR") {
      }
    });

    $A.enqueueAction(action);
  },

  queryPropertyAdvances: function (component) {
    var fieldList = [
      "Property__r.APN__c",
      "Property__r.Name",
      "Property__r.Yardi_Id__c",
      "Purchase_Price__c",
      "Property__r.Status__c",
      "Appraisal_Due_Date__c",
      "Renovation_Budget__c",
      "BPO_Appraisal_Value__c",
      "BlackSquare_Fee__c",
      "Total_Cost_Basis__c",
      "After_Repair_Value__c",
      "Total_LTC_percent__c",
      "Total_LTC_dollar__c",
      "As_Is_LTV_Percent__c",
      "As_Is_LTV_currency__c",
      "ARV_LTV_percent__c",
      "ARV_LTV_currency__c",
      "Initial_LTC_percent__c",
      "Initial_LTC_dollar__c",
      "Renovation_Reserve__c",
      "Max_LTC__c",
      "Max_LTV__c",
      "Approved_Advance_Amount_Calc__c",
      "Advance_Fee__c",
      "BPO_Appraisal_Fee__c",
      "Initial_Disbursement__c",
      "Doc_Prep_Fee__c",
      "Net_Funding__c",
      "Max_LTV_Dollar__c",
      "Max_LTC_Dollar__c",
      "Broker_Advance_Fee__c",
      "Perc_of_Rehab_Budget__c",
      "Origination_Fee__c",
      "Daily_Interest_Rate_Total__c",
      "Inspection_Fee__c",
      "Escrow_Agent__r.Name",
      "Title_Company__r.Name",
      "Wire__r.Name",
      "Wire__r.Wire_Number__c",
      "Wire__r.Origination_Fee__c",
      "Wire__r.Daily_Interest_Rate__c",
      "Wire__r.BlackSquare_Fee__c",
      "Approved_Renovation_Holdback__c",
      "Approved_Advance_Amount_Max__c",
      "Property__r.Title_Review_Company__c"
    ];

    var action = component.get("c.getRecordList");
    action.setParams({
      parentId: component.get("v.recordId"),
      parentFieldName: "Advance__c",
      sobjectType: "Property_Advance__c",
      fields: fieldList,
      sortCol: "Name",
      sortDir: "Desc",
      whereClause: "",
      orderBy: "Wire__r.Wire_Number__c ASC"
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log(response.getReturnValue());
        component.set("v.propertyAdvances", response.getReturnValue());
        component.find("refresh").set("v.disabled", false);
      } else if (state === "ERROR") {
        console.log(response.getError());
        console.log("error query prop adv");
      }
    });

    $A.enqueueAction(action);
  },

  queryWires: function (component) {
    var fieldList = [
      "Approved_Advance_Amount__c",
      "Advance_Fee__c",
      "BPO_Appraisal_Fee__c",
      "Doc_Prep_Fee__c",
      "Net_Funding__c",
      "Escrow_Agent__r.Name",
      "Wire_Number__c",
      "Advance_Fee_Adjustment__c",
      "BPO_Appraisal_Fee_Adjustment__c",
      "Doc_Prep_Fee_Adjustment__c",
      "Inspection_Fee_Adjustment__c",
      "Origination_Fee_Adjustment__c",
      "Origination_Fee__c",
      "Daily_Interest_Rate__c",
      "Daily_Interest_Rate_Adjustment__c",
      "BlackSquare_Fee__c",
      "BlackSquare_Fee_Adjustment__c"
    ];

    var action = component.get("c.getRecordList");
    action.setParams({
      parentId: component.get("v.recordId"),
      parentFieldName: "Advance__c",
      sobjectType: "Wire__c",
      fields: fieldList,
      sortCol: "Name",
      sortDir: "Desc",
      whereClause: "",
      orderBy: "Wire_Number__c ASC"
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var data = response.getReturnValue();
        data.forEach((el) => {
          if ($A.util.isEmpty(el.BPO_Appraisal_Fee_Adjustment__c)) {
            el.BPO_Appraisal_Fee_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.Doc_Prep_Fee_Adjustment__c)) {
            el.Doc_Prep_Fee_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.Advance_Fee_Adjustment__c)) {
            el.Advance_Fee_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.Origination_Fee_Adjustment__c)) {
            el.Origination_Fee_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.Daily_Interest_Rate_Adjustment__c)) {
            el.Daily_Interest_Rate_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.BlackSquare_Fee_Adjustment__c)) {
            el.BlackSquare_Fee_Adjustment__c = 0;
          }
          if ($A.util.isEmpty(el.Inspection_Fee_Adjustment__c)) {
            el.Inspection_Fee_Adjustment__c = 0;
          }
        });
        component.set("v.wires", response.getReturnValue());
      } else if (state === "ERROR") {
        console.log("error query prop adv");
      }
    });

    $A.enqueueAction(action);
  },

  compilePermissions: function (component, helper, records) {
    let fields = ["Name"];

    component.find("util").getPermissions("Advance__c", fields, (response) => {
      component.set("v.permissionsMap", response);
    });
  },

  compilePropertyPermissions: function (component, helper, records) {
    let fields = ["Status__c"];

    component.find("util").getPermissions("Property__c", fields, (response) => {
      console.log('Prop permissions', JSON.stringify(response));

      component.set("v.propertyPermissionsMap", response);
    });
  },

  queryDealNotes: function (component) {
    const recordId = component.get("v.recordId");
    const queryString = `SELECT Id, Deal__r.Deposit_Notes__c FROM Advance__c WHERE Id = '${recordId}'`;

    component.find("util").query(queryString, (data) => {
      // console.log("--deposit notes--", data);
      component.set("v.depositNotes", data[0].Deal__r.Deposit_Notes__c);
    });
  }
});