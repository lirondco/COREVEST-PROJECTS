import { api, LightningElement } from "lwc";
import SheetJS2 from "@salesforce/resourceUrl/SheetJS2";
import { loadScript } from "lightning/platformResourceLoader";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from "lightning/uiRecordApi";
import getFileBody from "@salesforce/apex/DscrImportHelper.getFileBody";
import getLastAttachment from "@salesforce/apex/DscrImportHelper.getLastAttachment";

export default class DscrImportAction extends LightningElement {
  @api recordId;
  uploadedFile;
  showComponent = false;

  async renderedCallback() {
    if (this.recordId && !this.showComponent) {
      const existingFile = await getLastAttachment({ recordId: this.recordId });
      if (!existingFile.noResult) {
        this.uploadedFile = existingFile;
      }
      this.showComponent = true;
    }
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

  get disallowImport() {
    return this.uploadedFile == null;
  }

  async handleClick(evt) {
    if (evt.target.dataset.name == "cancel") {
      this.handleCloseModal();
    } else if (evt.target.dataset.name == "upload") {
      await this.handleParseFile();
    }
  }

  handleUploadFinished(evt) {
    evt.preventDefault();
    this.uploadedFile = evt.detail.files[0];
    console.log(this.uploadedFile);
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

          console.log(arr);
          
          let workbook = XLSX.read(arr, { type: "base64" });
          let workBookAsJson = {};

          workbook.SheetNames.forEach((sheetName) => {
            workBookAsJson[sheetName] = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);
          });

          return workBookAsJson;
        };
        reader.readAsArrayBuffer(new Blob([fileBody]));
      })
      .then(res => {
        console.log(res);

        return;
      })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "File imported successfully",
            variant: "success"
          })
        );
        this.handleCloseModal();
      })
      .catch((error) => {
        console.error(error);
      });
  }

  handleFileRemove() {
    deleteRecord(this.uploadedFile.documentId)
      .then(() => {
        this.uploadedFile = null;
      })
      .catch((err) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error deleting record",
            message: err.body.message,
            variant: "error"
          })
        );
      });
  }

  handleCloseModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
