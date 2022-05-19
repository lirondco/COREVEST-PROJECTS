({
  fields: [
    "Id",
    "Name",
    "Approved_Advance_Amount_Total__c",
    "Approved_Advance_Amount_Max_Total__c",
    "Wire_Date__c",
    "RecordType_Name__c",
    "(SELECT Id, Approved_Advance_Amount__c, Initial_Disbursement__c, Renovation_Reserve__c, Property__r.Name, Property__r.APN__c, Property__r.County__c, Property__r.Escrow_Company_text__c, Property__r.Escrow_Agent__r.Name, Property__r.Escrow_Agent__r.BillingStreet, Property__r.Escrow_Agent__r.BillingCity, Property__r.Escrow_Agent__r.BillingState, Property__r.Escrow_Agent__r.BillingPostalCode, Property__r.Escrow_Contact_Name__c, Property__r.Title_Company__r.Name, Property__r.Title_Company__r.BillingStreet, Property__r.Title_Company__r.BillingCity, Property__r.Title_Company__r.BillingState, Property__r.Title_Company__r.BillingPostalCode, Property__r.Title_Company__r.Phone, Property__r.Title_Contact_Name__c, Net_Funding__c, Property__r.Requested_Funding_Date__c, Property__r.Acquisition_Price__c, Property__r.City__c, Property__r.State__c, Property__r.ZipCode__c, Property__r.Asset_Maturity_Date__c, Property__r.Renovation_Type_formula__c, Property__r.Approved_Advance_Amount_Max__c, Property__r.Approved_Advance_Amount__c, Property__r.Initial_Disbursement__c, Property__r.Approved_Renovation_Holdback__c  FROM Property_Advances__r)",
    "Deal__r.Name",
    "Deal__r.Loan_Effective_Date__c",
    "Deal__r.Modified_Expiration_Date__c",
    "Deal__r.Stated_Maturity_Date__c",
    "Deal__r.Deal_Loan_Number__c",
    "Deal__r.Product_Sub_Type__c",
    "Deal__r.LOC_Commitment__c",
    "Deal__r.Aggregate_Funding__c",
    "Deal__r.Account.Name",
    "Deal__r.Account.BillingStreet",
    "Deal__r.Account.BillingCity",
    "Deal__r.Account.BillingState",
    "Deal__r.Account.Billing_State_Code__c",
    "Deal__r.Account.BillingPostalCode",
    "Deal__r.Account.Phone",
    "Deal__r.Borrower_Entity__r.Name",
    "Deal__r.Borrower_Entity__r.Company_Jurisdiction__c",
    "Deal__r.Borrower_Entity__r.Entity_Type__c"
  ],

  opportunityFields: [
    "Id",
    "Name",
    "Loan_Effective_Date__c",
    "Modified_Expiration_Date__c",
    "Deal_Loan_Number__c",
    "LOC_Commitment__c",
    "Aggregate_Funding__c",
    "Account.Name",
    "Account.BillingStreet",
    "Account.BillingCity",
    "Account.BillingState",
    "Account.Billing_State_Code__c",
    "Account.BillingPostalCode",
    "Account.Phone",
    "Account.Company_Domicile__c",
    "Account.Company_Jurisdiction__c",
    "Account.Entity_Types__c",
    "Account.Entity_Filing_Date__c",
    "Account.Operating_Agreement_Date__c",
    "Authorized_Signor__c",
    "Signor_Capacity__c",
    "Signor_Capacity_Other__c",
    "CloseDate",
    "Referral_Source__r.Name",
    "Broker_Fees__c",
    "Rate__c",
    "CAF_Upfront_Fee__c",
    // "Interest_Rate_Formula__c",
    // "Broker_Fee_Formula__c",
    // "Origination_Fee_Formula__c",
    // "LOC_Commitment_In_Words__c",
    // "Interest_Rate_In_Words__c",
    // "Origination_Fee_In_Words__c",
    // "Broker_Fees_In_Words__c",
    "Document_Date__c",
    "First_Payment_Date__c",
    //"Guarantor__r.Name",
    //"Guarantor__r.Title",
    "Requested_Advance_Date__c",
    "Owner.Name",
    "LOC_Loan_Type__c",
    "Product_Sub_Type__c",
    //  "Contact__r.FirstName",
    // "Loan_Processor__r.Name",
    "Underwriter__r.Name",
    "Stated_Maturity_Date__c",
    "Order_No__c",
    "Seller__c",
    "Sales_Price__c",
    "Borrower_Entity__r.Name",
    "Borrower_Entity__r.Address_1__c",
    "Borrower_Entity__r.Address_2__c",
    "Borrower_Entity__r.City__c",
    "Borrower_Entity__r.State__c",
    "Borrower_Entity__r.Zip__c",
    "Borrower_Entity__r.Company_Jurisdiction__c",
    "Borrower_Entity__r.Entity_Type__c",
    // "Advance__r.Property_Record_Type__c",
    "Initial_Monthly_Debt_Service_Payment__c"
    //"Daily_Interest_Rate_Total__c",
    //"(SELECT Id, Contact__c  FROM Deal_Contacts__r )"
  ],

  /*AdvanceFields: [
        "Id",
        "Property_Record_Type__c"
    ],
  */
  dealContactFields: [
    "Id",
    "Contact_Name__c",
    "Contact__r.MailingStreet",
    "Contact__r.MailingCity",
    "Contact__r.MailingState",
    "Contact__r.MailingPostalCode",
    "Zip__c",
    "Email__c",
    "Phone__c",
    "Company_Name__c",
    "Street__c",
    "City__c",
    "State__c",
    "Contact_Full_Name__c",
    "Contact_Title__c",
    "Entity_Type__c"
  ],

  propertyFields: [
    "Approved_Advance_Amount__c",
    "Approved_Renovation_Holdback__c",
    "Approved_Advance_Amount_Max__c",
    "Initial_Disbursement_Remaining__c",
    "Initial_Disbursement__c",
    "Reno_Advance_Amount__c",
    //"Net_Funding__c",
    "Id",
    "Name",
    "APN__c",
    "County__c",
    "Escrow_Company_text__c",
    "Escrow_Agent__r.Name",
    "Escrow_Agent__r.BillingStreet",
    "Escrow_Agent__r.BillingCity",
    "Escrow_Agent__r.BillingState",
    "Escrow_Agent__r.BillingPostalCode",
    "Escrow_Contact_Name__c",
    "Title_Company__r.Name",
    "Title_Company__r.BillingStreet",
    "Title_Company__r.BillingCity",
    "Title_Company__r.BillingState",
    "Title_Company__r.BillingPostalCode",
    "Title_Company__r.Phone",
    "Title_Contact_Name__c",
    "Requested_Funding_Date__c",
    "Acquisition_Price__c",
    "City__c",
    "State__c",
    "State_Full__c",
    "ZipCode__c",
    "Legal_Description__c",
    "Asset_Maturity_Date__c",
    "Borrower_Name__c",
    "Deal__r.Contact__r.FirstName",
    "Deal__r.Contact__r.LastName",
    "Renovation_Type_formula__c",
    "RecordTypeId"
  ],

  compileQuery: function (component) {
    return component.get("v.sObjectName") == "Advance__c"
      ? this.compileAdvanceQuery(component)
      : this.compileOpportunityQuery(component);
  },

  compileOpportunityQuery: function (component) {
    let recordId = component.get("v.recordId");
    let queryString = "SELECT ";

    for (let field of this.opportunityFields) {
      queryString += `${field},`;
    }

    queryString += " (SELECT ";
    for (let field of this.propertyFields) {
      queryString += `${field},`;
    }

    queryString = queryString.substr(0, queryString.lastIndexOf(","));
    queryString += " FROM Properties__r ";

    let propertyIds = component.get("v.propertyIds");
    if (!$A.util.isEmpty(propertyIds)) {
      //do stuff here
      queryString += "WHERE Id IN " + propertyIds + " order by Name ASC ";

      // console.log("--propertyIds--");
      // console.log(propertyIds);
    }

    queryString += " ), ";

    queryString += " (SELECT ";
    for (let field of this.dealContactFields) {
      queryString += `${field},`;
    }
    queryString = queryString.substr(0, queryString.lastIndexOf(","));
    queryString += " FROM Deal_Contacts__r ";
    queryString += " ) ";
    /* 
    queryString += " (SELECT ";
    for (let field of this.AdvanceFields) {
      queryString += `${field},`;
    }
	queryString = queryString.substr(0, queryString.lastIndexOf(","));
	queryString += " FROM Advances__r limit 1 ";
      	queryString += " ) ";
	*/
    queryString += ` FROM Opportunity WHERE Id = '${recordId}'`;

    console.log("compileOpportunityQuery--> " + queryString);

    return queryString;
  },

  compileOpportuntiyData: function (component, deal) {
    //console.log(deal);
    let advance = { Deal__r: {}, Deal_Contacts__r: {} };
    let properties = [];
    let dealContactGuarantors = [];
    let dealContactMembers = [];
    let dealContactDirectors = [];
    let dealContactManagers = [];
    let dealContactShareholders = [];
    let dealContactArchitect = [];
    let dealContactContractor = [];
    let dealContactEngineer = [];
    let dealContactEscrowAgent = [];
    //  let dealContactvendar = [];
    let dealContactTitleCompany = [];
    //let advancesList= [];

    this.opportunityFields.forEach((field) => {
      if (field.includes(".")) {
        let fields = field.split(".");

        if (deal.hasOwnProperty(fields[0])) {
          if (!advance["Deal__r"].hasOwnProperty(fields[0])) {
            advance["Deal__r"][fields[0]] = {};
          }

          if (deal[fields[0]].hasOwnProperty(fields[1])) {
            advance["Deal__r"][fields[0]][fields[1]] =
              deal[fields[0]][fields[1]];
          }
        }
      } else if (!$A.util.isEmpty(deal[field])) {
        advance["Deal__r"][field] = deal[field];
      }
    });

    //add a special check for Signor capacity
    if (advance["Deal__r"]["Signor_Capacity__c"] == "Other") {
      advance["Deal__r"]["Signor_Capacity__c"] =
        deal["Signor_Capacity_Other__c"];
    }

    //New changes for adding check for borrower name and addreess
    if (
      !$A.util.isEmpty(advance["Deal__r"]["Borrower_Entity__r"]) &&
      !$A.util.isUndefined(advance["Deal__r"]["Borrower_Entity__r"])
    ) {
      let borrowerdetails = {
        name: advance["Deal__r"]["Borrower_Entity__r"].Name,
        company:
          advance["Deal__r"]["Borrower_Entity__r"].Company_Jurisdiction__c,
        entity: advance["Deal__r"]["Borrower_Entity__r"].Entity_Type__c,
        address1: advance["Deal__r"]["Borrower_Entity__r"].Address_1__c,
        address2:
          !$A.util.isEmpty(
            advance["Deal__r"]["Borrower_Entity__r"].Address_2__c
          ) &&
          !$A.util.isUndefined(
            advance["Deal__r"]["Borrower_Entity__r"].Address_2__c
          )
            ? advance["Deal__r"]["Borrower_Entity__r"].Address_2__c
            : "",
        city: advance["Deal__r"]["Borrower_Entity__r"].City__c,
        state: advance["Deal__r"]["Borrower_Entity__r"].State__c,
        zip: advance["Deal__r"]["Borrower_Entity__r"].Zip__c
      };
      advance["borrowerdetails"] = borrowerdetails;
    } else {
      let borrowerdetails = {
        name: advance["Deal__r"]["Account"].Name,
        company: advance["Deal__r"]["Account"].Company_Jurisdiction__c,
        entity: advance["Deal__r"]["Account"].Entity_Types__c,
        address2: advance["Deal__r"]["Account"].BillingStreet,
        city: advance["Deal__r"]["Account"].BillingCity,
        state: advance["Deal__r"]["Account"].BillingState,
        zip: advance["Deal__r"]["Account"].BillingPostalCode
      };
      advance["borrowerdetails"] = borrowerdetails;
    }

    //seperate ot different entity types
    deal.Deal_Contacts__r &&
      deal.Deal_Contacts__r.forEach((property) => {
        let dealContact = { Deal_Contacts__r: {} };

        this.dealContactFields.forEach((field) => {
          if (field.includes(".")) {
            let fields = field.split(".");

            if (property.hasOwnProperty(fields[0])) {
              if (!dealContact["Deal_Contacts__r"].hasOwnProperty(fields[0])) {
                dealContact["Deal_Contacts__r"][fields[0]] = {};
              }

              if (property[fields[0]].hasOwnProperty(fields[1])) {
                dealContact["Deal_Contacts__r"][fields[0]][fields[1]] =
                  property[fields[0]][fields[1]];
              }
            }
          } else {
            dealContact["Deal_Contacts__r"][field] = property[field];
          }
        });

        if (dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Guarantor") {
          dealContactGuarantors.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Member"
        ) {
          dealContactMembers.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Director"
        ) {
          dealContactDirectors.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Manager"
        ) {
          dealContactManagers.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Shareholder"
        ) {
          dealContactShareholders.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Architect"
        ) {
          dealContactArchitect.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Contractor"
        ) {
          dealContactContractor.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "Engineer"
        ) {
          dealContactEngineer.push(dealContact);
        } else if (
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "EscrowAgent"
        ) {
          dealContactEscrowAgent.push(dealContact);
        } else if (
          /**    else if(dealContact["Deal_Contacts__r"]["Entity_Type__c"]=='vendar'){
		  dealContactvandor.push(dealContact);
      }*/
          dealContact["Deal_Contacts__r"]["Entity_Type__c"] == "TitleCompany"
        ) {
          dealContactTitleCompany.push(dealContact);
        }
      });
    let dealContactObject = {
      Guarantors: dealContactGuarantors,
      Members: dealContactMembers,
      Directors: dealContactDirectors,
      Managers: dealContactManagers,
      Shareholders: dealContactShareholders,
      Architect: dealContactArchitect,
      Contractor: dealContactContractor,
      Engineer: dealContactEngineer,
      EscrowAgent: dealContactEscrowAgent,
      //  "vendar" : dealContactvendar,
      TitleCompany: dealContactTitleCompany
    };
    advance["Deal_Contacts__r"] = dealContactObject;
    console.log("dealContactObject---> " + dealContactObject);

    if (deal.Properties__r && deal.Properties__r.length > 0) {
      deal.Properties__r.forEach((property) => {
        console.log("property ==>" + property);
        let propAdvance = {
          Property__r: {}
        };

        propAdvance["Approved_Advance_Amount__c"] =
          property["Approved_Advance_Amount__c"];
        propAdvance["Initial_Disbursement__c"] =
          property["Initial_Disbursement_Remaining__c"];
        propAdvance["Renovation_Reserve__c"] =
          property["Reno_Advance_Amount__c"];

        this.propertyFields.forEach((field) => {
          if (field.includes(".")) {
            console.log(field);
            let fields = field.split(".");

            if (property.hasOwnProperty(fields[0])) {
              if (!propAdvance["Property__r"].hasOwnProperty(fields[0])) {
                propAdvance["Property__r"][fields[0]] = {};
              }

              if (property[fields[0]].hasOwnProperty(fields[1])) {
                propAdvance["Property__r"][fields[0]][fields[1]] =
                  property[fields[0]][fields[1]];
              }
            }
          } else {
            propAdvance["Property__r"][field] = property[field];
          }
        });

        properties.push(propAdvance);
      });
      //alert(JSON.stringify(properties));
      advance["Property_Advances__r"] = properties;
      console.log(
        "properties JSON --> " +
          JSON.stringify(properties[0].Property__r.RecordTypeId)
      );

      //add special check for Property_Record_Type__c
      console.log(
        "property record type" +
          this.fetchPropertRecordType(
            component,
            properties[0].Property__r.RecordTypeId
          )
      );

      if (
        advance["Property_Advances__r"] &&
        advance["Property_Advances__r"].length > 0 &&
        this.fetchPropertRecordType(
          component,
          properties[0].Property__r.RecordTypeId
        ) == "Ground Up Construction"
      ) {
        advance["Property_Record_Type"] = true;
      } else {
        advance["Property_Record_Type"] = false;
      }
    }

    /*
	//add related list for Advance object records
	deal.Advances__r && deal.Advances__r.forEach(property => {
      let dealAdvances = { Advances__r: {} };

      this.AdvanceFields.forEach(field => {
        if (field.includes(".")) {
          let fields = field.split(".");

          if (property.hasOwnProperty(fields[0])) {
            if (!dealAdvances["Advances__r"].hasOwnProperty(fields[0])) {
              dealAdvances["Advances__r"][fields[0]] = {};
            }

            if (property[fields[0]].hasOwnProperty(fields[1])) {
              dealAdvances["Advances__r"][fields[0]][fields[1]] =
                property[fields[0]][fields[1]];
            }
          }
        } else {
          dealAdvances["Advances__r"][field] = property[field];
        }
      });
	  advancesList.push(dealAdvances);
	});
	advance["Advances__r"] = advancesList;
	*/

    return advance;
  },

  compileAdvanceQuery: function (component) {
    let queryString = "SELECT ";

    for (let field of this.fields) {
      queryString += `${field},`;
    }

    queryString = queryString.substr(0, queryString.lastIndexOf(","));
    let recordId = component.get("v.recordId");
    queryString += ` FROM Advance__c WHERE Id = '${recordId}'`;

    return queryString;
  },

  generateDocx: function (component, docName) {
    debugger;
    if ($A.util.isUndefinedOrNull(component.get("v.record"))) {
      let queryString = this.compileQuery(component);

      console.log(queryString);

      component
        .find("util")
        .queryPromise(queryString)
        .then(
          $A.getCallback((response) => {
            if (component.get("v.sObjectName") == "Opportunity") {
              let record = this.compileOpportuntiyData(component, response[0]);

              component.set("v.record", record);
            } else {
              component.set("v.record", response[0]);
            }

            component
              .find("generator")
              .generateDocx(component.get("v.record"), docName);
          })
        );
    } else {
      component
        .find("generator")
        .generateDocx(component.get("v.record"), docName);
    }
  },
  fetchPropertRecordType: function (component, recordTypeId) {
    var recordTypeName = "";
    component
      .find("util")
      .queryPromise(
        "Select Name From RecordType where Id ='" + recordTypeId + "'"
      )
      .then(
        $A.getCallback((response) => {
          console.log(
            "fetchPropertRecordType response --->" + response[0].Name
          );
          recordTypeName = response[0].Name;
        })
      );
    return recordTypeName;
  },

  // createScheduleACmp: function (component, event) {
  //   $A.createComponent(
  //     "c:scheduleA",
  //     {
  //       dealId: component.get("v.dealId"),
  //       prodSubType: component.get("v.filterFields.ProductSubType"),
  //       propertyIds: component.get("v.propertyIds"),
  //       oncancel: component.getReference("c.onCancel")
  //     },
  //     function (newCmp, status, errorMessage) {
  //       if (status === "SUCCESS") {
  //         var body = component.get("v.body");
  //         body.push(newCmp);
  //         component.set("v.body", body);
  //         component.set("v.displayBridgeIcMemoCmp", true);
  //       }
  //     }
  //   );
  // },
  createLoanApprovalRequestFormCmp: function (component, event) {
    $A.createComponent(
      "c:loanRequestApprovalForm",
      {
        oncancel: component.getReference("c.cancel"),
        dealId: component.get("v.dealId")
      },
      function (newCmp, status, errorMessage) {
        if (status === "SUCCESS") {
          var body = component.get("v.body");
          body.push(newCmp);
          component.set("v.body", body);
          component.set("v.displayBridgeIcMemoCmp", true);
        }
      }
    );
  },

  createBridgeICMemoCmp: function (component, event) {
    $A.createComponent(
      "c:BridgeICMemo",
      {
        recordId: component.get("v.recordId")
      },
      function (newCmp, status, errorMessage) {
        if (status === "SUCCESS") {
          var body = component.get("v.body");
          body.push(newCmp);
          component.set("v.body", body);
          component.set("v.displayBridgeIcMemoCmp", true);
        } else if (status === "ERROR") {
          console.log("Error: " + errorMessage);
        }
      }
    );
  },
  createSABICMemoCmp: function (component, event) {
    $A.createComponent(
      "c:SABICMemo",
      {
        recordId: component.get("v.recordId")
      },
      function (newCmp, status, errorMessage) {
        if (status === "SUCCESS") {
          var body = component.get("v.body");
          body.push(newCmp);
          component.set("v.body", body);
          component.set("v.displayBridgeIcMemoCmp", true);
        } else if (status === "ERROR") {
          console.log("Error: " + errorMessage);
        }
      }
    );
  },
  setStaticResourceName: function (component, val) {
    if (val == "State Level Security Instruments") {
      component.set("v.staticResourceName", "BridgeStateDocuments");
    } else if (val == "Assignment Sets") {
      component.set("v.staticResourceName", "DocGenAssignments");
    } else {
      component.set("v.staticResourceName", "AdvanceDocuments");
    }
  },

  generateAssignmentSetOptions: function (component) {
    const states = [
      "Alabama",
      "Alaska",
      "Arizona",
      "Arkansas",
      "California",
      "Colorado",
      "Connecticut",
      "Delaware",
      "District of Columbia",
      "Florida",
      "Georgia",
      "Hawaii",
      "Idaho",
      "Illinois",
      "Indiana",
      "Iowa",
      "Kansas",
      "Kentucky",
      "Louisiana",
      "Maine",
      "Maryland",
      "Massachusetts",
      "Michigan",
      "Minnesota",
      "Mississippi",
      "Missouri",
      "Montana",
      "North Carolina",
      "North Dakota",
      "Nebraska",
      "Nevada",
      "New Hampshire",
      "New Jersey",
      "New Mexico",
      "New York",
      "Ohio",
      "Oklahoma",
      "Oregon",
      "Pennsylvania",
      "Rhode Island",
      "South Carolina",
      "South Dakota",
      "Tennessee",
      "Texas",
      "Utah",
      "Vermont",
      "Virginia",
      "Washington",
      "West Virginia",
      "Wisconsin",
      "Wyoming"
    ];

    const specialStates = [
      "Georgia",
      "Louisiana",
      "Connecticut",
      "New York",
      "South Carolina",
      "Indiana"
    ];

    const fileNames = [
      "Bridge_template_ASSIGNMENT_SET_Deed_of_Trust_except_GA_LA_CT_SC_IN.docx",
      "Bridge_template_ASSIGNMENT_SET_Connecticut_ONLY.docx",
      "Bridge_template_ASSIGNMENT_SET_South_Carolina_ONLY.docx",
      "Bridge_template_ASSIGNMENT_SET_New_York_ONLY.docx",
      "Bridge_template_ASSIGNMENT_SET_Lousiana_ONLY.docx",
      "Bridge_template_ASSIGNMENT_SET_Indiana_ONLY.docx",
      "Bridge_template_ASSIGNMENT_SET_Georgia_ONLY.docx"
    ];

    const assignmentSetOptions = states.map((v) => {
      if (specialStates.includes(v)) {
        return {
          label: v,
          value: fileNames.find((f) => f.includes(v.replaceAll(" ", "_")))
        };
      } else {
        return {
          label: v,
          value: fileNames[0]
        };
      }
    });

    component.set("v.assignmentSetStateOptions", assignmentSetOptions);
  }
});
