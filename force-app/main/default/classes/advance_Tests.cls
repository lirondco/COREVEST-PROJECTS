@isTest
private class advance_Tests {
  //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

  static testMethod void advance_Tests_UnitTest() {
    User u = test_Helper.createBridgeOperationsUser();
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Main';
    update opp;

    List<Property__c> property = new List<Property__c>();
    Id recordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;
    for (Integer i = 0; i < 20; i++) {
      property.add(
        new Property__c(
          Name = 'Test + ' + i,
          Property_Name__c = 'Test + ' + i,
          Deal__c = opp.Id,
          Escrow_Company_text__c = 'ESCROW',
          Insurance_Company_text__c = 'INSURANCE',
          Status__c = 'Pending',
          Acquisition_Price__c = 600000,
          RecordTypeId = recordTypeId,
          Closer__c = u.Id,
          Underwriter__c = u.Id,
          Requested_Funding_Date__c = system.today() + 5
        )
      );
    }

    property[0].Status__c = 'Due Diligence';
    property[1].Status__c = 'Active';
    property[2].Payoff_Received_Date__c = system.today();
    insert property;

    opp.StageName = 'Data Tape Received';
    update opp;

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = opp.Id);
    insert adv;
    List<Property_Advance__c> padv = new List<Property_Advance__c>{
      new Property_Advance__c(
        Property__c = property[0].Id,
        Advance__c = adv.Id
      ),
      new Property_Advance__c(
        Property__c = property[1].Id,
        Advance__c = adv.Id
      ),
      new Property_Advance__c(Property__c = property[2].Id, Advance__c = adv.Id)
    };

    insert padv;
    update padv;
    delete pAdv[0];

    Draw__c draw = new Draw__c(Property__c = property[0].Id);
    insert draw;

    Test.stopTest();
  }

  /* static TestMethod void advance_Tests_UnitTest2(){
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        opp.Apex_Context__c = true;
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Opportunity' and DeveloperName = 'LOC_Loan'].Id;
        opp.StageName = 'Hold';
        opp.Draw_Period__c = '12 Months';
        opp.Repayment_Period__c = '9 Months';
        opp.LOC_Loan_Type__c = 'Credit Line';
        opp.Loan_Size__c = 3000000;
        opp.Line_Expiration__c = '18 Months';
        opp.Requested_LTC_Max__c = 70;
        opp.Requested_LTV_Max__c = 80;
        opp.Requested_Origination_Fee__c = 0;
        opp.Requested_Draw_Fee__c = 2;
        opp.Requested_Exit_Fee__c = 0;
        opp.Requested_Interest_Type__c = 'Fixed';
        opp.Requested_Rate_1_9_Months__c = 10;
        opp.Requested_Revolving__c = 'Yes';
        opp.Requested_Draw_Fee_Cap__c = 'None';
        opp.Product_Sub_Type__c = 'No Renovation';
        opp.Interest_Rate_Type__c = 'Floating';
        opp.Index__c = '1M LIBOR';
        opp.Index_Floor__c = '1.00%';
        opp.Index_Margin__c = 1.50;
        opp.Deal_Intro_Source__c = 'Hotline';
        opp.Deal_Intro_Sub_source__c = 'Direct Mail';
        update opp;

        List<Property__c> property = new List<Property__c>();
        for(Integer i = 0; i < 20; i++){
            property.add(new Property__c(Name='Test + ' + i, Deal__c = opp.Id, Escrow_Company_text__c = 'ESCROW', Insurance_Company_text__c = 'INSURANCE', Status__c = 'Pending', RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Property__c' and DeveloperName = 'Bridge_No_Renovation'].Id));
        }

        property[0].Status__c = 'Due Diligence';
        property[1].Status__c = 'Active';
        property[2].Payoff_Received_Date__c = system.today();
        insert property;


        Advance__c adv = new Advance__c(Deal__c = opp.Id);
        insert adv;
        List<Property_Advance__c> padv = new List<Property_Advance__c>{new Property_Advance__c(Property__c = property[0].Id, Advance__c = adv.Id),
                                                                            new Property_Advance__c(Property__c = property[1].Id, Advance__c = adv.Id),
                                                                            new Property_Advance__c(Property__c = property[2].Id, Advance__c = adv.Id)};

        insert padv;
        Test.startTest();
            adv.Wire_Date__c = system.today();
            adv.Status__c = 'Pending';
            update adv;

            adv.Status__c = 'Completed';
            update adv;

            List<String> propertyFieldsList = new List<String>{
                'Property__r.Asset_ID__c',
                'Wire__r.Wire_Number__c',
                'Property__r.APN__c',
                'Property__r.Name',
                'Property__r.City__c',
                'Property__r.State__c',
                'Property__r.ZipCode__c',
                'Escrow_Agent__r.Name'
            };

            Property_Advance__c p = [SELECT Id FROM Property_Advance__c LIMIT 1];

            List<Property_Advance__c> pList = (List<Property_Advance__c>)advancePrint_Extension.queryChildren('Property_Advance__c', propertyFieldsList, 'Advance__c', p.Id);
            List<Property_Advance__c> pList2 = (List<Property_Advance__c>)Advance_Test_Data_Factory.queryChildren('Property_Advance__c', propertyFieldsList, 'Advance__c', p.Id);

            System.assertEquals(pList, pList2);

            Advance__c a = [SELECT Id FROM Advance__c LIMIT 1];

            PageReference pageRef = Page.advancePrint;
            Test.setCurrentPage(pageRef);

            advancePrint_Extension controller = new advancePrint_Extension(new ApexPages.StandardController(a));

            ApexPages.StandardController sc = new ApexPages.StandardController(a);
            ApexPages.currentPage().getParameters().put('id', a.Id);


        Test.stopTest();
    } */

  static testMethod void advance_Tests_UnitTest3() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    update opp;

    Advance__c adv = new Advance__c(Deal__c = opp.Id);
    insert adv;

    Advance__c adv2 = new Advance__c(Deal__c = opp.Id);
    insert adv2;

    Test.startTest();
    adv.Wire_Date__c = system.today();
    adv.Status__c = 'Pending';
    delete adv;

    adv2.Status__c = 'Completed';
    delete adv2;
    Test.stopTest();
  }

  static testMethod void advance_Tests_UnitTest4() {
    Id recID = Schema.SObjectType.advance__c.getRecordTypeInfosByName()
      .get('Interest Reserve')
      .getRecordTypeId();

    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    update opp;

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = opp.Id, RecordTypeId = recID);
    insert adv;

    Advance__c adv2 = new Advance__c(Deal__c = opp.Id, RecordTypeId = recID);
    insert adv2;

    Advance__c adv3 = new Advance__c(Deal__c = opp.Id, RecordTypeId = recID);
    insert adv3;

    Test.stopTest();
  }

   static testMethod void advance_Tests_UnitTest5() {
    //direct

    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Direct';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 800000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

   /*RS Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;RS */

    Test.startTest();
    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);

    Test.stopTest();
  }

 static testMethod void advance_Tests_UnitTest6() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';
    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 800000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

   /*RS Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;RS*/

    Test.startTest();
    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);

    Test.stopTest();
  }

 static testMethod void advance_Tests_UnitTest7() {
    //internal
    User u = test_Helper.createBridgeOperationsUser();
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';

    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Closing';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 600000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    /*RS Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;*/

    Test.startTest();
    adv.Target_Advance_Date__c = System.today() + 5;
    adv.Closer__c = u.Id;
    adv.Underwriter__c = u.Id;
    update adv;
    
    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);

    Test.stopTest();
  }

  static testMethod void advance_Tests_UnitTest8() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';

    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    opportunity opp1 = new opportunity();
    opp1.Name = 'test';
    opp1.Apex_Context__c = true;
    opp1.AccountId = acc.id;
    opp.Contact__c = cont.id;
    opp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp1.StageName = 'Closed Won';
    opp1.Draw_Period__c = '12 Months';
    opp1.Repayment_Period__c = '9 Months';
    opp1.LOC_Loan_Type__c = 'Credit Line';
    opp1.Loan_Size__c = 3000000;
    opp1.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp1.Line_Expiration__c = '18 Months';
    opp1.Requested_LTC_Max__c = 70;
    opp1.Requested_LTV_Max__c = 80;
    opp1.Requested_Origination_Fee__c = 0;
    opp1.Requested_Draw_Fee__c = 2;
    opp1.Requested_Exit_Fee__c = 0;
    opp1.Requested_Interest_Type__c = 'Fixed';
    opp1.Requested_Rate_1_9_Months__c = 10;
    opp1.Requested_Revolving__c = 'Yes';
    opp1.Requested_Draw_Fee_Cap__c = 'None';
    opp1.Product_Sub_Type__c = 'No Renovation';
    opp1.Interest_Rate_Type__c = 'Floating';
    opp1.Index__c = '1M LIBOR';

    opp1.Commission_Type__c = 'Internal';
    opp1.Index_Floor__c = '1.00%';
    opp1.Index_Margin__c = 1.50;
    opp1.Deal_Intro_Source__c = 'Hotline';
    opp1.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp1.Fee__c = 2;
    opp1.Aggregate_Funding__c = 85000000;
    opp1.Loan_Effective_Date__c = system.today().addDays(-3);
    opp1.CloseDate = system.today().addDays(-3);

    insert opp1;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 600000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Test.startTest();
    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;

    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    system.debug('account amount' + acc.Borrowed_on_Bridge_Loans__c);
    Test.stopTest();
  }
  static testMethod void advance_Tests_UnitTest9() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';

    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    opportunity opp1 = new opportunity();
    opp1.Name = 'test';
    opp1.Apex_Context__c = true;
    opp1.AccountId = acc.id;
    opp.Contact__c = cont.id;
    opp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp1.StageName = 'Closed Won';
    opp1.Draw_Period__c = '12 Months';
    opp1.Repayment_Period__c = '9 Months';
    opp1.LOC_Loan_Type__c = 'Credit Line';
    opp1.Loan_Size__c = 3000000;
    opp1.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp1.Line_Expiration__c = '18 Months';
    opp1.Requested_LTC_Max__c = 70;
    opp1.Requested_LTV_Max__c = 80;
    opp1.Requested_Origination_Fee__c = 0;
    opp1.Requested_Draw_Fee__c = 2;
    opp1.Requested_Exit_Fee__c = 0;
    opp1.Requested_Interest_Type__c = 'Fixed';
    opp1.Requested_Rate_1_9_Months__c = 10;
    opp1.Requested_Revolving__c = 'Yes';
    opp1.Requested_Draw_Fee_Cap__c = 'None';
    opp1.Product_Sub_Type__c = 'No Renovation';
    opp1.Interest_Rate_Type__c = 'Floating';
    opp1.Index__c = '1M LIBOR';

    opp1.Commission_Type__c = 'Internal';
    opp1.Index_Floor__c = '1.00%';
    opp1.Index_Margin__c = 1.50;
    opp1.Deal_Intro_Source__c = 'Hotline';
    opp1.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp1.Fee__c = 2;
    opp1.Aggregate_Funding__c = 85000000;
    opp1.Loan_Effective_Date__c = system.today().addDays(-3);
    opp1.CloseDate = system.today().addDays(-3);

    insert opp1;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 500000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;
    Test.startTest();
    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;

    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    system.debug('account amount' + acc.Borrowed_on_Bridge_Loans__c);
    Test.stopTest();
  }

  /*Raj static testMethod void advance_Tests_UnitTest10() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';

    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    opportunity opp1 = new opportunity();
    opp1.Name = 'test';
    opp1.Apex_Context__c = true;
    opp1.AccountId = acc.id;
    opp.Contact__c = cont.id;
    opp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp1.StageName = 'Closed Won';
    opp1.Draw_Period__c = '12 Months';
    opp1.Repayment_Period__c = '9 Months';
    opp1.LOC_Loan_Type__c = 'Credit Line';
    opp1.Loan_Size__c = 3000000;
    opp1.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp1.Line_Expiration__c = '18 Months';
    opp1.Requested_LTC_Max__c = 70;
    opp1.Requested_LTV_Max__c = 80;
    opp1.Requested_Origination_Fee__c = 0;
    opp1.Requested_Draw_Fee__c = 2;
    opp1.Requested_Exit_Fee__c = 0;
    opp1.Requested_Interest_Type__c = 'Fixed';
    opp1.Requested_Rate_1_9_Months__c = 10;
    opp1.Requested_Revolving__c = 'Yes';
    opp1.Requested_Draw_Fee_Cap__c = 'None';
    opp1.Product_Sub_Type__c = 'No Renovation';
    opp1.Interest_Rate_Type__c = 'Floating';
    opp1.Index__c = '1M LIBOR';

    opp1.Commission_Type__c = 'Internal';
    opp1.Index_Floor__c = '1.00%';
    opp1.Index_Margin__c = 1.50;
    opp1.Deal_Intro_Source__c = 'Hotline';
    opp1.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp1.Fee__c = 2;
    opp1.Aggregate_Funding__c = 55000000;
    opp1.Loan_Effective_Date__c = system.today().addDays(-3);
    opp1.CloseDate = system.today().addDays(-3);

    insert opp1;
    Test.startTest();
    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.Acquisition_Price__c = 500000;
    property.Rehab_Budget__c = 70000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;

    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;

    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    system.debug('account amount' + acc.Borrowed_on_Bridge_Loans__c);
    Test.stopTest();
  } Raj*/
  static testMethod void advance_Tests_UnitTest11() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'LOC_Loan'
    ]
    .Id;
    opp.StageName = 'Hold';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';

    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Internal_Referral__c = UserInfo.getUserId();
    opp.Internal_Referral_Fee__c = '20%';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    opportunity opp1 = new opportunity();
    opp1.Name = 'test';
    opp1.Apex_Context__c = true;
    opp1.AccountId = acc.id;
    opp.Contact__c = cont.id;
    opp1.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Bridge_Loan'
    ]
    .Id;
    opp1.StageName = 'Closed Won';
    opp1.Draw_Period__c = '12 Months';
    opp1.Repayment_Period__c = '9 Months';
    opp1.LOC_Loan_Type__c = 'Credit Line';
    opp1.Loan_Size__c = 3000000;
    opp1.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp1.Line_Expiration__c = '18 Months';
    opp1.Requested_LTC_Max__c = 70;
    opp1.Requested_LTV_Max__c = 80;
    opp1.Requested_Origination_Fee__c = 0;
    opp1.Requested_Draw_Fee__c = 2;
    opp1.Requested_Exit_Fee__c = 0;
    opp1.Requested_Interest_Type__c = 'Fixed';
    opp1.Requested_Rate_1_9_Months__c = 10;
    opp1.Requested_Revolving__c = 'Yes';
    opp1.Requested_Draw_Fee_Cap__c = 'None';
    opp1.Product_Sub_Type__c = 'No Renovation';
    opp1.Interest_Rate_Type__c = 'Floating';
    opp1.Index__c = '1M LIBOR';

    opp1.Commission_Type__c = 'Internal';
    opp1.Index_Floor__c = '1.00%';
    opp1.Index_Margin__c = 1.50;
    opp1.Deal_Intro_Source__c = 'Hotline';
    opp1.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp1.Fee__c = 2;
    opp1.Aggregate_Funding__c = 55000000;
    opp1.Loan_Effective_Date__c = system.today().addDays(-3);
    opp1.CloseDate = system.today().addDays(-3);

    insert opp1;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;
    Test.startTest();
    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;

    insert padv;

    adv.Wire_Date__c = system.today();

    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    system.debug('Deal Amount' + opp.Amount);
    system.debug('account amount' + acc.Borrowed_on_Bridge_Loans__c);
    Test.stopTest();
  }

  static testMethod void advance_Tests_SABTest() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Single_Asset_Bridge_Loan'
    ]
    .Id;
    opp.StageName = 'Underwriting';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;
    Test.startTest();
    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;
    insert padv;

    adv.Wire_Date__c = system.today();
    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    Test.stopTest();
  }

  static testMethod void advance_Tests_AcquiredBridgeTest() {
    //internal
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    opp.Apex_Context__c = true;
    opp.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE sobjecttype = 'Opportunity' AND DeveloperName = 'Acquired_Bridge_Loan_Active'
    ]
    .Id;
    opp.StageName = 'Underwriting';
    opp.Draw_Period__c = '12 Months';
    opp.Repayment_Period__c = '9 Months';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Maturity_Date_Calculation_Type__c = 'Fixed at Closing';
    opp.Line_Expiration__c = '18 Months';
    opp.Requested_LTC_Max__c = 70;
    opp.Requested_LTV_Max__c = 80;
    opp.Requested_Origination_Fee__c = 0;
    opp.Requested_Draw_Fee__c = 2;
    opp.Requested_Exit_Fee__c = 0;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 10;
    opp.Requested_Revolving__c = 'Yes';
    opp.Requested_Draw_Fee_Cap__c = 'None';
    opp.Product_Sub_Type__c = 'No Renovation';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Commission_Type__c = 'Internal';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Deal_Intro_Source__c = 'Hotline';
    opp.Deal_Intro_Sub_source__c = 'Direct Mail';
    opp.Fee__c = 2;

    update opp;

    Property__c property = new Property__c();
    property.Name = 'Test1';
    property.Deal__c = opp.Id;
    property.Escrow_Company_text__c = 'ESCROW';
    property.Insurance_Company_text__c = 'INSURANCE';
    property.Status__c = 'Pending';
    property.Override_Origination_Fee__c = 1000;
    property.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE
        sobjecttype = 'Property__c'
        AND DeveloperName = 'Bridge_No_Renovation'
    ]
    .Id;

    insert property;
    Test.startTest();
    Advance__c adv = new Advance__c(
      Deal__c = opp.Id,
      Status__c = 'Pending',
      Closing_Funds_Checklist__c = true,
      Manager_Approved__c = true,
      Evidence_of_Insurance_Approved__c = true,
      Flood_Certificate_Approved__c = true
    );
    insert adv;

    Property_Advance__c padv = new Property_Advance__c();
    padv.Property__c = property.Id;
    padv.Advance__c = adv.Id;
    padv.Advance_Fee__c = 1000;
    padv.Initial_Disbursement__c = 500000;
    padv.Renovation_Reserve__c = 500000;
    padv.Origination_Fee__c = 1000;
    insert padv;

    adv.Wire_Date__c = system.today();
    adv.Status__c = 'Completed';
    system.debug('subtotal adv' + adv.Advance_and_Origination_Fee_Subtotal__c);
    update adv;

    Test.stopTest();
  }
}