import { api, LightningElement, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord} from "lightning/uiRecordApi";
import parseBridge from "@salesforce/apex/BridgeLenderDealImportHelper.parseFileValues";
import parseDscr from "@salesforce/apex/DscrImportHelper.parseFileValues";
import NUMBER_LOANS_FIELD from '@salesforce/schema/Lender_Deal__c.Number_of_Loans__c';
import RECORD_TYPE_FIELD from '@salesforce/schema/Lender_Deal__c.RecordType.Name';

export default class LenderDealImportAction extends LightningElement {
  @api recordId;
  @track showComponent = false;
  @track errorMessage = '';
  disallowImport = false;
  recordTypeName = '';


  @wire(getRecord, { recordId: '$recordId', fields: [NUMBER_LOANS_FIELD, RECORD_TYPE_FIELD] })
  wiredRecord({ error, data }) {
    if (data) {
      const { Number_of_Loans__c, RecordType } = data.fields;
      const numberOfLoans = Number_of_Loans__c.value;
      if(numberOfLoans > 0) {
        this.errorMessage = 'An import has already been performed for this record.';
        this.disallowImport = true;
      } else {
        this.recordTypeName = RecordType.value.fields.Name.value;
        console.log(' Recordtype Name ', this.recordTypeName);
      }
      
    } else if (error) {
      let message = 'Unknown error';
      if (Array.isArray(error.body)) {
          message = error.body.map(e => e.message).join(', ');
      } else if (typeof error.body.message === 'string') {
          message = error.body.message;
      }
      this.errorMessage = message;
    }
  }

  handleToggleImport(evt) {
    const retVal = evt.detail;
    this.disallowImport = retVal;
    console.log(' handleToggleImport ' + retVal);
  }

  async handleClick(evt) {
    if (evt.target.dataset.name == "cancel") {
      this.handleCloseModal();
    } else if (evt.target.dataset.name == "upload") {
      await this.template.querySelector('c-excel-uploader').handleParseFile();
    }
  }

  async doParseFile(evt) {
    const file = evt.detail;
    try {
      let res;
      if(this.recordTypeName.toLowerCase().includes('bridge')){
        res = await parseBridge({ fileJson : file, recordId: this.recordId });
      } else if (this.recordTypeName.toLowerCase().includes('dscr')) {
        console.log(JSON.parse(file));
        return;
        // res = await parseDscr({ fileJson : file, recordId: this.recordId });
      }
      this.handleCloseModal();
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Import Successful",
          message: 'Successfully imported ' + res.length + ' records',
          variant: "success"
        })
      );
    } catch(e) {
      console.error(e);
      this.showComponent = true;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Import Failed",
          message: e.body.message,
          variant: "error"
        })
      );
    }
  }

  handleCloseModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
