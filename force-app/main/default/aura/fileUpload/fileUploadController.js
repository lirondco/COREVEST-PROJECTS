({
  init: function(component, event, helper) {
    console.log("test");
    component.set(
      "v.randomId",
      "_" +
        Math.random()
          .toString(36)
          .substr(2, 9)
    );
    var action = component.get("c.getSession");
    action.setCallback(this, function(response) {
      var state = response.getState();

      if (state == "SUCCESS") {
        //var sessionId = response.getReturnValue();
        var res = JSON.parse(response.getReturnValue());
        //var url = window.location.href;
        //var splitUrl = url.split("/s")
        //var sfInstanceUrl = splitUrl[0];
        //console.log(sfInstanceUrl);
        console.log(res);
        component.set("v.sessionId", res.sessionId);
        component.set("v.sfInstanceUrl", res.endpoint);
        component.set("v.isLoading", true);
      } else if (state === "ERROR") {
        //resolve();
        console.log("error");
        console.log(response.getError());
      }
    });

    $A.enqueueAction(action);
  },

  handleFiles: function(component, event, helper) {
    var inputFile = component.find("inputFile");
    var files = component.find("inputFile").getElement().files;
    //var fileList = [];
    //component.set('v.parentId', component.get('v.parentId'));
    for (var i = 0; i < files.length; i++) {
      helper.readFile(component, helper, files[i], component.get("v.parentId"));
    }
  },

  onDragOver: function(component, event, helper) {
    console.log("drag");
    event.preventDefault();
  },

  onDrop: function(component, event, helper) {
    console.log("drop");
    event.stopPropagation();
    event.preventDefault();
    $A.util.removeClass(component.find("spinner"), "slds-hide");
    event.dataTransfer.dropEffect = "copy";
    var files = event.dataTransfer.files;
    var fileList = [];
    for (var i = 0; i < files.length; i++) {
      fileList.push(files[i]);
    }
    helper
      .readFiles(component, helper, fileList, component.get("v.parentId"))
      .then(function() {
        $A.util.addClass(component.find("spinner"), "slds-hide");
      });
  },

  handleFilesPromise: function(component, event, helper) {
    $A.util.removeClass(component.find("spinner"), "slds-hide");
    var inputFile = component.find("inputFile");
    var files = component.find("inputFile").getElement().files;
    var fileList = [];
    for (var i = 0; i < files.length; i++) {
      fileList.push(files[i]);
    }
    helper
      .readFiles(component, helper, fileList, component.get("v.parentId"))
      .then(function() {
        console.log("all done");
        $A.util.addClass(component.find("spinner"), "slds-hide");
        component.find("inputFile").getElement().value = "";
      });
  }
});