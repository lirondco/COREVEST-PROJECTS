import { api, LightningElement, wire } from "lwc";
import SheetJS2 from "@salesforce/resourceUrl/SheetJS2";
import { loadScript } from "lightning/platformResourceLoader";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { deleteRecord, getRecord} from "lightning/uiRecordApi";
import getFileBody from "@salesforce/apex/ExcelUploadLwcHelper.getFileBody";
import getLastAttachment from "@salesforce/apex/ExcelUploadLwcHelper.getLastAttachment";
import parseFileValues from "@salesforce/apex/DscrImportHelper.parseFileValues";


export default class DscrImportAction extends LightningElement {
  @api recordId;
  @api errorMessage = '';
  @api showComponent = false;
  uploadedFile;
  hasRendered = false;

  async renderedCallback() {
    if (this.recordId && !this.showComponent && !this.hasRendered) {
      const existingFile = await getLastAttachment({ recordId: this.recordId });
      if (!existingFile.noResult) {
        this.uploadedFile = existingFile;
      }
      this.showComponent = true;
      this.hasRendered = true;
      this.checkIfImportsAreDisabled();
    }
  }

  get showErrorMessage() {
    return this.errorMessage.length > 0;
  }

  get acceptedFormats() {
    return [".xlsx"];
  }

  get showPill() {
    return this.pill.length > 0;
  }

  get pill() {
    if (!this.uploadedFile) {
      return [];
    } else {
      return [
        {
          type: "icon",
          href: "",
          label: this.uploadedFile.name,
          name: "filePill",
          iconName: "doctype:excel",
          alternativeText: "Excel file"
        }
      ];
    }
  }

  checkIfImportsAreDisabled() {
    console.log('checkIfImportsAreDisabled');
    const retVal = this.uploadedFile == null || !this.showComponent || this.showErrorMessage;
    this.dispatchEvent(new CustomEvent('toggleimport', { detail: retVal }));
  }

  handleUploadFinished(evt) {
    evt.preventDefault();
    this.uploadedFile = evt.detail.files[0];
    this.checkIfImportsAreDisabled();
  }

  fixData(data) {
    var o = "",
      l = 0,
      w = 10240;
    for (; l < data.byteLength / w; ++l)
      o += String.fromCharCode.apply(
        null,
        new Uint8Array(data.slice(l * w, l * w + w))
      );
    o += String.fromCharCode.apply(null, new Uint8Array(data.slice(l * w)));
    return o;
  }

  @api
  async handleParseFile() {
    const fileBody = await getFileBody({
      fileId: this.uploadedFile.contentVersionId
    });

    console.log(fileBody);
    loadScript(this, SheetJS2 + "/dist/xlsx.core.min.js")
      .then(() => {
        let reader = new FileReader();
        reader.onload = (event) => {
          const data = event.target.result;
          let arr = this.fixData(data);

          // console.log(arr);

          let workbook = XLSX.read(arr, { type: "base64", cellDates: true });
          let workBookAsJson = {};

          workbook.SheetNames.forEach((sheetName) => {
            // console.log(XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]));
            workBookAsJson[sheetName] = JSON.stringify(
              XLSX.utils.sheet_to_json(workbook.Sheets[sheetName])
            );
          });
          this.showComponent = false;
          this.checkIfImportsAreDisabled();
          const detail = JSON.stringify(workBookAsJson);
          this.dispatchEvent(new CustomEvent("parsefile", { detail }));
        };
        reader.readAsArrayBuffer(new Blob([fileBody]));
      })
      .catch((error) => {
        console.error(error);
        this.showComponent = true;
        this.checkIfImportsAreDisabled();
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error"
          })
        );
      });
      }

  handleFileRemove() {
    deleteRecord(this.uploadedFile.documentId)
      .then(() => {
        this.uploadedFile = null;
        this.checkIfImportsAreDisabled();
      })
      .catch((err) => {
        this.checkIfImportsAreDisabled();
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error deleting record",
            message: err.body.message,
            variant: "error"
          })
        );
      });
  }
}
