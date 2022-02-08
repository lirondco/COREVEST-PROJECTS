import { LightningElement, api } from "lwc";
import upsertItem from "@salesforce/apex/ChecklistController.upsertItem";
export default class ChecklistItemEdit extends LightningElement {
  itemId;

  @api
  open(itemId) {
    this.itemId = itemId;
    console.log(this.itemId);
    this.template.querySelector("c-modal").openModal();
  }

  close() {
    this.itemId = null;
    this.template.querySelector("c-modal").closeModal();
  }

  save() {
    console.log("save");

    const item = { sobjectType: "Checklist_Item__c", Id: this.itemId };

    this.template.querySelectorAll("lightning-input-field").forEach((field) => {
      // console.log(field);
      console.log(field.fieldName);
      item[field.fieldName] = field.value;
    });

    upsertItem({ item })
      .then((results) => {
        console.log(results);
        this.dispatchEvent(new CustomEvent("save"));
        this.close();
      })
      .catch((error) => {
        console.log("save item error");
        console.log(error);
      });
  }
}