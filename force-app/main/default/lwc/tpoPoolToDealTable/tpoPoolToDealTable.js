import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { api, LightningElement, wire } from "lwc";
import TPO_X_DEAL_OBJECT from "@salesforce/schema/TPO_Pool_x_Deal__c";
import STAGE_FIELD from "@salesforce/schema/TPO_Pool__c.Stage__c";
import STATUS_FIELD from "@salesforce/schema/TPO_Pool_x_Deal__c.Status__c";
import REJ_REASON_FIELD from "@salesforce/schema/TPO_Pool_x_Deal__c.Rejection_Reason__c";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import query from "@salesforce/apex/lightning_Util.query";

export default class TpoPoolToDealTable extends LightningElement {
  @api recordId;
  tableData;
  objectInfo;
  defaultSortDirection = "asc";
  sortDirection = "asc";
  sortedBy;

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

  get columns() {
    const isEditable = this.stage !== "Purchased";
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
        type: "picklist",
        sortable: true,
        editable:
          isEditable && this.objectInfo.data.fields.Status__c.updateable,
        typeAttributes: {
          placeholder: "Choose Status",
          options: this.statusPicklistValues,
          value: { fieldName: "Status__c" },
          context: { fieldName: "Id" }
        }
      },
      {
        label: "Rejection Reason",
        fieldName: "Rejection_Reason__c",
        type: "picklist",
        sortable: true,
        editable:
          isEditable &&
          this.objectInfo.data.fields.Rejection_Reason__c.updateable,
        typeAttributes: {
          placeholder: "Choose Rejection Reason",
          options: this.rejReasonPicklistValues,
          value: { fieldName: "Rejection_Reason__c" },
          context: { fieldName: "Id" }
        }
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
        type: "percent",
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
      Id: d.Id,
      Status__c: d.Status__c,
      Rejection_Reason__c: d.Rejection_Reason__c,
      Bid_Amount__c: d.Bid_Amount__c,
      Bid_Percent__c: d.Bid_Percent__c
    }));
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

  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.tableData];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
    this.tableData = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

}
