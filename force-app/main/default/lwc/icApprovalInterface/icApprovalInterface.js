import { api, track, LightningElement } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import returnDeal from "@salesforce/apex/IcApprovalController.returnDeal";
import sendEmail from "@salesforce/apex/IcApprovalController.sendEmail";
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class IcApprovalInterface extends LightningElement {
  @api recordId;
  @track isRendered = false;
  possibleAttachments;
  selectedAttachments = [];
  recipients;
  data;
  errorMessage;
  formats = [
    "font",
    "size",
    "bold",
    "italic",
    "underline",
    "strike",
    "list",
    "indent",
    "align",
    "link",
    "image",
    "clean",
    "table",
    "header",
    "color",
    "background",
    "code",
    "code-block",
    "script",
    "blockquote",
    "direction"
  ];

  closeModal = () => {
    this.dispatchEvent(new CloseActionScreenEvent());
  };

  handleSelect = (evt) => {
    this.selectedAttachments = JSON.parse(evt.detail);
  };

  handleChange = (evt) => {
    const name = evt.target.getAttribute("data-name");
    const data = { ...this.data };
    if (name === "user") {
      data.user.Email = evt.target.value;
    } else {
      data[name] = evt.target.value;
    }
    this.data = data;
  };

  sendEmail = async () => {
    let toastEvent;
    const mailformat = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;
    if(this.selectedAttachments.length < 1) {
      toastEvent = {
        title: "Please select an attachment.",
        message:
          "You cannot send an email without an attachment.",
        variant: "error"
      };
    } else if (!this.data.recipients) {
      toastEvent = {
        title: "No recipient found.",
        message:
          "Please enter at least one recipient's email address.",
        variant: "error"
      };
    } else if (this.data.recipients) {
      const recEmails = this.data.recipients.split(";");
      for(let i = 0; i < recEmails.length; i++) {
        if(!recEmails[i].trim().match(mailformat)) {
          toastEvent = {
            title: "Invalid email address",
            message:
              recEmails[i] + " is not a valid email address",
            variant: "error"
          };
          break;
        }
      }
    } else if (this.data.cc) {
      const recEmails = this.data.cc.split(";");
      for(let i = 0; i < recEmails.length; i++) {
        if(!recEmails[i].trim().match(mailformat)) {
          toastEvent = {
            title: "Invalid email address",
            message:
              recEmails[i] + " is not a valid email address",
            variant: "error"
          };
          break;
        }
      }
    }

    if(toastEvent) {
      this.dispatchEvent(new ShowToastEvent({...toastEvent}));
      return;
    }
    const res = await sendEmail({
      s: JSON.stringify({ ...this.data, user: this.data.user.Email }),
      attachIds: JSON.stringify(this.selectedAttachments.map((a) => a.Id))
    });
    const { Error, Success } = await JSON.parse(res);
    console.log(res);
    if (Error) {
      console.error(Error);
      this.errorMessage = Error;
    } else {
      const event = new ShowToastEvent({
        title: "Email Sent",
        message:
          "Your email for IC Approval has been succesfully sent.",
        variant: "success"
      });

      this.dispatchEvent(event);
      this.closeModal();
    }
  };

  async renderedCallback() {
    console.log("rendering");
    if (!this.isRendered && this.recordId) {
      const res = await returnDeal({ recordId: this.recordId });
      const data = await JSON.parse(res);
      if (data.Error) {
        this.isRendered = true;
        console.log("render failed");
        console.error(data.Error[0]);
        this.errorMessage = data.Error[0];
      } else {
        console.log(data);
        this.data = {
          recordId: this.recordId,
          recipients: data.Recipients[0].join(";"),
          user: data.CurrentUser[0],
          emailBody: data.EmailContents[0],
          subject: data.Subject[0],
          cc: data.CC.filter((c) => !!c).join(";"),
          approvalType: data.ApprovalType[0]
        };
        console.log(data.ApprovalType[0])

        this.possibleAttachments = data.ContentVersions.map((el) => ({
          Id: el.Id,
          Name: el.PathOnClient,
          Type: "ContentVersion",
          Description: el.Description
        }));
        this.isRendered = true;
      }
    }
  }
}