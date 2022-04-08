import { LightningElement, api, wire } from "lwc";
import {
  subscribe,
  unsubscribe,
  APPLICATION_SCOPE,
  MessageContext,
  publish
} from "lightning/messageService";

import calcMessage from "@salesforce/messageChannel/ScheduleLoanAgreementMessage__c";
import Interest_Rate_Type__c from "@salesforce/schema/Loan_Version__ChangeEvent.Interest_Rate_Type__c";

export default class ScheduleOfLenderCostsNew extends LightningElement {
  @api deal;
  @api recordTypeId;
  @api recordId;
  @api val1234 = 456;
  subscription = null;

  calculatedFields = {};
  loanFees = [];
  //@api loanVersion = {};

  @wire(MessageContext)
  messageContext;

  constructor() {
    super();
  }

  connectedCallback() {
    console.log("init of new");
    this.updateCalculatedFields();

    this.subscribeMessageChannel();
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
      this.updateCalculatedFields();
    }
  }

  updateCalculatedFields() {
    var v1 = 100;
    console.log("inside a func");
    //const calculatedFields = this.calculatedFields;
    let calculatedFields = {
      Final_Interest_Rate__c: this.finalInterestRateCalc(),
      Calculated_Origination_Fee__c: this.finalorignalfeeCalc(),
      Required_Holdback_Reserve__c: this.totalHoldbackReserveCalc(),
      Holdback_Reserve__c: this.holdbackReserveCalc(),
      Total_Sources__c: this.totalSourcesCalc(),
      Stub_Interest__c: this.stubInterestCalc(),
      Total_Lender__c: this.totalLenderCalc(),
      Proceeds_Paid_To_Escrow__c: this.corevestProceedsCalc(),
      Monthly_Tax__c: this.monthlyTaxCalc(),
      Total_Reserve_Tax__c: this.totalReserveTaxCalc(),
      Monthly_Insurance__c: this.monthlyInsuranceCalc(),
      Total_Reserve_Insurance__c: this.totalReserveInsuranceCalc(),
      Monthly_Cap_Ex__c: this.monthlyCapExCalc(),
      Total_Reserve_Cap_Ex__c: this.totalReserveCapExCalc(),
      Monthly_Payment__c: this.monthlyPaymentCalc(),
      Total_Reserve_at_Closing__c: this.totalReserveClosingCalc(),
      Total_Third_Party__c: this.totalThirdPartyCalc(),
      Net_Proceeds_to_Borrower__c: this.netProceedsBorrowerCalc(),
      Total_Uses__c: this.totalUsesCalc(),
      Holdback_Reserve_Override__c: this.deal.Holdback_Reserve_Override__c,
      Interest_Rate_Type__c: this.rateType,
      Total_Annual_Tax__c: this.deal.Total_Annual_Tax__c,
      Reserve_Tax__c: this.deal.Reserve_Tax__c,
      Total_Annual_Insurance__c: this.deal.Total_Annual_Insurance__c,
      Reserve_Insurance__c: this.deal.Reserve_Insurance__c,
      Total_Annual_Cap_Ex__c: this.deal.Total_Annual_Cap_Ex__c,
      Reserve_Cap_Ex__c: this.deal.Reserve_Cap_Ex__c,
      Bridge_Payoff__c: this.deal.Bridge_Payoff__c,
      Deposit_Lender_Out_of_Pocket__c: this.deal
        .Deposit_Lender_Out_of_Pocket__c,
      Legal_Fee__c: this.deal.Legal_Fee__c,
      Holdback_Reserve_Month_Multiplier__c: this.deal
        .Holdback_Reserve_Month_Multiplier__c,
      Installment_Comment__c: this.deal.Installment_Comment__c
    };
    //console.log("--updating--");
    //console.log(`scheduleData-${this.recordId}`);

    sessionStorage.setItem(
      `scheduleData-${this.recordId}`,
      JSON.stringify(calculatedFields)
    );

    publish(this.messageContext, calcMessage, {
      calculatedFields: calculatedFields,
      type: "update"
    });

    this.calculatedFields = calculatedFields;
  }

  handleUpdate(event) {
    // console.log("handle event");
    let loanFees = event.detail;

    // console.log("--loan fees update--");
    // console.log(loanFees);
    this.loanFees = loanFees;
    this.updateCalculatedFields();
  }

  get interestRateTypes() {
    const options = [
      { label: "", value: "" },
      { label: "Amortized", value: "Amortized" },
      { label: "Partial I/O", value: "Partial I/O" },
      { label: "Interest Only", value: "Interest Only" }
    ];

    return options;
  }

  get rateType() {
    const amTerm = this.deal.Amortization_Term__c && this.deal.Amortization_Term__c.toLowerCase();
    const ioTerm = this.deal.IO_Term__c && this.deal.IO_Term__c.toLowerCase();
    const baseCriteriaVal = "0 months";
    
    return (
      amTerm == baseCriteriaVal && ioTerm != baseCriteriaVal
      ? "Interest Only"
      : amTerm != baseCriteriaVal && ioTerm == baseCriteriaVal
      ? "Amortized"
      : amTerm != baseCriteriaVal && ioTerm != baseCriteriaVal
      ? "Partial I/O"
      : ""
    )
  }

  // get holdbackReserve() {
  //   return this.holdbackReserveCalc();
  // }

  totalHoldbackReserveCalc() {
    let val = this.holdbackReserveCalc();

    let override = this.deal.Holdback_Reserve_Override__c;
    let multiplier = this.deal.Holdback_Reserve_Month_Multiplier__c;

    if (override) {
     val = override;
    }

    if (multiplier) {
      val = multiplier * val;
    }

    // let holdbackReserveCalc =

    return val;
  }

  holdbackReserveCalc() {
    // console.log("--holdbackReserveCalc--");

    // console.trace();
    let val = 0;

    var PV = this.deal.Current_Loan_Amount__c;
    var Indicative_Rate = this.finalInterestRateCalc();
    //console.log(PV);
    //console.log(Indicative_Rate);
    // console.log(this.deal.Interest_Rate_Type__c);

    //console.log("indicative_rate");
    //console.log(Indicative_Rate);

    if (this.rateType == "Amortized") {
      if (PV && Indicative_Rate) {
        // //PMT= (PV*Rate*(1+Rate)^nper)/[(1+Rate)^nper - 1]
        var rate = parseFloat(((Indicative_Rate / 12 / 100) * 365) / 360);
        var pmt = parseFloat(
          (PV * rate * Math.pow(1 + rate, 360)) / (Math.pow(1 + rate, 360) - 1)
        ).toFixed(2);

        val = pmt;
      }
    } else if (this.rateType == "Interest Only" || this.rateType == "Partial I/O") {
      // if (PV && Indicative_Rate && this.deal.IO_Term__c) {
      //   //IPMT = pmt + (1+rate)^(nper-1)*(pv *rate - pmt)
      //   var rate = parseFloat((Indicative_Rate * 365) / (12 * 360 * 100));
      //   var IO_Term = this.deal.IO_Term__c;
      //   var nper = parseInt(IO_Term.split(" months")[0]);
      //   var pmt = parseFloat(
      //     (PV * rate * Math.pow(1 + rate, 360)) / (Math.pow(1 + rate, 360) - 1)
      //   );
      //   var ipmt = parseFloat(
      //     pmt + (1 + Math.pow(rate, nper - 1)) * PV * rate - pmt
      //   ).toFixed(2);
      //   //component.find("DebtService").set("v.value", ipmt);
      //   val = ipmt;
      // }

      if (PV && Indicative_Rate) {
        val = (PV * ((Indicative_Rate / 100 / 360) * 31)).toFixed(2);
      }
    }
    // console.log("--hold back reserve calc--");
    //console.log(val);

    return val;
  }

  // get finalInterestRate() {
  //   return this.finalInterestRateCalc();
  // }

  finalInterestRateCalc() {
    var InterestRateTermSheet = 0;
    if (this.deal.Final_Swap__c && this.deal.Final_Spread__c) {
      var yearSwapRate = parseFloat(this.deal.Final_Swap__c);
      var creditSpread = parseFloat(this.deal.Final_Spread__c);
      InterestRateTermSheet = parseFloat(yearSwapRate + creditSpread).toFixed(
        2
      );
    }

    //console.log("--finalInterestRateCalc=", InterestRateTermSheet);

    return InterestRateTermSheet;
  }

  // get totalSources() {
  //   return this.totalSourcesCalc();
  // }

  totalSourcesCalc() {
    var TotalSources = null;
    var Deposit_Amount = 0;
    if (this.deal.Current_Loan_Amount__c && this.deal.Deposit_Amount__c) {
      var Final_Loan_Amount = parseFloat(this.deal.Current_Loan_Amount__c);
      if (this.deal.Deposit_Amount__c != null || this.deal.Deposit_Amount__c != 0) {
        Deposit_Amount = parseFloat(this.deal.Deposit_Amount__c);
      } else {
        Deposit_Amount = 0;
      }
      TotalSources = parseFloat(Final_Loan_Amount + Deposit_Amount).toFixed(2);
    }

    return TotalSources;
  }

  // get stubInterest() {
  //   return this.stubInterestCalc();
  // }

  fundingDateCalc() {
    let closingDate = new Date(this.deal.CloseDate);

    let fundingDate2 = new Date(
      closingDate.getUTCFullYear(),
      closingDate.getUTCMonth() + 1,
      0
    );
    fundingDate2 = fundingDate2.toISOString();

    return fundingDate2;
  }

  stubInterestDayCountCalc() {
    let stubInterestDayCount = null;

    let fundingDate1 = this.deal.CloseDate;
    let fundingDate2 = this.fundingDateCalc();

    var date1 = new Date(fundingDate1);
    var date2 = new Date(fundingDate2);
    var diffTime = Math.abs(date2.getUTCDate() - date1.getUTCDate() + 1);
    stubInterestDayCount = diffTime;
    // console.log(date2.getUTCDate() + ' - ' +  date1.getUTCDate());
    // console.log("stub interest day count");
    // console.log(stubInterestDayCount);
    return stubInterestDayCount;
  }

  stubInterestCalc() {
    var stubInterest = 0;
    var InterestRateTermSheet = 0;
    var Final_Loan_Amount = 0;
    var stubInterestDayCount = 0;

    let finalInterestRate = this.finalInterestRateCalc();
    if (finalInterestRate) {
      InterestRateTermSheet = parseFloat(finalInterestRate).toFixed(2);
    }
    if (this.deal.Current_Loan_Amount__c) {
      Final_Loan_Amount = parseFloat(this.deal.Current_Loan_Amount__c).toFixed(
        2
      );
    }

    //Round(Interest Rate/360*Final Loan Amount*(Date difference of the last day of the closed date month - the Closed Date)


    let stubInterestDay = this.stubInterestDayCountCalc();

    if (stubInterestDay) {
      stubInterestDayCount = parseFloat(stubInterestDay).toFixed(2);
    }
    stubInterest = parseFloat(
      parseFloat((InterestRateTermSheet) / 36000) *
        parseFloat(Final_Loan_Amount) *
        parseFloat(stubInterestDayCount)
    ).toFixed(2);
    
    console.log(`Calculating as: (${InterestRateTermSheet}/36000)*${Final_Loan_Amount}*${stubInterestDayCount} = ${stubInterest}`);
    return stubInterest;
  }

  // get totalLender() {
  //   return this.totalLenderCalc();
  // }

  totalLenderCalc() {
    var totalLender = 0;
    var Origination_Fee = 0;
    var stubInterest = 0;
    var Lender_Diligence_Out_of_Pocket = 0;
    var cfcorevestpurchaser = 0;
    var legalFee = 0;
    let CalculatedOriginationFee = this.finalorignalfeeCalc();
    if (CalculatedOriginationFee) {
      Origination_Fee = parseFloat(CalculatedOriginationFee).toFixed(2);
    }

    let stubInterestTemp = this.stubInterestCalc();

    if (stubInterestTemp) {
      stubInterest = parseFloat(stubInterestTemp).toFixed(2);
    }
    if (this.deal.Deposit_Lender_Out_of_Pocket__c) {
      Lender_Diligence_Out_of_Pocket = parseFloat(
        this.deal.Deposit_Lender_Out_of_Pocket__c
      ).toFixed(2);
    }
    if (this.deal.Legal_Fee__c) {
      legalFee = parseFloat(
        this.deal.Legal_Fee__c
      ).toFixed(2);
    }
    if (this.deal.Bridge_Payoff__c) {
      cfcorevestpurchaser = parseFloat(this.deal.Bridge_Payoff__c).toFixed(2);
    }
    totalLender = parseFloat(
      parseFloat(
        parseFloat(Origination_Fee) +
          parseFloat(stubInterest) +
          parseFloat(Lender_Diligence_Out_of_Pocket) +
          parseFloat(cfcorevestpurchaser) +
          parseFloat(legalFee)
      )
    ).toFixed(2);

    return totalLender;
  }

  // get corevestProceeds() {
  //   return this.corevestProceedsCalc();
  // }

  corevestProceedsCalc() {
    var CorevestProceeds = 0;
    var TotalSources = 0;
    var totalLender = 0;

    let totalSources = this.totalSourcesCalc();

    if (totalSources) {
      TotalSources = parseFloat(totalSources).toFixed(2);
    }
    let totalLenderCalc = this.totalLenderCalc();
    if (totalLenderCalc) {
      totalLender = parseFloat(totalLenderCalc).toFixed(2);
    }
    CorevestProceeds = parseFloat(
      parseFloat(TotalSources) - parseFloat(totalLender)
    ).toFixed(2);

    return CorevestProceeds;
  }

  // get monthlyTax() {
  //   return this.monthlyTaxCalc();
  // }

  monthlyTaxCalc() {
    var tax = 0;
    var taxentry = 0;
    if (this.deal.Total_Annual_Tax__c) {
      taxentry = parseFloat(this.deal.Total_Annual_Tax__c);
      tax = parseFloat(taxentry / 12).toFixed(2);
    }
    return tax;
  }

  // get totalReserveTax() {
  //   return this.totalReserveTaxCalc();
  // }

  totalReserveTaxCalc() {
    var totalreservetax = 0;
    var tax = 0;
    var reservetax = 0;

    let monthlyTaxCalc = this.monthlyTaxCalc();

    if (monthlyTaxCalc) {
      tax = parseFloat(monthlyTaxCalc);
    }
    if (this.deal.Reserve_Tax__c) {
      reservetax = parseFloat(this.deal.Reserve_Tax__c);
    }
    totalreservetax =
      reservetax != 0 ? parseFloat(tax * reservetax).toFixed(2) : 0;
    return totalreservetax;
  }

  // get monthlyInsurance() {
  //   return this.monthlyInsuranceCalc();
  // }

  monthlyInsuranceCalc() {
    var insurance = 0;
    var insuranceentry = 0;
    if (this.deal.Total_Annual_Insurance__c) {
      insuranceentry = parseFloat(this.deal.Total_Annual_Insurance__c);
      insurance = parseFloat(insuranceentry / 12).toFixed(2);
    }

    return insurance;
  }

  // get totalReserveInsurance() {
  //   return this.totalReserveInsuranceCalc();
  // }

  totalReserveInsuranceCalc() {
    var totalreserveinsurance = 0;
    var insurence = 0;
    var reserveinsurance = 0;

    let monthlyInsuranceCalc = this.monthlyInsuranceCalc();

    if (monthlyInsuranceCalc) {
      insurence = parseFloat(monthlyInsuranceCalc);
    }
    if (this.deal.Reserve_Insurance__c) {
      reserveinsurance = parseFloat(this.deal.Reserve_Insurance__c);
    }
    totalreserveinsurance =
      reserveinsurance != 0
        ? parseFloat(insurence * reserveinsurance).toFixed(2)
        : 0;

    return totalreserveinsurance;
  }

  // get monthlyCapEx() {
  //   return this.monthlyCapExCalc();
  // }

  monthlyCapExCalc() {
    var capex = 0;
    var capexentry = 0;
    if (this.deal.Total_Annual_Cap_Ex__c) {
      capexentry = parseFloat(this.deal.Total_Annual_Cap_Ex__c);
      capex = parseFloat(capexentry / 12);
    }
    return capex;
  }

  // get totalReserveCapEx() {
  //   return this.totalReserveCapExCalc();
  // }
  finalorignalfeeCalc() {
    var finalorignalfee = 0;
    // console.log("this.deal.LOC_Commitment__c==", this.deal.LOC_Commitment__c);
    // console.log("this.deal.CAF_Upfront_Fee__c==", this.deal.CAF_Upfront_Fee__c);
    // console.log(
    //   "this.deal.Current_Loan_Amount__c==",
    //   this.deal.Current_Loan_Amount__c
    // );
    // console.log("this.deal.RecordType==", this.deal.RecordType__c);
    // console.log(
    //   "this.deal.Final_Loan_Amount__c==",
    //   this.deal.Final_Loan_Amount__c
    // );
    var tlone = "Term Loan";
    var blone = "Bridge Loan";
    //this.deal.Final_Loan_Amount__c

    if (blone.indexOf(this.deal.RecordType__c) > -1) {
      finalorignalfee =
        (this.deal.LOC_Commitment__c * this.deal.CAF_Upfront_Fee__c) / 100;
      //console.log("finalorignalfee==if", finalorignalfee);
    } else {
      if (
        tlone.indexOf(this.deal.RecordType__c) > -1 &&
        this.deal.Final_Loan_Amount__c
      ) {
        finalorignalfee = Math.max(
          7500,
          (this.deal.Final_Loan_Amount__c * this.deal.CAF_Upfront_Fee__c) / 100
        );
        //console.log("finalorignalfee==if==", finalorignalfee);
      } else {
        finalorignalfee = Math.max(
          7500,
          (this.deal.Current_Loan_Amount__c * this.deal.CAF_Upfront_Fee__c) /
            100
        );
        //console.log("finalorignalfee==else", finalorignalfee);
      }
    }

    return finalorignalfee;
  }

  totalReserveCapExCalc() {
    var totalreservecapex = 0;
    var capex = 0;
    var reservecapex = 0;

    let monthlyCapExCalc = this.monthlyCapExCalc();
    if (monthlyCapExCalc) {
      capex = parseFloat(monthlyCapExCalc);
    }
    if (this.deal.Reserve_Cap_Ex__c) {
      reservecapex = parseFloat(this.deal.Reserve_Cap_Ex__c);
    }
    totalreservecapex =
      reservecapex != 0 ? parseFloat(capex * reservecapex).toFixed(2) : 0;
    return totalreservecapex;
  }

  // get monthlyPayment() {
  //   return this.monthlyPaymentCalc();
  // }

  monthlyPaymentCalc() {
    var capex = 0;
    var insurence = 0;
    var tax = 0;
    var DebtService = 0;
    var debtreserve = 0;

    let monthlyCapExCalc = this.monthlyCapExCalc();

    let monthlyInsuranceCalc = this.monthlyInsuranceCalc();

    let monthlyTaxCalc = this.monthlyTaxCalc();

    let holdbackReserveCalc = this.holdbackReserveCalc();

    if (monthlyCapExCalc) {
      capex = parseFloat(monthlyCapExCalc);
    }
    if (monthlyInsuranceCalc) {
      insurence = parseFloat(monthlyInsuranceCalc);
    }
    if (monthlyTaxCalc) {
      tax = parseFloat(monthlyTaxCalc);
    }
    if (holdbackReserveCalc) {
      DebtService = parseFloat(holdbackReserveCalc);
    }

    debtreserve = parseFloat(capex + insurence + tax + DebtService).toFixed(2);
    return debtreserve;
  }

  // get totalReserveClosing() {
  //   return this.totalReserveClosingCalc();
  // }
  totalReserveClosingCalc() {
    var totalreserves = 0;

    let holdbackReserveCalc = this.totalHoldbackReserveCalc(); //this.holdbackReserveCalc();

    if (
      holdbackReserveCalc
      //&&
      //this.deal.Recourse__c == "Non-Recourse" &&
      //this.deal.Cash_Management__c === "None"
    ) {
      totalreserves += parseFloat(holdbackReserveCalc);
    }
    let totalReserveTaxCalc = this.totalReserveTaxCalc();
    if (totalReserveTaxCalc) {
      totalreserves += parseFloat(totalReserveTaxCalc);
    }

    let totalReserveCapExCalc = this.totalReserveCapExCalc();
    if (totalReserveCapExCalc) {
      totalreserves += parseFloat(totalReserveCapExCalc);
    }

    let totalReserveInsuranceCalc = this.totalReserveInsuranceCalc();
    if (totalReserveInsuranceCalc) {
      totalreserves += parseFloat(totalReserveInsuranceCalc);
    }
    return totalreserves;
  }

  // get totalThirdParty() {
  //   return this.totalThirdPartyCalc();
  // }

  totalThirdPartyCalc() {
    let totalThirdParty = 0;
    let loanFees = this.loanFees;

    if (loanFees) {
      loanFees.forEach((loanFee) => {
        let amt = 0;
        if (loanFee.Fee_Amount__c) {
          amt = loanFee.Fee_Amount__c;
        }

        totalThirdParty += amt;
      });
    }

    return totalThirdParty;
  }

  // get netProceedsBorrower() {
  //   return this.netProceedsBorrowerCalc();
  // }

  netProceedsBorrowerCalc() {
    var netproceedstoborrower = 0;

    let totalSourcesCalc = this.totalSourcesCalc();
    if (totalSourcesCalc) {
      netproceedstoborrower += parseFloat(totalSourcesCalc).toFixed(2);
    }

    let totalLenderCalc = this.totalLenderCalc();
    if (totalLenderCalc) {
      netproceedstoborrower -= parseFloat(totalLenderCalc).toFixed(2);
    }

    let totalReserveClosingCalc = this.totalReserveClosingCalc();
    if (totalReserveClosingCalc) {
      netproceedstoborrower -= parseFloat(totalReserveClosingCalc).toFixed(2);
    }

    let totalThirdPartyCalc = this.totalThirdPartyCalc();
    if (totalThirdPartyCalc) {
      netproceedstoborrower -= parseFloat(totalThirdPartyCalc).toFixed(2);
    }
    return netproceedstoborrower;
  }

  // get totalUses() {
  //   return this.totalUsesCalc();
  // }

  totalUsesCalc() {
    var totaluses = 0;

    let netProceedsBorrowerCalc = this.netProceedsBorrowerCalc();
    if (netProceedsBorrowerCalc) {
      totaluses += parseFloat(netProceedsBorrowerCalc);
    }

    let totalLenderCalc = this.totalLenderCalc();
    if (totalLenderCalc) {
      totaluses += parseFloat(totalLenderCalc);
    }

    let totalReserveClosingCalc = this.totalReserveClosingCalc();
    if (totalReserveClosingCalc) {
      totaluses += parseFloat(totalReserveClosingCalc);
    }

    let totalThirdPartyCalc = this.totalThirdPartyCalc();
    if (totalThirdPartyCalc) {
      totaluses += parseFloat(totalThirdPartyCalc);
    }
    //component.find("totaluses").set("v.value", totaluses);
    return totaluses;
  }

  updateValue(event) {
    // console.log(event.target.value);
    // console.log(event.target.getAttribute("data-field"));
    const deal = JSON.parse(JSON.stringify(this.deal));
    deal[event.target.getAttribute("data-field")] = event.target.value;
    this.deal = deal;
    this.updateCalculatedFields();
  }

  @api returnLoanVersion() {
    let deal = this.deal;
    let calculatedFields = this.calculatedFields;

    let loanFees = this.loanFees;

    loanFees.forEach((loanFee) => {
      if (
        loanFee.Vendor__c &&
        loanFee.Vendor__r.Name === "Berkadia Commercial Mortgage"
      ) {
        loanFee.Fee_Amount__c = calculatedFields.Total_Reserve_at_Closing__c;
      }
    });

    let discountFee = '', discountFeeNumber = 0;

    if(deal.Discount_Fee__c) {
      discountFee = deal.Discount_Fee__c;
      discountFeeNumber = deal.Discount_Fee_Formula__c;
    }

    let loanVersion = {
      Final_Loan_Amount__c: deal.Current_Loan_Amount__c,
      Deposit_Amount__c: deal.Deposit_Amount__c,
      Deal_Loan_Number__c: deal.Deal_Loan_Number__c,
      Borrower__c: deal.Borrower_Name,
      CloseDate__c: deal.CloseDate,
      Deposit_Collected__c: deal.Deposit_Collected__c,
      Swap_Rate__c: deal.Swap_Rate__c,
      Final_Swap_Rate__c: deal.Final_Swap__c,
      Credit_Spread__c: deal.Spread_BPS__c,
      Final_Credit_Spread__c: deal.Final_Spread__c,
      Interest_Rate_Type__c: deal.Interest_Rate_Type__c,
      Final_Interest_Rate__c: calculatedFields.Final_Interest_Rate__c,
      Required_Holdback_Reserve__c:
        calculatedFields.Required_Holdback_Reserve__c,
      Holdback_Reserve__c: calculatedFields.Holdback_Reserve__c,
      Total_Sources__c: calculatedFields.Total_Sources__c,
      Origination_Fee_Percentage__c: deal.CAF_Upfront_Fee__c,
      Origination_Fee__c: calculatedFields.Calculated_Origination_Fee__c,
      Bridge_Payoff__c: deal.Bridge_Payoff__c,
      Stub_Interest__c: calculatedFields.Stub_Interest__c,
      Deposit_Lender_Out_of_Pocket__c: deal.Deposit_Lender_Out_of_Pocket__c,
      Legal_Fee__c: deal.Legal_Fee__c,
      Total_Lender__c: calculatedFields.Total_Lender__c,
      Proceeds_Paid_To_Escrow__c: calculatedFields.Proceeds_Paid_To_Escrow__c,
      Total_Annual_Tax__c: deal.Total_Annual_Tax__c,
      Monthly_Tax__c: calculatedFields.Monthly_Tax__c,
      Reserve_Tax__c: deal.Reserve_Tax__c,
      Total_Reserve_Tax__c: calculatedFields.Total_Reserve_Tax__c,
      Total_Annual_Insurance__c: deal.Total_Annual_Insurance__c,
      Monthly_Insurance__c: calculatedFields.Monthly_Insurance__c,
      Reserve_Insurance__c: deal.Reserve_Insurance__c,
      Total_Reserve_Insurance__c: calculatedFields.Total_Reserve_Insurance__c,
      Total_Annual_Cap_Ex__c: deal.Total_Annual_Cap_Ex__c,
      Monthly_Cap_Ex__c: calculatedFields.Monthly_Cap_Ex__c,
      Reserve_Cap_Ex__c: deal.Reserve_Cap_Ex__c,
      Total_Reserve_Cap_Ex__c: calculatedFields.Total_Reserve_Cap_Ex__c,
      Monthly_Payment__c: calculatedFields.Monthly_Payment__c,
      Total_Reserve_at_Closing__c: calculatedFields.Total_Reserve_at_Closing__c,
      Total_Third_Party__c: calculatedFields.Total_Third_Party__c,
      Net_Proceeds_to_Borrower__c: calculatedFields.Net_Proceeds_to_Borrower__c,
      Total_Uses__c: calculatedFields.Total_Uses__c,
      Installment_Comment__c: deal.Installment_Comment__c,
      Loan_Fees_JSON__c: JSON.stringify(this.loanFees),
      Recourse__c: deal.Recourse__c,
      Cash_Management__c: deal.Cash_Management__c,
      Indicative_Rate_Calc__c: deal.Indicative_Rate_Calc__c,
      Holdback_Reserve_Override__c: deal.Holdback_Reserve_Override__c,
      Holdback_Reserve_Month_Multiplier__c:
        deal.Holdback_Reserve_Month_Multiplier__c,
      Term__c: deal.Term_Loan_Type__c,
      Discount_Fee__c: discountFee,
      Discount_Fee_Number__c: discountFeeNumber,
    };

    // console.log(loanVersion);

    return loanVersion;
  }
}