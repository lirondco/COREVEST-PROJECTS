({
    compileFields: function (component) {
      var fields = [];
      var columns = component.find("dataTable").get("v.columns");
      for (var i = 0; i < columns.length; i++) {
        if(columns[i].get("v.name") == 'isReadable'){
          continue;
        }
        fields.push(columns[i].get("v.name"));
      }
  
      component.set("v.fieldList", fields);
    },
  
    showSpinner: function (component) {
      $A.util.removeClass(component.find("spinner"), "slds-hide");
    },
  
    hideSpinner: function (component) {
      $A.util.addClass(component.find("spinner"), "slds-hide");
    },
  
    navigateToRecord: function (recordId) {
      console.log("navigating to record: " + recordId);
  
      var event = $A.get("e.force:navigateToSObject");
  
      if (event) {
        event
          .setParams({
            recordId: recordId
          })
          .fire();
      } else if (
        typeof sforce !== "undefined" &&
        typeof sforce.one !== "undefined"
      ) {
        sforce.one.navigateToSObject(recordId);
      } else {
        window.location.href = "/" + recordId;
      }
    },
  
    /**
     * actionName = the apex controller method to call (e.g. 'c.myMethod' )
     * params = JSON object specifying action parameters (e.g. { 'x' : 42 } )
     * successCallback = function to call when action completes (e.g. function( response ) { ... } )
     * failureCallback = function to call when action fails (e.g. function( response ) { ... } )
     */
    callAction: function (
      component,
      actionName,
      params,
      successCallback,
      failureCallback
    ) {
      this.showSpinner(component);
  
      var action = component.get(actionName);
  
      if (params) {
        action.setParams(params);
      }
  
      action.setCallback(this, function (response) {
        this.hideSpinner(component);
  
        if (component.isValid() && response.getState() === "SUCCESS") {
          if (successCallback) {
            successCallback(response.getReturnValue());
          }
        } else {
          console.error(
            'Error calling action "' +
              actionName +
              '" with state: ' +
              response.getState()
          );
  
          if (failureCallback) {
            failureCallback(response.getError(), response.getState());
          } else {
            this.logActionErrors(component, response.getError());
          }
        }
      });
  
      $A.enqueueAction(action);
    },
  
    logActionErrors: function (component, errors) {
      if (errors) {
        for (var index in errors) {
          console.error("Error: " + errors[index].message);
        }
      } else {
        console.error("Unknown error");
      }
    },
    //  queryRecords : function(component){
    //     var tableCmp = component.find('dataTable');
    //     console.log(tableCmp.get('v.pageNumber'));
    //     console.log(tableCmp.get('v.pageSize'));
    //     console.log(component.get('v.whereClause'));
    //     tableCmp.toggleSpinner();
    //     this.callAction(
    //         component,
    //         'c.getRecords',
    //         {
    //             'parentId' : component.get('v.recordId'),
    //             'parentFieldName' : component.get('v.parentFieldName'),
    //             'sobjectType' : component.get('v.sobjectType'),
    //             'fields' : component.get('v.fieldList'),
    //             'page' : 1,
    //             'pageSize' : tableCmp.get('v.pageNumber')*tableCmp.get( 'v.pageSize' ),
    //             'sortCol' : tableCmp.get( 'v.sortColumnName' ),
    //             'sortDir' : tableCmp.get( 'v.sortDirection' ),
    //             'whereClause' : component.get('v.whereClause')
    //         },
    //         function( data ) {
  
    //             var tableCmp = component.find( 'dataTable' );
  
    //             tableCmp.set( 'v.rows', data  );
  
    //             tableCmp.toggleSpinner();
  
    //         }
    //     )
    // },
    queryRecords: function (component, helper) {
      var tableCmp = component.find("dataTable");
  
      //tableCmp.toggleSpinner();
	  var showAdvancesDocs = component.get("v.showAdvancesDocs");
      var whereClause = component.get("v.whereClause");
      if ($A.util.isEmpty(whereClause)) {
        whereClause = "Is_Deleted__c = false";
      } else {
        whereClause += " AND Is_Deleted__c = false";
      }
  
      $A.util.removeClass(component.find("spinner"), "slds-hide");
      this.callAction(
        component,
        "c.getRecordListPropAdva",
        {
          parentId: component.get("v.recordId"),
          parentFieldName: component.get("v.parentFieldName"),
          sobjectType: component.get("v.sobjectType"),
          fields: component.get("v.fieldList"),
          sortCol: tableCmp.get("v.sortColumnName"),
          sortDir: tableCmp.get("v.sortDirection"),
          whereClause: whereClause,
          orderBy: component.get("v.orderBy"),
          showAdvancesDocs:showAdvancesDocs
        },
        function (data) {
          //var records = JSON.parse(data);
          var records = data;
          component.set("v.records", data);
          //console.log(records);
          const recordIds = [];
          for (var i = 0; i < records.length; i++) {
            recordIds.push(records[i].Id);
          }
          component.set("v.recordIds", recordIds);
          helper.compileRecordReadAccess(component, helper);       //tableCmp.toggleSpinner();
        }
      );
    },

    compileRecordReadAccess: function (component, helper) {
      this.callAction(
        component,
        "c.generateReadAccessMap",
        {
          recordIds: component.get("v.recordIds"),
        },
        function(data) {
          component.set("v.recordSharingMap", data);
          const raMap = component.get("v.recordSharingMap");
          var tableCmp = component.find("dataTable");
          console.log('sharing map', raMap);
          var pageSize = component.get("v.pageSize");
          var currentPage = component.get("v.currentPage");
          const records = component.get("v.records");
          
          for(var i = 0; i < records.length; i++){
            records[i].isReadable = raMap[records[i].Id];
          }
          console.log("records updated", records);
          component.set("v.records", records);
  
          component.set("v.maxPage", Math.ceil(records.length / pageSize));
  
          var recordsToDisplay = records.slice(
            (currentPage - 1) * pageSize,
            currentPage * pageSize
          );
          console.log("RECORDS TO DISPLAY", recordsToDisplay);
  
          tableCmp.set("v.rows", recordsToDisplay);
          $A.util.addClass(component.find("spinner"), "slds-hide");
        }
      )
    },
  
    saveRecords: function (component, helper) {
      var table = component.find("dataTable");
  
      var rows = table.get("v.rows");
      table.toggleSpinner();
      helper.callAction(
        component,
        "c.upsertRecords",
        {
          records: rows
        },
  
        function (data) {
          table.toggleSpinner();
          component.set("v.editMode", !component.get("v.editMode"));
          helper.queryRecords(component, helper);
        }
      );
    },
  
    deleteRecords: function (component, helper, records) {
      var tableCmp = component.find("dataTable");
  
      tableCmp.toggleSpinner();
      helper.callAction(
        component,
        "c.deleteRecords",
        {
          records: records
        },
        function (data) {
          tableCmp.toggleSpinner();
          helper.userType(component);
        }
      );
    },
  
    compilePermissions: function (component) {
      let fields = ["Name", "Reviewed_By__c", "Document_Type__c", "Section__c"];
  
      component
        .find("util")
        .getPermissions("Deal_Document__c", fields, (response) => {
          console.log(response);
  
          component.set("v.permissionsMap", response);
        });
    }
  });