import { LightningElement, api } from "lwc";

import getRecordDetails from "@salesforce/apex/ConfirmationOfTermsController.getRecordDetails";

import getWrapperBundle from "@salesforce/apex/ConfirmationOfTermsController.getWrapperBundle";
import submitApproval from "@salesforce/apex/ConfirmationOfTermsController.submitApproval";
import recallApproval from "@salesforce/apex/ConfirmationOfTermsController.recallApproval";

import orignationsApproval from "@salesforce/apex/ConfirmationOfTermsController.originatorApprove";
import orignationsReject from "@salesforce/apex/ConfirmationOfTermsController.originatorReject";

import underwriterApproval from "@salesforce/apex/ConfirmationOfTermsController.underwriterApprove";
import underwriterReject from "@salesforce/apex/ConfirmationOfTermsController.underwriterReject";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getApprovalPicklists from "@salesforce/apex/ConfirmationOfTermsController.getApprovalPicklists";

export default class ConfirmationTerms extends LightningElement {
  @api
  recordId = "0067h00000C2tqrAAB";

  activeSections = ["originations", "underwriter"];

  picklists = [{ label: "", value: "" }];
  selectedProcessInstanceId = null;

  comments = {};
  submissionDetails = {};
  currentDetails = {};

  isCloserPanel = false;
  isEnabledCloserPanel = false;
  isEnabledOriginatorPanel = false;
  isEnabledUnderwriterPanel = false;
  isOriginatorPanel = false;
  isUnderWriterPanel = false;

  showButtonsCloser = false;
  showButtonsOriginator = false;
  showButtonsUnderwriter = false;

  closerReviewComment = "";
  origingatorReviewComment = "";
  underwriterReviewComment = "";

  isRejection = false;

  isInApproval = false;

  historyChange(event) {
    const processInstanceId = event.detail.value;

    console.log(processInstanceId);

    // if(!processInstanceId){
    //   processInstanceId
    // }
    this.selectedProcessInstanceId = processInstanceId
      ? processInstanceId
      : null;

    this.getRecordDetails();
    this.getWrapperBundle();
  }

  get showSubmissionButton() {
    return !this.isInApproval && !this.selectedProcessInstanceId;
  }

  getRecordDetails() {
    // console.log()

    getRecordDetails({
      recordId: this.recordId,
      processInstanceId: this.selectedProcessInstanceId
    })
      .then((results) => {
        // console.log(results);
        const parsedResults = JSON.parse(results);
        console.log(parsedResults);
        this.comments = parsedResults.comments;
        this.submissionDetails = parsedResults.submissionDetails;
        this.currentDetails = parsedResults.currentDetails;

        // console.log("comments=>", this.comments);
        // console.log("submissionDetails=>", this.submissionDetails);
        // console.log("currentDetails=>", this.currentDetails);

        // console.log("empty");
      })
      .catch((error) => {
        console.log("error");
        console.log(error);
      });
  }

  getWrapperBundle() {
    getWrapperBundle({
      recordId: this.recordId,
      processInstanceId: this.selectedProcessInstanceId
    })
      .then((results) => {
        const parsedResults = JSON.parse(results);

        console.log("wrapper bundle=>", parsedResults);
        this.isInApproval = parsedResults.isInApproval;
        this.isCloserPanel = parsedResults.isCloserPanel;
        this.isEnabledCloserPanel = parsedResults.isEnabledCloserPanel;

        this.isEnabledOriginatorPanel = parsedResults.isEnabledOriginatorPanel;
        this.isEnabledUnderwriterPanel =
          parsedResults.isEnabledUnderWriterPanel;
        this.isOriginatorPanel = parsedResults.isOriginatorPanel;
        this.isUnderWriterPanel = parsedResults.isUnderWriterPanel;

        this.showButtonsCloser = parsedResults.isCloserPanel;
        this.showButtonsOriginator = parsedResults.isOriginatorPanel;
        this.showButtonsUnderwriter = parsedResults.isUnderWriterPanel;
        
        // console.log("isCloserPanel=>", this.isCloserPanel);
        // console.log("isEnabledCloserPanel=>", this.isEnabledCloserPanel);
        // console.log(
        //   "isEnabledOriginatorPanel=>",
        //   this.isEnabledOriginatorPanel
        // );
        // console.log(
        //   "isEnabledUnderwriterPanel=>",
        //   this.isEnabledUnderwriterPanel
        // );
        // console.log("isOriginatorPanel=>", this.isOriginatorPanel);
        // console.log("isUnderWriterPanel=>", this.isUnderWriterPanel);
      })
      .catch((error) => {
        console.log("error");
        this.showErrorToast(error.body.message);
        console.log(error);
      });
  }

  init() {
    getApprovalPicklists({ recordId: this.recordId })
      .then((results) => {
        console.log("results");
        console.log(results);
        this.picklists = results;

        if (
          results.length > 1 &&
          (results[1].label.includes("Submitted") ||
            results[1].label.includes("Approved"))
        ) {
          this.selectedProcessInstanceId = results[1].value;
        }

        this.getRecordDetails();
        this.getWrapperBundle();
      })
      .catch((error) => {
        console.log(error);
        console.log("error");
      });
  }

  connectedCallback() {
    //hello
    //
    this.init();
  }

  openModal(event) {
    console.log("open modal");
    let validated = true;

    if (this.isUnderWriterPanel && this.isEnabledUnderwriterPanel) {
      //do validation for the values to be populated;
      if(!this.currentDetails.amortizationStatus) {
        const amortizationStatus = this.template.querySelector('lightning-combobox[data-field="amortizationStatus"]');
        amortizationStatus.required = true;
        amortizationStatus.reportValidity();
        validated = false;
      }
    }

    if (this.isOriginatorPanel && this.isEnabledOriginatorPanel) {
      if (!this.currentDetails.depositCollected) {
        const depositCollected = this.template
        .querySelector(['[data-field="depositCollected"]']);
        depositCollected.required = true;
        depositCollected.reportValidity();
        validated = false;
      }
    }

    if (validated) {
      this.isRejection = false;
      this.closerReviewComment = "";
      this.origingatorReviewComment = "";
      this.underwriterReviewComment = "";

      this.template.querySelector("c-modal").openModal();
    }
  }

  openOriginationsModalReject(event) {
    this.isRejection = true;
    this.closerReviewComment = "";
    this.origingatorReviewComment = "";
    this.underwriterReviewComment = "";
    this.template.querySelector("c-modal").openModal();
  }

  openModalReject(event) {
    this.isRejection = true;
    this.closerReviewComment = "";
    this.origingatorReviewComment = "";
    this.underwriterReviewComment = "";
    this.template.querySelector("c-modal").openModal();

    console.log(this.isRejection);
  }

  closeModal(event) {
    this.template.querySelector("c-modal").closeModal();
  }

  submitApproval(event) {
    console.log("submitApproval");
    console.log("isRejection", this.isRejection);

    const comment = this.closerReviewComment;
    const recordId = this.recordId;

    if (!comment) {
      console.log("here");
      this.template
        .querySelector(['[data-field="closerReviewComment"]'])
        .reportValidity();
      return;
    }

    if (this.isRejection) {
      console.log(comment);
      this.showButtonsCloser = false;
      this.template.querySelector("c-modal").showSpinner();
      recallApproval({ recordId, comment })
        .then((results) => {
          this.template.querySelector("c-modal").hideSpinner();
          this.closeModal();
          this.showButtonsCloser = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showButtonsCloser = true;
          this.showErrorToast(error.body.message);
          this.template.querySelector("c-modal").hideSpinner();
        });
    } else {
      const submissionDetails = JSON.stringify(this.submissionDetails);
      // console.log(submissionDetails);
      // console.log(recordId);
      // console.log(comment);
      this.showButtonsCloser = false;
      this.template.querySelector("c-modal").showSpinner();
      submitApproval({ recordId, comment, submissionDetails })
        .then((results) => {
          console.log("approval went through");
          this.template.querySelector("c-modal").hideSpinner();

          this.closeModal();
          this.showButtonsCloser = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showErrorToast(error.body.message);
          this.showButtonsCloser = true;
          this.template.querySelector("c-modal").hideSpinner();
        });
    }
  }

  submitOriginator(event) {
    console.log("submitOriginator");
    const comment = this.origingatorReviewComment;
    const recordId = this.recordId;
    if (!comment) {
      console.log("here");
      this.template
        .querySelector(['[data-field="origingatorReviewComment"]'])
        .reportValidity();
      return;
    }

    if (this.isRejection) {
      console.log(comment);
      this.showButtonsOriginator = false;
      this.template.querySelector("c-modal").showSpinner();
      orignationsReject({ recordId, comment })
        .then((results) => {
          this.template.querySelector("c-modal").hideSpinner();
          this.closeModal();
          this.showButtonsOriginator = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showErrorToast(error.body.message);
          this.showButtonsOriginator = true;
          this.template.querySelector("c-modal").hideSpinner();
        });
    } else {
      const currentDetails = JSON.stringify(this.currentDetails);
      const comments = JSON.stringify(this.comments);
      // console.log(submissionDetails);
      // console.log(recordId);
      // console.log(comment);
      this.showButtonsOriginator = false;
      this.template.querySelector("c-modal").showSpinner();
      orignationsApproval({ recordId, comment, currentDetails, comments })
        .then((results) => {
          console.log("approval went through");
          this.template.querySelector("c-modal").hideSpinner();

          this.closeModal();
          this.showButtonsOriginator = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showErrorToast(error.body.message);
          this.showButtonsOriginator = true;
          this.template.querySelector("c-modal").hideSpinner();
        });
    }
  }

  submitUnderwriter(event) {
    const comment = this.underwriterReviewComment;
    const recordId = this.recordId;
    if (!comment) {
      console.log("here");
      this.template
        .querySelector(['[data-field="underwriterReviewComment"]'])
        .reportValidity();
      return;
    }

    if (this.isRejection) {
      console.log(comment);
      this.showButtonsUnderwriter = false;
      this.template.querySelector("c-modal").showSpinner();
      underwriterReject({ recordId, comment })
        .then((results) => {
          this.template.querySelector("c-modal").hideSpinner();
          this.closeModal();
          this.showButtonsUnderwriter = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showErrorToast(error.body.message);
          this.showButtonsUnderwriter = true;
          this.template.querySelector("c-modal").hideSpinner();
        });
    } else {
      const currentDetails = JSON.stringify(this.currentDetails);
      const comments = JSON.stringify(this.comments);
      // console.log(submissionDetails);
      // console.log(recordId);
      // console.log(comment);
      this.showButtonsUnderwriter = false;
      this.template.querySelector("c-modal").showSpinner();
      underwriterApproval({ recordId, comment, currentDetails, comments })
        .then((results) => {
          console.log("approval went through");
          this.template.querySelector("c-modal").hideSpinner();

          this.closeModal();
          this.showButtonsUnderwriter = true;
          this.init();
        })
        .catch((error) => {
          console.log("error");
          console.log(error);
          this.showErrorToast(error.body.message);

          this.showButtonsUnderwriter = true;
          this.template.querySelector("c-modal").hideSpinner();
        });
    }
  }

  handleCurrentDetailsUpdate(event) {
    const value = event.detail.value;
    // console.log(value);
    const fieldName = event.target.getAttribute("data-field");
    // console.log(fieldName);

    this.currentDetails[fieldName] = value;
    // console.log("handle current details update");
  }

  handleCommentsUpdate(event) {
    const value = event.detail.value;
    // console.log(value);
    const fieldName = event.target.getAttribute("data-field");
    // console.log(fieldName);

    this.comments[fieldName] = value;
  }

  handleModalComments(event) {
    const value = event.detail.value;
    // console.log(value);
    const fieldName = event.target.getAttribute("data-field");
    // console.log(fieldName);

    this[fieldName] = value;
  }

  get underwriterFieldsDisabled() {
    return !this.isEnabledUnderwriterPanel || !this.isUnderWriterPanel;
  }

  get originationsFieldsDisabled() {
    return !this.isEnabledOriginatorPanel || !this.isOriginatorPanel;
  }

  get picklistOptions() {
    return [
      { label: "", value: "" },
      { label: "Yes", value: "Yes" },
      { label: "No", value: "No" }
    ];
  }

  get amortizationStatusOptions() {
    return [
      { label: "", value: "" },
      { label: "Loan Amortized", value: "Loan Amortized" },
      { label: "Interest Only", value: "Interest Only" }
    ]
  }

  showErrorToast(message) {
    const event = new ShowToastEvent({
      title: "Error",
      message: message,
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(event);
  }
}