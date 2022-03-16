import { LightningElement, api, wire, track } from "lwc";

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
import getPicklistValues from "@salesforce/apex/lightning_Util.getPicklistValues";

import CONTACT_FIELD from "@salesforce/schema/Opportunity.Contact__c";
import { getFieldValue, getRecord } from "lightning/uiRecordApi";

export default class ConfirmationTerms extends LightningElement {
  @api
  recordId = "0067h00000C2tqrAAB";

  activeSections = ["originations", "underwriter"];

  picklists = [{ label: "", value: "" }];
  selectedProcessInstanceId = null;

  comments = {};
  submissionDetails = {};
  @track currentDetails = {};

  isCloserPanel = false;
  isEnabledCloserPanel = false;
  isEnabledOriginatorPanel = false;
  isEnabledUnderwriterPanel = false;
  isOriginatorPanel = false;
  isUnderWriterPanel = false;

  showButtonsCloser = false;
  showButtonsOriginator = false;
  showButtonsUnderwriter = false;
  localAmortizationStatusOptions = [{ label: "", value: "" }];

  localServicerOptions = [{ label: "", value: "" }];

  closerReviewComment = "";
  origingatorReviewComment = "";
  underwriterReviewComment = "";

  isRejection = false;

  isInApproval = false;

  formUpdated = false;

  @wire(getRecord, { recordId: "$recordId", fields: [CONTACT_FIELD] })
  deal;

  get contactId() {
    return getFieldValue(this.deal.data, CONTACT_FIELD);
  }

  get showContactNameField() {
    return this.currentDetails.servicerContactName == "Need to Update";
  }

  get showContactAddressFields() {
    return this.currentDetails.servicerContactAddress == "Need to Update";
  }

  get showContactPhoneField() {
    return this.currentDetails.servicerContactPhone == "Need to Update";
  }

  get showContactEmailField() {
    return this.currentDetails.servicerContactEmail == "Need to Update";
  }

  get showServicerContactForm() {
    return (
      this.contactId &&
      (this.showContactNameField ||
        this.showContactAddressFields ||
        this.showContactPhoneField ||
        this.showContactEmailField)
    );
  }

  get originatorButtonLabel() {
    return !this.showServicerContactForm
      ? "Submit"
      : this.formUpdated
      ? "Submit and Save"
      : "Submit without Saving";
  }

  get originatorButtonVariant() {
    return this.formUpdated ? "brand" : "neutral";
  }

  handleFormChange() {
    this.formUpdated = true;
  }

  handleFormError(evt) {
    evt.preventDefault();
    evt.stopImmediatePropagation();
    this.showErrorToast(evt.detail.detail);
    this.showButtonsOriginator = true;
    this.template.querySelector("c-modal").hideSpinner();

  }

  handleFormSubmit(evt) {
    evt.preventDefault();
    console.log("submitting");
    const fields = evt.detail.fields;
    console.log({ ...fields });
    this.template.querySelector("lightning-record-edit-form").submit(fields);
  }

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

  getAmortizationStatusPicklistvalues() {
    getPicklistValues({
      sobjectType: "Approval_History__c",
      fieldName: "Amortization_Status__c"
    })
      .then((results) => {
        console.log(results);
        const currentOptions = [];

        if (results.length > 0) {
          results.forEach((element) => {
            currentOptions.push({
              label: element,
              value: element
            });
          });
        }

        this.amortizationStatusOptions = currentOptions;
      })
      .catch((error) => {
        console.error(error);
      });
  }

  getServicerContactPicklistvalues() {
    getPicklistValues({
      sobjectType: "Approval_History__c",
      fieldName: "Servicer_Contact_Name__c"
    })
      .then((results) => {
        console.log(results);
        const currentOptions = [];

        if (results.length > 0) {
          results.forEach((element) => {
            currentOptions.push({
              label: element,
              value: element
            });
          });
        }

        this.servicerOptions = currentOptions;
      })
      .catch((error) => {
        console.error(error);
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
        this.getServicerContactPicklistvalues();
        this.getAmortizationStatusPicklistvalues();
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
    console.log("contact id", this.contactId);
    if (this.isUnderWriterPanel && this.isEnabledUnderwriterPanel) {
      //do validation for the values to be populated;
      if (!this.currentDetails.amortizationStatus) {
        const amortizationStatus = this.template.querySelector(
          'lightning-combobox[data-field="amortizationStatus"]'
        );
        amortizationStatus.required = true;
        amortizationStatus.reportValidity();
        validated = false;
      }
    }

    if (this.isOriginatorPanel && this.isEnabledOriginatorPanel) {
      if (!this.currentDetails.depositCollected) {
        const depositCollected = this.template.querySelector([
          '[data-field="depositCollected"]'
        ]);
        depositCollected.required = true;
        depositCollected.reportValidity();
        validated = false;
      }

      if (!this.currentDetails.servicerContactName) {
        const servicerContactName = this.template.querySelector([
          '[data-field="servicerContactName"]'
        ]);
        servicerContactName.required = true;
        servicerContactName.reportValidity();
        validated = false;
      }

      if (!this.currentDetails.servicerContactAddress) {
        const servicerContactAddress = this.template.querySelector([
          '[data-field="servicerContactAddress"]'
        ]);
        servicerContactAddress.required = true;
        servicerContactAddress.reportValidity();
        validated = false;
      }

      if (!this.currentDetails.servicerContactEmail) {
        const servicerContactEmail = this.template.querySelector([
          '[data-field="servicerContactEmail"]'
        ]);
        servicerContactEmail.required = true;
        servicerContactEmail.reportValidity();
        validated = false;
      }

      if (!this.currentDetails.servicerContactPhone) {
        const servicerContactPhone = this.template.querySelector([
          '[data-field="servicerContactPhone"]'
        ]);
        servicerContactPhone.required = true;
        servicerContactPhone.reportValidity();
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

  handleFormSuccess() {
    const comment = this.origingatorReviewComment;
    const recordId = this.recordId;
    const currentDetails = JSON.stringify(this.currentDetails);
    const comments = JSON.stringify(this.comments);

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
      if (this.showServicerContactForm) {
        this.template.querySelector(`[data-name="hidden-submit"]`).click();
      } else {
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
    return this.localAmortizationStatusOptions;
  }

  set amortizationStatusOptions(val) {
    this.localAmortizationStatusOptions = val;
  }

  get servicerOptions() {
    return this.localServicerOptions;
  }

  set servicerOptions(val) {
    this.localServicerOptions = val;
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
