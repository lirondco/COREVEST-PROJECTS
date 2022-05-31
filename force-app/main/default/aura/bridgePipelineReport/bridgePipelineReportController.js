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
    XlsxPopulate.fromDataAsync(
      helper.base64ToArrayBuffer(JSON.parse(sheetData.template))
    )
      .then((workbook) => {
        let columns = sheetData.columns;
        let rows = sheetData.data;

        const afterFinalRow = rows.length + 3;
        let colBeforeFirstNum = 0;
        let numColumns = [];

        let propStatusColumn;

        for (let i = 0; i <= rows.length; i++) {
          for (let j = 0; j < columns.length; j++) {
            if (i === rows.length) {
              workbook
                .sheet("Pipeline")
                .row(afterFinalRow)
                .cell(j + 2)
                .style({
                  topBorder: true,
                  topBorderStyle: "thick"
                });
              continue;
            }
            let r = columns[j].data;
            if (
              columns[j].data == "propStatus" &&
              propStatusColumn == undefined
            ) {
              propStatusColumn = String.fromCharCode(96 + j + 2);
            }

            if (columns[j].type == "date" && !$A.util.isEmpty(rows[i][r])) {
              rows[i][r] = $A.localizationService.formatDate(
                rows[i][r],
                "MM/dd/yyyy"
              );
            }

            // if (columns[j].type == "number" && !$A.util.isEmpty(rows[i][r])) {
            //   rows[i][r] = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(
            //     parseFloat(rows[i][r])
            //   );
            // }

            const reg = new RegExp("^\\d*$");

            if (!$A.util.isEmpty(r)) {
              if (
                columns[j].data == "fundingProb" &&
                propStatusColumn != undefined
              ) {
                let proStatusRowCol = propStatusColumn + (i + 3);
                let formula = `IF(${proStatusRowCol}="Pending", "Probable", IF(${proStatusRowCol}="Due Diligence", "Possible", IF(${proStatusRowCol}="Closing", "High Certainty", "")))`;
                workbook
                  .sheet("Pipeline")
                  .row(3 + i)
                  .cell(j + 2)
                  .formula(formula)
              } else if (
                columns[j].type == "currency" &&
                !$A.util.isEmpty(rows[i][r])
              ) {
                workbook
                  .sheet("Pipeline")
                  .row(3 + i)
                  .cell(j + 2)
                  .value(parseFloat(rows[i][r]))
                  .style("numberFormat", "$0,000.00");
                if (colBeforeFirstNum === 0) {
                  colBeforeFirstNum = j + 1;
                }
                if (i === 0) {
                  numColumns.push(j + 2);
                }
              } else if (
                columns[j].type == "percent" &&
                !$A.util.isEmpty(rows[i][r])
              ) {
                workbook
                  .sheet("Pipeline")
                  .row(3 + i)
                  .cell(j + 2)
                  .value(parseFloat(rows[i][r]) / 100)
                  .style("numberFormat", "00.00%");
              } else if (
                columns[j].type == "number" &&
                !$A.util.isEmpty(rows[i][r]) &&
                reg.test(rows[i][r])
              ) {
                workbook
                  .sheet("Pipeline")
                  .row(3 + i)
                  .cell(j + 2)
                  .value(parseFloat(rows[i][r]));
              } else {
                workbook
                  .sheet("Pipeline")
                  .row(3 + i)
                  .cell(j + 2)
                  .value(rows[i][r]);
              }
            }
          }
        }

        workbook
          .sheet("Pipeline")
          .row(afterFinalRow + 1)
          .cell(colBeforeFirstNum)
          .value("TOTALS:")
          .style({
            bold: true
          });

        for (let i = 0; i < numColumns.length; i++) {
          let col = String.fromCharCode(96 + numColumns[i]);
          workbook
            .sheet("Pipeline")
            .row(afterFinalRow + 1)
            .cell(numColumns[i])
            .formula(`SUM(${col}3:${col}${afterFinalRow - 1})`)
            .style("numberFormat", "$0,000.00");
        }

        return workbook.outputAsync("base64");
      })
      .then((data) => {
        const todayDate = new Date(new Date().toLocaleDateString("en-US"));
        const fileName =
          "Bridge Pipeline Prioritization " +
          $A.localizationService.formatDate(todayDate, "MMddyy") +
          ".xlsx";
        var link = document.createElement("a");
        link.href = "data:" + XlsxPopulate.MIME_TYPE + ";base64," + data;
        link.download = fileName;
        link.click();
      });
  }
});
