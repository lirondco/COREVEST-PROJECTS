({
  onCompLoad: function (component, event, helper) {
    console.log("INIT BRIDGE PIPELEINE");
    let action = component.get("c.retrieveAllData");
    action.setCallback(this, function (response) {
      let state = response.getState();
      if (state === "SUCCESS") {
        let res = response.getReturnValue();
        component.set("v.sheetData", res);
      } else if (state === "ERROR") {
        let errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            console.error("Error message: " + errors[0].message);
          }
        } else {
          console.error("Unknown error");
        }
      }
    });
    $A.enqueueAction(action);
  },
  onScriptLoad: function (component, event, helper) {
    console.log("INIT BRIDGE SCRIPT LOADED");
    component.set("v.scriptLoaded", true);
  },
  createPipelineReport: function (component, event, helper) {
    console.log("BRIDGE PIPELINE REPORT");
    const sheetData = JSON.parse(component.get("v.sheetData"));
    console.log(sheetData.template);
    XlsxPopulate.fromDataAsync(helper.base64ToArrayBuffer(JSON.parse(sheetData.template)))
      .then((workbook) => {
        let columns = sheetData.columns;
        let rows = sheetData.data;
        for (let i = 0; i < rows.length; i++) {
          for (let j = 0; j < columns.length; j++) {
            let r = columns[j].data;

            if (
              columns[j].type == "date" &&
              !$A.util.isEmpty(rows[i][r])
            ) {
              rows[i][r] = $A.localizationService.formatDate(
                rows[i][r],
                "MM/DD/YYYY"
              );
            }

            if (
              !$A.util.isEmpty(r)
            ) {
              workbook
                .sheet("Pipeline")
                .row(3 + i)
                .cell(j + 2)
                .value(rows[i][r]);
            }
          }
        }
        return workbook.outputAsync("base64");
      })
      .then((data) => {
        var link = document.createElement("a");
        link.href = "data:" + XlsxPopulate.MIME_TYPE + ";base64," + data;
        link.download = "CoreVestDataTapeTemplate.xlsx";
        link.click();
      });
  }
});
