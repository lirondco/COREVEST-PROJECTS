public without sharing class ScheduleOfLenderCostsPDFExtension {
  public Loan_Version__c record { get; set; }
  public List<Loan_Fee__c> loanFees { get; set; }

  public ScheduleOfLenderCostsPDFExtension(
    ApexPages.standardController standardController
  ) {
    this.record = (Loan_Version__c) standardController.getRecord();

    if (this.record.Id != null) {
      this.record = [
        SELECT
          Final_Loan_Amount__c,
          Deposit_Amount__c,
          Deal_Loan_Number__c,
          Borrower__c,
          CloseDate__c,
          Deposit_Collected__c,
          Swap_Rate__c,
          Final_Swap_Rate__c,
          Credit_Spread__c,
          Final_Credit_Spread__c,
          Interest_Rate_Type__c,
          Final_Interest_Rate__c,
          Required_Holdback_Reserve__c,
          Total_Sources__c,
          Origination_Fee_Percentage__c,
          Origination_Fee__c,
          Bridge_Payoff__c,
          Stub_Interest__c,
          Deposit_Lender_Out_of_Pocket__c,
          Total_Lender__c,
          Proceeds_Paid_To_Escrow__c,
          Total_Annual_Tax__c,
          Monthly_Tax__c,
          Reserve_Tax__c,
          Total_Reserve_Tax__c,
          Total_Annual_Insurance__c,
          Monthly_Insurance__c,
          Reserve_Insurance__c,
          Total_Reserve_Insurance__c,
          Total_Annual_Cap_Ex__c,
          Monthly_Cap_Ex__c,
          Reserve_Cap_Ex__c,
          Total_Reserve_Cap_Ex__c,
          Monthly_Payment__c,
          Total_Reserve_at_Closing__c,
          Total_Third_Party__c,
          Net_Proceeds_to_Borrower__c,
          Total_Uses__c,
          Installment_Comment__c,
          Loan_Fees_JSON__c,
          Recourse__c,
          Cash_Management__c,
          Indicative_Rate_Calc__c,
          Deal__r.Term_Loan_Type__c,
          Deal__r.Name,
          Deal__r.Rate_Lock_Picklist__c,
          Legal_Fee__c,
          Discount_Fee_Number__c,
          Early_Lock_Deposit__c
        FROM loan_version__c
        WHERE Id = :this.record.Id
        LIMIT 1
      ];


      if (String.isNotBlank(this.record.Loan_Fees_JSON__c)) {
        this.loanFees = (List<Loan_Fee__c>) JSON.deserializeStrict(
          this.record.Loan_Fees_JSON__c,
          List<Loan_Fee__c>.class
        );
        for(Loan_Fee__c lf : this.loanFees) {
          if(lf.Vendor_Type__c == 'PCA & ESA') {
            lf.Vendor_Type__c = 'Environmental & Engineering';
          }
        }
      }
    }
  }

  @AuraEnabled
  public static String getPDFContent(Id loanVersionId) {
    String retVal;
    if(Test.isRunningTest()) {
      retVal = 'test';
    } else {
      retVal = EncodingUtil.base64Encode(
        new PageReference('/apex/ScheduleOfLenderCostsPDF?id=' + loanVersionId)
          .getContentAsPDF()
      );
    }
    return retVal;
  }
}