public without sharing class ScheduleOfLenderCostController {
  public boolean printReady { get; set; }
  public String filtersJSON { get; set; }
  public WrapperData unsavedObj { get; set; }
  public Opportunity Deal { get; set; }
  public List<Deal_Contact__c> vendors { get; set; }
  public List<Loan_Fee__c> loanFees { get; set; }
  public decimal stubInterest { get; set; }
  public decimal CorevestProceeds { get; set; }
  public decimal totalLender { get; set; }
  public decimal legalFee { get; set; }
  public decimal totalreservecapex { get; set; }
  public decimal totalreserveinsurance { get; set; }
  public decimal totalreservetax { get; set; }
  public decimal debtreserve { get; set; }
  public decimal totalreserves { get; set; }
  public decimal totalthirdparty { get; set; }
  public decimal netproceedstoborrower { get; set; }
  public decimal TotalSources { get; set; }
  public decimal totaluses { get; set; }

  public void getData() {
    printReady = false;
    if (filtersJSON.substring(0, 1) != '$') {
      if (String.isNotBlank(filtersJSON)) {
        try {
          System.debug('filtersJSON---> ' + filtersJSON);
          unsavedObj = (WrapperData) JSON.deserialize(
            filtersJSON,
            WrapperData.class
          );
          if (
            unsavedObj.stubInterest != null &&
            unsavedObj.totalreservetax != null &&
            unsavedObj.totalreservecapex != null &&
            unsavedObj.totalreserveinsurance != null
          ) {
            stubInterest = unsavedObj.stubInterest != null
              ? decimal.valueOf(unsavedObj.stubInterest)
              : null;
            totalLender = unsavedObj.totalLender != null
              ? decimal.valueOf(unsavedObj.totalLender)
              : null;
            legalFee = unsavedObj.legalFee != null
              ? decimal.valueOf(unsavedObj.legalFee)
              : null;
            CorevestProceeds = unsavedObj.CorevestProceeds != null
              ? decimal.valueOf(unsavedObj.CorevestProceeds)
              : null;
            totalreserveinsurance = unsavedObj.totalreserveinsurance != null
              ? decimal.valueOf(unsavedObj.totalreserveinsurance)
              : null;
            totalreservetax = unsavedObj.totalreservetax != null
              ? decimal.valueOf(unsavedObj.totalreservetax)
              : null;
            totalreservecapex = unsavedObj.totalreservecapex != null
              ? decimal.valueOf(unsavedObj.totalreservecapex)
              : null;
            totalreserves = unsavedObj.totalreserves != null
              ? decimal.valueOf(unsavedObj.totalreserves)
              : null;
            totalthirdparty = unsavedObj.totalthirdparty != null
              ? decimal.valueOf(unsavedObj.totalthirdparty)
              : null;
            netproceedstoborrower = unsavedObj.netproceedstoborrower != null
              ? decimal.valueOf(unsavedObj.netproceedstoborrower)
              : null;
            TotalSources = unsavedObj.TotalSources != null
              ? decimal.valueOf(unsavedObj.TotalSources)
              : null;
            totaluses = unsavedObj.totaluses != null
              ? decimal.valueOf(unsavedObj.totaluses)
              : null;
          }

          Deal = getData(unsavedObj.dealId);
          vendors = [
            SELECT
              Id,
              Name,
              Payment_Reference__c,
              Account__r.Name,
              Account__r.Payment_Instructions__c,
              Vendor_Type__c
            FROM Deal_Contact__C
            WHERE
              Deal__C = :unsavedObj.dealId
              AND Account__c != NULL
              AND Vendor_Type__c IN (
                'Legal Counsel',
                'Valuation',
                'Insurance Review',
                'Cash Management',
                '3rd Party Title',
                'Flood Check',
                'Architect',
                'Contractor',
                'Engineer',
                'Escrow Agent',
                'Insurance',
                'Lease/Purchase Review',
                'Rent Deposit Bank',
                'Servicer',
                'Tax Verification',
                'Title and Escrow',
                'Title and Escrow 2',
                'Title Company',
                'Reserves'
              )
          ];
          loanFees = [
            SELECT
              Id,
              Vendor_Type__c,
              Fee_Amount__c,
              Reference__c,
              vendor__r.Name,
              vendor__r.Payment_Instructions__c
            FROM Loan_Fee__c
            WHERE Deal__c = :unsavedObj.dealId AND vendor__c != NULL
          ];
        } catch (Exception ex) {
          unsavedObj = new WrapperData();
          System.debug('Invalid JSON string passed. Unable to deserialize.');
        }
      }
      printReady = true;
    }
  }

  @AuraEnabled
  public static Opportunity getData(String recordId) {
    List<Opportunity> deals = [
      SELECT
        Id,
        IO_Term__c,
        Deal_Loan_Number__c,
        Swap_Rate__c,
        Spread_BPS__c,
        Final_Spread__c,
        Final_Swap__c,
        Interest_Rate_Type__c,
        Final_Loan_Amount__c,
        Deposit_Lender_Out_of_Pocket__c,
        Deposit_Collected__c,
        CAF_Upfront_Fee__c,
        Deposit_Amount__c,
        Indicative_Rate_Calc__c,
        CloseDate,
        Borrower_Entity__r.Name,
        Total_Annual_Tax__c,
        Total_Annual_Insurance__c,
        Deposit_Legal_Counsel_Diligence__c,
        Calculated_Origination_Fee__c,
        Recourse__c,
        Cash_Management__c,
        Are_Assets_Coming_Off_Bridge_Line__c,
        Total_Annual_Cap_Ex__c,
        Reserve_Cap_Ex__c,
        Reserve_Insurance__c,
        Reserve_Tax__c,
        (
          SELECT Id, Vendor__c, Vendor_Type__c, Reference__c, Fee_Amount__c
          FROM Loan_Fees__r
          ORDER BY CreatedDate
        ) // Deal Loan fees
      FROM Opportunity
      WHERE id = :recordId
    ];

    return deals[0];
  }
  // Deal Loan fees
  @AuraEnabled
  public static List<sObject> getDealLoanFees(String recordId) {
    System.debug('getDealLoanFees----->  ' + recordId);
    return [
      SELECT Id, Vendor__c, Vendor_Type__c, Reference__c, Fee_Amount__c
      FROM Loan_Fee__c
      WHERE Deal__c = :recordId
    ];
  }
  @AuraEnabled
  public static List<sObject> upsertRecords(List<sObject> records) {
    System.debug('records----->  ' + records);
    return lightning_Util.upsertRecords(records);
  }
  @AuraEnabled
  public static Boolean deleteRecords(List<sObject> records) {
    try {
      delete records;
    } catch (DmlException e) {
      throw new AuraHandledException('Failed to delete');
    }

    return true;
  }
  @AuraEnabled
  public static Map<String, String> saveDealData(Opportunity deal) {
    Map<String, String> result = new Map<String, String>();
    try {
      update deal;
      result.put('Success', 'true');
      result.put('ErrorMessage', null);
    } catch (DMLException e) {
      result.put('Success', 'false');
      result.put('ErrorMessage', e.getMessage());
    }
    return result;
  }

  @AuraEnabled
  public static String getUrlAndInstance() {
    String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    return baseUrl + '/apex/ScheduleOfLenderCostVfp';
  }

  public class WrapperData {
    public String dealId { public get; set; }
    public String fundingDate2 { public get; set; }
    //  public Decimal originationfeepercentage {public get; set;}
    public String yearSwapRate { public get; set; }
    public String installmentcomment { public get; set; }
    public String creditSpread { public get; set; }
    public Decimal InterestRateTermSheet { public get; set; }
    public Decimal InterestRateRateLock { public get; set; }
    public Decimal stubInterestDayCount { public get; set; }
    public Decimal debtreserve { public get; set; }
    public Decimal DebtService { public get; set; }
    public String stubInterest { public get; set; }
    public String CorevestProceeds { public get; set; }
    public Decimal cfcorevestpurchaser { public get; set; }
    //    public String taxentry {public get; set;}
    public String TotalSources { public get; set; }
    public String legalFee { public get; set; }
    public String totalLender { public get; set; }
    //    public String capexentry {public get; set;}
    //  public String insuranceentry {public get; set;}
    public String tax { public get; set; }
    public String capex { public get; set; }
    public String insurence { public get; set; }
    public String totalreserves { public get; set; }
    public String netproceedstoborrower { public get; set; }
    public String totalthirdparty { public get; set; }
    public String totaluses { public get; set; }
    public String rateType { public get; set; }
    public String totalreservetax { public get; set; }
    public String totalreservecapex { public get; set; }
    public String totalreserveinsurance { public get; set; }
    public String finalInterestRate { public get; set; }
  }
}