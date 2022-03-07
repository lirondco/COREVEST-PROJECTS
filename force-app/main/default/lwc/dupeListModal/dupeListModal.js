import { LightningElement, api } from "lwc";
import query from "@salesforce/apex/lightning_Util.query";
import { NavigationMixin } from "lightning/navigation";

export default class DupeListModal extends NavigationMixin(LightningElement) {
  @api showReturnToDealButton = false;
  dupeList = [];
  @api recordId;
  dealId;
  @api openModal(dupeList) {
    console.log("here");
    console.log(dupeList);

    this.template.querySelector("c-modal").openModal();

    this.template.querySelector("c-modal").showSpinner();

    if (this.dupeList.length === 0) {
      console.log("query");
      this.queryDupes(dupeList);
    } else {
      console.log("show");
      this.template.querySelector("c-modal").hideSpinner();
    }
  }

  queryDupes(dupes) {
    //
    //const idList = [];
    const dupeList = [];
    const idSet = new Set();
    dupes.forEach((dupe) => {
      if (`'${dupe.sourceId}'` != `'${dupe.matchId}'`) {
        idSet.add(`'${dupe.sourceId}'`);
        idSet.add(`'${dupe.matchId}'`);
        dupeList.push(dupe);
      }
    });

    const propertyFields = [
      "Id",
      "Name",
      "Deal__c",
      "Deal__r.Name",
      "Deal__r.StageName",
      "CreatedDate",
      "Deal__r.Owner.Name",
      "Deal__r.CloseDate",
      "Deal__r.CAF_Analyst__r.Name"
    ];

    let queryString = `SELECT ${propertyFields.join(
      ","
    )} FROM Property__c WHERE Id IN (${Array.from(idSet).join(", ")})`;

    query({ queryString: queryString }).then((results) => {
      results.forEach((property) => {
        if (!property.Deal__r.CAF_Analyst__r) {
          property.Deal__r.CAF_Analyst__r = { Name: "" };
        }

        dupeList.forEach((dupe) => {
          if (dupe.sourceId == dupe.matchId) {
            // do nothing
          } else if (property.Id === dupe.sourceId) {
            dupe.source = property;
            dupe.href = `/lightning/r/Property__c/${dupe.source.Id}/view`;
            dupe.deal_href = `/lightning/r/Opportunity/${dupe.source.Deal__c}/view`;
            this.dealId = dupe.source.Deal__c;
          } else if (property.Id === dupe.matchId) {
            dupe.match = property;
            dupe.match_href = `/lightning/r/Property__c/${dupe.match.Id}/view`;
            dupe.match_deal_href = `/lightning/r/Opportunity/${dupe.match.Deal__c}/view`;
          }
        });
      });

      dupeList.forEach((dupe) => {
        dupe.key = `${dupe.source.Id}-${dupe.match.Id}`;
      });

      this.dupeList = dupeList;
      this.template.querySelector("c-modal").hideSpinner();
    });
  }

  @api closeModal() {
    this.template.querySelector("c-modal").closeModal();
  }

  returnToDeal(event) {
    console.log(this.recordId);
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.dealId,
        objectApiName: "Opportunity",
        actionName: "view"
      }
    });
  }
}
