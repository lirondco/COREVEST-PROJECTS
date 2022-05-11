public without sharing class opportunity_Helper {
  public static boolean isRecursive = false;
  public static boolean hasBeforeUpdateRun = false;
  public static boolean hasAfterUpdateRun = false;

  public static final List<String> IC_REVERSE_TEMPLATES = new List<String>{
    'IC_Metrics_For_Term',
    'IC_Metrics_For_Bridge'
  };

  // public static final String RTL_WAREHOUSELINE = 'RTL';

  // public static final String RESOLUTE_DILIGENCE = 'Resolute Diligence Solutions';

  public static final String DEAL_EMAIL_HANDLER_DEVNAME = 'Deal_Email_Handler';

  public static List<String> IC_DOC_TYPES = new List<String>{
    'Draft IC Memo',
    'Committee Memo'
  };
  // static final Id TERM_LOAN_RECORDTYPEID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Term Loan').getRecordTypeId();

  // Mapping from Salesforce Record Type to PRES Loan ID Prefix
  // public static Map<String, String> TYPE_MAP = new Map<String, String>{
  //   'Term_Loan' => 'TermLoan',
  //   'LOC_Loan' => 'LOC'
  // };

  public static Map<String, RecordType> RECORDTYPE_MAP = util.compileRecordTypeMap(
    'Opportunity'
  );

  public static Map<String, Product2> PRODUCT_MAP = util.compileProductMap();

  // public static Map<String, PricebookEntry> PRICEBOOKENTRY_MAP = util.compilePricebookEntryMap();

  public static Set<String> ACTIVE_PENDING_STATUS = new Set<String>{
    'Initial Review',
    'Data Tape Received',
    'Term Sheet Issued',
    'Hold',
    'Approved by Committee',
    'Term Sheet Signed/Deposit Collected',
    'Underwriting',
    'Closed Won'
  };

  public static final User INTEGRATION_USER = [SELECT Id, Name FROM User WHERE Email LIKE 'integrations@cvest.com%' LIMIT 1];

  public static Integer CHUNK_SIZE = 1;

  // public static Map<String, Id> compileVendorMap(){
  //     Map<String, Id> vendorMap = new Map<String, Id>();
  //     for(Account vendor : [SELECT Id, Name FROM Account WHERE Name IN  ('OS National', 'Assurant', 'Green River Capital') AND RecordType.Name = 'Vendor']){
  //         vendorMap.put(vendor.Name, vendor.Id);
  //     }
  //     return vendorMap;
  // }

  // public static Map<String, ID> VENDOR_MAP;

  public static void beforeInsert(List<Opportunity> newList) {
    for (Opportunity o : newList) {
      o.Pricebook2Id = '01sj0000001DCOIAA4';
      List<Swap_Rate__c> SwapRate = [
        SELECT
          Five_Year_Swap__c,
          Seven_Year_Swap__c,
          Ten_Year_Swap__c,
          Thirty_Year_Swap__c
        FROM Swap_Rate__c
        WHERE CreatedDateTime__c != NULL
        ORDER BY CreatedDateTime__c DESC
        LIMIT 1
      ]; //Raj. 2/14/2022. CIP304.
      if (
        (o.LOC_Loan_Type__c == 'Single Asset (1-4 Unit)' ||
        o.LOC_Loan_Type__c == 'Single Asset (5-10 Unit)') &&
        o.RecordTypeId == RECORDTYPE_MAP.get('LOC_Loan').Id
      ) {
        o.RecordTypeId = RECORDTYPE_MAP.get('Single_Asset_Bridge_Loan').Id;
        o.Type = 'SAB Loan';
      } else if (
        o.LOC_Loan_Type__c == 'Term Loan' &&
        o.Product_Sub_Type__c == 'Floating Rate Term Loan'
      ) {
        o.RecordTypeId = RECORDTYPE_MAP.get(
            'Floating_Rate_Term_Loan_Originations'
          )
          .Id;
      }

      if (
        o.Account.Introductions_Source__c == 'Event' ||
        o.Account.Introductions_Source__c == 'Existing Relationship' ||
        o.Account.Introductions_Source__c == 'Conference' ||
        o.Account.Introductions_Source__c == 'Prospecting' ||
        o.Account.Introductions_Source__c == 'Non-Database'
      ) {
        o.Commission_Type__c = 'Direct';
      } else {
        o.Commission_Type__c = 'Internal';
      }

      if (o.Broker_Fees__c == 0) {
        o.Broker_Fee_Paid_When__c = 'N/A';
        o.Broker_Fee_Paid_By_Whom__c = 'N/A';
      }

      if (o.RecordType__c == 'Term') {
        if (o.Recourse__c == 'Recourse') {
          o.Cash_Management__c = 'None';
          o.Lockbox__c = 'N/A';
        } else if (
          o.Recourse__c == 'Non-Recourse' &&
          o.Cash_Management__c == null &&
          o.Foreign_National__c == true &&
          o.Loan_Size__c < 15000000
        ) {
          o.Cash_Management__c = 'Soft';
          o.Lockbox__c = 'N/A';
        } else if (
          o.Recourse__c == 'Non-Recourse' &&
          o.Cash_Management__c == null &&
          o.Foreign_National__c == false &&
          o.Loan_Size__c < 15000000
        ) {
          o.Cash_Management__c = 'None';
          o.Lockbox__c = 'N/A';
        } else if (
          o.Recourse__c == 'Non-Recourse' &&
          o.Cash_Management__c == null &&
          o.Loan_Size__c >= 15000000
        ) {
          o.Cash_Management__c = 'Hard';
          o.Lockbox__c = 'Springing';
        }

        if (o.Loan_Size__c >= 2000000) {
          o.Min_DSCR__c = '1.20x';
        } else {
          o.Min_DSCR__c = '1.20x';
        }

        if (o.Term_Loan_Type__c == '5 Year') {
          o.Term_Loan_Type_Months__c = '60 months';
          // o.Floor__c = 1.5;
        } else if (o.Term_Loan_Type__c == '7 Year') {
          o.Term_Loan_Type_Months__c = '84 months';
          // o.Floor__c = 1.55;
        } else if (o.Term_Loan_Type__c == '10 Year') {
          o.Term_Loan_Type_Months__c = '120 months';
          // o.Floor__c = 1.65;
        } else if (o.Term_Loan_Type__c == '30 Year') {
          o.Term_Loan_Type_Months__c = '360 months';
          // o.Floor__c = 1.8;
        }

        // if (o.IO_Term__c != '0 months') {
        //   o.Interest_Rate_Type__c = 'Interest Only';
        // } else {
        //   o.Interest_Rate_Type__c = 'Fixed';
        // }

        if (
          o.YM_Prepayment_Penalty__c != null &&
          o.Stepdown_Prepayment_Period__c == null
        ) {
          o.Stepdown_Prepayment_Period__c = 'N/A';
        }
      } else if (o.RecordType__c == 'Bridge') {
        if (o.Loan_Size__c < 5000000) {
          o.Deposit_Amount_Requested__c = 2500;
        } else if (o.Loan_Size__c >= 5000000 && o.Loan_Size__c < 10000000) {
          o.Deposit_Amount_Requested__c = 6000;
        } else {
          o.Deposit_Amount_Requested__c = 9000;
        }

        if (o.LOC_Loan_Type__c == 'Credit Line') {
          o.Asset_Unit_Count_Max__c = '20';
        } else {
          o.Asset_Unit_Count_Max__c = 'N/A';
        }
      }
      //Raj. 2/14/2022. CIP304. Begin
      if (
        o.RecordType__c == 'Term' &&
        o.Rate_Locked__c == false &&
        o.Term_Loan_Type__c != null &&
        o.StageName != 'Withdrawn' &&
        o.StageName != 'Rejected' &&
        SwapRate.size() > 0
      ) {
        decimal floor;
        if (o.Floor__c != null)
          floor = o.Floor__c;
        else
          floor = 0;

        switch on o.Term_Loan_Type__c {
          when '5 Year' {
            if (SwapRate[0].Five_Year_Swap__c != null) {
              if (SwapRate[0].Five_Year_Swap__c > floor) {
                o.Swap_Rate__c = SwapRate[0].Five_Year_Swap__c;
              } else {
                o.Swap_Rate__c = floor;
              }
            }
          }
          when '7 Year' {
            if (SwapRate[0].Seven_Year_Swap__c != null) {
              if (SwapRate[0].Seven_Year_Swap__c > floor) {
                o.Swap_Rate__c = SwapRate[0].Seven_Year_Swap__c;
              } else {
                o.Swap_Rate__c = floor;
              }
            }
          }
          when '10 Year' {
            if (SwapRate[0].Ten_Year_Swap__c != null) {
              if (SwapRate[0].Ten_Year_Swap__c > floor) {
                o.Swap_Rate__c = SwapRate[0].Ten_Year_Swap__c;
              } else {
                o.Swap_Rate__c = floor;
              }
            }
          }
          when '30 Year' {
            if (SwapRate[0].Thirty_Year_Swap__c != null) {
              if (SwapRate[0].Thirty_Year_Swap__c > floor) {
                o.Swap_Rate__c = SwapRate[0].Thirty_Year_Swap__c;
              } else {
                o.Swap_Rate__c = floor;
              }
            }
          }
        } //switch
      }
      //Raj. 2/14/2022. CIP304. End
    }
  }

  public static void afterInsert(Map<Id, Opportunity> newMap) {
    system.debug('after insert fired');
    //Map<String, Set<Id>> recordTypeMap = new Map<String, Set<Id>();
    Set<Id> termRecordIds = new Set<Id>();
    Set<Id> bridgeRecordIds = new Set<Id>();

    Map<Id, Opportunity> closedWonIds = new Map<Id, Opportunity>();
    List<Deal_Contact__c> applicants = new List<Deal_Contact__c>();
    List<OpportunityTeamMember> dealMembers = new List<OpportunityTeamMember>();
    //Contact Role list
    List<OpportunityContactRole> contactRoleMembers = new List<OpportunityContactRole>();
    // VENDOR_MAP = compileVendorMap();

    List<Opportunity> nonSecWarehouseLines = new List<Opportunity>();
    List<Opportunity> dealsWithSec = new List<Opportunity>();

    for (Opportunity o : newMap.values()) {
      if (String.isNotEmpty(o.Warehouse_Line__c)) {
        nonSecWarehouseLines.add(o);
      }

      if (o.Securitization__c != null) {
        dealsWithSec.add(o);
      }

      system.debug(o.Record_Type_Name__c);

      // query the record acc type from Opp
      List<Opportunity> accrecTypeId = [
        SELECT Contact__r.Account.RecordTypeId
        FROM Opportunity
        WHERE Id = :o.id
        LIMIT 1
      ];

      // // query record type id for compare
      id accBorrowerId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Borrower')
        .getRecordTypeId();
      system.debug('Check rec type Borrower' + accBorrowerId);

      id accBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get('Broker')
        .getRecordTypeId();
      system.debug('Check rec type Broker' + accBrokerID);

      system.debug(
        'acc rec type' + accrecTypeId[0].Contact__r.Account.RecordTypeId
      );

      if (o.RecordType__c == 'Term') {
        applicants.add(
          new Deal_Contact__c(
            Contact__c = o.Contact__c,
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Individual',
            // Entity_Type__c = 'Applicant'
            Entity_Type__c = accrecTypeId[0].Contact__r.Account.RecordTypeId ==
              accBrokerId
              ? 'Broker'
              : 'Applicant' //if statement based on record type.
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Title and Escrow'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Insurance Review'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Lease/Purchase Review'
          )
        );
        //  applicants.add(new Deal_Contact__c(Deal__c=o.Id, Deal_Contact_Type__c = 'Vendor', Vendor_Type__c = 'Tax Verification'));
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Flood Check'
          )
        );
        //  applicants.add(new Deal_Contact__c(Deal__c=o.Id, Deal_Contact_Type__c = 'Vendor', Vendor_Type__c = 'Rent Deposit Bank'));
        // applicants.add(new Deal_Contact__c(Deal__c=o.Id, Deal_Contact_Type__c = 'Vendor', Vendor_Type__c = 'Reserves'));
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Lender Legal Counsel'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Valuation'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = '3rd Party Title'
          )
        );

        termRecordIds.add(o.Id);
      } else if (o.RecordType__c == 'Bridge') {
        applicants.add(
          new Deal_Contact__c(
            Contact__c = o.Contact__c,
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Individual',
            // Entity_Type__c = 'Applicant'
            Entity_Type__c = accrecTypeId[0].Contact__r.Account.RecordTypeId ==
              accBrokerId
              ? 'Broker'
              : 'Applicant'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Title Review'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Valuation'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Flood Check'
          )
        );
        applicants.add(
          new Deal_Contact__c(
            Deal__c = o.Id,
            Deal_Contact_Type__c = 'Vendor',
            Vendor_Type__c = 'Insurance'
          )
        );
      }

      if (o.Underwriter__c != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.Underwriter__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Underwriter'
          )
        );
      }
      //Amelia. 04/11/2022. CIP1785. Start
      if (o.X2nd_Underwriter__c != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.X2nd_Underwriter__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = '2nd Underwriter'
          )
        );
      }
      //Amelia. 04/11/2022. CIP1785. End
      if (o.Closer__c != null && o.Closer__c == o.Loan_Coordinator__c) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.Closer__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Closer'
          )
        );
      } else {
        if (o.Closer__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Closer__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Closer'
            )
          );
        }

        if (o.Loan_Coordinator__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Loan_Coordinator__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Loan Manager'
            )
          );
        }
      }

      if (o.CAF_Analyst__c != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.CAF_Analyst__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Sales Analyst'
          )
        );
      }

      if (o.Second_Production_Analyst__c != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.Second_Production_Analyst__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Sales Analyst'
          )
        );
      }

      if (o.OwnerId != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.OwnerId,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Originator'
          )
        );
      }

      if (o.Co_Originator__c != null) {
        dealMembers.add(
          new OpportunityTeamMember(
            OpportunityId = o.Id,
            UserId = o.Co_Originator__c,
            OpportunityAccessLevel = 'Edit',
            TeamMemberRole = 'Co-Originator'
          )
        );
      }

      //Add Contact role
      if (o.Contact__c != null) {
        contactRoleMembers.add(
          new OpportunityContactRole(
            OpportunityId = o.Id,
            IsPrimary = true,
            ContactId = o.Contact__c,
            Role = 'Borrower'
          )
        );
      }

      if (o.StageName == 'Closed Won') {
        closedWonIds.put(o.Id, o);
      }
    }

    if (dealMembers.size() > 0) {
      insert dealMembers;
    }

    if (applicants.size() > 0) {
      insert applicants;
    }

    if (contactRoleMembers.size() > 0) {
      insert contactRoleMembers;
    }

    if (closedWonIds.size() > 0) {
      attachVendors(closedWonIds);
    }

    Map<String, List<Opportunity>> dealTypeForFundingVehicleMap = new Map<String, List<Opportunity>>{
      'Non_Securitisation' => nonSecWarehouseLines,
      'Securitisation' => dealsWithSec
    };

    if (nonSecWarehouseLines.size() > 0 || dealsWithSec.size() > 0) {
      upsertFundingVehicleConnections(dealTypeForFundingVehicleMap);
    }

    //if(termRecordIds.size() > 0){
    //createDealDocuments(termRecordIds, 'Term Loan');
    //}
  }

  /**
   * @name beforeUpdate
   * @description Add the correct prefix to PRES IDs now that we track both LOC and TERM
   * @param
   **/
  public static void beforeUpdate(
    Map<Id, Opportunity> newMap,
    Map<Id, Opportunity> oldMap
  ) {
    //Map<String,Id> userMap = new Map<String,Id>();
    Map<Id, Opportunity> reveresedIcDeals = new Map<Id, Opportunity>();

    Map<Id, Opportunity> closedWonMap = new Map<Id, Opportunity>();
    List<Opportunity> oppsNeedLoanIds = new List<Opportunity>();

    Map<Id, List<Property__c>> mapFromOppIdToProperties = new Map<Id, List<Property__c>>();
    Map<Id, List<Deal_Document__c>> mapFromOppIdToDealDocs = new Map<Id, List<Deal_Document__c>>();

    Set<Id> businessEntityIds = new Set<Id>();

    Map<Id, Opportunity> oppsHaveTeamToDelete = new Map<Id, Opportunity>();
    List<Approval_History__c> rejectedIcAHS = new List<Approval_History__c>();

    for (Opportunity currOpp : newMap.values()) {
      Opportunity prevOpp = oldMap.get(currOpp.Id);
      if (
        currOpp.Underwriter__c != prevOpp.Underwriter__c ||
        currOpp.Closer__c != prevOpp.Closer__c ||
        currOpp.Loan_Coordinator__c != prevOpp.Loan_Coordinator__c ||
        currOpp.Loss_Mitigation_Associate__c !=
        prevOpp.Loss_Mitigation_Associate__c ||
        currOpp.X2nd_Underwriter__c != prevOpp.X2nd_Underwriter__c
      ) {
        oppsHaveTeamToDelete.put(currOpp.Id, currOpp);
      }

      if (
        prevOpp.StageName != currOpp.StageName &&
        currOpp.StageName == 'Closed Won' &&
        currOpp.IC_Approval__c != 'Approved' &&
        !test.isRunningTest()
      ) {
        currOpp.addError(
          'Unable to change stage to Closed Won. This deal\'s related IC Approval has not yet been approved.'
        );
      }

      if (
        prevOpp.IC_Approval__c != 'Approved' &&
        currOpp.IC_Approval__c == 'Approved'
      ) {
        currOpp.IC_Approval_Date__c = System.today();
      }

   if (validateDealForIcReapproval(prevOpp, currOpp) && currOpp.IC_Approval__c == 'Approved') {
    Savepoint sp = Database.setSavepoint();
    try {
        rejectedIcAHS.add(rejectDeal(currOpp));
        currOpp.IC_Approval__c = null;
        currOpp.IC_Approval_Date__c = null;
        currOpp.StageName = 'Underwriting';
        reveresedIcDeals.put(currOpp.Id, currOpp);
    } catch (Exception err) {
      Database.rollback(sp);
      System.debug(err.getMessage() + ' ' + err.getLineNumber());
      currOpp.addError(err.getMessage());
    }

      }
    }

    if(rejectedIcAHS.size() > 0){
      insert rejectedIcAHS;
    }
    if (reveresedIcDeals.size() > 0) {
      emailReversedIcApprovalAlert(reveresedIcDeals);
    }

    Map<String, String> fieldNames = new Map<String, String>{
      'Underwriter' => 'Underwriter__c',
      'Closer' => 'Closer__c',
      'Loan Manager' => 'Loan_Coordinator__c',
      'Loss Mitigation Associate' => 'Loss_Mitigation_Associate__c',
      '2nd Underwriter' => 'X2nd_Underwriter__c'
    };

    if (!oppsHaveTeamToDelete.isEmpty()) {
      List<OpportunityTeamMember> oppTeams = new List<OpportunityTeamMember>();
      for (OpportunityTeamMember oppTM : [
        SELECT Id, OpportunityId, TeamMemberRole, UserId
        FROM OpportunityTeamMember
        WHERE
          OpportunityId IN :oppsHaveTeamToDelete.keySet()
          AND TeamMemberRole IN :fieldNames.keySet()
      ]) {
        Opportunity oppToDelete = oppsHaveTeamToDelete.get(oppTM.OpportunityId);
        if (
          oppToDelete.get(fieldNames.get(oppTM.TeamMemberRole)) != null &&
          oppToDelete.get(fieldNames.get(oppTM.TeamMemberRole)) != oppTM.UserId
        ) {
          oppTeams.add(oppTM);
        }
      }
      try {
        delete oppTeams;
      } catch (DmlException err) {
        System.debug('Error deleting team member : ' + err);
      }
    }

    if (!Test.isRunningTest()) {
      mapFromOppIdToProperties = getMapFromOppIdToProperties(newMap.keySet());
      mapFromOppIdToDealDocs = getMapFromOppIdToDealDocs(newMap.keySet());
    }

    for (Opportunity o : newMap.values()) {
      if (!String.isEmpty(o.Borrower_Entity__c)) {
        businessEntityIds.add(o.Borrower_Entity__c);
      }
    }

    Map<Id, Business_Entity__c> businessEntitiesMap = new Map<Id, Business_Entity__c>();
    if (businessEntityIds.size() > 0) {
      businessEntitiesMap = new Map<Id, Business_Entity__c>(
        [
          SELECT
            Id,
            Entity_Type__c,
            Entity_Number__c,
            Company_Jurisdiction__c,
            Date_of_Cert_of_Good_Standing__c,
            Entity_Filing_Date__c,
            Operating_Agreement_Date__c,
            Business_Tax_ID_EIN__c,
            Borrower__r.Name,
            Borrower__r.Phone,
            Borrower__r.HomePhone,
            Guarantor__r.Name,
            Guarantor__r.HomePhone,
            Guarantor__r.MobilePhone,
            Guarantor__r.Phone,
            Guarantor__r.MailingStreet,
            Guarantor__r.MailingCity,
            Guarantor__r.MailingState,
            Borrower__r.MobilePhone,
            Borrower__r.Email,
            Guarantor__r.MailingCountry,
            Guarantor__r.MailingPostalCode,
            Guarantor__r.Fico__c,
            Borrower__r.Middle_Credit_Score__c,
            Guarantor__r.Equifax__c,
            Guarantor__r.Experian__c,
            Guarantor__r.TransUnion__c,
            Borrower_2__r.HomePhone,
            Borrower_2__r.Phone,
            Borrower_2__r.MobilePhone,
            Guarantor_2__r.Name,
            Guarantor_2__r.HomePhone,
            Guarantor_2__r.Phone,
            Guarantor_2__r.MobilePhone,
            Guarantor_2__r.Middle_Credit_Score__c,
            Guarantor__r.Email,
            Guarantor__r.Middle_Credit_Score__c,
            Guarantor__r.Sex__c,
            Guarantor__r.Birthdate,
            Address_1__c,
            Address_2__c,
            City__c,
            State__c,
            Zip__c
          FROM Business_Entity__c
          WHERE Id IN :businessEntityIds
        ]
      );
    }

    Map<Id, List<Business_Entity__c>> businessEntityDealMap = new Map<Id, List<Business_Entity__c>>();

    for (Opportunity o : newMap.values()) {
      if (!String.isEmpty(o.Borrower_Entity__c)) {
        if (!businessEntityDealMap.containsKey(o.Id)) {
          businessEntityDealMap.put(o.Id, new List<Business_Entity__c>());
        }

        businessEntityDealMap.get(o.Id)
          .add(businessEntitiesMap.get(o.Borrower_Entity__c));
      }
    }

    String errorMsg = DealFieldValidationHelper.validateDeals(
      oldMap,
      newMap,
      mapFromOppIdToProperties,
      businessEntityDealMap,
      mapFromOppIdToDealDocs
    );

    system.debug('--- error msg----');
    system.debug(errorMsg);

    if (String.isNotBlank(errorMsg) && !Test.isRunningTest()) {
      system.debug(errorMsg);
      List<String> dealFieldValidationErrors = errorMsg.split('~~');
      newMap.get(dealFieldValidationErrors[0])
        .addError(dealFieldValidationErrors[1]);
    }

    for (Opportunity o : newMap.values()) {
      // ** Before Update Loop begins here **
      Opportunity oldOpp = oldMap.get(o.Id);
      system.debug('oldOpp::' + oldOpp);
      system.debug('new map::' + o);
      // if (oldOpp.StageName != 'Submitted to Underwriting' && o.StageName == 'Submitted to Underwriting') {
      //     List<Property__c> oppProps = mapFromOppIdToProperties.get(o.Id);
      //     if (oppProps != null && o.RecordTypeId == TERM_LOAN_RECORDTYPEID && !propertiesHaveBeenRedBellSynced(oppProps)) {
      //         o.addError('Stage cannot be changed to "Submitted to Underwriting" until Properties have been synced with Red Bell');
      //     }
      // }

      //if(String.isEmpty(o.base64_Id__c)){
      //o.base64_Id__c = EncodingUtil.base64Encode(Blob.valueof(o.Id));cxv
      //}

      if (
        o.Broker_Fees__c != oldMap.get(o.Id).Broker_Fees__c &&
        o.Broker_Fees__c == 0
      ) {
        o.Broker_Fee_Paid_When__c = 'N/A';
        o.Broker_Fee_Paid_By_Whom__c = 'N/A';
      }

      if (
        oldMap.get(o.Id).Securitization__c !=
        newMap.get(o.Id).Securitization__c &&
        newMap.get(o.Id).Securitization__c == null
      ) {
        o.Securitized__c = false;
      }

      if (o.GLC_Approved__c != oldMap.get(o.Id).GLC_Approved__c) {
        if (o.GLC_Approved__c == true) {
          o.GLC_Approval_Date__c = System.today();
        }
      }

      if (
        o.Background_Check_Completed__c !=
        oldMap.get(o.Id).Background_Check_Completed__c
      ) {
        o.Background_Check_Completed_Date__c = System.today();
      }

      if (
        o.Credit_Check_Completed__c !=
        oldMap.get(o.Id).Credit_Check_Completed__c
      ) {
        o.Credit_Check_Completed_Date__c = System.today();
      }

      if (o.Appraisal_Ordered__c != oldMap.get(o.Id).Appraisal_Ordered__c) {
        o.Appraisal_Ordered_Date__c = System.today();
      }

      if (
        o.Anticipated_Closing_Date__c !=
        oldMap.get(o.Id).Anticipated_Closing_Date__c && !o.IsClosed
      ) {
        o.CloseDate = o.Anticipated_Closing_Date__c;
      }

      // ** Before Update - Logic for actions when Stage changes
      if (o.StageName != oldMap.get(o.Id).StageName) {
        o.Loan_Status_Change_Date__c = System.today();

        if (
          oldMap.get(o.Id).StageName == 'UW Hold' &&
          o.StageName != 'UW Hold'
        ) {
          o.In_Process_of_Withdrawn_or_Rejected__c = false;
        }

        if (o.StageName == 'Loan Processing') {
          o.LOC_Commitment__c = o.Loan_Size__c;
          //} else if (o.StageName == 'Underwriting') {
          // if (o.Type == 'SAB Loan' || o.Type == 'Bridge Loan') {
          //   o.CloseDate = System.today() + 60;
          // }
        } else if (o.StageName == 'Underwriting') {
          if (o.Type == 'Term Loan') {
            if (
              o.Record_Type_Name__c == 'Floating_Rate_Term_Loan_Originations'
            ) {
              o.RecordTypeId = RECORDTYPE_MAP.get(
                  'Floating_Rate_Term_Loan_Underwriting'
                )
                .Id;
            }
          }
        } else if (o.StageName == 'UW Hold') {
          o.Date_Stage_Changed_To_UW_Hold__c = System.today();
          //} else if (o.StageName == 'Approved by Committee') {
          // if (o.Type == 'SAB Loan' || o.Type == 'Bridge Loan') {
          //   o.CloseDate = System.today() + 30;
          // }
        } else if (o.StageName == 'Processing Hold') {
          o.Date_Stage_Changed_To_UW_Hold__c = System.today();
        } else if (o.StageName == 'Closed Won') {
          if (o.RecordType__c == 'Term') {
            closedWonMap.put(o.Id, o);
            o.CloseDate = System.today();
            o.Loan_Effective_Date__c = System.today();
            if (o.Servicer_Commitment_Id__c == null) {
              oppsNeedLoanIds.add(o);
            }
            if (
              o.Record_Type_Name__c == 'Floating_Rate_Term_Loan_Underwriting'
            ) {
              o.RecordTypeId = RECORDTYPE_MAP.get(
                  'Floating_Rate_Term_Loan_Active'
                )
                .Id;
            }
          } else if (o.RecordType__c == 'Single Asset Bridge') {
            closedWonMap.put(o.Id, o);
            o.CloseDate = System.today();
          } else if (o.RecordType__c == 'Bridge') {
            closedWonMap.put(o.Id, o);
            if (o.LOC_Loan_Type__c == 'Credit Line') {
              o.CloseDate = System.today();
            }
          }
        } else if (
          (o.StageName == 'Rejected' || o.StageName == 'Withdrawn') &&
          oldMap.get(o.Id).StageName != o.StageName
        ) {
          if (o.Type == 'Term Loan') {
            if (o.Record_Type_Name__c.contains('Floating')) {
              o.RecordTypeId = RECORDTYPE_MAP.get(
                  'Floating_Rate_Term_Loan_Closed_Lost'
                )
                .Id;
              o.CloseDate = System.today();
            } else {
              o.RecordTypeId = RECORDTYPE_MAP.get('Term_Loan_Closed_Lost').Id;
              o.CloseDate = System.today();
            }
          } else if (o.Type == 'Bridge Loan') {
            o.RecordTypeId = RECORDTYPE_MAP.get('Bridge_Loan_Closed_Lost').Id;
            o.CloseDate = System.today();
          } else if (o.Type == 'SAB Loan') {
            o.RecordTypeId = RECORDTYPE_MAP.get(
                'Single_Asset_Bridge_Loan_Closed_Lost'
              )
              .Id;
            o.CloseDate = System.today();
          } else if (o.Type == 'Single Rental Loan') {
            o.RecordTypeId = RECORDTYPE_MAP.get(
                'Single_Rental_Loan_Closed_Lost'
              )
              .Id;
            o.CloseDate = System.today();
          }
        }

        if (
          oldMap.get(o.Id).StageName == 'UW Hold' &&
          oldMap.get(o.Id).StageName != o.StageName
        ) {
          o.Date_Stage_Changed_To_UW_Hold__c = null;
          o.Days_In_UW_Hold_Total__c =
            util.fixNull(o.Days_In_UW_Hold_Total__c) + o.Days_In_UW_Hold__c;
        } else if (
          oldMap.get(o.Id).StageName == 'Processing Hold' &&
          oldMap.get(o.Id).StageName != o.StageName
        ) {
          o.Date_Stage_Changed_To_UW_Hold__c = null;
          o.Days_In_UW_Hold_Total__c =
            util.fixNull(o.Days_In_UW_Hold_Total__c) + o.Days_In_UW_Hold__c;
        }
      }

      if (
        o.LOC_Loan_Type__c != oldMap.get(o.Id).LOC_Loan_Type__c ||
        o.Product_Sub_Type__c != oldMap.get(o.Id).Product_Sub_Type__c
      ) {
        if (
          o.LOC_Loan_Type__c == 'Single Asset (1-4 Unit)' ||
          o.LOC_Loan_Type__c == 'Single Asset (5-10 Unit)'
        ) {
          o.RecordTypeId = RECORDTYPE_MAP.get('Single_Asset_Bridge_Loan').Id;
          o.Type = 'SAB Loan';
        } else if (
          o.LOC_Loan_Type__c == 'Multifamily/CRE' ||
          o.LOC_Loan_Type__c == 'Credit Line' ||
          o.LOC_Loan_Type__c == 'Build to Rent' ||
          o.LOC_Loan_Type__c == 'Model Home Lease' ||
          o.LOC_Loan_Type__c == 'Purchased Bridge'
        ) {
          o.RecordTypeId = RECORDTYPE_MAP.get('LOC_Loan').Id;
          o.Type = 'Bridge Loan';
        } //else if (o.LOC_Loan_Type__c == 'Term Loan') {
        // if (o.Product_Sub_Type__c == 'Fixed Rate Term Loan') {
        //   o.RecordTypeId = RECORDTYPE_MAP.get('Term_Loan').Id;
        // } else {
        //   o.RecordTypeId = RECORDTYPE_MAP.get(
        //       'Floating_Rate_Term_Loan_Originations'
        //     )
        //     .Id;
        // }
        // }
      }

      if (o.RecordTypeId != oldMap.get(o.Id).RecordTypeId) {
        if (o.RecordTypeId == RECORDTYPE_MAP.get('Term_Loan').Id) {
          o.Type = 'Term Loan';
          o.LOC_Loan_Type__c = 'Term Loan';
          o.Product_Sub_Type__c = null;
        } else if (o.RecordTypeId == RECORDTYPE_MAP.get('LOC_Loan').Id) {
          o.Type = 'Bridge Loan';
          o.Term_Loan_Type__c = null;
          o.Term_Loan_Type_Months__c = null;
        } else if (
          o.RecordTypeId == RECORDTYPE_MAP.get('Single_Asset_Loan').Id
        ) {
          o.Type = 'Single Rental Loan';
          o.LOC_Loan_Type__c = 'Single Rental Loan';
          o.Product_Sub_Type__c = null;
          o.Term_Loan_Type__c = null;
          o.Term_Loan_Type_Months__c = null;
        } else if (
          o.RecordTypeId == RECORDTYPE_MAP.get('Single_Asset_Bridge_Loan').Id
        ) {
          o.Type = 'SAB Loan';
          o.Term_Loan_Type__c = null;
          o.Term_Loan_Type_Months__c = null;
        }
      }

      if (o.Product_Sub_Type__c != oldMap.get(o.Id).Product_Sub_Type__c) {
        if (
          o.Product_Sub_Type__c == 'No Renovation' &&
          o.StageName == 'Initial Review'
        ) {
          o.Requested_Max_Reno_Cost_Reimbursement__c = null;
          o.Requested_Reno_Limit__c = null;
          o.Requested_Total_Loan_LTC__c = null;
          o.Requested_ARV_LTV__c = null;
        }
      }

      if (o.Term_Sheet_Issued__c != oldMap.get(o.Id).Term_Sheet_Issued__c) {
        if (
          o.StageName == 'Initial Review' ||
          o.StageName == 'Data Tape Received' ||
          o.StageName == 'Issue Term Sheet/Order Appraisal'
        ) {
          o.StageName = 'Term Sheet Issued';
        }
      }

      if (
        o.Term_Sheet_Signed__c != oldMap.get(o.Id).Term_Sheet_Signed__c ||
        o.Deposit_Amount__c != oldMap.get(o.Id).Deposit_Amount__c ||
        o.Deposit_Fed_Reference__c !=
        oldMap.get(o.Id).Deposit_Fed_Reference__c ||
        o.Deposit_Collected__c != oldMap.get(o.Id).Deposit_Collected__c
      ) {
        if (
          (o.StageName == 'Initial Review' ||
          o.StageName == 'Data Tape Received' ||
          o.StageName == 'Issue Term Sheet/Order Appraisal' ||
          o.StageName == 'Term Sheet Issued') &&
          o.Term_Sheet_Signed__c != null &&
          o.Deposit_Amount__c != null &&
          o.Deposit_Fed_Reference__c != null &&
          o.Deposit_Collected__c != null
        ) {
          o.StageName = 'Term Sheet Signed/Deposit Collected';
        }
      }

      // if (
      //   oldMap.get(o.Id).Swap_Rate__c != newMap.get(o.Id).Swap_Rate__c &&
      //   newMap.get(o.Id).Swap_Rate__c != null
      // ) {
      //   Deal_Swap_Rate__c swaprate = new Deal_Swap_Rate__c(
      //     Deal__c = o.Id,
      //     Name = 'SWAP-' +
      //       o.Deal_Loan_Number__c +
      //       '-' +
      //       System.today().format(),
      //     Rate__c = o.Swap_Rate__c
      //   );
      //   insert swaprate;
      // }

      if (o.RecordType__c == 'Term') {
        if (o.Recourse__c == 'Recourse') {
          o.Cash_Management__c = 'None';
          o.Lockbox__c = 'N/A';
        } else if (
          o.Recourse__c == 'Non-Recourse' &&
          o.Cash_Management__c == null &&
          o.Loan_Size__c < 15000000
        ) {
          o.Cash_Management__c = 'Soft';
          o.Lockbox__c = 'N/A';
        } else if (
          o.Recourse__c == 'Non-Recourse' &&
          o.Cash_Management__c == null &&
          o.Loan_Size__c >= 15000000
        ) {
          o.Cash_Management__c = 'Hard';
          o.Lockbox__c = 'Springing';
        }

        if (
          o.Loan_Size__c != oldMap.get(o.Id).Loan_Size__c &&
          o.Min_DSCR__c == null
        ) {
          if (o.Loan_Size__c >= 2000000) {
            o.Min_DSCR__c = '1.20x';
          } else {
            o.Min_DSCR__c = '1.20x';
          }
        }

        if (o.Term_Loan_Type__c != oldMap.get(o.Id).Term_Loan_Type__c) {
          if (o.Term_Loan_Type__c == '5 Year') {
            o.Term_Loan_Type_Months__c = '60 months';
            o.Floor__c = 1.5;
          } else if (o.Term_Loan_Type__c == '7 Year') {
            o.Term_Loan_Type_Months__c = '84 months';
            o.Floor__c = 1.55;
          } else if (o.Term_Loan_Type__c == '10 Year') {
            o.Term_Loan_Type_Months__c = '120 months';
            o.Floor__c = 1.65;
          } else if (o.Term_Loan_Type__c == '30 Year') {
            o.Term_Loan_Type_Months__c = '360 months';
            o.Floor__c = 1.8;
          }
        }

        if (
          o.Term_Loan_Type_Months__c !=
          oldMap.get(o.Id).Term_Loan_Type_Months__c
        ) {
          if (o.Term_Loan_Type_Months__c == '60 months') {
            o.Term_Loan_Type__c = '5 Year';
            o.Floor__c = 1.5;
          } else if (o.Term_Loan_Type_Months__c == '84 months') {
            o.Term_Loan_Type__c = '7 Year';
            o.Floor__c = 1.55;
          } else if (o.Term_Loan_Type_Months__c == '120 months') {
            o.Term_Loan_Type__c = '10 Year';
            o.Floor__c = 1.65;
          } else if (o.Term_Loan_Type_Months__c == '360 months') {
            o.Term_Loan_Type__c = '30 Year';
            o.Floor__c = 1.8;
          }
        }

        if (o.Final_Loan_Amount__c != oldMap.get(o.Id).Final_Loan_Amount__c) {
          if (o.Final_Loan_Amount__c != null) {
            o.Current_Loan_Amount__c = o.Final_Loan_Amount__c;
          }
        }

        // if (
        //   o.Current_Loan_Amount__c != oldMap.get(o.Id).Current_Loan_Amount__c
        // ) {
        //   o.Final_Loan_Amount__c = null;
        // }

        //if (o.Total_Properties__c != oldMap.get(o.Id).Total_Properties__c) {
        //if (o.Total_Properties__c > 0 && o.StageName == 'Initial Review') {
        //o.StageName = 'Data Tape Received';
        // }
        //}

        // if (o.IO_Term__c != oldMap.get(o.Id).IO_Term__c) {
        //   if (o.IO_Term__c != '0 months') {
        //     o.Interest_Rate_Type__c = 'Interest Only';
        //   } else {
        //     o.Interest_Rate_Type__c = 'Fixed';
        //   }
        // }

        if (
          newMap.get(o.Id).YM_Prepayment_Penalty__c !=
          oldMap.get(o.Id).YM_Prepayment_Penalty__c &&
          o.YM_Prepayment_Penalty__c != null &&
          o.Stepdown_Prepayment_Period__c == null
        ) {
          o.Stepdown_Prepayment_Period__c = 'N/A';
        }

        // if (
        //   o.CloseDate != oldMap.get(o.Id).CloseDate &&
        //   o.StageName == 'Closed Won'
        // ) {
        //   o.Loan_Effective_Date__c = o.CloseDate;
        // }

        if (
          o.CloseDate != oldMap.get(o.Id).CloseDate ||
          o.Term_Loan_Type__c != oldMap.get(o.Id).Term_Loan_Type__c ||
          o.Term_Loan_Type_Months__c !=
          oldMap.get(o.Id).Term_Loan_Type_Months__c
        ) {
          system.debug('My Close Date' + o.CloseDate);
          // integer termLoanType;

          // if (o.Term_Loan_Type_Months__c == '60 months') {
          //   termLoanType = 60;
          //   o.Stated_Maturity_Date__c = o.First_Payment_Date1__c.AddMonths(
          //     termLoanType - 1
          //   );
          //   system.debug('First Payment 60' + o.First_Payment_Date1__c);
          // } else if (o.Term_Loan_Type_Months__c == '84 months') {
          //   termLoanType = 84;
          //   o.Stated_Maturity_Date__c = o.First_Payment_Date1__c.AddMonths(
          //     termLoanType - 1
          //   );
          //   system.debug('First Payment 84' + o.First_Payment_Date1__c);
          // } else if (o.Term_Loan_Type_Months__c == '120 months') {
          //   termLoanType = 120;
          //   o.Stated_Maturity_Date__c = o.First_Payment_Date1__c.AddMonths(
          //     termLoanType - 1
          //   );
          //   system.debug('First Payment 120' + o.First_Payment_Date1__c);
          // }
          if (
            o.Term_Loan_Type_Months__c != null &&
            o.Term_Loan_Type__c != null
          ) {
            String term = o.Term_Loan_Type_Months__c.substringBefore(' ');
            Integer termValue = Integer.valueOf(term);
            o.Stated_Maturity_Date__c = o.First_Payment_Date1__c.AddMonths(
              termValue - 1
            );
            o.Updated_Loan_Maturity_Date__c = o.First_Payment_Date1__c.AddMonths(
              termValue - 1
            );
          }
        }

        if (
          (oldMap.get(o.Id).Trigger_Field__c !=
          newMap.get(o.Id).Trigger_Field__c) &&
          newMap.get(o.Id).Trigger_Field__c != null
        ) {
          if (
            newMap.get(o.Id).Trigger_Field__c.contains('Originations Model')
          ) {
            Model_Save_Log__c msl = new Model_Save_Log__c(
              Deal__c = o.Id,
              Model_Type__c = 'Originations Model',
              Name = o.Trigger_Field__c.substringBefore(';'),
              Model_Name__c = o.Trigger_Field__c.substringAfter(';')
            );
            insert msl;
          } else if (
            newMap.get(o.Id)
              .Trigger_Field__c.contains('Term Underwriting Model')
          ) {
            Model_Save_Log__c msl = new Model_Save_Log__c(
              Deal__c = o.Id,
              Model_Type__c = 'Term Underwriting Model',
              Name = o.Trigger_Field__c.substringBefore(';'),
              Model_Name__c = o.Trigger_Field__c.substringAfter(';')
            );
            insert msl;
          }
        }

        if (
          o.Servicer_Name__c != oldMap.get(o.id).Servicer_Name__c &&
          o.Servicer_Commitment_Id__c !=
          oldMap.get(o.id).Servicer_Commitment_Id__c &&
          oldMap.get(o.id).Servicer_Commitment_Id__c != null &&
          oldMap.get(o.id).Servicer_Name__c != null
        ) {
          Servicer_Loan__c servicerloan = new Servicer_Loan__c(
            Name = oldMap.get(o.id).Servicer_Name__c +
              '-' +
              o.Deal_Loan_Number__c,
            Deal__c = o.Id,
            Servicer_Commitment_ID__c = oldMap.get(o.id)
              .Servicer_Commitment_Id__c,
            Servicer_Name__c = oldMap.get(o.id).Servicer_Name__c,
            First_Payment_Date__c = oldMap.get(o.id).First_Payment_Date__c,
            Last_Payment_Date__c = oldMap.get(o.id).Last_Payment_Date__c,
            Delinquent_30_Days__c = oldMap.get(o.id).Delinquent_30_Days__c,
            Delinquent_60_Days__c = oldMap.get(o.id).Delinquent_60_Days__c,
            Delinquent_90_Days__c = oldMap.get(o.id).Delinquent_90_Days__c,
            Delinquent_120_Days__c = oldMap.get(o.id).Delinquent_120_Days__c,
            Current_UPB__c = oldMap.get(o.id).Current_UPB__c,
            Onboarded_at_Servicer__c = oldMap.get(o.id)
              .Onboarded_at_Servicer__c,
            Onboarding_File_Sent_to_Servicer__c = oldMap.get(o.id)
              .Onboarding_File_Sent_to_Servicer__c,
            P_and_I__c = oldMap.get(o.id).P_I__c,
            T_and_I__c = oldMap.get(o.id).T_I__c,
            Servicer_Loan_Status__c = oldMap.get(o.id).Servicer_Status__c,
            Servicer_Provided_Portfolio_Name__c = oldMap.get(o.id)
              .Servicer_Provided_Portfolio_Name__c
          );
          insert servicerloan;
          // o.Delinquent_30_Days__c = null;
          // o.Delinquent_60_Days__c = null;
          // o.Delinquent_90_Days__c = null;
          // o.Delinquent_120_Days__c = null;
        }

        if (
          oldMap.get(o.Id).Current_UPB__c != newMap.get(o.Id).Current_UPB__c &&
          newMap.get(o.Id).Current_UPB__c == 0
        ) {
          o.Servicer_Status__c = 'Paidoff';
          o.StageName = 'Paid Off';
        }
      } else if (o.RecordType__c == 'Bridge') {
        if (oldMap.get(o.Id).Loan_Size__c != newMap.get(o.Id).Loan_Size__c) {
          if (o.Loan_Size__c < 5000000) {
            if (
              o.Deposit_Amount_Requested__c == 6000 ||
              o.Deposit_Amount_Requested__c == 9000
            ) {
              o.Deposit_Amount_Requested__c = 2500;
            }
          } else if (o.Loan_Size__c >= 5000000 && o.Loan_Size__c < 10000000) {
            if (
              o.Deposit_Amount_Requested__c == 2500 ||
              o.Deposit_Amount_Requested__c == 9000
            ) {
              o.Deposit_Amount_Requested__c = 6000;
            }
          } else {
            if (
              o.Deposit_Amount_Requested__c == 2500 ||
              o.Deposit_Amount_Requested__c == 6000
            ) {
              o.Deposit_Amount_Requested__c = 9000;
            }
          }
        }

        if (
          o.Product_Sub_Type__c != oldMap.get(o.Id).Product_Sub_Type__c &&
          o.Product_Sub_Type__c == 'No Renovation'
        ) {
          o.Requested_ARV_LTV__c = null;
          o.Requested_Max_Reno_Cost_Reimbursement__c = null;
          o.Requested_Reno_Limit__c = null;
          o.Requested_Total_Loan_LTC__c = null;
        }

        if (o.CloseDate != oldMap.get(o.Id).CloseDate) {
          o.Anticipated_Closing_Date__c = o.CloseDate;
        }

        if (
          o.Loan_Effective_Date__c != oldMap.get(o.Id).Loan_Effective_Date__c
        ) {
          if (o.Loan_Effective_Date__c != null) {
            if (o.LOC_Term__c != null) {
              List<String> locTerm = o.LOC_Term__c.split(' ');
              Integer locTermNumber = Integer.valueOf(locTerm[0]);
              if (o.Maturity_Date_Calculation_Type__c == 'Fixed at Closing') {
                o.Stated_Maturity_Date__c = o.Loan_Effective_Date__c.addMonths(
                  locTermNumber
                );
                o.Updated_Loan_Maturity_Date__c = o.Loan_Effective_Date__c.addMonths(
                  locTermNumber
                );
              }
            }
          } else {
            o.Stated_Maturity_Date__c = null;
            o.Updated_Loan_Maturity_Date__c = null;
          }
        }

        if (
          (o.Maturity_Date_Calculation_Type__c !=
          oldMap.get(o.Id).Maturity_Date_Calculation_Type__c) ||
          (o.LOC_Term__c != oldMap.get(o.Id).LOC_Term__c)
        ) {
          if (o.Maturity_Date_Calculation_Type__c == 'Fixed at First Advance') {
            o.Stated_Maturity_Date__c = null;
            o.Updated_Loan_Maturity_Date__c = null;
          } else if (
            o.Maturity_Date_Calculation_Type__c == 'Fixed at Closing' &&
            o.LOC_Term__c != null &&
            o.Loan_Effective_Date__c != null
          ) {
            List<String> locTerm = o.LOC_Term__c.split(' ');
            Integer locTermNumber = Integer.valueOf(locTerm[0]);
            o.Stated_Maturity_Date__c = o.Loan_Effective_Date__c.addMonths(
              locTermNumber
            );
            o.Updated_Loan_Maturity_Date__c = o.Loan_Effective_Date__c.addMonths(
              locTermNumber
            );
          }
        }
      }
    }

    if (oppsNeedLoanIds.size() > 0) {
      ServicerLoanNumberHelper.assignLoanNumbers(oppsNeedLoanIds);
    }

    // Do closed won verification here
    if (closedWonMap.keySet().size() > 0) {
      //List<ClearToCloseWrapper> closedWrappers = );

      for (
        ClearToCloseWrapper wrapper : checkClearToClose(
          new List<Id>(closedWonMap.keySet())
        )
      ) {
        if (!wrapper.clearToClose) {
          if (!Test.isRunningTest()) {
            newMap.get(wrapper.opportunityId)
              .addError(
                'This Deal is not Clear to Close, please check the "CTC" tab for missing items.'
              );
          }
        }
      }
    }
  }

  /**
   * @name afterUpdate
   * @description
   * @param
   **/
  public static void afterUpdate(
    Map<Id, Opportunity> newMap,
    Map<Id, Opportunity> oldMap
  ) {
    Map<Id, Opportunity> closedWonIds = new Map<Id, Opportunity>();
    Map<Id, Contact> contacts = new Map<Id, Contact>();
    Map<Id, Opportunity> approvedIcDeals = new Map<Id, Opportunity>();

    //Set<Id> populateUnique = new Set<Id>();
    //Set<Id> removeUnique = new Set<Id>();

    // Set<Id> locParentIds = new Set<Id>();
    List<OpportunityTeamMember> dealMembers = new List<OpportunityTeamMember>();
    Map<Id, List<OpportunityTeamMember>> dealMemberMap = new Map<Id, List<OpportunityTeamMember>>();

    List<OpportunityContactRole> newContactRoleMembers = new List<OpportunityContactRole>();
    List<OpportunityContactRole> updateContactRoleMembers = new List<OpportunityContactRole>();
    List<Opportunity> oppsWithRolestoUpdate = new List<Opportunity>();
    List<Deal_Contact__c> applicantToCreate = new List<Deal_Contact__c>();
    Set<Id> sendToYardiCSV = new Set<Id>();

    List<Opportunity> nonSecWarehouseLines = new List<Opportunity>();
    List<Opportunity> dealsWithSec = new List<Opportunity>();
    Map<Id, String> updatedWarehouseLines = new Map<Id, String>();

    /*CIP 2215 4/22/2022 begin */
    List<String> stagesForSfv = new List<String>{
      'Sold',
      'Matured',
      'Expired',
      'Paid Off',
      'Rejected',
      'Withdrawn'
    };
    /*CIP 2215 4/22/2022 end */

    /* CIP 1686 3/17/2022 begin */
    Map<Id, Opportunity> paidOffDeals = new Map<Id, Opportunity>();
    /* CIP 1686 3/17/2022 end */

    Map<String, Map<Id, Opportunity>> oppsLineItemUnitPriceMap = new Map<String, Map<Id, Opportunity>>{
      'Loan_Size__c' => new Map<Id, Opportunity>(),
      'Current_Loan_Amount__c' => new Map<Id, Opportunity>(),
      'Final_Loan_Amount__c' => new Map<Id, Opportunity>()
    };
    Map<Id, Opportunity> oppsServiceDate = new Map<Id, Opportunity>();

    // Set<Id> rtlDeals = new Set<Id>();
    Map<Id, Opportunity> dealsToCheckforNotes = new Map<Id, Opportunity>();
    Set<Id> securitizationsToExclude = new Set<Id>();
    List<Id> dealsWithSecsToExclude = new List<Id>();
    Map<Id, Opportunity> oppsToToggleInclusion = new Map<Id, Opportunity>();
    Set<Id> secsToToggleInclusion = new Set<Id>();
    Map<Id, Decimal> dealMemberSize = new Map<Id, Decimal>();
    for (AggregateResult ar : [
      SELECT count(Id) cnt, OpportunityId parent
      FROM OpportunityTeamMember
      WHERE OpportunityId IN :newMap.keySet()
      GROUP BY OpportunityId
    ]) {
      dealMemberSize.put(
        String.valueOf(ar.get('parent')),
        (Decimal) ar.get('cnt')
      );
    }

    /* CIP 2326 4/1/2022 begin */
    Map<Id, Opportunity> oppsToCheckLossMitigation = new Map<Id, Opportunity>();
    /* CIP 2326 4/1/2022 end */

    List<Property__c> propList = new List<property__c>(); /*CIP2254. 3/14/2022. Begin */
    /*CIP2026.RS. 3/2/2022. Begin */
    Set<Id> propertyAdvancePropIds = new Set<Id>();
    List<String> propertyAdvanceUpdateDealFields = new List<String>{
      'LTC__c',
      'LTV__c',
      'Total_Loan_LTC__c',
      'Total_ARV_LTV__c',
      'Max_Reno_Cost_Reimbursement__c',
      'Renovation_Limit__c',
      'Fee__c',
      'CAF_Upfront_Fee__c',
      'Broker_Fees__c'
    };
    Map<Id, List<Property__c>> mapFromOppIdToProperties = new Map<Id, List<Property__c>>();
    if (!Test.isRunningTest()) {
      mapFromOppIdToProperties = getMapFromOppIdToProperties(newMap.keySet());
    }
    /*CIP2026.RS. 3/2/2022. End*/

    for (Opportunity o : newMap.values()) {
      system.debug('o.StageName::::' + o);
      system.debug('oldMap::::' + oldMap);

      /* CIP2215 4/22/2022 begin */
      if(o.StageName != oldMap.get(o.Id).StageName && stagesForSfv.contains(o.StageName)){
        updatedWarehouseLines.put(o.Id, 'Closing');
      }
      /* CIP2215 4/22/2022 end */

      /* CIP 2326 4/1/2022 begin */

      if (
        o.Loss_Mitigation_Associate__c != null &&
        o.Loss_Mitigation_Associate__c !=
        oldMap.get(o.Id).Loss_Mitigation_Associate__c
      ) {
        oppsToCheckLossMitigation.put(o.Id, o);
      }

      /* CIP 2326 4/1/2022 end */

      /*CIP 1686 3/17/2022 Begin */

      if (
        o.Record_Type_Name__c == 'Single_Asset_Bridge_Loan' &&
        o.StageName == 'Paid Off' &&
        o.LOC_Loan_Type__c == 'Single Asset (1-4 Unit)' &&
        (oldMap.get(o.Id).StageName != o.StageName ||
        o.RecordTypeId != oldMap.get(o.Id).RecordTypeId ||
        o.LOC_Loan_Type__c != oldMap.get(o.Id).LOC_Loan_Type__c ||
        o.Payoff_Date__c != oldMap.get(o.Id).Payoff_Date__c)
      ) {
        paidOffDeals.put(o.Id, o);
      }

      /*CIP 1686 3/17/2022 End */

      // if (
      //   o.StageName == 'Closed Won' &&
      //   o.Warehouse_Line__c.contains(RTL_WAREHOUSELINE) &&
      //   o.Warehouse_Line__c != oldMap.get(o.Id).Warehouse_Line__c
      // ) {
      //   rtlDeals.add(o.Id);
      // }
      if (
        String.isNotEmpty(o.Deal_Lost_Reason__c) &&
        o.Deal_Lost_Reason__c == 'Other - See Deal Notes' &&
        o.Deal_Lost_Reason__c != oldMap.get(o.Id).Deal_Lost_Reason__c
      ) {
        dealsToCheckforNotes.put(o.Id, o);
      }

      if (
        oldMap.get(o.Id).Warehouse_Line__c != o.Warehouse_Line__c &&
        o.Warehouse_Line__c != 'Securitization'
      ) {
        if (String.isNotEmpty(o.Warehouse_Line__c)) {
          nonSecWarehouseLines.add(o);
        }
        if (String.isNotEmpty(oldMap.get(o.Id).Warehouse_Line__c)) {
          updatedWarehouseLines.put(o.Id, oldMap.get(o.Id).Warehouse_Line__c);
        }
      }



      if (
        oldMap.get(o.Id).Securitization__c != null &&
        oldMap.get(o.Id).Securitization__c != o.Securitization__c
      ) {
        securitizationsToExclude.add(oldMap.get(o.Id).Securitization__c);
        dealsWithSecsToExclude.add(o.Id);
      } else if (
        oldMap.get(o.Id).Securitized__c != o.Securitized__c &&
        o.Securitization__c != null
      ) {
        oppsToToggleInclusion.put(o.Id, o);
        secsToToggleInclusion.add(o.Securitization__c);
      }

      System.debug(
        'SECURITIZATIONS: ' +
        o.Securitization__c +
        ' OLD: ' +
        oldMap.get(o.Id).Securitization__c
      );
      if (
        o.Securitization__c != null &&
        oldMap.get(o.Id).Securitization__c != o.Securitization__c
      ) {
        dealsWithSec.add(o);
        if (String.isNotEmpty(oldMap.get(o.Id).Warehouse_Line__c)) {
          updatedWarehouseLines.put(o.Id, oldMap.get(o.Id).Warehouse_Line__c);
        }
      }

      if (
        o.StageName != oldMap.get(o.Id).StageName &&
        o.StageName == 'Closed Won'
      ) {
        closedWonIds.put(o.Id, o);
        attachDealContactIFClosedWON(newMap);
      }

      if (
        (o.StageName == 'Approved by Committee' ||
        o.StageName == 'Underwriting') &&
        o.Type == 'Term Loan' &&
        ((o.Third_Party_Title__c != oldMap.get(o.Id).Third_Party_Title__c &&
        o.Third_Party_Title__c != null) ||
        o.Title__c != oldMap.get(o.Id).Title__c &&
        o.Title__c != null)
      ) {
        sendToYardiCSV.add(o.Id);
      }

      if (
        o.IC_Approval__c == 'Approved' &&
        oldMap.get(o.Id).IC_Approval__c != 'Approved'
      ) {
        approvedIcDeals.put(o.Id, o);
      }

      // if((o.Record_Type_Name__c == 'LOC_Loan' || o.Record_Type_Name__c.contains('Bridge')) && o.Parent_Deal__c != null){
      //     locParentIds.add(o.Parent_Deal__c);
      // }

      if (o.RecordType__c == 'Term' || o.RecordType__c == 'Investor DSCR') {
        Map<Id, Opportunity> lineItemOppMap = new Map<Id, Opportunity>();
        if (
          o.Loan_Size__c != oldMap.get(o.Id).Loan_Size__c &&
          o.Current_Loan_Amount__c == null &&
          o.Final_Loan_Amount__c == null
        ) {
          lineItemOppMap = oppsLineItemUnitPriceMap.get('Loan_Size__c');
          lineItemOppMap.put(o.Id, o);
          oppsLineItemUnitPriceMap.put('Loan_Size__c', lineItemOppMap);
        } else if (
          o.Current_Loan_Amount__c != oldMap.get(o.Id).Current_Loan_Amount__c
        ) {
          lineItemOppMap = oppsLineItemUnitPriceMap.get(
            'Current_Loan_Amount__c'
          );
          lineItemOppMap.put(o.Id, o);
          oppsLineItemUnitPriceMap.put(
            'Current_Loan_Amount__c',
            lineItemOppMap
          );
        } else if (
          o.Final_Loan_Amount__c != oldMap.get(o.Id).Final_Loan_Amount__c
        ) {
          lineItemOppMap = oppsLineItemUnitPriceMap.get('Final_Loan_Amount__c');
          lineItemOppMap.put(o.Id, o);
          oppsLineItemUnitPriceMap.put('Final_Loan_Amount__c', lineItemOppMap);
        }

        if (o.CloseDate != oldMap.get(o.Id).CloseDate) {
          oppsServiceDate.put(o.Id, o);
        }
      }

      if (
        o.Underwriter__c != oldMap.get(o.Id).Underwriter__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.Underwriter__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Underwriter__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Underwriter'
            )
          );
        }

        if (
          oldMap.get(o.Id).Underwriter__c != null ||
          (dealMemberSize.get(o.Id) == null ||
          dealMemberSize.get(o.Id) == 0)
        ) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Underwriter__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Underwriter'
              )
            );
        }
      }

      if (
        o.X2nd_Underwriter__c != oldMap.get(o.Id).X2nd_Underwriter__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.X2nd_Underwriter__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.X2nd_Underwriter__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = '2nd Underwriter'
            )
          );
        }

        if (
          oldMap.get(o.Id).X2nd_Underwriter__c != null ||
          (dealMemberSize.get(o.Id) == null ||
          dealMemberSize.get(o.Id) == 0)
        ) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).X2nd_Underwriter__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = '2nd Underwriter'
              )
            );
        }
      }

      if (
        o.Loan_Coordinator__c != oldMap.get(o.Id).Loan_Coordinator__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (
          o.Loan_Coordinator__c == o.Closer__c ||
          o.Loan_Coordinator__c == oldMap.get(o.Id).Closer__c
        ) {
        } else {
          if (o.Loan_Coordinator__c != null) {
            dealMembers.add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = o.Loan_Coordinator__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Loan Manager'
              )
            );
          }
        }

        // if(o.Loan_Coordinator__c != null ){
        //     dealMembers.add(new OpportunityTeamMember(OpportunityId = o.Id, UserId = o.Loan_Coordinator__c, TeamMemberRole = 'Loan Coordinator'));
        // }
        if (
          oldMap.get(o.Id).Loan_Coordinator__c != null ||
          (dealMemberSize.get(o.Id) == null ||
          dealMemberSize.get(o.Id) == 0)
        ) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Loan_Coordinator__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Loan Manager'
              )
            );
        }
      }

      if (
        o.Closer__c != oldMap.get(o.Id).Closer__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.Closer__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Closer__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Closer'
            )
          );
        }
        if (oldMap.get(o.Id).Closer__c != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Closer__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Closer'
              )
            );
        }
      }

      if (
        o.Loss_Mitigation_Associate__c !=
        oldMap.get(o.Id).Loss_Mitigation_Associate__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.Loss_Mitigation_Associate__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Loss_Mitigation_Associate__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Loss Mitigation Associate'
            )
          );
        }
        if (oldMap.get(o.Id).Loss_Mitigation_Associate__c != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Loss_Mitigation_Associate__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Loss Mitigation Associate'
              )
            );
        }
      }

      if (
        o.CAF_Analyst__c != oldMap.get(o.Id).CAF_Analyst__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.CAF_Analyst__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.CAF_Analyst__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Sales Analyst'
            )
          );
        }
        if (oldMap.get(o.Id).CAF_Analyst__c != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).CAF_Analyst__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Sales Analyst'
              )
            );
        }
      }

      if (
        o.Second_Production_Analyst__c !=
        oldMap.get(o.Id).Second_Production_Analyst__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        if (o.Second_Production_Analyst__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Second_Production_Analyst__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Sales Analyst'
            )
          );
        }
        if (oldMap.get(o.Id).Second_Production_Analyst__c != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Second_Production_Analyst__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Sales Analyst'
              )
            );
        }
      }

      if (
        o.OwnerId != oldMap.get(o.Id).OwnerId ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        system.debug('---owner id---');
        system.debug(
          [SELECT id FROM opportunityteammember WHERE opportunityid = :o.Id]
            .size()
        );
        if (o.OwnerId != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.OwnerId,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Originator'
            )
          );
        }
        if (oldMap.get(o.Id).OwnerId != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).OwnerId,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Originator'
              )
            );
        }
      }

      if (
        o.Co_Originator__c != oldMap.get(o.Id).Co_Originator__c ||
        (dealMemberSize.get(o.Id) == null ||
        dealMemberSize.get(o.Id) == 0)
      ) {
        system.debug('---owner id---');
        system.debug(
          [SELECT id FROM opportunityteammember WHERE opportunityid = :o.Id]
            .size()
        );
        if (o.Co_Originator__c != null) {
          dealMembers.add(
            new OpportunityTeamMember(
              OpportunityId = o.Id,
              UserId = o.Co_Originator__c,
              OpportunityAccessLevel = 'Edit',
              TeamMemberRole = 'Co-Originator'
            )
          );
        }
        if (oldMap.get(o.Id).Co_Originator__c != null) {
          if (!dealMemberMap.containsKey(o.Id)) {
            dealMemberMap.put(o.Id, new List<OpportunityTeamMember>());
          }
          dealMemberMap.get(o.Id)
            .add(
              new OpportunityTeamMember(
                OpportunityId = o.Id,
                UserId = oldMap.get(o.Id).Co_Originator__c,
                OpportunityAccessLevel = 'Edit',
                TeamMemberRole = 'Co-Originator'
              )
            );
        }
      }

      if (oldMap.get(o.id).Contact__c == null && o.Contact__c != null) {
        newContactRoleMembers.add(
          new OpportunityContactRole(
            OpportunityId = o.Id,
            IsPrimary = true,
            ContactId = o.Contact__c,
            Role = 'Borrower'
          )
        );
      }

      if (o.Contact__c != oldMap.get(o.id).Contact__c && o.Contact__c != null) {
        oppsWithRolestoUpdate.add(o);
        system.debug('Going into Condition');
      }
      /*CIP2254.RS.3/14/2022. Begin */
      if (o.StageName == 'Withdrawn' || o.StageName == 'Rejected') {
        // List<Property__c> propList = new List<property__c>();
        if (o.Type == 'Bridge Loan') {
          for (Property__c pr : mapFromOppIdToProperties.get(o.Id)) {
            pr.Status__c = 'Cancelled';
            propList.add(pr);
          }
        }
        if (o.Type == 'Term Loan') {
          for (Property__c pr : mapFromOppIdToProperties.get(o.Id)) {
            pr.Status__c = 'Inactive';
            pr.Active__c = false;
            propList.add(pr);
          }
        }

        if (propList.size() > 0) {
          Database.Update(propList, false);
        }
      }
      /*CIP2254.RS.3/14/2022. End */

      /*CIP2026.RS. 3/2/2022. Begin */
      if (o.Type == 'Bridge Loan') {
        for (String s : propertyAdvanceUpdateDealFields) {
          if (o.get(s) != oldMap.get(o.Id).get(s)) {
            for (Property__c pr : mapFromOppIdToProperties.get(o.Id)) {
              propertyAdvancePropIds.add(pr.Id);
            }
          }
        }
      }
      /*CIP2026.RS. 3/2/2022. End */
    }

    /* CIP2326 - 4/1/2022. Begin */

    if (oppsToCheckLossMitigation.size() > 0) {
      OpportunityMethods.reassignLossMitUser(oppsToCheckLossMitigation);
    }

    /* CIP2326 - 4/1/2022. End */

    /*CIP 1686 3/17/2022 Begin */
    if (paidOffDeals.size() > 0) {
      OpportunityMethods.updatePaidOffProperties(paidOffDeals);
    }
    /*CIP 1686 3/17/2022 End */

    /*CIP2026.RS. 3/2/2022. Begin */
    if (propertyAdvancePropIds.size() > 0) {
      List<Property_Advance__c> propAdvs = new List<Property_Advance__c>();
      if (!Test.isRunningTest()) {
        for (Property_Advance__c pAdv : [
          SELECT Id, Advance__r.Status__c
          FROM Property_Advance__c
          WHERE
            Property__c IN :propertyAdvancePropIds
            AND Advance__r.Status__c != 'Completed'
        ]) {
          propAdvs.add(pAdv);
        }
        if (propAdvs.size() > 0) {
          Database.update(propAdvs, false);
        }
      }
    }
    /*CIP2026.RS. 3/2/2022. End */

    List<OpportunityLineItem> updatedLineItems = new List<OpportunityLineItem>();

    for (String key : oppsLineItemUnitPriceMap.keySet()) {
      if (oppsLineItemUnitPriceMap.get(key).size() > 0) {
        updatedLineItems.addAll(
          updateOppLineItems(
            oppsLineItemUnitPriceMap.get(key),
            'UnitPrice',
            key
          )
        );
      }
    }

    if (updatedLineItems.size() > 0) {
      Database.update(updatedLineItems, false);
      updatedLineItems = new List<OpportunityLineItem>();
    }

    if (securitizationsToExclude.size() > 0) {
      excludeSecuritizations(securitizationsToExclude, dealsWithSecsToExclude);
    }

    if (secsToToggleInclusion.size() > 0 && oppsToToggleInclusion.size() > 0) {
      toggleSecurizations(oppsToToggleInclusion, secsToToggleInclusion);
    }

    if (dealsToCheckforNotes.size() > 0) {
      checkIfDealHasNotes(dealsToCheckforNotes);
    }

    if (oppsServiceDate.size() > 0) {
      updatedLineItems.addAll(
        updateOppLineItems(oppsServiceDate, 'ServiceDate', 'CloseDate')
      );
    }

    if (updatedLineItems.size() > 0) {
      Database.update(updatedLineItems, false);
    }

    if (approvedIcDeals.size() > 0) {
      processIcApproval(approvedIcDeals);
    }

    // if (rtlDeals.size() > 0) {
    //   createRtlDealContacts(rtlDeals);
    // }

    Map<String, List<Opportunity>> dealTypeForFundingVehicleMap = new Map<String, List<Opportunity>>{
      'Non_Securitisation' => nonSecWarehouseLines,
      'Securitisation' => dealsWithSec
    };

    System.debug(JSON.serializePretty(dealTypeForFundingVehicleMap));

    if (nonSecWarehouseLines.size() > 0 || dealsWithSec.size() > 0) {
      upsertFundingVehicleConnections(dealTypeForFundingVehicleMap);
    }

    if (updatedWarehouseLines.size() > 0) {
      updateDealFundingVehicleEndDate(updatedWarehouseLines);
    }

    // if(locParentIds.size() > 0){
    //     rollupLoanMods(locParentIds);
    // }

    // if(dealMemberMap.size() > 0){
    //     List<OpportunityTeamMember> toDelete = new List<OpportunityTeamMember>();
    //     for(OpportunityTeamMember member : [SELECT Id, UserId, OpportunityId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId IN : dealMemberMap.keySet()]){
    //         for(OpportunityTeamMember memberDelete : dealMemberMap.get(member.OpportunityId)){
    //             if(member.UserId == memberDelete.UserId && member.TeamMemberRole == memberDelete.TeamMemberRole){
    //                 toDelete.add(member);
    //             }
    //         }
    //     }

    //     if(toDelete.size() > 0){
    //         delete toDelete;
    //     }
    // }

    if (dealMembers.size() > 0) {
      insert dealMembers;
    }

    if (closedWonIds.size() > 0) {
      checkClosedWonContacts(closedWonIds);
      attachVendors(closedWonIds);
    }

    if (newContactRoleMembers.size() > 0) {
      insert newContactRoleMembers;
    }

    //USE THIS FOR CIS-6814

    if (oppsWithRolestoUpdate.size() > 0) {
      id conBorrowerId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
        .get('Borrower')
        .getRecordTypeId();
      system.debug('rectype' + conBorrowerId);

      updateContactRoleMembers = [
        SELECT
          ContactId,
          Opportunity.Contact__c,
          id,
          OpportunityId,
          Opportunity.Contact__r.RecordTypeId,
          Opportunity.Contact__r.Account.id
        FROM OpportunityContactRole
        WHERE IsPrimary = TRUE AND OpportunityId IN :oppsWithRolestoUpdate
      ];
      system.debug('updateContactRoleMembers' + updateContactRoleMembers);
      //this is not correct. Gathering the role member id. Have to query contact
      for (OpportunityContactRole cRoleMember : updateContactRoleMembers) {
        cRoleMember.ContactId = cRoleMember.Opportunity.Contact__c;
        if (cRoleMember.Opportunity.Contact__r.RecordTypeId == conBorrowerId) {
          system.debug(
            'contrectype' + cRoleMember.Opportunity.Contact__r.RecordTypeId
          );

          Deal_Contact__c myApplicant = new Deal_Contact__c();
          myApplicant.Deal__c = cRoleMember.OpportunityId;
          myApplicant.Contact__c = cRoleMember.Opportunity.Contact__c;
          myApplicant.Deal_Contact_Type__c = 'Individual';
          myApplicant.Entity_Type__c = 'Applicant';
          myApplicant.Account__c = cRoleMember.Opportunity.Contact__r.Account.Id;
          applicantToCreate.add(myApplicant);
        }
      }
      if (updateContactRoleMembers.size() > 0) {
        update updateContactRoleMembers;
      }
      if (applicantToCreate.size() > 0) {
        system.debug('applicantToCreate' + applicantToCreate.size());
        insert applicantToCreate;
      }
    }
    if (sendToYardiCSV.size() > 0) {
      system.enqueueJob(
        new YardiQueueable('termCSV', new List<Id>(sendToYardiCSV))
      );
    }
  }

  public static void checkClosedWonContacts(Map<Id, Opportunity> closedWonMap) {
    Set<String> termEntities = new Set<String>{
      'Borrower',
      'Pledgor',
      'Guarantor',
      'Sponsor'
    };

    Set<String> locEntities = new Set<String>{
      'Borrower',
      'Guarantor',
      'Sponsor'
    };

    Set<String> sabEntities = new Set<String>{
      'Borrower',
      'Guarantor',
      'Sponsor'
    };

    Set<String> sarEntities = new Set<String>{};
    Set<String> dscrEntities = new Set<String>{};
    Set<String> acquiredBridgeEntities = new Set<String>{};
    Set<String> noEntities = new Set<String>{};

    for (Opportunity o : [
      SELECT
        Id,
        RecordType.DeveloperName,
        RecordType__c,
        LOC_Commitment__c,
        (
          SELECT Id, Entity_Type__c, Business_Entity__c, Contact__c
          FROM Deal_Contacts__r
          WHERE Entity_Type__c != NULL OR Contact__c != NULL
        )
      FROM Opportunity
      WHERE Id IN :closedWonMap.keySet()
    ]) {
      Set<String> entities;

      if (o.RecordType__c == 'Term') {
        entities = new Set<String>(termEntities);
      } else if (o.RecordType__c == 'Bridge') {
        entities = new Set<String>(locEntities);
      } else if (o.RecordType__c == 'Single Asset Bridge') {
        entities = new Set<String>(sabEntities);
      } else if (o.RecordType__c == 'Single Asset Rental') {
        entities = new Set<String>(sarEntities);
      } else if (o.RecordType__c == 'Investor DSCR') {
        entities = new Set<String>(dscrEntities);
      } else if (o.RecordType__c == 'Acquired Bridge') {
        entities = new Set<String>(acquiredBridgeEntities);
      } else {
        entities = new Set<String>(noEntities);
      }

      Boolean hasPledgor = false;

      for (Deal_Contact__c dc : o.Deal_Contacts__r) {
        entities.remove(dc.Entity_Type__c);

        if (dc.Entity_Type__c == 'Pledgor') {
          hasPledgor = true;
        }
      }

      if (!hasPledgor && o.LOC_Commitment__c > 10000000) {
        entities.add('Pledgor');
      }

      if (entities.size() > 0 && !Test.isRunningTest()) {
        String errorMsg = 'Deal cannot be closed, the following entities/individuals have not been entered: ';
        for (String entity : entities) {
          errorMsg += entity + ', ';
        }
        errorMsg = errorMsg.subStringBeforeLast(',');
        closedWonMap.get(o.Id).addError(errorMsg);
      }
    }
  }

  // public static void rollUpLoanMods(Set<Id> locIds){

  //     //Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

  //     List<Opportunity> ops = new List<Opportunity>();
  //     for(Opportunity o : [SELECT Id, Original_Line_Maturity_Date__c, Current_Line_Maturity_Date__c, LOC_Commitment__c, LOC_Commitment_Total__c,
  //                          (SELECT Id, CloseDate, Original_Line_Maturity_Date__c, Current_Line_Maturity_Date__c, LOC_Commitment__c
  //                           FROM Opportunities__r WHERE StageName IN ('Closed Won', 'Expired', 'Matured'))
  //                          FROM Opportunity WHERE Id IN : locIds]){
  //                              //system.debug(o);

  //                              o.LOC_Commitment_Total__c = util.fixNull(o.LOC_Commitment__c);
  //                              for(Opportunity mod : o.Opportunities__r){
  //                                  o.LOC_Commitment_Total__c += util.fixNull(mod.LOC_Commitment__c);
  //                              }
  //                              ops.add(o);
  //                          }

  //     if(ops.size() > 0){
  //         update ops;
  //     }
  // }

  /*public static void createDealDocuments(Set<Id> recordIds, String recordTypeName){
  List<Deal_Document__c> documents = new List<Deal_Document__c>();
  for(Document_Structure__mdt docType : [SELECT Id, Document_Type__c, Folder_Structure_String__c, Public__c, Borrower_Access__c, Vendor_Access__c,
  Vendor_Type_Access__c
  FROM Document_Structure__mdt 
  WHERE sobject__c = 'Opportunity'
  AND RecordType__c = 'Term Loan'
  ]){
  
  List<String> folderList = doctype.Folder_Structure_String__c.split(';');
  for(Id i : recordIds){
  Deal_Document__c doc = new Deal_Document__c();
  doc.Type__c = folderList[0];
  if(folderList.size() > 1){
  doc.Section__c = folderList[1];
  }else{
  doc.Section__c = folderList[0];
  }
  doc.Document_Type__c = docType.Document_Type__c;
  doc.Active__c = true;
  doc.Public__c = docType.public__c;
  doc.Deal__c = i;
  doc.Borrower_Access__c = docType.Borrower_Access__c;
  doc.Vendor_Access__c = docType.Vendor_Access__c;
  doc.Vendor_Type_Access__c = docType.Vendor_Type_Access__c;
  //doc.Deal_Folder__c = folder.Id;
  //doc.Property__c = folder.Property__c;
  documents.add(doc);
  }   
  }
  
  if(documents.size() > 0){
  insert documents;
  }
  
  }*/
  public static void attachDealContactIFClosedWON(Map<Id, Opportunity> newMap) {
    system.debug('newMap::::' + JSON.serialize(newMap));
    Map<ID, Deal_Contact__c> idVSDealContactMap = new Map<ID, Deal_Contact__c>();
    set<string> oppIdSet = new Set<string>();
    for (Opportunity o : newMap.values()) {
      if (o.stagename == 'Closed Won' && o.type == 'Term Loan') {
        oppIdSet.add(o.id);
      }
    }

    list<Deal_Contact__c> dealContactList = new List<Deal_Contact__c>();
    for (Deal_Contact__c de : [
      SELECT id, name, Deal__c, Account__c, Account__r.name
      FROM Deal_Contact__c
      WHERE Deal__c = :oppIdSet
    ]) {
      if (de.Account__r.name != 'Alston & Bird') {
        idVSDealContactMap.put(de.Deal__c, de);
      }
    }

    if (idVSDealContactMap.size() > 0) {
      List<Account> accs = [
        SELECT id, name
        FROM Account
        WHERE Name = 'Alston & Bird'
        LIMIT 1
      ];

      if (accs.size() > 0) {
        Account acc = accs[0];
        for (id dec : idVSDealContactMap.keySet()) {
          Deal_Contact__c dealcon = new Deal_Contact__c();
          dealcon.Account__c = acc.id;
          dealcon.Deal__c = dec;
          dealcon.Deal_Contact_Type__c = 'Vendor';
          dealcon.Entity_Type__c = 'Vendor';
          dealcon.Vendor_Type__c = 'Securitization Legal Counsel';
          dealContactList.add(dealcon);
        }
        insert dealContactList;
      }
    }
  }

  @AuraEnabled
  public static String compileClearToCloseTabData(Id opportunityId) {
    Opportunity opp = [
      SELECT Id, RecordType.DeveloperName, LOC_Loan_Type__c
      FROM Opportunity
      WHERE Id = :opportunityId
    ];

    String recordType = opp.RecordType.DeveloperName;
    if (recordType.contains('LOC_Loan')) {
      recordType = 'LOC_Loan';
    }

    Map<String, Object> response = new Map<String, Object>();

    // List<Clear_To_Close__mdt> c2cSettings = new List<Clear_To_Close__mdt>();
    List<Map<String, Object>> settings = new List<Map<String, Object>>();
    for (Clear_To_Close__mdt c2c : [
      SELECT
        Id,
        Label,
        Section_Order__c,
        Header_Name__c,
        (
          SELECT
            Id,
            Document_Type__c,
            Folder_Structure_String__c,
            C2C_Sort__c,
            Additional_C2C_Filtering__c
          FROM Document_Structures__r
        )
      FROM Clear_To_Close__mdt
      WHERE Record_Type__c = :recordType
      ORDER BY Section_Order__c ASC
    ]) {
      List<Document_Structure__mdt> docStructures = c2c.Document_Structures__r;
      if (
        recordType == 'LOC_Loan' ||
        recordType == 'Single_Asset_Bridge_Loan'
      ) {
        for (Integer i = docStructures.size() - 1; i >= 0; i--) {
          Set<String> dealTypes = compileDealType(opp);
          //system.debug(dealTypes);
          Document_Structure__mdt doc = docStructures[i];
          String additionalFilters = doc.Additional_C2C_Filtering__c != null
            ? doc.Additional_C2C_Filtering__c
            : '';
          Set<String> filters = new Set<String>(additionalFilters.split(';'));

          dealTypes.retainAll(filters);

          //system.debug(dealTypes);
          //system.debug(filters);
          //system.debug(dealTypes.size());
          if (dealTypes.size() == 0) {
            //docStrings.add(docStructure.Folder_Structure_String__c + '|' + docStructure.Document_Type__c);
            //structs.add(checklist.Document_Structures__r[i]);

            docStructures.remove(i);

            //this.docMap.put(docString, new List<Object>{false, false, doc.Required__c, '', '' });
          }
        }
      }

      //Clear_To_Close__mdt c2cClone = c2c.clone(false, false, false, false);
      //c2cClone.Document_Structures__r = docStructures;

      //c2c.Document_Structures__r = docStructures;

      // system.debug(c2cClone.Document_Structures__r.size());
      // system.debug(c2cClone.Document_Structures__r);

      // if(c2cClone.Document_Structures__r.size() > 0){
      //     c2cSettings.add(c2cClone);
      // }

      Map<String, Object> setting = new Map<String, Object>();
      //setting.Document_Structures__r = docStructures;
      setting.put('Document_Structures__r', docStructures);
      setting.put('Label', c2c.Label);
      setting.put('Section_Order__c', c2c.Section_Order__c);
      setting.put('Header_Name__c', c2c.Header_Name__c);
      // setting.Label = c2c.Label;
      // setting.Section_Order__c = setting.Section_Order__c;

      if (docStructures.size() > 0) {
        settings.add(setting);
      }
    }

    response.put('settings', settings);

    // response.put('settings', [SELECT Id, Label, Section_Order__c, Header_Name__c,
    //                                 (SELECT Id, Document_Type__c, Folder_Structure_String__c, C2C_Sort__c FROM Document_Structures__r)
    //                                 FROM Clear_To_Close__mdt
    //                                 WHERE Record_Type__c =: recordType Order By Section_Order__c Asc]);

    response.put(
      'wrapper',
      checkClearToClose(new List<Id>{ opportunityId })[0]
    );

    return JSON.serialize(response);
  }

  public static List<ClearToCloseWrapper> checkClearToClose(
    List<Id> opportunityIds
  ) {
    //List<Clear_To_Close__mdt> c2cSettings = new List<Clear_To_Close__mdt>();

    //Set<String> docStrings = new Set<String>();
    // Map<Id, String> oppRecordTypeMap = new Map<Id, String>();
    List<Opportunity> opps = new List<Opportunity>();
    for (Opportunity opp : [
      SELECT Id, RecordType.DeveloperName, RecordType__c, LOC_Loan_Type__c
      FROM Opportunity
      WHERE Id IN :opportunityIds
    ]) {
      // String recordType = opp.RecordType.DeveloperName;
      // if(recordType == 'LOC_Loan'
      //     || recordType.contains('Bridge')
      //     || recordType == 'Single_Asset_Loan' ){
      //     recordType = 'LOC_Loan';
      // }

      // oppRecordTypeMap.put(opp.Id, recordType);

      opps.add(opp);
    }

    // Map<String, Boolean> docStringMap = new Map<String, Boolean>();

    Map<String, Map<String, Document_Structure__mdt>> docStringMap = new Map<String, Map<String, Document_Structure__mdt>>();
    docStringMap.put('Term_Loan', new Map<String, Document_Structure__mdt>());
    docStringMap.put('LOC_Loan', new Map<String, Document_Structure__mdt>());
    docStringMap.put(
      'Single_Asset_Bridge_Loan',
      new Map<String, Document_Structure__mdt>()
    );

    // Map<String, Document_Structure__mdt>

    // for(Clear_To_Close__mdt c2c : [SELECT Id, Label, Section_Order__c, Record_Type__c,
    //                                (SELECT Id, Document_Type__c, Folder_Structure_String__c, Required__c, Additional_C2C_Filtering__c FROM Document_Structures__r)
    //                                FROM Clear_To_Close__mdt Order By Section_Order__c Asc]){

    //                                 if(c2c.label == 'Funding Requirements'){
    //                                     system.debug('this is funding requirements');
    //                                     system.debug(c2c);
    //                                 }
    //                                    for(Document_Structure__mdt docStructure : c2c.Document_Structures__r){

    //                                        docStringMap.get(c2c.Record_Type__c).put(docStructure.Folder_Structure_String__c + '|' + docStructure.Document_Type__c, docStructure);
    //                                    }
    // }

    for (Document_Structure__mdt docStructure : [
      SELECT
        Id,
        Document_Type__c,
        Folder_Structure_String__c,
        Required__c,
        Additional_C2C_Filtering__c,
        Clear_To_Close_Setting__c,
        Clear_To_Close_Setting__r.Record_Type__c
      FROM Document_Structure__mdt
      WHERE Clear_To_Close_Setting__c != NULL
    ]) {
      docStringMap.get(docStructure.Clear_To_Close_Setting__r.Record_Type__c)
        .put(
          docStructure.Folder_Structure_String__c +
          '|' +
          docStructure.Document_Type__c,
          docStructure
        );
    }

    //system.debug(JSON.serialize(docStringMap.get('Single_Asset_Bridge_Loan')));

    Map<Id, ClearToCloseWrapper> c2cMap = new Map<Id, ClearToCloseWrapper>();
    // for(Id oppId : opportunityIds){
    //     c2cMap.put(oppId, new ClearToCloseWrapper(oppId, docStringMapRTMap.get(oppRecordTypeMap.get(oppId))));
    // }

    for (Opportunity opp : opps) {
      c2cMap.put(opp.Id, new ClearToCloseWrapper(opp, docStringMap));
    }
    system.debug('---c2cMap--' + c2cMap);

    for (Deal_Document__c document : [
      SELECT
        Id,
        Document_Type__c,
        Folder_String__c,
        Document_Loaded__c,
        Reviewed__c,
        Doc_String__c,
        Deal__c,
        Added_On__c,
        Comments__c
      FROM Deal_Document__c
      WHERE
        Deal__c IN :opportunityIds
        AND Document_Loaded__c = TRUE
        AND Is_Deleted__c = FALSE
        AND (Doc_String__c IN :docStringMap.get('Term_Loan').keyset()
        OR Doc_String__c IN :docStringMap.get('LOC_Loan').keyset()
        OR Doc_String__c IN :docStringMap.get('Single_Asset_Bridge_Loan')
          .keySet())
      ORDER BY Added_On__c ASC
    ]) {
      c2cMap.get(document.Deal__c).setDocument(document);
    }

    if (!Test.isRunningTest()) {
      for (Document_Information__c docInfo : [
        SELECT
          Id,
          Exclude_From_CTC__c,
          Internal_COmments__c,
          External_Comments__c,
          Doc_String__c,
          Deal__c,
          Required_For_Clear_to_Close__c
        FROM Document_Information__c
        WHERE
          Deal__c IN :opportunityIds
          AND (Doc_String__c IN :docStringMap.get('Term_Loan').keyset()
          OR Doc_String__c IN :docStringMap.get('LOC_Loan').keyset()
          OR Doc_String__c IN :docStringMap.get('Single_Asset_Bridge_Loan')
            .keySet())
      ]) {
        //   system.debug('--Document_Information__c--');
        //   system.debug(docInfo);
        c2cMap.get(docInfo.Deal__c).setDocumentInfo(docInfo);
      }
    }

    List<Document_Information__c> infosToAdd = new List<Document_Information__c>();
    for (String dealId : c2cMap.keySet()) {
      ClearToCloseWrapper wrapper = c2cMap.get(dealId);

      for (String docString : wrapper.docMap.keySet()) {
        if (String.isBlank(wrapper.docMap.get(docString).docInfoId)) {
          infosToAdd.add(
            new Document_Information__c(
              Deal__c = dealId,
              Doc_String__c = docString,
              Required_for_Clear_to_Close__c = wrapper.docMap.get(docString)
                .required
            )
          );
        }
      }
    }

    if (infosToAdd.size() > 0) {
      insert infosToAdd;
      for (Document_Information__c docInfo : infosToAdd) {
        //documents.get(docInfo.Doc_String__c).addDocInfo(docInfo);
        c2cMap.get(docInfo.Deal__c).setDocumentInfo(docInfo);
      }
    }

    for (ClearToCloseWrapper wrapper : c2cMap.values()) {
      system.debug('--checking if clear--');
      wrapper.checkClearToClose();
    }

    return c2cMap.values();
  }

  public static Map<Id, List<Property__c>> getMapFromOppIdToProperties(
    Set<Id> oppIds
  ) {
    List<Property__c> allProps = [
      SELECT Property_Type__c, Red_Bell_Sync__c, Deal__c
      FROM Property__c
      WHERE Deal__c IN :oppIds
    ];

    Map<Id, List<Property__c>> mapFromOppIdToProperties = new Map<Id, List<Property__c>>();
    for (Property__c prop : allProps) {
      if (mapFromOppIdToProperties.get(prop.Deal__c) == null) {
        mapFromOppIdToProperties.put(prop.Deal__c, new List<Property__c>());
      }
      List<Property__c> oppProps = mapFromOppIdToProperties.get(prop.Deal__c);
      oppProps.add(prop);
      mapFromOppIdToProperties.put(prop.Deal__c, oppProps);
    }
    return mapFromOppIdToProperties;
  }

  public static Map<Id, List<Deal_Document__c>> getMapFromOppIdToDealDocs(
    Set<Id> oppIds
  ) {
    List<Deal_Document__c> allDocs = [
      SELECT Id, Document_Type__c, Deal__c
      FROM Deal_Document__c
      WHERE Deal__c IN :oppIds
    ];

    Map<Id, List<Deal_Document__c>> mapFromOppIdToDealDoc = new Map<Id, List<Deal_Document__c>>();
    for (Deal_Document__c doc : allDocs) {
      if (mapFromOppIdToDealDoc.get(doc.Deal__c) == null) {
        mapFromOppIdToDealDoc.put(doc.Deal__c, new List<Deal_Document__c>());
      }
      List<Deal_Document__c> oppDocs = mapFromOppIdToDealDoc.get(doc.Deal__c);
      oppDocs.add(doc);
      mapFromOppIdToDealDoc.put(doc.Deal__c, oppDocs);
    }
    return mapFromOppIdToDealDoc;
  }

  public static Boolean propertiesHaveBeenRedBellSynced(
    List<Property__c> props
  ) {
    Boolean condoSfaOrTownhomeExists = false;
    Boolean condoSfaOrTownhomeSynced = false;

    for (Property__c prop : props) {
      if (
        prop.Property_Type__c == 'Condo' ||
        prop.Property_Type__c == 'SFR' ||
        prop.Property_Type__c == 'Townhome'
      ) {
        condoSfaOrTownhomeExists = true;
        if (prop.Red_Bell_Sync__c) {
          condoSfaOrTownhomeSynced = true;
        }
      }
    }

    return (!condoSfaOrTownhomeExists || condoSfaOrTownhomeSynced);
  }

  public class ClearToCloseWrapper {
    @AuraEnabled
    public Id opportunityId;
    @AuraEnabled
    public Boolean clearToClose;
    @AuraEnabled
    public Map<String, C2CDocWrapper> docMap;

    ClearToCloseWrapper(Id opportunityId, Map<String, Object> docStringMap) {
      this.opportunityId = opportunityId;
      this.clearToClose = true;
      this.docMap = new Map<String, C2CDocWrapper>();

      for (String docString : docStringMap.keySet()) {
        this.docMap.put(docString, new C2CDocWrapper());
      }
    }

    ClearToCloseWrapper(
      Opportunity opp,
      Map<String, Map<String, Document_Structure__mdt>> docStringRTMap
    ) {
      this.opportunityId = opp.Id;
      this.clearToClose = true;
      this.docMap = new Map<String, C2CDocWrapper>();

      String recordType = opp.RecordType.DeveloperName;
      if (recordType == 'Bridge') {
        recordType = 'LOC_Loan';
      } else if (recordType == 'Term') {
        recordType = 'Term_Loan';
      } else if (recordType == 'Single Asset Bridge') {
        recordType = 'Single_Asset_Bridge_Loan';
      }

      Map<String, Document_Structure__mdt> docStringMap = docStringRTMap.get(
        recordType
      );
      for (String docString : docStringMap.keySet()) {
        Document_Structure__mdt doc = docStringMap.get(docString);
        Set<String> dealTypes = compileDealType(opp);
        String additionalFilters = doc.Additional_C2C_Filtering__c != null
          ? doc.Additional_C2C_Filtering__c
          : '';
        Set<String> filters = new Set<String>(additionalFilters.split(';'));

        dealTypes.retainAll(filters);

        if (
          dealTypes.size() > 0 ||
          (recordType == 'Term_Loan' ||
          recordType == 'Single_Asset_Bridge_Loan')
        ) {
          this.docMap.put(docString, new C2CDocWrapper(doc.Required__c));
        }
      }
    }

    public void setDocument(Deal_Document__c doc) {
      String docString = doc.Doc_String__c;

      //for()
      //system.debug(doc);
      //system.debug(docString);
      C2CDocWrapper docWrapper = this.docMap.get(docString);
      //system.debug(docWrapper);

      // if (
      //   docString ==
      //   'Diligence Documents;Background and Credit Search|Picture Id'
      // ) {
      //   system.debug(doc.Id);
      //   system.debug(doc.Reviewed__c);
      //   system.debug('---');
      // }

      if (docWrapper != null) {
        docWrapper.documentLoaded = doc.Document_Loaded__c;
        docWrapper.documentReviewed = doc.Reviewed__c;
        docWrapper.docId = doc.Id;
        docWrapper.documentCount++;
      }
    }

    public void setDocumentInfo(Document_Information__c docInfo) {
      String docString = docInfo.Doc_String__c;
      // system.debug(docString);
      C2CDocWrapper docWrapper = this.docMap.get(docString);
      // system.debug(docWrapper);

      if (docWrapper != null) {
        docWrapper.docInfoId = docInfo.Id;
        docWrapper.internalComments = docInfo.Internal_Comments__c;
        docWrapper.externalComments = docInfo.External_Comments__c;
        // docWrapper.excludeFromC2C = docInfo.Exclude_From_CTC__c;
        docWrapper.required = docInfo.Required_For_Clear_to_Close__c;
      }
    }

    public void checkClearToClose() {
      this.clearToClose = true;
      system.debug('--docMap values--');
      system.debug(docMap.values());
      for (C2CDocWrapper wrapper : docMap.values()) {
        system.debug(wrapper);
        if (
          wrapper != null &&
          wrapper.required &&
          (!wrapper.documentLoaded || !wrapper.documentReviewed)
        ) {
          this.clearToClose = false;
        }
      }
    }
  }

  public class C2CDocWrapper {
    public boolean documentLoaded = false;
    public boolean documentReviewed = false;
    public boolean required = false;

    public Integer documentCount = 0;
    public String docId;
    public String internalComments;
    public String externalComments;
    public String docInfoId;
    public Boolean defaultRequiredC2C;
    Boolean excludeFromC2C = false;

    C2CDocWrapper(Boolean defaultRequired) {
      this.required = defaultRequired;
    }

    C2CDocWrapper() {
    }
  }

  public static Set<String> compileDealType(Opportunity o) {
    Set<String> dealTypes = new Set<String>();

    if (
      o.LOC_Loan_Type__c == 'Single Asset (1-4 Unit)' ||
      o.LOC_Loan_Type__c == 'Single Asset (5-10 Unit)'
    ) {
      dealTypes.add('SAB');
    } else if (o.LOC_Loan_Type__c == 'Build to Rent') {
      dealTypes.add('BTR');
    } else if (o.LOC_Loan_Type__c == 'Multifamily/CRE') {
      dealTypes.add('Commercial');
    } else {
      dealTypes.add('Non SAB');
    }
    return dealTypes;
  }

  // public static void createModelSaveLog(Opportunity o) {
  //   String modelType = '';
  //   String modelName = '';
  //   String name = '';
  //   Model_Save_Log__c msl = new Model_Save_Log__c(
  //     Deal__c = o.Id,
  //     Model_Type__c = modelType,
  //     Name = name,
  //     Model_Name__c = modelName
  //   );
  //   insert msl;
  // }

  @AuraEnabled
  public static string getFiles(String dealId, String docInfoId) {
    return BorrowerChecklistController.getFiles(dealId, docInfoId);
  }

  @AuraEnabled
  public static string reviewDocuments(List<String> docIds) {
    return BorrowerChecklistController.reviewDocuments(docIds);
  }

  //attach Berkadia and Statebridge
  public static void attachVendors(Map<Id, Opportunity> oppMap) {
    List<Account> berkadiaAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'Berkadia Commercial Mortgage'
      LIMIT 1
    ];

    List<Account> statebridgeAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'Statebridge Company, LLC'
      LIMIT 1
    ];

    List<Account> fciAccs = [
      SELECT Id
      FROM Account
      WHERE Name = 'FCI Lender Services'
      LIMIT 1
    ];

    if (
      berkadiaAccs.size() > 0 &&
      statebridgeAccs.size() > 0 &&
      fciAccs.size() > 0
    ) {
      Id berkadiaAccId = berkadiaAccs[0].Id;
      Id statebridgeAccId = statebridgeAccs[0].Id;
      Id fciAccId = fciAccs[0].Id;
      List<Opportunity> termOppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND RecordType__c = 'Term'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :berkadiaAccId
          )
      ];

      List<Opportunity> bridgeOppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND RecordType__c = 'Bridge'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :statebridgeAccId
          )
      ];

      List<Opportunity> churchillOppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND RecordType__c = 'Investor DSCR'
          AND Approved_Third_Party_Originators__r.Name = 'Churchill Real Estate'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :statebridgeAccId
          )
      ];

      List<Opportunity> acquiredDSCROppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND RecordType__c = 'Investor DSCR'
          AND Approved_Third_Party_Originators__r.Name != 'Churchill Real Estate'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :fciAccId
          )
      ];

      List<Opportunity> acquiredBridgeOppsToUpdate = [
        SELECT Id
        FROM Opportunity
        WHERE
          Id IN :oppMap.keySet()
          AND RecordType__c = 'Acquired Bridge'
          AND Id NOT IN (
            SELECT Deal__c
            FROM Deal_Contact__c
            WHERE Account__c = :fciAccId
          )
      ];

      System.debug(termOppsToUpdate);

      List<Deal_Contact__c> newDealContacts = new List<Deal_Contact__c>();

      for (Opportunity o : termOppsToUpdate) {
        Deal_Contact__c newDC = new Deal_Contact__c();
        newDC.Vendor_Type__c = 'Servicer';
        newDC.Deal__c = o.Id;
        newDC.Deal_Contact_Type__c = 'Vendor';
        newDC.Account__c = berkadiaAccId;
        newDC.Entity_Type__c = 'Vendor';
        newDealContacts.add(newDC);
      }

      for (Opportunity o : bridgeOppsToUpdate) {
        Deal_Contact__c newDC = new Deal_Contact__c();
        newDC.Vendor_Type__c = 'Servicer';
        newDC.Deal__c = o.Id;
        newDC.Deal_Contact_Type__c = 'Vendor';
        newDC.Account__c = statebridgeAccId;
        newDC.Entity_Type__c = 'Vendor';
        newDealContacts.add(newDC);
      }

      for (Opportunity o : churchillOppsToUpdate) {
        Deal_Contact__c newDC = new Deal_Contact__c();
        newDC.Vendor_Type__c = 'Servicer';
        newDC.Deal__c = o.Id;
        newDC.Deal_Contact_Type__c = 'Vendor';
        newDC.Account__c = statebridgeAccId;
        newDC.Entity_Type__c = 'Vendor';
        newDealContacts.add(newDC);
      }

      for (Opportunity o : acquiredDSCROppsToUpdate) {
        Deal_Contact__c newDC = new Deal_Contact__c();
        newDC.Vendor_Type__c = 'Servicer';
        newDC.Deal__c = o.Id;
        newDC.Deal_Contact_Type__c = 'Vendor';
        newDC.Account__c = fciAccId;
        newDC.Entity_Type__c = 'Vendor';
        newDealContacts.add(newDC);
      }

      for (Opportunity o : acquiredBridgeOppsToUpdate) {
        Deal_Contact__c newDC = new Deal_Contact__c();
        newDC.Vendor_Type__c = 'Servicer';
        newDC.Deal__c = o.Id;
        newDC.Deal_Contact_Type__c = 'Vendor';
        newDC.Account__c = fciAccId;
        newDC.Entity_Type__c = 'Vendor';
        newDealContacts.add(newDC);
      }

      System.debug(newDealContacts);
      if (newDealContacts.size() > 0) {
        Database.insert(newDealContacts, false);
      }
    }
  }

  public static void processIcApproval(Map<Id, Opportunity> dealMap) {
    Set<Id> dealIds = dealMap.keySet();
    List<Deal_Document__c> dealDocs = [
      SELECT ContentVersion_Id__c, Deal__c, File_Name__c, Type__c
      FROM Deal_Document__c
      WHERE Deal__c IN :dealIds AND Document_Type__c IN :IC_DOC_TYPES
      ORDER BY CreatedDate DESC
    ];

    Map<Id, Opportunity> updDeals = new Map<Id, Opportunity>();
    List<Deal_Document__c> updatedDocs = new List<Deal_Document__c>();
    for (Deal_Document__c dd : dealDocs) {
      if (updDeals.containsKey(dd.Deal__c)) {
        continue;
      }
      Opportunity newOpp = new Opportunity();
      newOpp.Id = dd.Deal__c;
      updDeals.put(newOpp.Id, newOpp);
      if (dealMap.get(dd.Deal__c).Record_Type_Name__c == 'Term_Loan') {
        Deal_Document__c newDd = dd.clone(false, true, false, false);
        System.debug('DEAL DOC');
        System.debug(JSON.serializePretty(dd));
        String fileName =
          dd.File_Name__c.SubStringBefore('.pdf') +
          'vFinal' +
          '.pdf';
        newDd.File_Name__c = fileName;
        newDd.Document_Type__c = 'Final IC Memo';
        updatedDocs.add(newDd);
      }
    }

    if (updDeals.size() > 0) {
      update updDeals.values();
    }
    if (updatedDocs.size() > 0) {
      insert updatedDocs;
    }
  }

  public static void emailReversedIcApprovalAlert(
    Map<Id, Opportunity> dealMap
  ) {

    List<EmailServicesAddress> esas = [
      SELECT Id, LocalPart, EmailDomainName, DeveloperName
      FROM EmailServicesAddress
      WHERE DeveloperName = :DEAL_EMAIL_HANDLER_DEVNAME
    ];

    Map<Id, Set<Id>> termDealIdsByRecipients = new Map<Id, Set<Id>>();
    Map<Id, Set<Id>> bridgeDealIdsByRecipients = new Map<Id, Set<Id>>();

    List<String> ccNames = new List<String>{
      'Libby Burgeson',
      'Micaela Lumpkin'
    };

    Map<Id, Opportunity> dealMembersMap = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          (
            SELECT Id, OpportunityId, UserId
            FROM OpportunityTeamMembers
            WHERE UserId != NULL
          )
        FROM Opportunity
        WHERE Id IN :dealMap.keySet()
      ]
    );

    Set<Id> recipientIds = new Set<Id>();

    Group gp = [
      SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers)
      FROM Group
      WHERE DeveloperName = 'Term_IC_Approval'
    ];

    Map<Id, User> ccusers = new Map<Id, User>(
      [SELECT Id, Name FROM User WHERE Id IN :ccNames]
    );

    recipientIds.addAll(ccusers.keySet());

    for (GroupMember gm : gp.GroupMembers) {
      recipientIds.add(gm.UserOrGroupId);
    }

    for (Opportunity o : dealMembersMap.values()) {
      Set<Id> addlRecipIds = new Set<Id>();

      addlRecipIds.addAll(recipientIds);

      Opportunity deal = dealMap.get(o.Id);
      if (o.OpportunityTeamMembers != null) {
        for (OpportunityTeamMember otm : o.OpportunityTeamMembers) {
          addlRecipIds.add(otm.UserId);
        }
      }

      addlRecipIds.add(deal.OwnerId);
      if(deal.Underwriter__c != null) {
        addlRecipIds.add(deal.Underwriter__c);
      }

      if(deal.X2nd_Underwriter__c != null) {
        addlRecipIds.add(deal.X2nd_Underwriter__c);
      }

      if (deal.Record_Type_Name__c == 'Term_Loan') {
        termDealIdsByRecipients.put(deal.Id, addlRecipIds);
      } else if (deal.Record_Type_Name__c == 'LOC_Loan') {
        bridgeDealIdsByRecipients.put(deal.Id, addlRecipIds);
      }
    }

    Map<String, Id> templateMap = new Map<String, Id>();

    for (EmailTemplate et : [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName IN :IC_REVERSE_TEMPLATES
    ]) {
      templateMap.put(et.DeveloperName, et.Id);
    }

    String handlerAddress = '';

    if (esas.size() > 0) {
      handlerAddress =
        esas.get(0).LocalPart +
        '@' +
        esas.get(0).EmailDomainName;
    }

    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    if (termDealIdsByRecipients.size() > 0) {
      for (Id tOpptId : termDealIdsByRecipients.keySet()) {
        List<Id> recpIds = new List<Id>();
        recpIds.addAll(termDealIdsByRecipients.get(tOpptId));
        Messaging.SingleEmailMessage termEmail = new Messaging.SingleEmailMessage();
        termEmail.setTemplateId(templateMap.get('IC_Metrics_For_Term'));
        termEmail.setTargetObjectId(dealMap.get(tOpptId).Contact__c);
        termEmail.setTreatTargetObjectAsRecipient(false);
        termEmail.setToAddresses(recpIds);
        termEmail.setWhatId(tOpptId);
        termEmail.setReplyTo('caf-apps@cvest.com');
        if (handlerAddress != '') {
          termEmail.setCcAddresses(new List<String>{ handlerAddress });
        }
        termEmail.setSaveAsActivity(false);
        messages.add(termEmail);
      }
    }

    if (bridgeDealIdsByRecipients.size() > 0) {
      for (Id bOpptId : bridgeDealIdsByRecipients.keySet()) {
        List<Id> recpIds = new List<Id>();
        recpIds.addAll(bridgeDealIdsByRecipients.get(bOpptId));
        Messaging.SingleEmailMessage bridgeEmail = new Messaging.SingleEmailMessage();
        bridgeEmail.setTemplateId(templateMap.get('IC_Metrics_For_Bridge'));
        bridgeEmail.setTargetObjectId(dealMap.get(bOpptId).Contact__c);
        bridgeEmail.setTreatTargetObjectAsRecipient(false);
        bridgeEmail.setToAddresses(recpIds);
        bridgeEmail.setWhatId(bOpptId);
        bridgeEmail.setReplyTo('caf-apps@cvest.com');
        if (handlerAddress != '') {
          bridgeEmail.setCcAddresses(new List<String>{ handlerAddress });
        }
        bridgeEmail.setSaveAsActivity(false);
        messages.add(bridgeEmail);
      }
    }

    if (messages.size() > 0 && !Test.isRunningTest()) {
      List<Messaging.SendEmailResult> results = Messaging.sendEmail(messages);

      if (results[0].success) {
        System.debug('The email was sent successfully.');
      } else {
        System.debug(
          'The email failed to send: ' + results[0].errors[0].message
        );
      }
    }
  }

  public static List<OpportunityLineItem> updateOppLineItems(
    Map<Id, Opportunity> oppMap,
    String fieldToUpdate,
    String fieldFrom
  ) {
    String soql =
      'SELECT Id, OpportunityId, ' +
      fieldToUpdate +
      ' FROM OpportunityLineItem WHERE OpportunityId IN (\'' +
      String.join(new List<Id>(oppMap.keySet()), '\',\'') +
      '\')';
    List<OpportunityLineItem> oppLineItems = Database.query(soql);

    for (OpportunityLineItem oli : oppLineItems) {
      Opportunity currOpp = oppMap.get(oli.OpportunityId);
      oli.put(fieldToUpdate, currOpp.get(fieldFrom));
    }

    return oppLineItems;
  }

  public static void updateDealFundingVehicleEndDate(Map<Id, String> dealMap) {
    List<Deal_x_Funding_Vehicle__c> dfvs = [
      SELECT
        Id,
        Deal__c,
        Funding_Vehicle__c,
        Funding_Vehicle__r.Name,
        End_Date__c,
        Deal__r.Securitization__r.Close_Date__c,
        Deal__r.Securitization__c,
        Deal__r.Payoff_Date__c,
        Deal__r.StageName
      FROM Deal_x_Funding_Vehicle__c
      WHERE Deal__c IN :dealMap.keySet() AND End_Date__c = NULL
    ];

    for (Deal_x_Funding_Vehicle__c d : dfvs) {
      if(dealMap.containsKey(d.Deal__c) && dealMap.get(d.Deal__c) == 'Closing') {
        if(d.Deal__r.Payoff_Date__c != null) {
          d.End_Date__c = d.Deal__r.Payoff_Date__c;
        } else {
          d.End_Date__c = System.today();
        }
      }
      else if (
        d.Deal__r.Securitization__c != null &&
        dealMap.get(d.Deal__c) == d.Funding_Vehicle__r.Name &&
        d.Deal__r.Securitization__r.Close_Date__c != null
      ) {
        d.End_Date__c = d.Deal__r.Securitization__r.Close_Date__c;
      } else if (
        d.Deal__r.Securitization__c == null &&
        d.Funding_Vehicle__r.Name == dealMap.get(d.Deal__c)
      ) {
        d.End_Date__c = (Date) System.today();
      }
    }

    update dfvs;
  }

  public static void upsertFundingVehicleConnections(
    Map<String, List<Opportunity>> dealTypeMap
  ) {
    List<Deal_x_Funding_Vehicle__c> newFundingVehicleConnections = new List<Deal_x_Funding_Vehicle__c>();
    System.debug(JSON.serializePretty(dealTypeMap));
    List<Opportunity> nonSecOpps = dealTypeMap.get('Non_Securitisation');
    List<Opportunity> secOpps = dealTypeMap.get('Securitisation');
    List<Opportunity> updatedDeals = new List<Opportunity>();

    if (nonSecOpps.size() > 0) {
      Map<Id, String> dealWarehouseMap = new Map<Id, String>();
      for (Opportunity nso : nonSecOpps) {
        dealWarehouseMap.put(nso.Id, nso.Warehouse_Line__c);
      }

      Map<String, Id> fundingVehicleMap = generateFundingVehicleMap(
        dealWarehouseMap
      );

      if (fundingVehicleMap.size() > 0) {
        for (Opportunity nso : nonSecOpps) {
          if (fundingVehicleMap.containsKey(nso.Warehouse_Line__c)) {
            Deal_x_Funding_Vehicle__c newDxfv = new Deal_x_Funding_Vehicle__c();
            newDxfv.Deal__c = nso.Id;
            newDxfv.Funding_Vehicle__c = fundingVehicleMap.get(
              nso.Warehouse_Line__c
            );
            newDxfv.Start_Date__c = (Date) System.today();
            newFundingVehicleConnections.add(newDxfv);
          }
        }
      }
    }

    if (secOpps.size() > 0) {
      System.debug('SECURITISATION');
      System.debug(secOpps);
      Map<Id, Funding_Vehicle__c> secFvMap = new Map<Id, Funding_Vehicle__c>();
      for (Opportunity op : secOpps) {
        secFvMap.put(op.Securitization__c, new Funding_Vehicle__c());
      }

      for (Funding_Vehicle__c fv : [
        SELECT
          Id,
          Securitization__c,
          Securitization__r.Close_Date__c,
          Securitization__r.Status__c
        FROM Funding_Vehicle__c
        WHERE Securitization__c IN :secFvMap.keySet()
      ]) {
        secFvMap.put(fv.Securitization__c, fv);
      }

      for (Opportunity op : secOpps) {
        if (
          secFvMap.containsKey(op.Securitization__c) &&
          secFvMap.get(op.Securitization__c).Id != null
        ) {
          Deal_x_Funding_Vehicle__c newDxfv = new Deal_x_Funding_Vehicle__c();
          if (
            secFvMap.get(op.Securitization__c).Securitization__r.Status__c ==
            'Closed'
          ) {
            newDxfv.Include_Yes_No__c = true;
            updatedDeals.add(
              new Opportunity(Id = op.Id, Securitized__c = true)
            );
          }
          newDxfv.Deal__c = op.Id;
          newDxfv.Funding_Vehicle__c = secFvMap.get(op.Securitization__c).Id;
          newDxfv.Start_Date__c = secFvMap.get(op.Securitization__c)
            .Securitization__r.Close_Date__c;
          newFundingVehicleConnections.add(newDxfv);
        }
      }
    }

    if (newFundingVehicleConnections.size() > 0) {
      upsert newFundingVehicleConnections;
    }

    if (updatedDeals.size() > 0) {
      update updatedDeals;
    }
  }

  public static Map<String, Id> generateFundingVehicleMap(
    Map<Id, String> dealWarehouseMap
  ) {
    List<Funding_Vehicle__c> fundingVehicles = [
      SELECT Id, Name
      FROM Funding_Vehicle__c
      WHERE Name IN :dealWarehouseMap.values()
    ];

    if (fundingVehicles.size() > 0) {
      Map<String, Id> fundingVehicleMap = new Map<String, Id>();

      for (Funding_Vehicle__c fv : fundingVehicles) {
        fundingVehicleMap.put(fv.Name, fv.Id);
      }

      return fundingVehicleMap;
    } else {
      return new Map<String, Id>();
    }
  }

  public static void checkIfDealHasNotes(Map<Id, Opportunity> dealMap) {
    List<Opportunity> dealsWithNoNotes = [
      SELECT Id
      FROM Opportunity
      WHERE
        Id IN :dealMap.keySet()
        AND Id NOT IN (
          SELECT Deal__c
          FROM Loan_Status__c
          WHERE
            Deal__c IN :dealMap.keySet()
            AND CreatedById = :UserInfo.getUserId()
            AND CreatedDate > :Datetime.now().addMinutes(-30)
        )
    ];

    for (Opportunity o : dealsWithNoNotes) {
      dealMap.get(o.Id)
        .addError(
          'Please add a Loan Note to this deal first before changing the lost reason to "Other - See Deal Notes".'
        );
    }
  }

  public static void toggleSecurizations(
    Map<Id, Opportunity> dealMap,
    Set<Id> secIds
  ) {
    List<Deal_x_Funding_Vehicle__c> dxfvs = [
      SELECT
        Id,
        Include_Yes_No__c,
        Deal__c,
        Funding_Vehicle__r.Securitization__c
      FROM Deal_x_Funding_Vehicle__c
      WHERE
        Funding_Vehicle__r.Securitization__c IN :secIds
        AND Deal__c IN :dealMap.keySet()
        AND Deal__r.Securitization__c IN :secIds
    ];

    List<Deal_x_Funding_Vehicle__c> updatedDxfvs = new List<Deal_x_Funding_Vehicle__c>();

    for (Deal_x_Funding_Vehicle__c dxfv : dxfvs) {
      Opportunity opp = dealMap.get(dxfv.Deal__c);
      if (opp.Securitization__c == dxfv.Funding_Vehicle__r.Securitization__c) {
        updatedDxfvs.add(
          new Deal_x_Funding_Vehicle__c(
            Id = dxfv.Id,
            Include_Yes_No__c = opp.Securitized__c
          )
        );
      }

      if (updatedDxfvs.size() > 0) {
        update updatedDxfvs;
      }
    }
  }

  public static void excludeSecuritizations(Set<Id> secids, List<Id> dealIds) {
    List<Deal_x_Funding_Vehicle__c> dxfvs = [
      SELECT Id, Include_Yes_No__c
      FROM Deal_x_Funding_Vehicle__c
      WHERE
        Funding_Vehicle__r.Securitization__c IN :secids
        AND Deal__c IN :dealIds
        AND Include_Yes_No__c = TRUE
    ];

    if (dxfvs.size() > 0) {
      for (Deal_x_Funding_Vehicle__c d : dxfvs) {
        d.Include_Yes_No__c = false;
      }

      update dxfvs;
    }
  }

  public static Boolean validateDealForIcReapproval(
    Opportunity prevOpp,
    Opportunity currOpp
  ) {
    Boolean isBridge =
      currOpp.Record_Type_Name__c == 'LOC_Loan' ||
      currOpp.Record_Type_Name__c == 'Single_Asset_Bridge_Loan';
    Boolean isLTVHigher = currOpp.LTV__c > prevOpp.LTV__c;
    Boolean isCommitmentHigher =
      currOpp.LOC_Commitment__c > prevOpp.LOC_Commitment__c;

    Boolean isRecourseChanged = currOpp.Recourse__c != prevOpp.Recourse__c;
    Boolean shouldReapproveActualDSCR = false;

    Decimal prevActualDSCR = String.isNotEmpty(prevOpp.Actual_DSCR__c) && prevOpp.Actual_DSCR__c.replaceAll('[^\\d]', '')
        .isNumeric()
      ? Decimal.valueOf(prevOpp.Actual_DSCR__c.replaceAll('[^.\\d]', ''))
      : null;
    if (prevActualDSCR != null) {
      Decimal currActualDSCR = String.isNotEmpty(currOpp.Actual_DSCR__c) && currOpp.Actual_DSCR__c.replaceAll('[^\\d]', '')
          .isNumeric()
        ? Decimal.valueOf(currOpp.Actual_DSCR__c.replaceAll('[^.\\d]', ''))
        : null;
      Decimal dscrDifference =  prevActualDSCR - currActualDSCR;
      shouldReapproveActualDSCR =
        (prevActualDSCR < 1.30 && dscrDifference > 0) || 
        (dscrDifference > 0.05 &&
        !(prevActualDSCR >= 1.80 &&
        currActualDSCR >= 1.30));
    }

    if (isBridge) {
      return isLTVHigher ||
        isCommitmentHigher ||
        isRecourseChanged ||
        shouldReapproveActualDSCR;
    }

    Boolean isTerm = currOpp.Record_Type_Name__c == 'Term_Loan';  
    Boolean isLoanAmountHigher =
      currOpp.Current_Loan_Amount__c > prevOpp.Current_Loan_Amount__c;

    if (isTerm) {
      return isLoanAmountHigher ||
        isLTVHigher ||
        isRecourseChanged ||
        shouldReapproveActualDSCR;
    }

    return false;
  }


  public static Approval_History__c rejectDeal(Opportunity deal) {
    List<ProcessInstance> processInstances = [
      SELECT
        Id,
        Status,
        ProcessDefinition.Name
      FROM ProcessInstance
      WHERE
        ProcessDefinition.Name LIKE '%IC%'
        AND Status = 'Approved'
        AND TargetObjectId = :deal.Id
        ORDER BY CreatedDate Desc
      LIMIT 1
    ];

    if (processInstances.size() > 0) {
         return createApprovalHistory(processInstances[0].ProcessDefinition.Name, deal);
    } else {
      return null;
    }
  }
  

  public static Approval_History__c createApprovalHistory(String approvalType, Opportunity deal) {
    String ahProcessName = (approvalType != 'Term Sub-IC' || approvalType != 'Bridge Sub-IC')
    ? approvalType + ' Process'
    : approvalType;
    Approval_History__c ahc = new Approval_History__c(
      Parent_Status__c = 'Rejected',
      Deal__c = deal.Id,
      Name = 'Approval Request: ' + deal.Name.left(50),
      ProcessName__c = ahProcessName,
      Approver__c = INTEGRATION_USER.Name,
      Actor__c = INTEGRATION_USER.Id,
      Date_Acted__c = System.now(),
      Status__c = 'Rejected',
      Status_Text__c = 'Rejected',
      Approval_Type__c = approvalType,
      Tracking_Status__c = 'Committee',
      Deal_Stage_At_Time_of_Submission__c = 'Underwriting',
      Comments__c = 'IC Approval is no longer approved.'
    );

    if (deal.Final_Spread__c != null) {
      ahc.Spread__c = deal.Final_Spread__c;
    }

    if(deal.CAF_Upfront_Fee__c != null) {
      ahc.Origination_Fee__c = deal.CAF_Upfront_Fee__c;
    }
    return ahc;
  }

  // public static void createRtlDealContacts(Set<Id> dealIds) {
  //   List<Account> rtlAccs = [
  //     SELECT Id
  //     FROM Account
  //     WHERE Name = :RESOLUTE_DILIGENCE AND RecordType.DeveloperName = 'Vendor'
  //     LIMIT 1
  //   ];

  //   if (Test.isRunningTest()) {
  //     rtlAccs = [SELECT Id FROM Account LIMIT 1];
  //   }

  //   List<Deal_Contact__c> newDealContacts = new List<Deal_Contact__c>();

  //   if (rtlAccs.size() > 0) {
  //     for (Id dealId : dealIds) {
  //       Deal_Contact__c newDealContact = new Deal_Contact__c();
  //       newDealContact.Deal__c = dealId;
  //       newDealContact.Account__c = rtlAccs[0].Id;
  //       newDealContact.Deal_Contact_Type__c = 'Vendor';
  //       newDealContact.Vendor_Type__c = 'Diligence Review';
  //       newDealContacts.add(newDealContact);
  //     }

  //     if (newDealContacts.size() > 0) {
  //       insert newDealContacts;
  //     }
  //   }
  // }
}