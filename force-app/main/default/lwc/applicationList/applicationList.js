import { LightningElement, api, wire } from "lwc";
import getApplications from "@salesforce/apex/ApplicationListController.getApplications";
import { getRecord } from "lightning/uiRecordApi";
import setMainApplication from "@salesforce/apex/ApplicationListController.setMainApplication";
const FIELDS = ["Opportunity.Application__c"];

import { updateRecord } from "lightning/uiRecordApi";

export default class AccountRelatedAttorneyList extends LightningElement {
  @api recordId;

  pageSize = 25;

  currentPage = 1;
  totalPages = 1;

  columns = [
    {
      label: "Name",
      fieldName: "url",
      type: "url",
      typeAttributes: { label: { fieldName: "Name" } }
    },
    {
      label: "Status",
      fieldName: "Status__c",
      type: "text"
    },
    {
      label: "Applicant",
      fieldName: "applicantUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "applicantName" } }
    },
    {
      label: "Active",
      fieldName: "active",
      type: "boolean"
    }
  ];

  applications = [];
  applicationId = "";
  @wire(getRecord, {
    recordId: "$recordId",
    fields: FIELDS
  })
  getRecord({ data, error }) {
    if (data) {
      console.log("application refresh");
      this.applicationId = data.fields.Application__c.value;
      this.init();
    } else if (error) {
      console.error("ERROR => ", JSON.stringify(error)); // handle error properly
    }
  }

  init() {
    getApplications({ recordId: this.recordId })
      .then((results) => {
        console.log(results);
        this.applications = results;
        this.totalPages = Math.ceil(results.length / this.pageSize);
      })
      .catch((error) => {
        console.log("--error--");
        console.log(error);
      });
  }

  get showList() {
    return this.applications.length > 0;
  }

  get applicationList() {
    const displayedApplications = [];

    const applications = JSON.parse(JSON.stringify(this.applications));

    console.log(applications);
    applications.forEach((application) => {
      if (application.Contact__c) {
        application.applicantName = application.Contact__r.Name;
        application.applicantUrl = `/lightning/r/Contact/${application.Contact__c}/view`;
      }
      if (!application.Status__c) {
        application.Status__c = "Pending";
      }
      application.url = `/lightning/r/Application__c/${application.Id}/view`;
      application.active = this.applicationId === application.Id;
    });

    const start = (this.currentPage - 1) * this.pageSize;
    const end = this.currentPage * this.pageSize;

    // console.log(start);
    // console.log(end);

    for (let i = start; i < end; i++) {
      if (applications[i]) {
        displayedApplications.push(applications[i]);
      }
    }

    // consol;

    return displayedApplications;
  }

  get displayNavButtons() {
    return this.applications.length > this.pageSize;
  }

  get firstButtonDisabled() {
    return this.currentPage === 1;
  }

  get previousButtonDisabled() {
    return this.currentPage === 1;
  }

  get nextButtonDisabled() {
    return this.currentPage === this.totalPages;
  }

  get lastButtonDisabled() {
    return this.currentPage === this.totalPages;
  }

  firstPage() {
    this.currentPage = 1;
  }

  nextPage() {
    this.currentPage = this.currentPage + 1;
  }

  previousPage() {
    this.currentPage = this.currentPage - 1;
  }

  lastPage() {
    this.currentPage = this.totalPages;
  }

  setActive(event) {
    const rows = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();

    this.template.querySelector("lightning-button").disabled = true;

    console.log(rows);
    if (rows.length > 0) {
      console.log(rows[0].Id);

      setMainApplication({ dealId: this.recordId, applicationId: rows[0].Id })
        .then(() => {
          updateRecord({ fields: { Id: this.recordId } });
          this.template.querySelector("lightning-button").disabled = false;
        })
        .catch((error) => {
          console.log("application error");
          console.log(error);
          this.template.querySelector("lightning-button").disabled = false;
        });
    } else {
      this.template.querySelector("lightning-button").disabled = false;
    }
  }
}