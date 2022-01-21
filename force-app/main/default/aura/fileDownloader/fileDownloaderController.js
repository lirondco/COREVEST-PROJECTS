({
  init: function (component, event, helper) {
    //console.log('file download init');

    var recordId = component.get("v.recordId");

    //console.log(recordId);

    var action = component.get("c.getDocuments");
    action.setParams({
      recordId: recordId,
      userType: component.get("v.userType"),
      accountId: component.get("v.accountId"),
      accountType: component.get("v.accountType")
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        var data = JSON.parse(response.getReturnValue());
        component.set("v.documents", data);
        console.log(component.get("v.documents"));
        var folderStructure = {};
        let localData = [];
        data.forEach((el) => {
          var folderString = el.Folder_String__c;
          if (
            el.hasOwnProperty("Advance__r") &&
            el.Advance__r.hasOwnProperty("Name") &&
            el.Advance__r.Name != null
          ) {
            folderString = el.Advance__r.Name + ";" + folderString;
          }

          let elCopy = Object.assign({}, el);
          elCopy.Folder_String__c = folderString;

          var folders = folderString.split(";");

          var obj = folderStructure;

          for (var i = folders.length - 1; i >= 0; i--) {
            if ($A.util.isEmpty(folders[i])) {
              folders.splice(i, 1);
            }
          }

          for (var i = 0; i < folders.length; i++) {
            if (!$A.util.isEmpty(folders[i])) {
              if (!obj.hasOwnProperty(folders[i])) {
                var fileTypes = new Set();
                obj[folders[i]] = {
                  checked: true,
                  subFolders: {},
                  label: folders[i],
                  fileTypes: fileTypes,
                  fileTypesArr: []
                  //'folderString': el.Folder_String__c,
                };
              }

              if (i == folders.length - 1) {
                obj[folders[i]].folderString = folderString;
                if (
                  $A.util.isEmpty(el.Document_Type__c) &&
                  $A.util.isEmpty(el.Property__c)
                ) {
                  obj[folders[i]].fileTypes.add(obj[folders[i]].label);
                } else if (
                  !$A.util.isEmpty(el.Document_Type__c) &&
                  $A.util.isEmpty(el.Property__c))
                 {
                  obj[folders[i]].fileTypes.add(el.Document_Type__c);
                }

                obj[folders[i]].fileTypesArr = Array.from(
                  obj[folders[i]].fileTypes
                );
              }

              obj = obj[folders[i]].subFolders;
            }
          }

          if (!$A.util.isEmpty(el.Property__c)) {
            //obj[el.Property__r.]
            //console.log(el.Property__r.Name);
            if (!obj.hasOwnProperty(el.Property__r.Name)) {
              var fileTypes = new Set();
              obj[el.Property__r.Name] = {
                checked: true,
                subFolders: {},
                label: el.Property__r.Name,
                fileTypes: fileTypes,
                fileTypesArr: []
                //'folderString': el.Folder_String__c
              };

              // console.log(el);
            }

            if ($A.util.isEmpty(el.Document_Type__c)) {
              obj[el.Property__r.Name].fileTypes.add(
                obj[el.Property__r.Name].label
              );
            } else if (!$A.util.isEmpty(el.Document_Type__c)) {
              obj[el.Property__r.Name].fileTypes.add(el.Document_Type__c);
              console.log("add");
            }
            console.log(el.Property__r.Name);
            console.log(el.Document_Type__c);
            //console.log(el.Property__r.Name].fileTypes);
            obj[el.Property__r.Name].fileTypesArr = Array.from(
              obj[el.Property__r.Name].fileTypes
            );
          }

          if (data.length > 0) {
            component.set(
              "v.dealLabel",
              data[0].Deal__r.Name + " - " + data[0].Deal__r.Deal_Loan_Number__c
            );
          }

          localData.push(elCopy);
        });
        component.set("v.documents", localData);

        console.log(folderStructure);
        component.set("v.folderStructure", folderStructure);

        var files = [];

        Object.keys(folderStructure).forEach((key) => {
          files = files.concat(helper.returnFolderObj(folderStructure[key]));
        });

        console.log(files);
        component.set("v.fileTypes", files);

        helper.compileFileTypes(component);
        console.log(component.get("v.fileTypesArr"));
      } else if (state === "ERROR") {
        console.log("---error---");
        var errors = response.getError();
        console.log(errors);
      }
    });

    $A.enqueueAction(action);
  },

  export: function (component, event, helper) {
    var folderStrings = new Set();
    var folderStructure = component.get("v.folderStructure");
    //console.log(folderStructure);

    Object.keys(folderStructure).forEach((key) => {
      var obj = folderStructure[key];
      helper.travelFolders(obj, folderStrings);
    });

    var documents = component.get("v.documents");
    var exportDocs = [];

    documents.forEach((doc) => {
      if (
        folderStrings.has(doc.Folder_String__c) &&
        $A.util.isEmpty(doc.Property__c)
      ) {d
        exportDocs.push(doc);
      }

      if (!$A.util.isEmpty(doc.Property__c)) {
        var fString = doc.Folder_String__c.split(";");
        //console.log(doc);
        if ($A.util.isEmpty(fString[1])) {
          if (
            folderStructure[fString[0]].subFolders[doc.Property__r.Name].checked
          ) {
            exportDocs.push(doc);
            console.log(doc);
          }
        } else {
          if (
            folderStructure[fString[0]].subFolders[fString[1]].subFolders[
              doc.Property__r.Name
            ].checked
          ) {
            exportDocs.push(doc);
          }
        }
      }
    });

    console.log(exportDocs);

    var checks = component.find("checks");
    var docTypes = new Set();
    if (!$A.util.isEmpty(checks)) {
      if (checks.constructor !== Array) {
        checks = [checks];
      }
      checks.forEach((el) => {
        if (el.get("v.checked")) {
          docTypes.add(el.get("v.label"));
        }
      });
    }

    for (var i = exportDocs.length - 1; i >= 0; i--) {
      if (!$A.util.isEmpty(exportDocs[i].Document_Type__c)) {
        if (!docTypes.has(exportDocs[i].Document_Type__c)) {
          exportDocs.splice(i, 1);
        }
      } else {
        if (
          $A.util.isEmpty(exportDocs[i].Property__c) &&
          exportDocs[i].Folder_String__c != "Term Sheet;Term Sheet" &&
          !docTypes.has(exportDocs[i].Folder_String__c.replace(";", ""))
        ) {
          exportDocs.splice(i, 1);
        } else if (
          !$A.util.isEmpty(exportDocs[i].Property__c) &&
          !docTypes.has(exportDocs[i].Property__r.Name)
        ) {
          exportDocs.splice(i, 1);
        }
      }
    }

    //console.log(exportDocs);

    if (exportDocs.length > 0) {
      var jszip = new JSZip();
      component.set("v.numOfFiles", exportDocs.length);
      component.set("v.downloading", true);
      helper
        .loadDocuments(component, helper, exportDocs, jszip)
        .then(function () {
          //

          if (0 !== Object.keys(jszip.files).length) {
            jszip.generateAsync({ type: "blob" }).then(function (content) {
              saveAs(content, component.get("v.dealLabel") + ".zip");
            });
          }

          component.set("v.downloading", false);
          //console.log('all done');
          //$A.util.addClass(component.find('spinner', 'slds-hide'));
          //$A.util.addClass(component.find('spinner'), 'slds-hide');
          //component.find('inputFile').getElement().value = '';
        });
    }
  },

  treeEvent: function (component, event, helper) {
    //event.stopPropagation()
    //component.set('v.fileTypes', component.get('v.fileTypes'));
    //helper.compileFileTypes(component);
  },

  checkOn: function (component, event, helper) {
    var checks = component.find("checks");
    if (!$A.util.isEmpty(checks)) {
      if (checks.constructor !== Array) {
        //console.log(item.ge);
        checks = [checks];
      }
      checks.forEach((el) => {
        el.set("v.checked", true);
      });
    }
  },

  checkOff: function (component, event, helper) {
    var checks = component.find("checks");
    if (!$A.util.isEmpty(checks)) {
      if (checks.constructor !== Array) {
        //console.log(item.ge);
        checks = [checks];
      }
      checks.forEach((el) => {
        el.set("v.checked", false);
      });
    }
  },

  compileFileTypes: function (component, event, helper) {
    console.log("change");
    helper.compileFileTypes(component);
  }
});
