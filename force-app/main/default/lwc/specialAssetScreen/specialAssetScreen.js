import { LightningElement, api, track, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// import SEVERITY_FIELD from "@salesforce/schema/Special_Asset__c.Severity_Level__c";
// import FOLLOWUP_FIELD from "@salesforce/schema/Special_Asset__c.Follow_Up_Date__c";
// import RESOLUTION_FIELD from "@salesforce/schema/Special_Asset__c.Resolution_Type__c";
// import LITIGATION_FIELD from "@salesforce/schema/Special_Asset__c.Litigation_Pending__c";
// import ESTIMATEDRECOVERYDATE_FIELD from "@salesforce/schema/Special_Asset__c.Estimated_Recovery_Date__c";
// import RESOLVEDDATE_FIELD from "@salesforce/schema/Special_Asset__c.Resolved_Date__c";
// import REASON_FIELD from "@salesforce/schema/Special_Asset__c.Special_Asset_Reason__c";
// import SAMANAGER_FIELD from "@salesforce/schema/Special_Asset__c.Special_Asset_Manager__c";
// import STATUS_FIELD from "@salesforce/schema/Special_Asset__c.Status_Comment__c";
// import STRAGTEGY_FIELD from "@salesforce/schema/Special_Asset__c.Strategy__c";
// import MILESTONES_FIELD from "@salesforce/schema/Special_Asset__c.Milestones__c";

const fields = ["Property__c.Name", "Property__c.Special_Asset__c"];

export default class SpecialAssetScreen extends LightningElement {
  @api recordId;
  @track property;
  // @track specialAsset = "a2f2C000000TYCKQA4";
  @track specialAssetId;
  // @track specialAssetFields = [SEVERITY_FIELD, FOLLOWUP_FIELD, RESOLUTION_FIELD, LITIGATION_FIELD, ESTIMATEDRECOVERYDATE_FIELD, RESOLVEDDATE_FIELD, 
  //   REASON_FIELD, SAMANAGER_FIELD, STATUS_FIELD, STRAGTEGY_FIELD, MILESTONES_FIELD];
  autoDateLocal;

  @wire(getRecord, { recordId: '$recordId', fields })  
  wiredProperty(value) {
    if (value.data) {
      this.property = value.data;
      this.specialAssetId = this.property.fields.Special_Asset__c.value;
      // console.log(value);
    } else if (value.error) {
      console.log("ERROR: ", value.error)
    }
  }

  handleChange(event) {
    this.autoDate = event.detail.value;
  }

  handleReset(event) {
    const inputFields = this.template.querySelectorAll(
        'lightning-input-field'
    );
    if (inputFields) {
        inputFields.forEach(field => {
            field.reset();
        });
    }
 }

  fireToast() {
    const event = new ShowToastEvent({
      title: "Success!",
      message: "The Special Asset Details have been successfully updated.",
      variant: "success",
    });
    this.dispatchEvent(event);
  }

  get autoDate() {
    return this.autoDateLocal;
  }

  set autoDate(val) {
    this.autoDateLocal = val;
  }
  
  // querySpecialAsset() {
  //   let queryString = `SELECT Id, Name, Accrual_Stop_Date__c, Estimated_Recovery_Date__c, Follow_Up_Date__c, Property__c, Referred_for_FC_Date__c, `;
  //   queryString += `Resolution_Type__c, Resolved_Date__c, Severity_Level__c, `;
  //   queryString += `FROM Special_Asset__c WHERE Property__c = '${this.recordId}' LIMIT 1`;

  //   query({ queryString: queryString })
  //     .then((specialAsset) => {
  //       console.log("--Special Asset--");
  //       console.log(specialAsset);
  //       this.specialAsset = specialAsset;
  //       // this.isLoading = false;
  //     })
  //     .catch((error) => {
  //       console.log(error);
  //     });
  // }
}