import { LightningElement, api, track } from "lwc";

import query from "@salesforce/apex/lightning_Util.query";
import upsert from "@salesforce/apex/lightning_Util.upsertRecords";
import compileEmailTemplate from "@salesforce/apex/lightning_Util.compileEmailTemplate";
import getUser from "@salesforce/apex/lightning_Util.getUser";
import compileFieldPermissions from "@salesforce/apex/lightning_Util.compileFieldPermissions";

export default class LoanAgreementTab extends LightningElement {
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

  agreementFinalized = false;
  finalizedAgreementId = "";

  recordTypeName = "Loan_Agreement";
  recordTypeId = "";

  templateId = "00X0a0000017EDyEAM";
  emailInputs = {
    subject: "",
    // to: "",
    // from: [],
    // to: [],
    body: ""
  };

  showSpinner = false;

  connectedCallback() {
    console.log("init");
    this.queryRecordTypeId();

    //console.log(deal);
    //this.deal = deal;
    this.queryUser();
    this.compileFieldPermissions();
  }

  queryRecordTypeId() {
    let queryString = `SELECT Id, DeveloperName FROM RecordType WHERE sobjectType = 'Loan_Version__c' AND DeveloperName = '${this.recordTypeName}'`;

    //console.log(queryString);

    query({ queryString }).then((results) => {
      console.log(results);

      this.recordTypeId = results[0].Id;

      this.queryOpportunity();
    });
  }

  queryOpportunity() {
    const fields = [
      "Borrower_Entity__c",
      "Borrower_Entity__r.Name",
      "Origination_Fee__c",
      "Final_Interest_Rate_Calc__c",
      "Monthly_Payment__c",
      "Property_Management_Adjustment__c",
      "Static_Vacancy__c",
      "Credit_Loss_Adjustment__c",
      "IO_Term__c",
      "First_Payment_Date__c",
      "First_Payment_Date1__c",
      "Term_Loan_Type_Months__c",
      "Deposit_Insurance_Review__c",
      "Deal_Loan_Number__c",
      "Swap_Rate__c",
      "Spread_BPS__c",
      "Final_Spread__c",
      "Final_Swap__c",
      "Interest_Rate_Type__c",
      // "Final_Loan_Amount__c",
      "Deposit_Lender_Out_of_Pocket__c",
      "Deposit_Collected__c",
      "CAF_Upfront_Fee__c",
      "Deposit_Amount__c",
      "Indicative_Rate_Calc__c",
      "CloseDate",
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
      "YM_Prepayment_Penalty__c",
      "YM_Prepayment_Penalty_Description__c",
      "Current_Loan_Amount__c",
      "Initial_Monthly_Debt_Service_Payment__c",
      "Min_DSCR__c",
      //"(SELECT Id, Name, Loan_Agreement_Name__c,  Finalized__c FROM Loan_Versions__r Order By CreatedDate ASC)",
      "(Select Id, Contact__c, Contact__r.Name, Entity_Type__c, Business_Entity__c, Business_Entity__r.Name FROM Deal_Contacts__r WHERE Entity_Type__c IN ('Pledgor', 'Sponsor'))"
    ];

    const loanVersionFields = ["Id"];

    let queryString = `SELECT Id, ${fields.join(",")}`;
    queryString += `, (SELECT Id, Name, Finalized__c, Full_Name__c FROM Loan_Versions__r WHERE RecordTypeId = '${this.recordTypeId}' Order By CreatedDate ASC)`;
    queryString += ` FROM Opportunity WHERE Id = '${this.recordId}'`;

    console.log(queryString);

    query({ queryString: queryString }).then((results) => {
      const deal = results[0];
      // console.log(deal);
      if (!deal.Deal_Contacts__r) {
        deal.Deal_Contacts__r = [];
      }

      //const borrowers = [];
      const pledgors = [];
      const sponsors = [];

      if (deal.Borrower_Entity__c && deal.Borrower_Entity__r) {
        deal.Borrower__c = deal.Borrower_Entity__r.Name;
      }

      deal.Deal_Contacts__r.forEach((dc) => {
        // if (
        //   dc.Business_Entity__c &&
        //   dc.Entity_Type__c === "Pledgor" //|| dc.Entity_Type__c === "Borrower")
        // ) {
        //   if (dc.Entity_Type__c === "Pledgor") {
        //     if (dc.Business_Entity__c) {
        //       pledgors.push(dc.Business_Entity__r.Name);
        //     } else if (dc.Contact__c) {
        //       pledgors.push(dc.Contact__r.Name);
        //     }
        //   }
        //   // else if (dc.Entity_Type__c == "Borrower") {
        //   //   if (dc.Business_Entity__c) {
        //   //     borrowers.push(dc.Business_Entity__r.Name);
        //   //   } else if (dc.Contact__c) {
        //   //     borrowers.push(dc.Contact__r.Name);
        //   //   }
        //   // }
        // } else if (dc.Contact__c && dc.Entity_Type__c === "Sponsor") {
        //   sponsors.push(dc.Contact__r.Name);
        // }

        if (dc.Entity_Type__c == "Pledgor") {
          if (dc.Business_Entity__c && dc.Business_Entity__r) {
            pledgors.push(dc.Business_Entity__r.Name);
          } else if (dc.Contact__c && dc.Contact__c) {
            pledgors.push(dc.Contact__r.Name);
          }
        } else if (dc.Entity_Type__c == "Sponsor") {
          if (dc.Contact__c && dc.Contact__r) {
            sponsors.push(dc.Contact__r.Name);
          }
        }
      });

      // if(deal.Borrower__r){
      //   deal.Borrower__c = deal.Borrower__r.Name;
      // }

      //deal.Borrower__c = borrowers.join(",");
      deal.Pledgor__c = pledgors.join(",");
      deal.Sponsor__c = sponsors.join(",");

      if (!deal.Loan_Versions__r) {
        deal.Loan_Versions__r = [];
      }

      const loanVersions = []; //JSON.parse(JSON.stringify(this.loanVersions));
      deal.Loan_Versions__r.forEach((version) => {
        if (version.Finalized__c) {
          this.agreementFinalized = true;
          this.finalizedAgreementId = version.Id;
          this.selectedLoanVersionId = version.Id;
        }

        loanVersions.push({
          label: version.Full_Name__c,
          value: version.Id
        });
      });

      console.log(loanVersions);

      this.loanVersions = loanVersions;

      // console.log(this.loanVersions);

      // deal.Underwriter_Vacancy_and_Credit_Loss_Perc__c =
      //   deal.Static_Vacancy__c &&
      //   deal.Credit_Loss_Adjustment__c &&
      //   deal.Static_Vacancy__c + deal.Credit_Loss_Adjustment__c;

      console.log(deal);

      this.deal = deal;
    });

    //return deal;
  }

  get loanVersionOptions() {
    //const loanVersions =

    return this.agreementFinalized
      ? this.loanVersions
      : [{ label: "", value: "" }].concat(this.loanVersions);
  }

  get showNew() {
    if (this.agreementFinalized) {
      return false;
    }

    return this.selectedLoanVersionId ? false : true;
  }

  get showButtonsFinalized() {
    return this.selectedLoanVersionId == this.finalizedAgreementId;
  }

  get showButtonsUnfinalized() {
    return !this.agreementFinalized;
  }

  get showSelectedButtons() {
    return this.selectedLoanVersionId;
  }

  selectLoanVersion(event) {
    console.log(event.target.value);

    this.selectedLoanVersionId = event.target.value;
  }

  refreshNew() {
    this.template.querySelector("c-loan-agreement-new").refresh();
  }

  createLoanAgreement() {
    this.showSpinner = true;
    console.log("save");

    const loanVersion = this.template
      .querySelector("c-loan-agreement-new")
      .returnLoanVersion();

    console.log(loanVersion);
    loanVersion.Deal__c = this.recordId;

    upsert({ records: [loanVersion] }).then((results) => {
      this.selectedLoanVersionId = results[0].Id;
      this.queryOpportunity();
      this.generateDocument(this.selectedLoanVersionId);
      console.log(results);
    })
    .then(() => {
      this.showSpinner = false;
    });

    //console.log(results);
  }

  finalizeAgreement() {
    this.showSpinner = true;
    console.log("finalize");

    const loanVersion = {
      sobjectType: "Loan_Version__c",
      Id: this.selectedLoanVersionId,
      Finalized__c: true
    };

    upsert({ records: [loanVersion] }).then((results) => {
      console.log("results");
      this.agreementFinalized = true;
      this.finalizedAgreementId = this.selectedLoanVersionId;
    })
    .then(() => {
      this.showSpinner = false;
    });
  }

  unfinalizeAgreement() {
    this.showSpinner = true;
    console.log("unfinalize");
    console.log("finalize");

    const loanVersion = {
      sobjectType: "Loan_Version__c",
      Id: this.selectedLoanVersionId,
      Finalized__c: false
    };

    upsert({ records: [loanVersion] }).then((results) => {
      console.log("results");
      this.agreementFinalized = false;
      this.finalizedAgreementId = "";
    })
    .then(() => {
      this.showSpinner = false;
    });
  }

  sendEmail() {
    console.log("send email");
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
    const fields = [
      "Deal__r.Name",
      "Deal__r.CloseDate",
      "Deal__r.IO_Term__c",
      "Deal__r.Amortization_Term__c",
      "Deal__r.Term_Loan_Type__c",
      "Name",
      "Borrower__c",
      "Closing_Date_Insurance_Reserve_Deposit__c",
      "Closing_Date_Tax_Reserve_Deposit__c",
      "Deal__c",
      "Final_Interest_Rate__c",
      "Final_Loan_Amount__c",
      "Finalized__c",
      "InitialMonthlyInsuranceReserveDeposit__c",
      "Initial_Monthly_Tax_Reserve_Deposit__c",
      "Interest_Only__c",
      "Loan_Version_Emailed__c",
      "Loan_Version_Number__c",
      "Maturity_Date__c",
      "Monthly_Payment__c",
      "Origination_Fee__c",
      "Loan_Agreement_Name__c",
      "Pledgor__c",
      "Property_Management_Adjustment__c",
      "Recourse__c",
      "Required_DSCR_Non_Recourse_Only__c",
      "Required_Holdback_Reserve__c",
      "Required_Rent_to_Debt_Service_Ratio__c",
      "Sponsor__c",
      "Underwriter_Vacancy_and_Credit_Loss_Perc__c",
      "Full_Name__c",
      "Cash_Management__c",
      "YM_Prepayment_Penalty__c",
      "YM_Prepayment_Penalty_Description__c",
      "Holdback_Reserve__c",
      "Principal_Amortization_Period__c"
    ];
    let queryString = `SELECT Id, ${fields.join(",")}`;
    queryString += ` FROM Loan_Version__c WHERE Id = '${versionId}'`;
    console.log(queryString);

    const results = await query({ queryString });

    // console.log(results);

    return results[0];

    // query({ queryString: queryString }).then((results) => {
    //   const loanVersion = results[0];
    // });
  };

  get dealQueried() {
    // console.log(this.deal.Id === true);
    return this.deal.Id;
  }

  generateDocument = async () => {
    this.showSpinner = true;
    const loanVersion = await this.queryLoanVersion(this.selectedLoanVersionId);

    console.log(loanVersion);

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
    let fields = ["Name", "Finalized__c"];
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