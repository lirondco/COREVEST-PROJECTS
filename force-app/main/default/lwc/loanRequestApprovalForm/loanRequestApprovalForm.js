import { LightningElement } from 'lwc';
import xlsxPopulate from "@salesforce/resourceUrl/xlsx_populate";
import { loadScript } from "lightning/platformResourceLoader";

export default class LoanRequestApprovalForm extends LightningElement {
  connectedCallback() {
    console.log('CONNECTED');
    this.onFileSave();
  }
  onFileSave() {
    loadScript(this, xlsxPopulate)
      .then(() => {
        console.log('XLSX POPULATE LOADED');
      });
  }
}