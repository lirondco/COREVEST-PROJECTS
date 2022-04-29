import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { api, LightningElement, wire } from "lwc";
import TPO_X_DEAL_OBJECT from "@salesforce/schema/TPO_Pool_x_Deal__c";
import STAGE_FIELD from "@salesforce/schema/TPO_Pool__c.Stage__c";
import STATUS_FIELD from "@salesforce/schema/TPO_Pool_x_Deal__c.Status__c";
import REJ_REASON_FIELD from "@salesforce/schema/TPO_Pool_x_Deal__c.Rejection_Reason__c";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import query from "@salesforce/apex/lightning_Util.query";
import upsertRecords from "@salesforce/apex/lightning_Util.upsertRecords";

export default class TpoPoolToDealTable extends LightningElement {
  @api recordId;
  tableData;
  objectInfo;
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;
  isEditModeLocal = false;
  draftValues = [];
  hasError = false;

  @wire(getObjectInfo, { objectApiName: TPO_X_DEAL_OBJECT })
  wiredObjectinfo({ error, data }) {
    if (data) {
      console.log(data);
      this.objectInfo = { data };
    } else if (error) {
      console.error(error);
    }
  }

  @wire(getRecord, { recordId: "$recordId", fields: [STAGE_FIELD] })
  record;

  @wire(getPicklistValues, {
    recordTypeId: "$defaultRecordTypeId",
    fieldApiName: STATUS_FIELD
  })
  statusPicklistValuesData;

  @wire(getPicklistValues, {
    recordTypeId: "$defaultRecordTypeId",
    fieldApiName: REJ_REASON_FIELD
  })
  rejReasonPicklistValuesData;

  get stage() {
    return getFieldValue(this.record.data, STAGE_FIELD);
  }

  get defaultRecordTypeId() {
    return this.objectInfo.data.defaultRecordTypeId;
  }

  get statusPicklistValues() {
    if (this.statusPicklistValuesData.data) {
      return this.statusPicklistValuesData.data.values.map((v) => ({
        label: v.label,
        value: v.value
      }));
    }
  }

  get rejReasonPicklistValues() {
    if (this.rejReasonPicklistValuesData.data) {
      return this.rejReasonPicklistValuesData.data.values.map((v) => ({
        label: v.label,
        value: v.value
      }));
    }
  }

  get cardTitle() {
    return `TPO Pool to Deals (${this.tableData.length})`;
  }

  get showEditButton() {
    return (
      this.stage !== "Purchased" &&
      this.objectInfo.data.fields.Status__c.updateable &&
      this.objectInfo.data.fields.Rejection_Reason__c.updateable &&
      this.objectInfo.data.fields.Bid_Amount__c.updateable &&
      this.objectInfo.data.fields.Bid_Percent__c.updateable
    );
  }

  get isEditMode() {
    return this.isEditModeLocal;
  }

  set isEditMode(value) {
    this.isEditModeLocal = value;
  }

  get columns() {
    const isEditable = this.stage !== "Purchased" && this.isEditMode;
    return [
      {
        label: "Deal Name",
        fieldName: "_dealUrl",
        type: "url",

        typeAttributes: { label: { fieldName: "_dealName" }, target: "_blank" },
        sortable: true,
        editable: false
      },
      {
        label: "Status",
        fieldName: "Status__c",

        type:
          isEditable && this.objectInfo.data.fields.Status__c.updateable
            ? "picklist"
            : "text",
        sortable: true,
        editable:
          isEditable && this.objectInfo.data.fields.Status__c.updateable,
        typeAttributes:
          isEditable && this.objectInfo.data.fields.Status__c.updateable
            ? {
                placeholder: "Choose Status",
                options: this.statusPicklistValues,
                value: { fieldName: "Status__c" },
                context: { fieldName: "Id" },
                apiName: "Status__c"
              }
            : {}
      },
      {
        label: "Rejection Reason",
        fieldName: "Rejection_Reason__c",

        type:
          isEditable &&
          this.objectInfo.data.fields.Rejection_Reason__c.updateable
            ? "picklist"
            : "text",
        sortable: true,
        editable:
          isEditable &&
          this.objectInfo.data.fields.Rejection_Reason__c.updateable,

        typeAttributes:
          isEditable &&
          this.objectInfo.data.fields.Rejection_Reason__c.updateable
            ? {
                placeholder: "Choose Rejection Reason",
                options: this.rejReasonPicklistValues,
                value: { fieldName: "Rejection_Reason__c" },
                context: { fieldName: "Id" },
                apiName: "Rejection_Reason__c",
                showError: {
                  fieldName: "_showError"
                },
                errorMessage: {
                  fieldName: "_errorMessage"
                },
                disabled: { fieldName: "_disabled" }
              }
            : {}
      },
      {
        label: "Loan Amount",
        fieldName: "_loanAmount",

        type: "currency",
        typeAttributes: { currencyCode: "USD", step: "0.01" },
        sortable: true,
        editable: false
      },
      {
        label: "Bid Amount",
        fieldName: "Bid_Amount__c",
        type: "currency",

        typeAttributes: { currencyCode: "USD", step: "0.01" },
        sortable: true,
        editable:
          isEditable && this.objectInfo.data.fields.Bid_Amount__c.updateable
      },
      {
        label: "Bid % of Loan Amount",
        fieldName: "Bid_Percent__c",
        type: "number",
        sortable: true,

        editable:
          isEditable && this.objectInfo.data.fields.Bid_Percent__c.updateable,
        typeAttributes: {
          step: "0.00001",
          minimumFractionDigits: "2",
          maximumFractionDigits: "3"
        }
      },
      {
        label: "Account Name",
        fieldName: "_accountNameUrl",

        type: "url",
        typeAttributes: {
          label: { fieldName: "_accountName" },
          target: "_blank"
        },
        sortable: true,
        editable: false
      },
      {
        label: "# of Prior Loans",
        fieldName: "_numPriorLoans",

        type: "number",
        sortable: true,
        editable: false
      }
    ];
  }

  get isComponentReady() {
    return (
      this.columns &&
      this.tableData &&
      this.statusPicklistValues &&
      this.rejReasonPicklistValues
    );
  }

  async connectedCallback() {
    await this.loadData();
  }

  async loadData() {
    const queryString = `SELECT 
      Id, 
      Deal__c,
      Deal__r.AccountId,
      Deal__r.Name, 
      Status__c, 
      Rejection_Reason__c, 
      Deal__r.Final_Loan_Amount__c, 
      Bid_Amount__c, 
      Bid_Percent__c, 
      Deal__r.Account.Name, 
      Deal__r.Account.Deals_Won__c 
      FROM TPO_Pool_x_Deal__c WHERE TPO_Pool__c = '${this.recordId}'`;

    const res = await query({ queryString });
    this.tableData = res.map((d) => ({
      _dealName: d.Deal__r.Name,
      _dealUrl: `/lightning/r/Opportunity/${d.Deal__c}/view`,
      _accountName: d.Deal__r.Account.Name,
      _accountNameUrl: `/lightning/r/Account/${d.Deal__r.AccountId}/view`,
      _numPriorLoans: d.Deal__r.Account.Deals_Won__c,
      _loanAmount: d.Deal__r.Final_Loan_Amount__c,
      _showError: false,
      _errorMessage: "",
      _disabled: d.Status__c != "No Bid",
      Id: d.Id,
      Status__c: d.Status__c,
      Rejection_Reason__c: d.Rejection_Reason__c,
      Bid_Amount__c: d.Bid_Amount__c,
      Bid_Percent__c: d.Bid_Percent__c
    }));
  }

  handleClick(evt) {
    const name = evt.target.dataset.name;

    switch (name) {
      case "edit":
        this.toggleEdit();
        break;
      case "save":
        this.handleSave();
        break;
      case "cancel":
        this.toggleEdit();
        this.draftValues = [];
        this.tableData = [...this.tableData];
        break;
    }
  }

  handleSave() {
    const draftVals = [...this.draftValues];
    let showError = false;
    let errorMessage = "";
    const errorRows = [];
    draftVals.forEach((d) => {
      if (
        d.hasOwnProperty("Status__c") &&
        d.Status__c === "No Bid" &&
        (!d.hasOwnProperty("Rejection_Reason__c") || !d.Rejection_Reason__c)
      ) {
        showError = true;
        errorMessage =
          "A rejection reason must be selected if the status is No Bid";
        errorRows.push(d.Id);
      } else if (
        d.hasOwnProperty("Status__c") &&
        d.Status__c !== "No Bid"

      ) {
        d["Rejection_Reason__c"] = null;
      }
    });

    if (showError) {
      this.hasError = true;
      const data = [...this.tableData];
      data.forEach((d) => {
        if (errorRows.includes(d.Id)) {
          d._showError = true;
          d._errorMessage = errorMessage;
        }
      });
      this.tableData = [...data];
      return;
    } else {
      upsertRecords({ records: draftVals })
        .then(() => {
          this.draftValues = [];
          this.loadData();
        })
        .then(() => {
          this.toggleEdit();
          this.showToast({
            title: "Success",
            message: "Bids saved successfully",
            variant: "success"
          });
        })
        .catch((err) => {
          console.error(err);
          let errorMessage = "An error occurred while saving the data";
          if (err.hasOwnProperty("body") && Array.isArray(err.body)) {
            errorMessage = err.body.map((e) => e.message).join(", ");
          } else if (
            err.hasOwnProperty("body") &&
            typeof err.body.message == "string"
          ) {
            errorMessage = err.body.message;
          }

          this.showToast({
            title: "Error",
            message: errorMessage,
            variant: "error"
          });
        });
    }
  }

  showToast({ title, message, variant }) {
    const event = new ShowToastEvent({
      title,
      message,
      variant
    });
    this.dispatchEvent(event);
  }

  toggleEdit() {
    this.isEditMode = !this.isEditMode;
  }

  sortBy(field, reverse, primer) {
    const key = primer
      ? function (x) {
          return primer(x[field]);
        }
      : function (x) {
          return x[field];
        };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }

  handlePicklistChange(evt) {
    const val = evt.detail.data.value;
    const context = evt.detail.data.context;
    const apiName = evt.detail.data.apiName;
    const draftVals = this.draftValues;
    if (apiName === "Status__c" && val === "No Bid") {
      const data = [...this.tableData];
      data.forEach((d) => {
        if (d._disabled && d.Id === context) {
          d._disabled = false;
        }
      });
      this.tableData = [...data];
    } else if (apiName === "Status__c" && val !== "No Bid") {
      const data = [...this.tableData];
      data.forEach((d) => {
        if (!d._disabled && d.Id === context) {
          d._disabled = true;
        }
      });
      this.tableData = [...data];
    }
    if (
      (apiName === "Status__c" && val != "No Bid" && this.hasError) ||
      (apiName === "Rejection_Reason__c" && val != "" && this.hasError)
    ) {
      this.hasError = false;
      const data = [...this.tableData];
      data.forEach((d) => {
        if (d._showError && d.Id === context) {
          d._showError = false;
          d._errorMessage = "";
        }
      });
      this.tableData = [...data];
    }
    if (draftVals.length > 0 && draftVals.some((d) => d.Id === context)) {
      draftVals.forEach((d) => {
        if (d.Id === context) {
          d[apiName] = val;
        }
      });
    } else {
      draftVals.push({
        Id: context,
        [apiName]: val
      });
    }
    this.draftValues = draftVals;
  }

  handleCellChange(evt) {
    const row = evt.detail.draftValues[0];
    console.log(row);
    const draftVals = this.draftValues;
    if (draftVals.length > 0 && draftVals.some((d) => d.Id === row.Id)) {
      draftVals.forEach((d) => {
        if (d.Id === row.Id) {
          Object.entries(row).forEach(([k, v]) => {
            d[k] = v;
          });
        }
      });
    } else {
      draftVals.push(row);
    }
    this.draftValues = draftVals;
  }

  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.tableData];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.tableData = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }
}
