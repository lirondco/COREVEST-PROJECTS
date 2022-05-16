import { api, LightningElement } from 'lwc';
import xlsxPopulate from "@salesforce/resourceUrl/xlsx_populate";
import { loadScript } from "lightning/platformResourceLoader";

export default class LoanRequestApprovalForm extends LightningElement {
  @api dealId;

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

  handleCancel() {
    this.dispatchEvent(new CustomEvent('cancel'));
  }
}