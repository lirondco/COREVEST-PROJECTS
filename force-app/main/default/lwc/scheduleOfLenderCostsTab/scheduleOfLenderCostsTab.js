import { LightningElement, api, track, wire } from "lwc";

import query from "@salesforce/apex/lightning_Util.query";
import upsert from "@salesforce/apex/lightning_Util.upsertRecords";
import compileEmailTemplate from "@salesforce/apex/lightning_Util.compileEmailTemplate";
import getUser from "@salesforce/apex/lightning_Util.getUser";
import compileFieldPermissions from "@salesforce/apex/lightning_Util.compileFieldPermissions";
import { getRecord } from 'lightning/uiRecordApi';

export default class ScheduleOfLenderCostsTab extends LightningElement {
  @api recordId;
  @track permissionsMap = {
    sobject: {
      isAccessible: false,
      isUpdateable: false,
      isCreateable: false,
      isDeletable: false
    },
    Finalized__c: {
      isAccessible: false,
      isUpdateable: false,
      isCreateable: false
    }
  };

  deal = {};
  versionId = "";
  loanVersions = [{ label: "", value: "" }];

  selectedLoanVersionId = "";
  showSpinner = false;
  versionFinalized = false;
  finalizedVersionId = "";
  recordTypeName = "Schedule_Of_Lender_Cost";
  recordTypeId = "";
  templateId = "00X0a0000017EDtEAM";
  emailInputs = {
    subject: "",
    // to: "",
    // from: [],
    // to: [],
    body: ""
  };

  // dealQueried = "";
  // added a wire to make the tab aut-refresh when these fields are changed
  @wire(getRecord, { recordId: "$recordId", fields: ["Opportunity.IO_Term__c","Opportunity.Rate_Lock_Picklist__c", "Opportunity.Amortization_Term__c", "Opportunity.Discount_Fee__c", "Opportunity.Final_Loan_Amount__c", "Opportunity.Interest_Rate_Type__c"] })
  wiredDeal({ error, data }) {
    if (data) {
      this.connectedCallback();
    }
    else if (error) {
      console.error(error.body.message);
    }
  }
  connectedCallback() {
    console.log("tab init");
    //this.queryOpportunity();
    this.queryRecordTypeId();
    //console.log(deal);
    //this.deal = deal;
    this.queryUser();
    this.compileFieldPermissions();
    
  }

  handleRefresh() {
    this.connectedCallback();
  }

  refreshNew() {
    if(this.template.querySelector("c-schedule-of-lender-costs-new") != null) {
      this.template.querySelector("c-schedule-of-lender-costs-new").refreshPage();
    }
  }

  queryRecordTypeId() {
    let queryString = `SELECT Id, DeveloperName FROM RecordType WHERE sobjectType = 'Loan_Version__c' AND DeveloperName = '${this.recordTypeName}'`;

    //console.log(queryString);

    query({ queryString }).then((results) => {
      // console.log(results);

      this.recordTypeId = results[0].Id;

      this.queryOpportunity();
    });
  }

  queryOpportunity() {
    const fields = [
      "Name",
      "IO_Term__c",
      "Deal_Loan_Number__c",
      "Swap_Rate__c",
      "Spread_BPS__c",
      "Final_Spread__c",
      "Final_Swap__c",
      "Interest_Rate_Type__c",
      "Final_Loan_Amount__c",
      "Deposit_Collected__c",
      "CAF_Upfront_Fee__c",
      "Deposit_Amount__c",
      "Indicative_Rate_Calc__c",
      "CloseDate",
      "Borrower_Entity__r.Name",
      "Total_Annual_Tax__c",
      "Total_Annual_Insurance__c",
      "Calculated_Origination_Fee__c",
      "Recourse__c",
      "Cash_Management__c",
      "Are_Assets_Coming_Off_Bridge_Line__c",
      "Total_Annual_Cap_Ex__c",
      "Reserve_Cap_Ex__c",
      "Reserve_Insurance__c",
      "Reserve_Tax__c",
      "RecordType__c",
      "LOC_Commitment__c",
      "Current_Loan_Amount__c",
      "Term_Loan_Type__c",
      "Amortization_Term__c",
      "Discount_Fee__c",
      "RecordTypeId",
      "Rate_Lock_Picklist__c"
      //   "(SELECT Id', Name, Loan_Agreement_Name__c,  Finalized__c FROM Loan_Versions__r Order By CreatedDate ASC)",
    ];

    const loanVersionFields = ["Id"];

    let queryString = `SELECT Id, ${fields.join(",")}`;
    queryString += `, (SELECT Id, Name, Finalized__c, Full_Name__c, `;
    queryString += ` Total_Annual_Tax__c, Total_Annual_Insurance__c, Total_Annual_Cap_Ex__c, Reserve_Tax__c, Reserve_Insurance__c, Holdback_Reserve__c,`;
    queryString += ` Reserve_Cap_Ex__c, Holdback_Reserve_Override__c, Holdback_Reserve_Month_Multiplier__c, Interest_Rate_Type__c, Deposit_Lender_Out_of_Pocket__c, Legal_Fee__c, Bridge_Payoff__c, Installment_Comment__c `;
    queryString += ` FROM Loan_Versions__r WHERE RecordTypeId = '${this.recordTypeId}' Order By CreatedDate ASC)`;
    queryString += ` FROM Opportunity WHERE Id = '${this.recordId}'`;

    //console.log(queryString);

    query({ queryString: queryString }).then((results) => {
      const deal = results[0];
      console.log("--deal queried--");
      console.log(deal);
      if (!deal.Loan_Versions__r) {
        deal.Loan_Versions__r = [];
      }

      if (deal.Borrower_Entity__c && deal.Borrower_Entity__r) {
        deal.Borrower_Name = deal.Borrower_Entity__r.Name;
      }

      const loanVersions = []; //JSON.parse(JSON.stringify(this.loanVersions));
      deal.Loan_Versions__r.forEach((version, index) => {
        if (version.Finalized__c) {
          this.versionFinalized = true;
          this.finalizedVersionId = version.Id;
          this.selectedLoanVersionId = version.Id;
        }

        if (index === deal.Loan_Versions__r.length - 1) {
          deal.Total_Annual_Tax__c = version.Total_Annual_Tax__c;
          deal.Total_Annual_Insurance__c = version.Total_Annual_Insurance__c;
          deal.Total_Annual_Cap_Ex__c = version.Total_Annual_Cap_Ex__c;
          deal.Reserve_Tax__c = version.Reserve_Tax__c;
          deal.Reserve_Insurance__c = version.Reserve_Insurance__c;
          deal.Reserve_Cap_Ex__c = version.Reserve_Cap_Ex__c;
          deal.Holdback_Reserve_Override__c =
            version.Holdback_Reserve_Override__c;
          deal.Holdback_Reserve_Month_Multiplier__c =
            version.Holdback_Reserve_Month_Multiplier__c;
          deal.Interest_Rate_Type__c = version.Interest_Rate_Type__c;
          deal.Deposit_Lender_Out_of_Pocket__c =
            version.Deposit_Lender_Out_of_Pocket__c;
          deal.Legal_Fee__c =
            version.Legal_Fee__c;
          deal.Bridge_Payoff__c = version.Bridge_Payoff__c;
          deal.Installment_Comment__c = version.Installment_Comment__c;
        }
        loanVersions.push({
          label: version.Full_Name__c,
          value: version.Id
        });
      });

      let sessionData = sessionStorage.getItem(`scheduleData-${this.recordId}`);
      if (sessionData) {
        const calculatedData = JSON.parse(sessionData);
        console.log(calculatedData);
        deal.Total_Annual_Tax__c = calculatedData.Total_Annual_Tax__c;
        deal.Total_Annual_Insurance__c =
          calculatedData.Total_Annual_Insurance__c;
        deal.Total_Annual_Cap_Ex__c = calculatedData.Total_Annual_Cap_Ex__c;
        deal.Reserve_Tax__c = calculatedData.Reserve_Tax__c;
        deal.Reserve_Insurance__c = calculatedData.Reserve_Insurance__c;
        deal.Reserve_Cap_Ex__c = calculatedData.Reserve_Cap_Ex__c;
        deal.Holdback_Reserve_Override__c =
          calculatedData.Holdback_Reserve_Override__c;
        deal.Holdback_Reserve_Month_Multiplier__c =
          calculatedData.Holdback_Reserve_Month_Multiplier__c;
        deal.Interest_Rate_Type__c = calculatedData.Interest_Rate_Type__c;
        deal.Deposit_Lender_Out_of_Pocket__c =
          calculatedData.Deposit_Lender_Out_of_Pocket__c;
        deal.Bridge_Payoff__c = calculatedData.Bridge_Payoff__c;
        deal.Installment_Comment__c = calculatedData.Installment_Comment__c;
        deal.Reserve_Tax__c = calculatedData.Reserve_Tax__c;
        deal.Total_Annual_Insurance__c =
          calculatedData.Total_Annual_Insurance__c;
        deal.Reserve_Insurance__c = calculatedData.Reserve_Insurance__c;
        deal.Total_Annual_Cap_Ex__c = calculatedData.Total_Annual_Cap_Ex__c;
        deal.Reserve_Cap_Ex__c = calculatedData.Reserve_Cap_Ex__c;
        deal.Bridge_Payoff__c = calculatedData.Bridge_Payoff__c;
        deal.Deposit_Lender_Out_of_Pocket__c =
          calculatedData.Deposit_Lender_Out_of_Pocket__c;
        deal.Legal_Fee__c =
          calculatedData.Legal_Fee__c;        
        deal.Holdback_Reserve_Month_Multiplier__c =
          calculatedData.Holdback_Reserve_Month_Multiplier__c;
        deal.Installment_Comment__c = calculatedData.Installment_Comment__c;
      }

      if (!deal.Installment_Comment__c) {
        deal.Installment_Comment__c =
          "*** Title to pay all taxes due within 90 days";
      }

      //console.log(loanVersions);

      this.loanVersions = loanVersions;

      // console.log(this.loanVersions);

      // deal.Underwriter_Vacancy_and_Credit_Loss_Perc__c =
      //   deal.Static_Vacancy__c &&
      //   deal.Credit_Loss_Adjustment__c &&
      //   deal.Static_Vacancy__c + deal.Credit_Loss_Adjustment__c;

      //console.log(deal);

      this.deal = deal;
      
    }).then(() => {
      this.refreshNew()
    });

    //return deal;
  }

  get loanVersionOptions() {
    //const loanVersions =

    return this.versionFinalized
      ? this.loanVersions
      : [{ label: "", value: "" }].concat(this.loanVersions);
  }

  get showNew() {
    if (this.versionFinalized) {
      return false;
    }

    return this.selectedLoanVersionId ? false : true;
  }

  get showButtonsFinalized() {
    return this.selectedLoanVersionId == this.finalizedVersionId;
  }

  get showButtonsUnfinalized() {
    return !this.versionFinalized;
  }

  get showSelectedButtons() {
    return this.selectedLoanVersionId;
  }

  get dealQueried() {
    // console.log(this.deal.Id === true);
    return this.deal.Id;
  }

  selectLoanVersion(event) {
    console.log(event.target.value);

    this.selectedLoanVersionId = event.target.value;

    if (this.selectedLoanVersionId) {
      if (this.template.querySelector("c-schedule-of-lender-costs-edit")) {
        // console.log(
        //   this.template.querySelector("c-schedule-of-lender-costs-edit")
        // );
        this.template
          .querySelector("c-schedule-of-lender-costs-edit")
          .queryLoanVersion(this.selectedLoanVersionId);
      }
    }
  }

  createLoanVersion() {
    //console.log("save");
    this.showSpinner = true;
    const loanVersion = this.template
      .querySelector("c-schedule-of-lender-costs-new")
      .returnLoanVersion();

    console.log(loanVersion);

    loanVersion.Deal__c = this.recordId;
    loanVersion.RecordTypeId = this.recordTypeId;
    loanVersion.sobjectType = "Loan_Version__c";
    upsert({ records: [loanVersion] }).then((results) => {
      this.selectedLoanVersionId = results[0].Id;
      this.queryOpportunity();
      this.generateDocument();
    })
    .then(() => {
      this.showSpinner = false;
    });

  }

  finalizeVersion() {
    //console.log("finalize"); 
    this.showSpinner = true;
    const loanVersion = {
      sobjectType: "Loan_Version__c",
      Id: this.selectedLoanVersionId,
      Finalized__c: true
    };

    upsert({ records: [loanVersion] }).then((results) => {
      console.log("results");
      this.versionFinalized = true;
      this.finalizedVersionId = this.selectedLoanVersionId;
    })
    .then(() => {
      this.showSpinner = false;
    });
  }

  unfinalizeVersion() {
    //console.log("unfinalize");
    //console.log("finalize");
    this.showSpinner = true;
    const loanVersion = {
      sobjectType: "Loan_Version__c",
      Id: this.selectedLoanVersionId,
      Finalized__c: false
    };

    upsert({ records: [loanVersion] }).then((results) => {
      //console.log("results");
      this.versionFinalized = false;
      this.finalizedVersionId = "";
    })
    .then(() => {
      this.showSpinner = false;
    });
  }

  sendEmail() {
    console.log("send email");

    this.template.querySelector("c-email-composer").send();
  }

  openEmailModal() {
    console.log("open email modal");

    compileEmailTemplate({
      templateId: this.templateId,
      whatId: this.recordId
    }).then((result) => {
      const defaults = JSON.parse(result);
      //console.log(defaults);
      //console.log(defaults.htmlBody);
      // this.emailInputs = { subject: defaults.subject, body: defaults.htmlBody };
      //this.template.querySelector("c-modal").toggleModal();
      const emailEvent = new CustomEvent("initemail", {
        detail: defaults
      });
      this.dispatchEvent(emailEvent);
    });
  }

  closeEmailModal() {
    this.template.querySelector("c-modal").toggleModal();
  }

  queryLoanVersion = async (versionId) => {
    const fields = ["Name", "Full_Name__c"];
    let queryString = `SELECT Id, ${fields.join(",")}`;
    queryString += ` FROM Loan_Version__c WHERE Id = '${versionId}'`;
    //console.log(queryString);

    const results = await query({ queryString });

    // console.log(results);

    return results[0];
  };

  generateDocument = async () => {
    this.showSpinner = true;
    const loanVersion = await this.queryLoanVersion(this.selectedLoanVersionId);
    // console.log(loanVersion);

    // console.log(this.selectedLoanVersionId);

    const generationEvent = new CustomEvent("generate", {
      detail: loanVersion
    });
    this.dispatchEvent(generationEvent);
    this.showSpinner = false;
  };

  queryUser() {
    getUser({})
      .then((results) => {
        console.log(results);
        let senderEmails = [{ label: results.Email, value: results.Id }];
        this.senderEmails = senderEmails;
        //this.user = results;
      })
      .catch((error) => {
        console.log(error);
        console.log("user error");
      });
  }

  compileFieldPermissions() {
    let fields = [
      "Name",
      "Finalized__c"
    ];
    compileFieldPermissions({
      sObjectName: "Loan_Version__c",
      fields: fields
    }).then((results) => {
      console.log("field permission results");
      console.log(results);

      this.permissionsMap = results;
    });
  }
}