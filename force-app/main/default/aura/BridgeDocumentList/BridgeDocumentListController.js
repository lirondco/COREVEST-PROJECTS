({
  init: function (component, event, helper) {
    console.log("init");
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

  handleSortChangeEvent: function (component, event, helper) {
    var tableCmp = component.find("dataTable");

    //tableCmp.set( 'v.pageNumber', 1 );
    component.set("v.currentPage", 1);
    console.log("handling sort event in app container");
    console.log("columnName=" + event.getParam("columnName"));
    console.log("sortDirection=" + event.getParam("sortDirection"));
    console.log("pageNumber=" + tableCmp.get("v.pageNumber"));
    console.log("pageSize=" + tableCmp.get("v.pageSize"));

    tableCmp.set("v.sortColumnName", event.getParam("columnName"));
    tableCmp.set("v.sortDirection", event.getParam("sortDirection"));
    helper.queryRecords(component, helper);
  },

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
    let selectedDocuments = [];
    for (var i = 0; i < rowsChecked.length; i++) {
      //rows[rowsChecked[i]].Reviewed__c = false;
      selectedIds.push(rows[rowsChecked[i]].Id);
      selectedDocuments.push(rows[rowsChecked[i]]);
    }

    console.log(selectedIds);

    if (selectedIds.length > 0) {
      component.set("v.modalOpen", true);
      component.set("v.selectedIds", selectedIds);
      //component.set("v.selectedDocuments", selectedDocuments);
      console.log(selectedDocuments);
    }
  }
});