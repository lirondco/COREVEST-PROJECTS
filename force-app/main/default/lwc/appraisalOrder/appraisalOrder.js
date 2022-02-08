import { LightningElement, track, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import query from "@salesforce/apex/lightning_Util.query";
import submitOrder from "@salesforce/apex/AppraisalMergeController.submitOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import checkStatus from "@salesforce/apex/AppraisalMergeController.checkStatus";
// import retrieveOrder from "@salesforce/apex/AppraisalMergeController.retrieveOrder";
import checkPermission from "@salesforce/apex/lightning_Util.userHasPermission";
import getAppName from "@salesforce/apex/lightning_Util.getAppName";
import getType from "@salesforce/apex/lightning_Util.getType";
import retrievePicklists from "@salesforce/apex/lightning_Util.getPicklistValues";
import getUser from "@salesforce/apex/lightning_Util.getUser";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
// import refreshAppraisalStatus from "@salesforce/apex/AppraisalMergeController.refreshAppraisalStatus";
// import PROPERTY_TYPES from "@salesforce/schema/Property__c.Property_Type__c";

export default class AppraisalOrder extends LightningElement {
  //@api recordId = "0062D000004erxnQAA";
  //@api recordId ='0060a00000obPjhAAE';
  @api recordId;
  // @api recordId;
  @track properties = [];
  @track selectedPropertyIds = [];

  @track reportType = "";
  @track addOns = [];
  @track turnTime = "";

  @track canOrder = false;
  @track canRefresh = false;

  @track showFilters = false;
  @track propertyTypes = [];
  @track selectedPropertyTypes = [];

  @track statuses = [];
  @track selectedStatuses = [];

  @track propertystatuses = [];
  @track selectedPropertyStatuses = [];

  @track appName;
  @track dealType;
  @track comments = [];
  @track appraisalFirm = "";
  // @track reportType = ''

  @track isLoading = true;

  @track user = {};
  @track showFooter = true;
  selectedProperties = [];
  @track objname;
  @track fname;
  @track picklistresult;
  // @wire(checkPermission, { permissionSetName: "Order_Appraisals_Through_API" })
  // canOrder;

  // @wire(checkPermission, {
  //   permissionSetName: "Refresh_Appraisals_Through_API"
  // })
  // canRefresh;
  /*constructor()
  {
    super();
    console.log('===call==');
  
  }*/

  @wire(retrievePicklists, {
    sobjectType: "Property__c",
    fieldName: "Property_Type__c"
  })
  wirePropertyTypeValues({ error, data }) {
    let picklists = [];
    let selectedPicklists = [];
    if (data) {
      data.forEach((picklist) => {
        picklists.push({ label: picklist, value: picklist });
        selectedPicklists.push(picklist);
        console.log("picklists==" + picklists);
      });
    } else if (error) {
      console.log(error);
    }

    this.propertyTypes = picklists;
    this.selectedPropertyTypes = selectedPicklists;
  }

  @wire(retrievePicklists, {
    sobjectType: "Appraisal__c",
    fieldName: "Status__c"
  })
  wireAppraisalStatusValues({ error, data }) {
    let picklists = [];
    let selectedPicklists = [];
    if (data) {
      data = data.concat(["Unordered"]);
      data.forEach((picklist) => {
        picklists.push({ label: picklist, value: picklist });
        selectedPicklists.push(picklist);
        console.log("picklists@@" + picklists);
      });
    } else if (error) {
      console.log(error);
    }

    this.statuses = picklists;
    this.selectedStatuses = selectedPicklists;
  }

  //BJHASTART
  //propertystatuses
  //BJHAEND

  @wire(getUser, {})
  wireUser({ error, data }) {
    this.user = data;
  }
  get password() {
    let password = "";
    const appraisalFirm = this.template.querySelector(
      '[data-name="appraisalFirm"]'
    ).value;

    if (appraisalFirm === "Appraisal Nation") {
      password = this.user.Appraisal_Nation_Password__c;
    } else if (appraisalFirm === "Clarocity Valuation Services") {
      password = this.user.Clarocity_Password__c;
    } else if (appraisalFirm === "Valuation Services AMC") {
      password = this.user.Valuation_Services_Password__c;
    }

    return password;
  }

  get username() {
    let username = "";
    const appraisalFirm = this.template.querySelector(
      '[data-name="appraisalFirm"]'
    ).value;

    if (appraisalFirm === "Appraisal Nation") {
      username = this.user.Appraisal_Nation_Username__c;
    } else if (appraisalFirm === "Clarocity Valuation Services") {
      username = this.user.Clarocity_Username__c;
    } else if (appraisalFirm === "Valuation Services AMC") {
      username = this.user.Valuation_Services_Username__c;
    }

    return username;
  }

  get propertyList() {
    let properties = JSON.parse(JSON.stringify(this.properties));
    console.log("get propertylist--" + JSON.stringify(this.properties));
    let selectedPropertyTypes = new Set(this.selectedPropertyTypes);
    let selectedStatuses = new Set(this.selectedStatuses);
    let selectedPropertyStatuses = new Set(this.selectedPropertyStatuses);

    let visibleProperties = [];

    properties.forEach((property) => {
      console.log("property-----", property);
      if (!property.hasOwnProperty("Appraisals__r")) {
        property.Appraisals__r = [];
      }

      property.linkUrl = `/lightning/r/Property__c/${property.Id}/view`;

      property.Appraisals__r.forEach((appraisal) => {
        appraisal.showCheckbox = false;
        appraisal.showURL = true;
        if (appraisal.Number_of_Comments__c > 0) {
          appraisal.hasComments = true;
        }

        if (
          appraisal.Status__c === "On Hold" ||
          appraisal.Status__c === "Cancelled"
        ) {
          if (
            appraisal.Status_Description__c &&
            appraisal.Status_Description__c !== ""
          ) {
            appraisal.showToolTip = true;
          }
        }

        if (
          appraisal.Status__c !== "Cancelled" &&
          appraisal.Status__c !== "Complete-Delivered" &&
          appraisal.Status__c !== "Complete-Undelivered"
        ) {
          appraisal.showCheckbox = true;
        }
      });

      if (property.Appraisals__r.length === 0) {
        property.Appraisals__r.push({
          Status__c: "Unordered",
          showCheckbox: false,
          showToolTip: false,
          hasComments: false,
          showURL: false,
          Id: "appraisal-" + property.Id
        });
      }
      console.log("selectedStatuses" + JSON.stringify(selectedStatuses));
      console.log("property.Property_Type__c", property.Property_Type__c);

      let hasAppraisal = false;
      let hasStatus = false;
      console.log("if selectedPropertyTypes==", selectedPropertyTypes);
      console.log("if property.Property_Type__c==", property.Property_Type__c);

      if (selectedPropertyTypes.has(property.Property_Type__c)) {
        console.log(
          "if property.selectedPropertyTypes==",
          selectedPropertyTypes
        );
        console.log(
          "if Property_Type__c.appraisal==",
          property.Property_Type__c
        );

        property.Appraisals__r.forEach((appraisal) => {
          console.log("if selectedStatuses==", selectedStatuses);
          console.log("if appraisal.Status__c==", appraisal.Status__c);

          if (selectedStatuses.has(appraisal.Status__c)) {
            hasAppraisal = true;
            appraisal.visible = true;
          }
          console.log("if hasAppraisal==", hasAppraisal);
          console.log("if property.appraisal.visible==", appraisal.visible);
        });
      }
      console.log("==selectedPropertyStatuses==", selectedPropertyStatuses);
      console.log("==property.Status__c==", property.Status__c);

      if (selectedPropertyStatuses.has(property.Status__c)) {
        hasStatus = true;
      }

      console.log("last hasStatus==", hasStatus);
      console.log("last hasAppraisal==", hasAppraisal);

      if (hasAppraisal && hasStatus) {
        visibleProperties.push(property);
      }
    });
    console.log("visiblr prop==", visibleProperties);
    return visibleProperties;
  }

  connectedCallback() {
    console.log("===connectedCallback==");
    //this.queryProperties();

    checkPermission({ permissionSetName: "Order_Appraisals_Through_API" })
      .then((results) => {
        this.canOrder = results;
      })
      .catch((error) => {
        console.log(error);
      });

    checkPermission({ permissionSetName: "Refresh_Appraisals_Through_API" })
      .then((results) => {
        this.canRefresh = results;
      })
      .catch((error) => {
        console.log(error);
      });
    getAppName()
      .then((appNameResults) => {
        console.log("results", appNameResults);
        this.appName = appNameResults;
        console.log("appname", this.appName);
        console.log("this.recordid==", this.recordId);
        getType({ recordId: this.recordId })
          .then((getTypeResults) => {
            this.dealType = getTypeResults;
            console.log("results get type", getTypeResults);
            console.log("= connectedcallback dealtype==" + this.dealType);
            retrievePicklists({
              sobjectType: "Property__c",
              fieldName: "Status__c"
            })
              .then((data) => {
                let picklists = [];
                let selectedPicklists = [];
                if (data) {
                  data = data.concat(["Unordered"]);
                  data.forEach((picklist) => {
                    console.log("==this.appname==" + this.appName);
                    console.log("==dealtype==" + this.dealType);
                    if (
                      this.appName == "Asset Management" &&
                      (this.dealType == "Bridge Loan" ||
                        this.dealType == "SAB Loan")
                    ) {
                      console.log("===Asset Management if 1==");
                      if (
                        picklist == "Due Diligence" ||
                        picklist == "Pending" ||
                        picklist == "Closing" ||
                        picklist == "Active" ||
                        picklist == "On Hold" ||
                        picklist == "Cancelled" ||
                        picklist == "Paid Off"
                      ) {
                        picklists.push({ label: picklist, value: picklist });
                      }
                      if (picklist == "Active") {
                        selectedPicklists.push(picklist);
                      }
                    } else if (
                      this.appName != "Asset Management" &&
                      (this.dealType == "Bridge Loan" ||
                        this.dealType == "SAB Loan")
                    ) {
                      console.log("===Asset Management if 2==");
                      if (
                        picklist == "Due Diligence" ||
                        picklist == "Pending" ||
                        picklist == "Closing" ||
                        picklist == "Active" ||
                        picklist == "On Hold" ||
                        picklist == "Cancelled" ||
                        picklist == "Paid Off"
                      ) {
                        picklists.push({ label: picklist, value: picklist });
                      }
                      if (
                        picklist == "Due Diligence" ||
                        picklist == "Pending" ||
                        picklist == "Closing" ||
                        picklist == "On Hold"
                      ) {
                        selectedPicklists.push(picklist);
                      }
                    } else if (
                      this.dealType != "Term Loan" ||
                      this.dealType != "Single Rental Loan"
                    ) {
                      console.log("===Asset Management if 3==");

                      if (
                        picklist == "Inactive" ||
                        picklist == "Cancelled" ||
                        picklist == "Active" ||
                        picklist == "Paid Off"
                      ) {
                        picklists.push({ label: picklist, value: picklist });
                      }
                      if (picklist == "Active") {
                        selectedPicklists.push(picklist);
                      }
                    } /*if(this.dealType!='Term Loan' && this.dealType!='Single Rental Loan' && this.dealType!='Bridge Loan' && this.dealType!='SAB Loan')*/ else {
                      console.log("===Asset Management if 4==");
                      if (
                        picklist == "Active" ||
                        picklist == "Due Diligence" ||
                        picklist == "Pending" ||
                        picklist == "Inactive" ||
                        picklist == "On Hold" ||
                        picklist == "Cancelled" ||
                        picklist == "Paid Off"
                      ) {
                        picklists.push({ label: picklist, value: picklist });
                      }
                    }
                  });
                } else if (error) {
                  console.log("error of picklist", error);
                }

                this.propertystatuses = picklists;
                this.selectedPropertyStatuses = selectedPicklists;
                console.log(
                  "selectpropertystatus",
                  this.selectedPropertyStatuses
                );
                this.queryProperties();
              })
              .catch((error) => {
                this.error = error;
                this.accounts = undefined;
              });
          })
          .catch((error) => {
            console.log(error);
            console.log("error res", error);
          });
      })
      .catch((error) => {
        console.log(error);
      });
    console.log("deal id", this.recordId);
  }
  queryProperties() {
    let pstatus = this.selectedPropertyStatuses;
    let pStatusArray = String(pstatus).split(",");
    console.log("pStatusArray:", pStatusArray);
    let pStFinal = "";
    for (let eachStatus of pStatusArray) pStFinal += "'" + eachStatus + "',";

    console.log("pStFinal:", pStFinal.substring(0, pStFinal.length - 1));
    pStFinal = pStFinal.substring(0, pStFinal.length - 1);
    let queryString = `SELECT Id, Name, City__c, Status__c,Number_of_Units__c, Property_Type__c, DealID__c, Asset_ID__c, Square_Feet__c, Interior_Access_POC__c, Interior_Access_POC_Phone__c, `;
    queryString += `(SELECT Id, Link_Formula__c, Number_Of_Comments__c, Status_Description__c, Status__c, Vendor_Ordered_From__c, Order_Received_Date__c, Estimated_Completion_Date__c, Appraisal_Completion_Date__c, Appraisal_Product_Ordered__c, Appraisal_Fee__c, `;
    queryString += ` Can_Order__c, Can_Refresh__c `;
    queryString += ` FROM Appraisals__r Order BY CreatedDate ASC) `;
    queryString += `FROM Property__c WHERE Deal__c = '${this.recordId}' `;
    queryString += `AND Status__c IN (${pStFinal}) AND (Is_Sub_Unit__c = false OR Parent_Property__c = null) `;
    queryString += `AND Property_Type__c != null`;
    console.log("queryString:", queryString);

    query({ queryString: queryString })
      .then((properties) => {
        console.log("c" + JSON.stringify(properties));
        console.log(properties);
        this.properties = properties;
        this.isLoading = false;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  checkValidations() {
    let validated = false;

    const appraisalFirm = this.template.querySelector(
      '[data-name="appraisalFirm"]'
    ).value;
    if (appraisalFirm === "Appraisal Nation") {
      validated = this.checkValidationsAN();
    } else if (appraisalFirm === "Clear Capital") {
      validated = this.checkValidationsCC();
    } else if (appraisalFirm === "Clarocity Valuation Services") {
      validated = this.checkValidationsClarocity();
    } else if (appraisalFirm === "Valuation Services AMC") {
      validated = this.checkValidationsVS();
    }

    return validated;
    // return false;
  }

  checkValidationsCC() {
    const productType = this.template.querySelector('[data-name="productType"]')
      .value;

    const turnTime = this.template.querySelector('[data-name="turnTime"]')
      .value;

    return productType && productType !== "" && turnTime && turnTime !== "";
  }

  checkValidationsAN() {
    const productType = this.template.querySelector('[data-name="productType"]')
      .value;

    const username = this.template.querySelector('[data-name="anUsername"]')
      .value;
    const password = this.template.querySelector('[data-name="anPassword"]')
      .value;

    return (
      productType &&
      productType !== "" &&
      username &&
      username !== "" &&
      password &&
      password !== ""
    );
  }

  checkValidationsVS() {
    const productType = this.template.querySelector('[data-name="productType"]')
      .value;

    const username = this.template.querySelector('[data-name="anUsername"]')
      .value;
    const password = this.template.querySelector('[data-name="anPassword"]')
      .value;

    return (
      productType &&
      productType !== "" &&
      username &&
      username !== "" &&
      password &&
      password !== ""
    );
  }

  checkValidationsClarocity() {
    const productType = this.template.querySelector('[data-name="productType"]')
      .value;

    const username = this.template.querySelector('[data-name="anUsername"]')
      .value;
    const password = this.template.querySelector('[data-name="anPassword"]')
      .value;

    return (
      productType &&
      productType !== "" &&
      username &&
      username !== "" &&
      password &&
      password !== ""
    );
  }

  submitOrder(event) {
    this.toggleFooterButtons();
    let params = {};
    this.template.querySelectorAll("[data-id='params']").forEach((input) => {
      // console.log(input);
      let key = input.getAttribute("data-name");
      let value = input.value ? input.value : "";

      if (key === "rushOrder") {
        value = input.checked;
      }

      params[key] = value;
    });

    console.log("params");
    console.log(params);

    let propertyTypes = new Set();

    let checkboxes = this.template.querySelectorAll(
      '[data-name="propertyCheckbox"]'
    );

    checkboxes.forEach((checkbox) => {
      //console.log(checkbox);
      if (checkbox.checked) {
        propertyTypes.add(checkbox.getAttribute("data-propertytype"));
      }
    });

    if (
      propertyTypes.has("Multifamily") &&
      (params.appraisalFirm === "Appraisal Nation" ||
        params.appraisalFirm === "Clear Capital" ||
        params.appraisalFirm === "Valuation Services AMC")
    ) {
      this.showNotification(
        "Unable to Order",
        "Selected Vendor does not provide CoreVest with Appraisals on Multifamily or Mixed Use Property Types."
      );

      return;
    }

    if (
      propertyTypes.has("Multifamily") &&
      (params.appraisalFirm === "Appraisal Nation" ||
        params.appraisalFirm === "Clear Capital")
    ) {
      return;
    }

    if (
      (propertyTypes.has("Multifamily") || propertyTypes.has("Mixed Use")) &&
      params.appraisalFirm === "Appraisal Nation"
    ) {
      this.showNotification(
        "Unable to Order",
        "Appraisal Nation does not provide CoreVest with Appraisals on Multifamily or Mixed Use Property Types.",
        "warning"
      );
      // this.template
      //   .querySelector('[data-name="submitButton"]')
      //   .removeAttribute("disabled");
      this.toggleFooterButtons();
      return;
    }

    // if (
    //   (propertyTypes.has("Multifamily") || propertyTypes.has("Mixed Use")) &&
    //   params.appraisalFirm === "Clear Capital"
    // ) {
    //   this.showNotification(
    //     "Unable to Order",
    //     "Clear Capital does not provide CoreVest with Appraisals on Multifamily or Mixed Use Property Types.",
    //     "warning"
    //   );
    //   // this.template
    //   //   .querySelector('[data-name="submitButton"]')
    //   //   .removeAttribute("disabled");.
    //   this.toggleFooterButtons();
    //   return;
    // }

    if (params.productType && params.productType.includes("Interior")) {
      let badData = false;

      let badNames = [];

      this.selectedProperties.forEach((property) => {
        if (
          (!property.Interior_Access_POC_Phone__c ||
            !property.Interior_Access_POC_Email__c) &&
          !property.Interior_Access_POC__c
        ) {
          badData = true;
          badNames.push(property.Name);
        }
      });

      if (badData) {
        this.showNotification(
          "Unable to Order",
          `Point of Contact is required.  Please add via the Data Tape page or by editing the individual Property: ${badNames.join(
            ", "
          )}`,
          "warning"
        );
        this.toggleFooterButtons();
        return;
      }
    }

    if (this.checkValidations()) {
      //console.log("submit order");

      this.template.querySelector('[data-id="orderModal"]').showSpinner();
      // this.toggleFooterButtons();

      let isError = false;
      let errorMsgs = [];

      // this.template.querySelector('[data-id="orderModal"]').showSpinner();
      // this.toggleFooterButtons();

      // if(params.productType.in)

      params.addOns = this.addOns;
      params.turnTime = this.turnTime;
      

      this.selectedPropertyIds.reduce((promise, propertyId, index) => {
        return promise.then(() => {
          return submitOrder({
            propertyId: propertyId,
            arguments: params
          }).then(
            (res) => {
              // do stuff
              //console.log("property???");

              if (index === this.selectedPropertyIds.length - 1) {
                if (isError) {
                  //
                  this.template
                    .querySelector('[data-id="orderModal"]')
                    .hideSpinner();
                  // this.template
                  //   .querySelector('[data-name="submitButton"]')
                  //   .removeAttribute("disabled");
                  this.toggleFooterButtons();
                  let errorMsg = "An error occured on one or more properties.";
                  for (let msg of errorMsgs) {
                    errorMsg += "\n" + msg;
                  }

                  console.log(errorMsg);

                  this.showNotification("Error", errorMsg, "error");
                } else {
                  // this.template
                  //   .querySelector('[data-name="submitButton"]')
                  //   .removeAttribute("disabled");
                  this.toggleFooterButtons();
                  this.closeOrderModal();
                  //this.template.querySelector('[data-id="orderModal"]').closeModal();
                  this.template
                    .querySelector('[data-id="orderModal"]')
                    .hideSpinner();

                  this.showNotification("Success", "Orders created", "success");
                  this.queryProperties();
                }
              }

              console.log("submitted order");
            },
            (error) => {
              console.log("error");

              errorMsgs.push(error.body.message);
              if (index === this.selectedPropertyIds.length - 1) {
                //  this.hideSpinner(component);
                this.template
                  .querySelector('[data-id="orderModal"]')
                  .hideSpinner();
                // this.template
                //   .querySelector('[data-name="submitButton"]')
                //   .removeAttribute("disabled");
                this.toggleFooterButtons();
                let errorMsg = "An error occured on one or more properties.";
                for (let msg of errorMsgs) {
                  errorMsg += "\n" + msg;
                }

                console.log(errorMsg);
                this.queryProperties();
                this.showNotification("Error", errorMsg, "error");
              }
            }
          );
        });
      }, Promise.resolve());
    } else {
      this.toggleFooterButtons();
      this.template
        .querySelector('[data-name="submitButton"]')
        .removeAttribute("disabled");
    }
  }

  toggleFooterButtons() {
    //event.target.removeAttribute('disabled');
    this.showFooter = !this.showFooter;
  }

  retrieveAppraisal() {
    if (!this.canRefresh) {
      this.showNotification(
        "Unable to Refresh",
        "You do not have permission to refresh the appraisal order.  Please contact your manager to be granted permission",
        "warning"
      );

      return;
    }

    let selectedAppraisalIds = [];

    let checkboxes = this.template.querySelectorAll(
      '[data-name="appraisalCheckbox"]'
    );

    checkboxes.forEach((checkbox) => {
      //console.log(checkbox);
      if (checkbox.checked) {
        selectedAppraisalIds.push(checkbox.getAttribute("data-id"));
      }
    });

    console.log(selectedAppraisalIds);

    if (selectedAppraisalIds.length > 0) {
      let isError = false;
      let errorMsgs = [];

      selectedAppraisalIds.reduce((promise, appraisalId, index) => {
        return promise.then(() => {
          return retrieveOrder({
            appraisalId: appraisalId
          }).then(
            (res) => {
              // do stuff
              //console.log("property???");

              if (index === selectedAppraisalIds.length - 1) {
                if (isError) {
                  //
                  let errorMsg = "An error occured on one or more orders.";
                  for (let msg of errorMsgs) {
                    errorMsg += "\n" + msg;
                  }

                  console.log(errorMsg);

                  this.showNotification("Error", errorMsg, "error");
                } else {
                  this.showNotification(
                    "Success",
                    "Orders refreshed",
                    "success"
                  );
                  this.queryProperties();
                }
              }

              console.log("submitted order");
            },
            (error) => {
              console.log("error");

              errorMsgs.push(error.body.message);
              if (index === selectedAppraisalIds.length - 1) {
                //  this.hideSpinner(component);

                let errorMsg = "An error occured on one or more orders.";
                for (let msg of errorMsgs) {
                  errorMsg += "\n" + msg;
                }

                console.log(errorMsg);

                this.showNotification("Error", errorMsg, "error");
              }
            }
          );
        });
      }, Promise.resolve());
    }
  }

  refreshStatus() {
    if (!this.canRefresh) {
      this.showNotification(
        "Unable to Refresh",
        "You do not have permission to refresh the appraisal order.  Please contact your manager to be granted permission",
        "warning"
      );

      return;
    }
    this.isLoading = true;
    let selectedAppraisalIds = [];

    let checkboxes = this.template.querySelectorAll(
      '[data-name="appraisalCheckbox"]'
    );

    checkboxes.forEach((checkbox) => {
      //console.log(checkbox);
      if (checkbox.checked) {
        selectedAppraisalIds.push(checkbox.getAttribute("data-id"));
      }
    });

    console.log(selectedAppraisalIds);

    if (selectedAppraisalIds.length > 0) {
      this.refreshAppraisals(selectedAppraisalIds);
      /*let isError = false;
      let errorMsgs = [];

      selectedAppraisalIds.reduce((promise, appraisalId, index) => {
        return promise.then(() => {
          return checkStatus({
            appraisalId: appraisalId
          }).then(
            res => {
              if (index === selectedAppraisalIds.length - 1) {
                if (isError) {
                  //
                  let errorMsg = "An error occured on one or more orders.";
                  for (let msg of errorMsgs) {
                    errorMsg += "\n" + msg;
                  }

                  console.log(errorMsg);

                  this.showNotification("Error", errorMsg, "error");
                } else {
                  this.showNotification(
                    "Success",
                    "Orders refreshed",
                    "success"
                  );
                  this.queryProperties();
                }
              }

              console.log("submitted order");
            },
            error => {
              console.log("error");

              errorMsgs.push(error.body.message);
              if (index === selectedAppraisalIds.length - 1) {
                //  this.hideSpinner(component);

                let errorMsg = "An error occured on one or more orders.";
                for (let msg of errorMsgs) {
                  errorMsg += "\n" + msg;
                }

                //console.log(errorMsg);

                this.showNotification("Error", errorMsg, "error");
                this.queryProperties();
              }
            }
          );
        });
      }, Promise.resolve());*/
    } else {
      this.isLoading = false;
    }
  }

  refreshAllOpen(event) {
    if (!this.canRefresh) {
      this.showNotification(
        "Unable to Refresh",
        "You do not have permission to refresh the appraisal order.  Please contact your manager to be granted permission",
        "warning"
      );

      return;
    }
    this.isLoading = true;

    const properties = this.properties;
    const appraisalIds = [];
    properties.forEach((property) => {
      // eslint-disable-next-line no-unused-expressions
      property.hasOwnProperty("Appraisals__r") &&
        property.Appraisals__r.forEach((appraisal) => {
          if (
            appraisal.Status__c !== "Complete-Delivered" &&
            appraisal.Status__c !== "Cancelled" &&
            appraisal.Status__c !== "Complete-Undelivered"
          ) {
            appraisalIds.push(appraisal.Id);
          }
        });
    });

    if (appraisalIds.length > 0) {
      this.refreshAppraisals(appraisalIds);
    } else {
      this.isLoading = false;
    }
  }

  refreshAppraisals(appraisalIds) {
    let isError = false;
    let errorMsgs = [];
    appraisalIds.reduce((promise, appraisalId, index) => {
      return promise.then(() => {
        return checkStatus({
          appraisalId: appraisalId
        }).then(
          (res) => {
            if (index === appraisalIds.length - 1) {
              if (isError) {
                //
                let errorMsg = "An error occured on one or more orders.";
                for (let msg of errorMsgs) {
                  errorMsg += "\n" + msg;
                }

                console.log(errorMsg);

                this.showNotification("Error", errorMsg, "error");
              } else {
                this.showNotification("Success", "Orders refreshed", "success");
                this.queryProperties();
              }
            }

            console.log("submitted order");
          },
          (error) => {
            console.log("error");

            errorMsgs.push(error.body.message);
            if (index === appraisalIds.length - 1) {
              //  this.hideSpinner(component);

              let errorMsg = "An error occured on one or more orders.";
              for (let msg of errorMsgs) {
                errorMsg += "\n" + msg;
              }

              //console.log(errorMsg);

              this.showNotification("Error", errorMsg, "error");
              this.queryProperties();
            }
          }
        );
      });
    }, Promise.resolve());
  }

  openOrderModal() {
    console.log("open order modal");

    if (!this.canOrder) {
      this.showNotification(
        "Unable to Order",
        "You do not have permission to order appraisals.  Please contact your manager to be granted permission",
        "warning"
      );

      return;
    }

    let selectedPropertyIds = [];

    let propertyTypes = new Set();
    let selectedProperties = [];
    let checkboxes = this.template.querySelectorAll(
      '[data-name="propertyCheckbox"]'
    );

    checkboxes.forEach((checkbox) => {
      //console.log(checkbox);
      if (checkbox.checked) {
        selectedPropertyIds.push(checkbox.getAttribute("data-id"));
        propertyTypes.add(checkbox.getAttribute("data-propertytype"));
        selectedProperties.push(
          this.properties[checkbox.getAttribute("data-index")]
        );
      }
    });

    if (propertyTypes.has("Multifamily") && propertyTypes.size > 1) {
      this.showNotification(
        "Unable to Order",
        "Multifamily Property Types must be ordered separately from other Property Types.",
        "warning"
      );
      return;
    }

    if (propertyTypes.has("Mixed Use") && propertyTypes.size > 1) {
      this.showNotification(
        "Unable to Order",
        "Mixed Use Property Types must be ordered separately from other Property Types.",
        "warning"
      );
      return;
    }

    //this.template.querySelector
    // this.template.querySelector('[data-id="orderModal"]').showSpinner();
    if (selectedPropertyIds.length > 0) {
      this.template.querySelector('[data-id="orderModal"]').toggleModal();
    }
    this.selectedPropertyIds = selectedPropertyIds;
    this.selectedProperties = selectedProperties;
  }

  closeOrderModal() {
    this.template.querySelector('[data-id="orderModal"]').toggleModal();
    this.selectedPropertyIds = [];
    console.log("close order modal");
  }

  checkAll() {
    console.log("check all");
  }

  get appraisalFirms() {
    let options = [];
    options = [
      { label: "Appraisal Nation", value: "Appraisal Nation" },
      {
        label: "Clarocity Valuation Services",
        value: "Clarocity Valuation Services"
      },
      { label: "Clear Capital", value: "Clear Capital" },
      { label: "Valuation Services AMC", value: "Valuation Services AMC" }
    ];
    return options;
  }

  appraisalFirmChangeHandler(event) {
    console.log("appraisal firm change handler");
    this.appraisalFirm = event.detail.value;
    this.reportType = "";
  }

  get productTypes() {
    console.log("---product types---");
    console.log(this.appraisalFirm);
    let options = [];

    if (this.appraisalFirm === "Clear Capital") {
      options = [
        { label: "Interior Appraisal", value: "Interior Appraisal" },
        { label: "Exterior Appraisal", value: "Exterior Appraisal" },
        { label: "Appraisal Update", value: "Appraisal Update" },
        {
          label: "Certification of Completion",
          value: "Certification of Completion"
        },
        {
          label: "Drive By BPO",
          value: "Drive By BPO"
        },
        {
          label: "Interior BPO",
          value: "Interior BPO"
        },
        {
          label: "ClearVal 2.0 (Interior PCI)",
          value: "ClearVal 2.0 (Interior PCI)"
        },
        {
          label: "ClearVal 2.0 (Exterior PCI)",
          value: "ClearVal 2.0 (Exterior PCI)"
        },
        // {
        //   label: "Commercial",
        //   value: "Commercial"
        // },
        {
          label: "Post Disaster Inspection",
          value: "Post Disaster Inspection"
        }
      ];
    } else if (this.appraisalFirm === "Appraisal Nation") {
      options = [
        { label: "Interior Appraisal", value: "Interior Appraisal" },
        { label: "Exterior Appraisal", value: "Exterior Appraisal" },
        { label: "Final Inspection", value: "Final Inspection" },
        { label: "Recert. of Value", value: "Recert. of Value" },
        {
          label: "CDAIR Exterior Disaster Area Inspection Report",
          value: "CDAIR Exterior Disaster Area Inspection Report"
        },
        {
          label: "CDAIR Interior Disaster Area Inspection Report",
          value: "CDAIR Interior Disaster Area Inspection Report"
        },
        { label: "CoreVal+", value: "CoreVal+" }
      ];
    } else if (this.appraisalFirm === "Clarocity Valuation Services") {
      options = [
        // { label: "Interior Appraisal", value: "Interior Appraisal" },
        // { label: "Exterior Appraisal", value: "Exterior Appraisal" },
        // { label: "Appraisal Update", value: "Appraisal Update" },
        // {
        //   label: "BPO Pro Desktop",
        //   value: "BPO Pro Desktop"
        // },
        // {
        //   label: "BPO Pro Interior",
        //   value: "BPO Pro Interior"
        // },
        // {
        //   label: "BPO Pro Exterior",
        //   value: "BPO Pro Exterior"
        // },
        {
          label: "Market Value Pro Interior",
          value: "Market Value Pro Interior"
        },
        {
          label: "Market Value Pro Exterior",
          value: "Market Value Pro Exterior"
        }
        // {
        //   label: "PCR RE Interior",
        //   value: "PCR RE Interior"
        // },
        // {
        //   label: "PCR RE Exterior",
        //   value: "PCR RE Exterior"
        // }
      ];
    } else if (this.appraisalFirm === "Valuation Services AMC") {
      options = [
        { label: "Interior Appraisal", value: "Interior Appraisal" },
        { label: "Interior Appraisal with ARV", value: "Interior Appraisal with ARV" },
        { label: "Exterior Appraisal", value: "Exterior Appraisal" },
        { label: "Exterior Appraisal with ARV", value: "Exterior Appraisal with ARV" },
        { label: "Final Inspection", value: "Final Inspection" },
        { label: "Final Inspection & Appraisal Update", value: "Final Inspection & Appraisal Update" },
        // {
        //   label: "CDAIR Exterior Disaster Area Inspection Report",
        //   value: "CDAIR Exterior Disaster Area Inspection Report"
        // },
        // {
        //   label: "CDAIR Interior Disaster Area Inspection Report",
        //   value: "CDAIR Interior Disaster Area Inspection Report"
        // }
      ];
    }
    return options;
  }

  get addOnOptions() {
    let options = [];

    if (this.appraisalFirm === "Clear Capital") {
      if (this.reportType === "ClearVal 2.0 (Interior PCI)") {
        options = [
          { label: "As-Repaired Value Addendum", value: "As-Repaired Value Addendum" },
          { label: "Budget Analysis w/ As-Repaired Value Addendum", value: "Budget Analysis w/ As-Repaired Value Addendum" },
          { label: "Comparable Sales History", value: "Comparable Sales History" },
          { label: "Estimated Monthly Rent Addendum", value: "Estimated Monthly Rent Addendum" }
        ];
      } else if (this.reportType === "ClearVal 2.0 (Exterior PCI)") {
        options = [
          { label: "As-Repaired Value Addendum", value: "As-Repaired Value Addendum" },
          { label: "Budget Analysis w/ As-Repaired Value Addendum", value: "Budget Analysis w/ As-Repaired Value Addendum" },
          { label: "Comparable Sales History", value: "Comparable Sales History" },
          { label: "Estimated Monthly Rent Addendum", value: "Estimated Monthly Rent Addendum" }
        ];
      }
    }
    return options;
  }

  reportTypeChange(event) {
    this.turnTime = "";
    this.addOns = [];
    this.reportType = event.detail.value;
  }

  handleAddonChange(event) {
    this.addOns = event.detail.value;
  }

  turnTimeChange(event) {
    this.turnTime = event.detail.value;
  }

  get turnTimeOptions() {
    let options = [];

    if (
      this.reportType === "Interior Appraisal" ||
      this.reportType === "Exterior Appraisal"
    ) {
      options = [{ label: "7 Day", value: "168" }];
    } else if (this.reportType === "Post Disaster Inspection") {
      options = [
        { label: "2 Day", value: "48" },
        { label: "5 Day", value: "120" }
      ];
    } else if (
      this.reportType === "ClearVal 2.0 (Interior PCI)" ||
      this.reportType === "ClearVal 2.0 (Exterior PCI)"
    ) {
      options = [
        { label: "5 Day", value: "120" },
        { label: "7 Day", value: "168" }
      ];
    } else if (this.reportType === "Commercial") {
      options = [{ label: "7 Day", value: "168" }];
    } else if (
      this.reportType === "Appraisal Update" ||
      this.reportType === "Certification of Completion"
    ) {
      options = [{ label: "5 Day", value: "120" }];
    } else if (this.reportType === "Drive By BPO") {
      options = [
        { label: "1 Day", value: "24" },
        { label: "2 Day", value: "48" },
        { label: "3 Day", value: "72" },
        { label: "5 Day", value: "120" }
      ];
    } else if (this.reportType === "Interior BPO") {
      options = [
        { label: "2 Day", value: "48" },
        { label: "3 Day", value: "72" },
        { label: "5 Day", value: "120" }
      ];
    }
    return options;
  }

  showNotification(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      duration: 10000
      // mode: sticky
    });
    this.dispatchEvent(evt);
  }

  viewComments(event) {
    let appraisalId = event.target.getAttribute("data-id");
    console.log("appraisalId");
    let queryString = `SELECT Id, Comment__c, FORMAT(Comment_Date__c) Comment_Date__c FROM Appraisal_Order_Comment__c`;
    queryString += ` WHERE Appraisal__c = '${appraisalId}' ORDER BY Comment_Date__c DESC`;
    this.template.querySelector('[data-id="commentsModal"]').showSpinner();
    this.template.querySelector('[data-id="commentsModal"]').toggleModal();

    query({ queryString: queryString }).then((results) => {
      this.comments = results;

      this.template.querySelector('[data-id="commentsModal"]').hideSpinner();
    });
  }

  closeCommentModal(event) {
    this.comments = [];
    this.template.querySelector('[data-id="commentsModal"]').toggleModal();
  }

  toggleFilter(event) {
    this.showFilters = !this.showFilters;
  }

  refresh(event) {
    this.isLoading = true;
    this.queryProperties();
  }

  get tableWidth() {
    return this.showFilters ? 8 : 12;
  }

  handleFilterChange(event) {
    let fieldName = event.target.getAttribute("data-name");
    this[fieldName] = event.target.value;
  }
  handleFilterChangepick(event) {
    let fieldName = event.target.getAttribute("data-name");
    this[fieldName] = event.target.value;
    this.queryProperties();
  }

  selectAll(event) {
    console.log("select all");

    const checked = event.target.checked;

    this.template
      .querySelectorAll('[data-name="propertyCheckbox"]')
      .forEach((checkbox) => {
        checkbox.checked = checked;
      });
  }

  get isClearCapital() {
    return this.appraisalFirm === "Clear Capital";
  }

  get isAppraisalNation() {
    return this.appraisalFirm === "Appraisal Nation";
  }

  get isClarocity() {
    return this.appraisalFirm === "Clarocity Valuation Services";
  }

  get isValuationServices() {
    return this.appraisalFirm === "Valuation Services AMC";
  }

  openInhouseModal() {
    let propertyId = "";

    this.template
      .querySelectorAll('[data-name="propertyCheckbox"]')
      .forEach((checkbox) => {
        if (checkbox.checked && !propertyId) {
          propertyId = checkbox.getAttribute("data-id");
        }
      });

    if (propertyId) {
      this.template
        .querySelector("c-appraisal-input-modal")
        .openModal(propertyId);
    }
  }
}