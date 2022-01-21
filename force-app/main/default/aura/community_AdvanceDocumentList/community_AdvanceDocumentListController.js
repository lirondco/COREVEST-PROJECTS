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

          let whereClauseString = component.get("v.whereClause");
          
          if(!$A.util.isEmpty(whereClauseString)){ 
            whereClauseString += ' AND Property__c = null';
          } else {
            whereClauseString = 'Property__c = null';
          }

          component.set("v.whereClause", whereClauseString);
  
          //fields.push('Vendor_Type_Access__c');
  
          component.set("v.fieldList", fields);
          console.log(component.get("v.fieldList"));
          console.log("entering query records list helper");
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
          console.log("GET USER END, STARTING NEXT ACTION");
          $A.enqueueAction(action);
        } else {
          console.log("error");
          console.log(response.getError()[0].message);
        }
      });
      $A.enqueueAction(action1);
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
  
    modalOpen: function (component, event, helper) {
      component.set("v.modalOpen", true);
    },
  
    modalClose: function (component, event, helper) {
      component.set("v.modalOpen", false);
    }
  });