import query from "@salesforce/apex/lightning_Util.query";
import { api, LightningElement } from "lwc";

const DEAL_FIELDS = ["Active_States__c"];
const PROP_FIELDS = ["Refinance_Acquisition__c"];
const DEAL_INFO = [
  {
    fieldName: "Loan_Number__c",
    label: "Loan #",
    isParent: false
  }
];
export default class BridgeFundingMemo extends LightningElement {
  @api recordId;
  recordData = [];
  columnA = [];
  columnB = [];
  get queryString() {
    return `SELECT Deal__r.${DEAL_FIELDS.join(
      ",Deal__r."
    )}, (SELECT Property__r.${PROP_FIELDS.join(
      ",Property__r."
    )} FROM Property_Advances__r) FROM Advance__c WHERE Id='${this.recordId}'`;
  }

  connectedCallback() {
    if (this.recordId) {
      this.retrieveData();
    }
  }
  async retrieveData() {
    const res = await query({ queryString: this.queryString });
    this.recordData = res;
  }
}
