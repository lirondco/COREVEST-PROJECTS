import { LightningElement, api, wire } from "lwc";
import query from "@salesforce/apex/lightning_Util.query";

import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";

import calcMessage from "@salesforce/messageChannel/ScheduleLoanAgreementMessage__c";

export default class ScheduleOfLenderCostsEdit extends LightningElement {
  @api recordId;
  loanFees;
  loanVersion;
  showDiscountFee = false;
  showEarlyLockField = false;

  connectedCallback() {
    console.log(this.recordId);

    console.log("edit init");
    this.queryLoanVersion(this.recordId);
    this.subscribeMessageChannel();
  }

  @wire(MessageContext)
  messageContext;

  @api
  queryLoanVersion(versionId) {
    console.log("--edit query--");

    const fields = [
      "Early_Lock_Deposit__c",
      "Loan_Fees_JSON__c",
      "Final_Interest_Rate__c",
      "Required_Holdback_Reserve__c",
      "Total_Sources__c",
      "Stub_Interest__c",
      "Total_Lender__c",
      "Proceeds_Paid_To_Escrow__c",
      "Monthly_Tax__c",
      "Total_Reserve_Tax__c",
      "Monthly_Insurance__c",
      "Total_Reserve_Insurance__c",
      "Monthly_Cap_Ex__c",
      "Total_Reserve_Cap_Ex__c",
      "Monthly_Payment__c",
      "Total_Reserve_at_Closing__c",
      "Total_Third_Party__c",
      "Net_Proceeds_to_Borrower__c",
      "Total_Uses__c",
      "Holdback_Reserve__c",
      "Holdback_Reserve_Override__c",
      "Interest_Rate_Type__c",
      "Term__c",
      "Legal_Fee__c",
      "Discount_Fee__c",
      "Discount_Fee_Number__c",
      "Deal__r.Rate_Lock_Picklist__c"
    ];
    let queryString = `SELECT Id, ${fields.join(",")}`;
    queryString += ` FROM Loan_Version__c WHERE Id = '${versionId}'`;
    //console.log(queryString);

    query({ queryString }).then((results) => {
      let loanVersion = results[0];

      let loanFees = JSON.parse(results[0].Loan_Fees_JSON__c);

      loanFees.forEach((loanFee) => {
        loanFee.original = Object.assign({}, loanFee);
      });
      if(loanVersion.Discount_Fee__c) {
        this.showDiscountFee = true;
      }

      if(loanVersion.Deal__r.Rate_Lock_Picklist__c == "Early Rate Locked") {
        this.showEarlyLockField = true;
      } 

      this.loanFees = loanFees;
      console.log(loanVersion);
      this.sendCalculatedFields(loanVersion);
    });

    //
  }

  subscribeMessageChannel() {
    if (this.subscription) {
      return;
    }
    this.subscription = subscribe(
      this.messageContext,
      calcMessage,
      (message) => {
        this.handleMessage(message);
      },
      { scope: APPLICATION_SCOPE }
    );
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  handleMessage(message) {
    console.log("--receiving message--");
    console.log(message);
    //this.calculatedFields();

    if (message.type === "init") {
      //this.updateCalculatedFields();
      this.queryLoanVersion(this.recordId);
    }
  }

  sendCalculatedFields(loanVersion) {
    console.log(loanVersion);

    let calculatedFields = {
      Final_Interest_Rate__c: loanVersion.Final_Interest_Rate__c,
      Holdback_Reserve__c: loanVersion.Holdback_Reserve__c,
      Required_Holdback_Reserve__c: loanVersion.Required_Holdback_Reserve__c,
      Total_Sources__c: loanVersion.Total_Sources__c,
      Stub_Interest__c: loanVersion.Stub_Interest__c,
      Total_Lender__c: loanVersion.Total_Lender__c,
      Proceeds_Paid_To_Escrow__c: loanVersion.Proceeds_Paid_To_Escrow__c,
      Monthly_Tax__c: loanVersion.Monthly_Tax__c,
      Total_Reserve_Tax__c: loanVersion.Total_Reserve_Tax__c,
      Monthly_Insurance__c: loanVersion.Monthly_Insurance__c,
      Total_Reserve_Insurance__c: loanVersion.Total_Reserve_Insurance__c,
      Monthly_Cap_Ex__c: loanVersion.Monthly_Cap_Ex__c,
      Total_Reserve_Cap_Ex__c: loanVersion.Total_Reserve_Cap_Ex__c,
      Monthly_Payment__c: loanVersion.Monthly_Payment__c,
      Total_Reserve_at_Closing__c: loanVersion.Total_Reserve_at_Closing__c,
      Total_Third_Party__c: loanVersion.Total_Third_Party__c,
      Net_Proceeds_to_Borrower__c: loanVersion.Net_Proceeds_to_Borrower__c,
      Total_Uses__c: loanVersion.Total_Uses__c,
      Holdback_Reserve_Override__c: loanVersion.Holdback_Reserve_Override__c,
      Interest_Rate_Type__c: loanVersion.Interest_Rate_Type__c
    };

    console.log(calculatedFields);

    publish(this.messageContext, calcMessage, {
      calculatedFields: calculatedFields,
      type: "update"
    });
  }
}