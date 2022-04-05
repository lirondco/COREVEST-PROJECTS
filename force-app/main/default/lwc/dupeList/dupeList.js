import { LightningElement, api, wire } from "lwc";
import queryDupes from "@salesforce/apex/DuplicateCheckJobHelper.getDupeListFromDeal";
import RECORDTYPEID from "@salesforce/schema/Opportunity.RecordTypeId";
import query from "@salesforce/apex/lightning_Util.query";
import { getRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const _FIELDS = [RECORDTYPEID];

export default class DupeList extends LightningElement {
  // @api recordId = "0065b00000pezH2AAI";
  @api recordId;
  dupeList = [];
  recordTypeId;

  @wire(getRecord, { recordId: "$recordId", fields: _FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.recordTypeId = data.fields.RecordTypeId.value;
      this.queryDupes();

    } else if (error) {
      let errMessage = 'An unexpected error has occured.';
      if (Array.isArray(error.body)) {
        errMessage = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
        errMessage = error.body.message;
      }
      const toastEvent = new ShowToastEvent({
        title: 'Error Loading Duplicates',
        message: errMessage,
        variant: 'error'
      });
      this.dispatchEvent(toastEvent);

    }
  }

  connectedCallback() {
    // if (!this.isChild) {
    // }
  }

  openModal() {
    console.log("open modal");
    this.template.querySelector("c-dupe-list-modal").openModal(this.dupeList);
  }

  queryProperties() {}

  async queryDupes() {
    console.log('Record Type Id', this.recordTypeId);

    const dupes = await queryDupes({ dealId: this.recordId });
    console.log("---dupes--");
    console.log(dupes);
    this.dupeList = dupes;
    //this.transformDupeList(dupes);
  }

  get display() {
    return this.dupeList.length > 0;
  }

  // transformDupeList(dupeList) {
  //   console.log("inside transform dupelist");
  //   const idSet = new Set();
  //   dupeList.forEach((dupe) => {
  //     idSet.add(`'${dupe.sourceId}'`);
  //     idSet.add(`'${dupe.matchId}'`);
  //   });

  //   const propertyFields = [
  //     "Id",
  //     "Name",
  //     "Deal__c",
  //     "Deal__r.Name",
  //     "Deal__r.StageName",
  //     "CreatedDate",
  //     "Deal__r.Owner.Name",
  //     "Deal__r.CloseDate",
  //     "Deal__r.CAF_Analyst__r.Name"
  //   ];

  //   let queryString = `SELECT ${propertyFields.join(
  //     ","
  //   )} FROM Property__c WHERE Id IN (${Array.from(idSet).join(", ")})`;

  //   query({ queryString: queryString }).then((results) => {
  //     results.forEach((property) => {
  //       if (!property.Deal__r.CAF_Analyst__r) {
  //         property.Deal__r.CAF_Analyst__r = { Name: "" };
  //       }

  //       dupeList.forEach((dupe) => {
  //         if (property.Id === dupe.sourceId) {
  //           dupe.source = property;
  //           dupe.href = `/lightning/r/Property__c/${dupe.source.Id}/view`;
  //           dupe.deal_href = `/lightning/r/Opportunity/${dupe.source.Deal__c}/view`;
  //           this.dealId = dupe.source.Deal__c;
  //         } else if (property.Id === dupe.matchId) {
  //           dupe.match = property;
  //           dupe.match_href = `/lightning/r/Property__c/${dupe.match.Id}/view`;
  //           dupe.match_deal_href = `/lightning/r/Opportunity/${dupe.match.Deal__c}/view`;
  //         }
  //       });
  //     });

  //     dupeList.forEach((dupe) => {
  //       dupe.key = `${dupe.source.Id}-${dupe.match.Id}`;
  //     });

  //     this.dupeList = dupeList;
  //   });
  // }
}