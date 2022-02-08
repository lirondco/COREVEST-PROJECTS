import { LightningElement, api } from "lwc";
import queryDocumentTypes from "@salesforce/apex/ChecklistController.queryDocumentTypes";
import upsertItem from "@salesforce/apex/ChecklistController.upsertItem";
export default class ChecklistItemNew extends LightningElement {
  sectionId = null;
  itemType = "";
  documentTypes = [];
  @api milestone;
  @api
  open(sectionId, itemType) {
    // console.log(this.sectionId);
    this.itemType = itemType;
    if (itemType == "upload") {
      queryDocumentTypes({ sectionId })
        .then((results) => {
          console.log(results);
          this.documentTypes = results;
          this.sectionId = sectionId;
        })
        .catch((error) => {
          console.log("document types errors");
          console.log(error);
        });
    } else {
      this.sectionId = sectionId;
    }

    this.template.querySelector("c-modal").openModal();
  }

  get showDocumentTypes() {
    return this.itemType == "upload";
  }

  close() {
    this.sectionId = null;
    this.itemType = null;
    this.template.querySelector("c-modal").closeModal();
  }

  save() {
    const item = {
      sobjectType: "Checklist_Item__c",
      Id: this.section,
      Milestone__c: this.milestone,
      Checklist_Section__c: this.sectionId
    };
    this.template.querySelectorAll("lightning-input-field").forEach((field) => {
      // console.log(field);
      item[field.fieldName] = field.value;
    });

    // console.log(item);

    if (this.itemType == "upload") {
      const documentType = this.template.querySelector("lightning-combobox")
        .value;

      item.Doc_Structure_Id__c = documentType;
    } else if (this.itemType == "task") {
      const taskType = this.template.querySelector("lightning-input").value;
      item.Uploader__c = taskType;
    }

    //console.log(documentType);
    console.log(item);
    if (
      (this.itemType == "upload" && item.Doc_Structure_Id__c && item.Name) ||
      (this.itemType == "task" && item.Uploader__c && item.Name)
    ) {
      upsertItem({ item, itemType: this.itemType })
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
}