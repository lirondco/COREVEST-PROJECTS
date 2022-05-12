({
  init: function (component, event, helper) {
    //   	var recordId = location.hash.split('#!')[1].split('?')[0];
    //   	console.log(recordId);
    // component.set('v.recordId', recordId);
    // console.log(component.get('v.recordId'));
    // var url = location.hash;
    // if(!$A.util.isEmpty(url)){
    //     var recordId = location.hash.split('#!')[1].split('?')[0];
    //     console.log(recordId);
    //     component.set('v.recordId', recordId);
    // }

    var queryString = location.search;

    if (!$A.util.isEmpty(queryString)) {
      var query = {};
      var pairs = (queryString[0] === "?"
        ? queryString.substr(1)
        : queryString
      ).split("&");
      for (var i = 0; i < pairs.length; i++) {
        var pair = pairs[i].split("=");
        query[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || "");
      }

      console.log(query);

      component.set("v.recordId", query.id);
    }

    var action = component.get("c.getRecordTypeName");
    action.setParams({
      i: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        component.set("v.recordTypeName", response.getReturnValue());
        console.log(response.getReturnValue());
        console.log(component.get("v.recordTypeName"));

        var fields = [];
        var columns = component.find("dataTable").get("v.columns");
        for (var i = 0; i < columns.length; i++) {
          fields.push(columns[i].get("v.name"));
        }

        component.set("v.fieldList", fields);
        //console.log(component.get('v.fieldList'));
        helper.queryRecordsList(component);
      } else if (state === "ERROR") {
        console.log("error");
      }
    });

    var action1 = component.get("c.getUser");
    action1.setStorable();
    action1.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        //console.log(JSON.parse( response.getReturnValue() ));
        component.set("v.user", JSON.parse(response.getReturnValue()));
        var user = JSON.parse(response.getReturnValue());
        console.log('user::::', user);
        //var user = component.get('v.user');

        component.set("v.whereClause", "Property__c != null");

        $A.enqueueAction(action);
      } else {
        console.log("error");
        console.log(response);
      }
    });
    $A.enqueueAction(action1);
  },

  handleReviewEvent: function (component, event, helper) {
    console.log("event in parent");
    helper.showSpinner(component);
    const docId = event.getParam("documentId");
    const rec = {
      Id: docId,
      Reviewed__c: true,
      Reviewed_By__c: component.get("v.user").id,
      Reviewed_On__c: new Date().toISOString(),
      Reviewed_By_Contact__c: component.get("v.user").contactId,
    };
    const action = component.get("c.upsertRecords");
    console.log(rec);
    action.setParams({
      records: [rec]
    });
    action.setCallback(this, function (response) {
      const state = response.getState();
      if (state === "SUCCESS") {
        helper.hideSpinner(component);
        helper.queryRecordsList(component);
      }
      else if(state === "ERROR"){
        console.log(response.getError());

      }
    });
    $A.enqueueAction(action);
  },

  handleSortChangeEvent: function (component, event, helper) {
    var tableCmp = component.find("dataTable");

    component.set("v.pageNumber", 1);
    console.log("sort");

    component.set("v.sortColumnName", event.getParam("columnName"));
    component.set("v.sortDir", event.getParam("sortDirection"));

    tableCmp.set("v.sortColumnName", event.getParam("columnName"));
    tableCmp.set("v.sortDirection", event.getParam("sortDirection"));
    helper.queryRecordsList(component);
    console.log("query");
  },

  refresh: function (component, event, helper) {
    helper.queryRecordsList(component);
  },

  nextPage: function (component, event, helper) {
    var records = component.get("v.records");
    var currentPage = component.get("v.currentPage") + 1;
    var pageSize = component.get("v.pageSize");

    var table = component.find("dataTable");

    var recordsToDisplay = records.slice(
      (currentPage - 1) * pageSize,
      currentPage * pageSize
    );

    table.set("v.rows", recordsToDisplay);

    component.set("v.currentPage", currentPage);
  },

  prevPage: function (component, event, helper) {
    var records = component.get("v.records");
    var currentPage = component.get("v.currentPage") - 1;
    var pageSize = component.get("v.pageSize");

    var table = component.find("dataTable");
    var recordsToDisplay = records.slice(
      (currentPage - 1) * pageSize,
      currentPage * pageSize
    );
    table.set("v.rows", recordsToDisplay);
    component.set("v.currentPage", currentPage);
  },

  lastPage: function (component, event, helper) {
    var records = component.get("v.records");
    var currentPage = component.get("v.maxPage");
    var pageSize = component.get("v.pageSize");

    var table = component.find("dataTable");
    var recordsToDisplay = records.slice(
      (currentPage - 1) * pageSize,
      currentPage * pageSize
    );
    table.set("v.rows", recordsToDisplay);
    component.set("v.currentPage", currentPage);
  },

  firstPage: function (component, event, helper) {
    var records = component.get("v.records");
    var currentPage = 1;
    var pageSize = component.get("v.pageSize");

    var table = component.find("dataTable");
    var recordsToDisplay = records.slice(
      (currentPage - 1) * pageSize,
      currentPage * pageSize
    );
    table.set("v.rows", recordsToDisplay);
    component.set("v.currentPage", currentPage);
  },

  handleUpdateFolder: function (component, event, helper) {
    console.log('UPDATE FOLDER CLICKED');
    const table = component.find("dataTable");
    let checked = [];
    table.getChecked(function(resp){
      checked = resp;
    });

    if(checked == null || checked.length == 0){ 
      let toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
          "title": "Error",
          "message": "Please select at least one document first.",
          "type": "error"
      });
      toastEvent.fire();  
    } else {
      const rows = table.get('v.rows');
      const ids = [];
      for(let i = 0; i < checked.length; i++){
        ids.push(rows[checked[i]].Id);
      }
      component.set("v.selectedIds", ids);
      component.set("v.modalOpen", true);  
    }

  }
});