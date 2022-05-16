({
  init: function (component, event, helper) {
    helper.callAction(component, "c.getUserId", {}, function (data) {
      component.set("v.userId", data);
    });

    var fields = [];
    var columns = component.find("dataTable").get("v.columns");
    for (var i = 0; i < columns.length; i++) {
      if(columns[i].get("v.name") == "isReadable") {
        continue;
      }
      fields.push(columns[i].get("v.name"));
    }

    component.set("v.fieldList", fields);

    helper.queryRecords(component, helper);
    helper.compilePermissions(component);
  },

  // handlePageChangeEvent : function( component, event, helper ) {

  //     var tableCmp = component.find( 'dataTable' );

  //     console.log( 'handling page change event in app container' );
  //     console.log( 'columnName=' + tableCmp.get( 'v.sortColumnName' ) );
  //     console.log( 'sortDirection=' + tableCmp.get( 'v.sortDirection' ) );
  //     console.log( 'page=' + event.getParam( 'pageNumber' ) );
  //     console.log( 'pageSize=' + event.getParam( 'pageSize' ) );

  //     if($A.util.isEmpty(component.get('v.fieldList'))){
  //     	helper.compileFields(component);
  //     }

  //     helper.callAction(
  //         component,
  //         'c.getRecords',
  //         {
  //         	'parentId' : component.get('v.recordId'),
  //         	'parentFieldName' : component.get('v.parentFieldName'),
  //         	'sobjectType' : component.get('v.sobjectType'),
  //         	'fields' : component.get('v.fieldList'),
  //             'page' : event.getParam( 'pageNumber' ),
  //             'pageSize' : event.getParam( 'pageSize' ),
  //             'sortCol' : tableCmp.get( 'v.sortColumnName' ),
  //             'sortDir' : tableCmp.get( 'v.sortDirection' ),
  //             'whereClause' : component.get('v.whereClause')
  //         },
  //         function( data ) {

  //             var tableCmp = component.find( 'dataTable' );

  //             var rows = tableCmp.get( 'v.rows' );
  //             //console.log(JSON.parse(data));

  //             tableCmp.set( 'v.rows', rows.concat( data ) );

  //         }
  //     );

  // },

  deleteDocuments: function (component, event, helper) {
    var table = component.find("dataTable");
    table.toggleSpinner();
    var rowsChecked = [];
    table.getChecked(function (resp) {
      rowsChecked = resp;
    });

    var rows = table.get("v.rows");

    var toUpdate = [];

    for (var i = 0; i < rowsChecked.length; i++) {
      if (rows[rowsChecked[i]].Document_Loaded__c) {
        rows[rowsChecked[i]].Is_Deleted__c = true;
        toUpdate.push(rows[rowsChecked[i]]);
      }
    }

    console.log(toUpdate);

    helper.callAction(
      component,
      "c.upsertRecords",
      {
        records: toUpdate
      },

      function (data) {
        table.toggleSpinner();
        helper.queryRecords(component, helper);
      }
    );
  },

  handleSortChangeEvent: function (component, event, helper) {
    var tableCmp = component.find("dataTable");

    //tableCmp.set( 'v.pageNumber', 1 );
    component.set("v.currentPage", 1);
    console.log("handling sort event in app container");
    console.log("columnName=" + event.getParam("columnName"));
    console.log("sortDirection=" + event.getParam("sortDirection"));
    console.log("pageNumber=" + tableCmp.get("v.pageNumber"));
    console.log("pageSize=" + tableCmp.get("v.pageSize"));

    // console.log(component.find('dataTable').get('v.rows'), rows);

    // if($A.util.isEmpty(component.get('v.fieldList'))){
    // 	helper.compileFields(component);
    // }

    // helper.callAction(
    //     component,
    //     'c.getRecords',
    //     {
    //     	'parentId' : component.get('v.recordId'),
    //     	'parentFieldName' : component.get('v.parentFieldName'),
    //     	'sobjectType' : component.get('v.sobjectType'),
    //     	'fields' : component.get('v.fieldList'),
    //         'page' : tableCmp.get( 'v.pageNumber' ),
    //         'pageSize' : tableCmp.get( 'v.pageSize' ),
    //         'sortCol' : event.getParam( 'columnName' ),
    //         'sortDir' : event.getParam( 'sortDirection' ),
    //         'whereClause' : component.get('v.whereClause')
    //     },
    //     function( data ) {

    //         var tableCmp = component.find( 'dataTable' );

    //          tableCmp.set( 'v.rows', data );
    //         //tableCmp.set('v.rows', []);

    //     }
    // );

    tableCmp.set("v.sortColumnName", event.getParam("columnName"));
    tableCmp.set("v.sortDirection", event.getParam("sortDirection"));
    helper.queryRecords(component, helper);
  },

  saveRows: function (component, event, helper) {
    component.set("v.editMode", !component.get("v.editMode"));
    var table = component.find("dataTable");
    table.saveRows();
  },

  addRow: function (component, event, helper) {
    var entityScreen = component.find("newEntity");

    entityScreen.set("v.hidden", false);
  },

  toggleEdit: function (component, event, helper) {
    component.set("v.editMode", !component.get("v.editMode"));
  },

  addRecord: function (component, event, helper) {
    var record = event.getParam("record");

    var table = component.find("dataTable");
    table.addRow(record);
  },

  makeActive: function (component, event, helper) {
    var table = component.find("dataTable");
    table.toggleSpinner();
    var rowsChecked = [];
    table.getChecked(function (resp) {
      rowsChecked = resp;
    });

    //console.log(table.get('v.rows'));

    console.log(rowsChecked);
    var rows = table.get("v.rows");
    for (var i = 0; i < rowsChecked.length; i++) {
      rows[rowsChecked[i]].Active__c = true;
    }

    console.log(rows);

    helper.callAction(
      component,
      "c.upsertRecords",
      {
        records: rows
      },

      function (data) {
        table.toggleSpinner();
        helper.queryRecords(component, helper);
      }
    );
  },

  reviewSelected: function (component, event, helper) {
    var table = component.find("dataTable");
    //table.toggleSpinner();
    var rowsChecked = [];
    table.getChecked(function (resp) {
      rowsChecked = resp;
    });

    var rows = table.get("v.rows");
    for (var i = 0; i < rowsChecked.length; i++) {
      rows[rowsChecked[i]].Reviewed__c = true; //component.get('v.userId')
    }

    console.log(rows);

    helper.callAction(
      component,
      "c.upsertRecords",
      {
        records: rows
      },
      function (data) {
        //table.toggleSpinner();
        helper.queryRecords(component, helper);
      }
    );
  },
  unreviewSelected: function (component, event, helper) {
    var table = component.find("dataTable");
    //table.toggleSpinner();
    var rowsChecked = [];
    table.getChecked(function (resp) {
      rowsChecked = resp;
    });

    console.log(rowsChecked);

    var rows = table.get("v.rows");
    for (var i = 0; i < rowsChecked.length; i++) {
      rows[rowsChecked[i]].Reviewed__c = false;
    }

    console.log(rows);

    helper.callAction(
      component,
      "c.upsertRecords",
      {
        records: rows
      },
      function (data) {
        //table.toggleSpinner();
        helper.queryRecords(component, helper);
      }
    );
  },

  refresh: function (component, event, helper) {
    helper.queryRecords(component, helper);
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

  updateFolder: function (component, event, helper) {
    var table = component.find("dataTable");
    //table.toggleSpinner();
    var rowsChecked = [];
    table.getChecked(function (resp) {
      rowsChecked = resp;
    });

    //console.log(rowsChecked);

    var rows = table.get("v.rows");
    let selectedIds = [];
    for (var i = 0; i < rowsChecked.length; i++) {
      //rows[rowsChecked[i]].Reviewed__c = false;
      selectedIds.push(rows[rowsChecked[i]].Id);
    }

    console.log(selectedIds);

    if (selectedIds.length > 0) {
      component.set("v.modalOpen", true);
      component.set("v.selectedIds", selectedIds);
    }
  }
});