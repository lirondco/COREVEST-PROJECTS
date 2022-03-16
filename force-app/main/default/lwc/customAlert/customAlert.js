import queryRecords from "@salesforce/apex/lightning_Util.query";
import { api, LightningElement } from "lwc";

export default class CustomAlert extends LightningElement {
  @api recordId;
  @api
  get alertText() {
    return this._alertText;
  }

  set alertText(value) {
    this._alertText = value;
  }

  @api
  get soqlQuery() {
    return this._soqlQuery;
  }

  set soqlQuery(value) {
    let soqlLocal = value;
    if (soqlLocal && soqlLocal.includes(":recordId:")) {
      soqlLocal = soqlLocal.replace(":recordId:", this.recordId);
    }
    this._soqlQuery = soqlLocal;
  }

  loadComponent;

  async connectedCallback() {
    if(!this.soqlQuery) {
      this.loadComponent = true;
      return;
    }
    let res = await queryRecords({ queryString: this.soqlQuery });

    if (res && res.length > 0) {
      this.loadComponent = true;
    }
  }
}
