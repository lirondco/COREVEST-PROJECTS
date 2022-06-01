@isTest
/*private class lightning_Tests {

//static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

    static TestMethod void lightning_Tests_UnitTest(){
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        List<Property__c> properties = test_Helper.createProperties(opp);
        // Trivikram
        Advance__c objAdvance = new Advance__c(Deal__c = opp.Id,Status__c='Completed',Wire_Date__c=system.today());
        insert objAdvance;

        Test.startTest();
            //Trivikram - start
            lightning_Controller.calculateTotal(opp.Id);
            //DashboardDetailsController.updateDashboardDisplay(opp.Id);
            //DashboardDetailsController.getDashboardDisplay(opp.Id);
            //Trivikram - End
            lightning_Controller.getSession();
            lightning_Controller.getLoanApplication(opp.Id);
            lightning_Controller.getRecord(opp.Id);
            lightning_Controller.getRelatedListCount(opp.Id, 'Deal__c', 'Property__c', '');
            lightning_Controller.getRecordTypeName(opp.Id);
            lightning_Controller.getRecordList(opp.Id, 'Deal__c', 'Property__c', new List<String>{'Name'}, 'Id', 'Desc', '', '');
            lightning_Controller.getRecords(opp.Id, 'Deal__c', 'Property__c', new List<String>{'Name'}, 1, 10, 'Name', 'Desc', '', '');
            lightning_Controller.getRelatedList(opp.Id, 'Deal__c', 'Property__c', '', 'Name desc');
            lightning_Controller.upsertRecords(properties);
            lightning_Controller.upsertRecord(opp);
            lightning_Controller.getUserId();
            lightning_Controller.searchRecords('Test', 'Opportunity', '', 10);
            properties[0].Property_Name__c = 'different name';
            lightning_Controller.saveDataTape(JSON.serialize(properties), opp.Id);
            properties[0].Active__c = false;
            update properties;
            properties[0].Active__c = true;
            update properties;
            lightning_Controller.deleteRecord(properties.remove(0));
            lightning_Controller.deleteRecords(properties);

            Id i = lightning_Controller.saveAttachment(opp.Id, 'test', 'test', 'txt');
            lightning_Controller.saveTheChunk(opp.Id, 'test', 'test', 'text', '');
            lightning_Controller.saveTheChunk(opp.Id, 'test', 'test', 'text', i);

        Test.stopTest();
    }

    static TestMethod void lightning_Tests_UNitTest2(){
        Account acc = test_Helper.createAccount();
        System.debug(1);
        Contact cont = test_Helper.createContact( acc );
        System.debug(2);

        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        System.debug(3);

        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        System.debug(4);

        opp.StageName = 'Term Sheet Issued';
        System.debug(5);

        List<Property__c> properties = test_Helper.createProperties(opp);
        System.debug(6);


        properties[0].Active__c = false;
        update properties;
        System.debug(7);

        properties[0].Active__c = true;
        properties[0].Parent_Property__c = properties[1].Id;
        update properties;
        System.debug(8);

    }

    static TestMethod void lightning_Tests_UnitTest3(){
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity(acc, cont);
        List<Property__c> properties = test_Helper.createProperties(opp);

        insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
        insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
        insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
        insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');

        List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>)JSON.deserialize(documentUploader_Controller.getAttachments(opp.Id, null), List<documentUploader_Controller.AttachmentWrapper>.class);
        documentUploader_Controller.getPicklists('Opportunity', 'Term_Loan', 'standard', null, null);
        documentUploader_Controller.getPicklists('Opportunity', 'Term_Loan', 'borrower', null, null);
        documentUploader_Controller.getPicklists('Opportunity', 'Term_Loan', 'vendor', null, 'Legal Counsel');
        wrapper[0].section = 'Due Diligence Document - Submission Documents';
        wrapper[0].documentType = 'Wire Confirmation';

        wrapper[1].section = 'Due Diligence Document - Submission Documents';
        wrapper[1].documentType = 'Wire Confirmation';

        wrapper[2].section = 'Due Diligence Document - Submission Documents';
        wrapper[2].documentType = 'Wire Confirmation';

        wrapper[3].section = 'Due Diligence Document - Submission Documents';
        wrapper[3].documentType = 'Wire Confirmation';

        documentUploader_Controller.saveFile(JSON.serialize(wrapper[0]), opp.Id, 'Opportunity', 'Term_Loan');
        documentUploader_Controller.saveFile(JSON.serialize(wrapper[1]), opp.Id, 'Opportunity', 'Term_Loan');
        documentUploader_Controller.saveFile(JSON.serialize(wrapper[2]), properties[0].Id, 'Property__c', 'Term_Loan');
        documentUploader_Controller.saveFile(JSON.serialize(wrapper[3]), properties[0].Id, 'Property__c', 'Term_Loan');
        lightning_Controller.getDocuments(String.valueOf(opp.Id), 'vendor', String.valueOf(acc.Id), 'Title and Escrow');
        lightning_Controller.getDocuments(String.valueOf(opp.Id), 'borrower', String.valueOf(acc.Id), 'Title and Escrow');
        lightning_Controller.getDocuments(String.valueOf(opp.Id), 'internal', String.valueOf(acc.Id), 'Title and Escrow');
        contentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        lightning_Controller.getDOcumentData(cv.Id);

        delete [SELECT Id FROM ContentDocument];

        //documentUploader_Controller.saveFile(JSON.)

    }

    static TestMethod void lightning_Tests4(){
        Account acc = test_Helper.createAccount();
        Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Opportunity' and DeveloperName = 'LOC_Loan'].Id;


        opp.StageName = 'Termsheet Issued';
        opp.LOC_Loan_Type__c = 'Institutional';
        opp.Loan_Size__c = 3000000;
         opp.Draw_Period__c = '9 Months';
         opp.Repayment_Period__c = '12 Months';
         opp.Line_Expiration__c = '9 Months';
         opp.Requested_LTC_Max__c = 1;
         opp.Requested_LTV_Max__c = 1;
         opp.Requested_Origination_Fee__c = 1;
         opp.Requested_Draw_Fee__c = 1;
         opp.Requested_Exit_Fee__c = 1;
         opp.Requested_Interest_Type__c = 'Floating';
         opp.Requested_Rate_1_9_Months__c = 1;
         opp.Requested_Revolving__c = 'No';
         opp.Requested_Draw_Fee_Cap__c = 'N/A';
         opp.Index__c = '1M LIBOR';
         opp.Index_Floor__c = '1.00%';
         opp.Index_Margin__c = 1.50;
        opp.Product_Sub_Type__c = 'Single Asset w/out Renovation';
        opp.Apex_Context__c = true;
        opp.Approval_Status__c = 'Pending';
        update opp;

        List<Property__c> property = new List<Property__c>();
        for(Integer i = 0; i < 20; i++){
            property.add(new Property__c(Name='Test + ' + i, Deal__c = opp.Id, Escrow_Company_text__c = 'ESCROW', Insurance_Company_text__c = 'INSURANCE', Status__c = 'Pending'));
        }

        // insert property;

        Test.startTest();
            Advance__c adv = new Advance__c(Deal__c = opp.Id);
            insert adv;

             documentUploader_Controller.getPicklists('Opportunity', 'LOC_Loan', 'standard', null, null);
             insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
             insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
             insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');
             insert new Attachment(ParentId = opp.Id, Body = Blob.valueOf('saadsf'), Name='Test');

            List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>)JSON.deserialize(documentUploader_Controller.getAttachments(opp.Id), List<documentUploader_Controller.AttachmentWrapper>.class);
            wrapper[0].section = 'Funding Package';
            wrapper[0].documentType = '1';
            wrapper[1].section = 'Funding Package';
            wrapper[1].documentType = '1';
            documentUploader_Controller.getAdvancePicklists(opp.Id);
            documentUploader_Controller.getPropertyPicklists(opp.Id);



            documentUploader_Controller.saveFile(JSON.serialize(wrapper[0]), adv.Id, 'Advance__c', 'LOC_Loan');
            documentUploader_Controller.saveFile(JSON.serialize(wrapper[1]), adv.Id, 'Advance__c', 'LOC_Loan');


        Test.stopTest();
    }
}*/

private class lightning_Tests {
  //static List<Account> testAccounts = testDataFactory.createTestRecords(new Account[10]);

  static testMethod void lightning_Tests_UnitTest() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    List<Property__c> properties = test_Helper.createProperties(opp);

    Test.startTest();
    lightning_Controller.getSession();
    //lightning_Controller.getLoanApplication(opp.Id);
    lightning_Controller.getRecord(opp.Id);
    lightning_Controller.getRelatedListCount(
      opp.Id,
      'Deal__c',
      'Property__c',
      ''
    );
    lightning_Controller.getRecordTypeName(opp.Id);
    lightning_Controller.fetchLookUpValues('test', 'opportunity');
    lightning_Controller.getRecordList(
      opp.Id,
      'Deal__c',
      'Property__c',
      new List<String>{ 'Name' },
      'Id',
      'Desc',
      '',
      ''
    );
    lightning_Controller.getRecordListPropAdva(
      opp.Id,
      'Deal__c',
      'Property__c',
      new List<String>{ 'Name' },
      'Id',
      'Desc',
      '',
      '',
      True
    );    
    lightning_Controller.getRecordListPropAdva(
      opp.Id,
      'Deal__c',
      'Property__c',
      new List<String>{ 'Name' },
      'Id',
      'Desc',
      '',
      '',
      False
    );       
    lightning_Controller.getRecords(
      opp.Id,
      'Deal__c',
      'Property__c',
      new List<String>{ 'Name' },
      1,
      10,
      'Name',
      'Desc',
      '',
      ''
    );
    lightning_Controller.getRelatedList(
      opp.Id,
      'Deal__c',
      'Property__c',
      '',
      'Name desc'
    );
    lightning_Controller.upsertRecords(properties);
    lightning_Controller.upsertRecord(opp);
    lightning_Controller.getUserId();
    lightning_Controller.searchRecords('Test', 'Opportunity', '', 10);
    properties[0].Property_Name__c = 'different name';
    lightning_Controller.saveDataTape(JSON.serialize(properties), opp.Id);
    properties[0].Status__c = 'Inactive';
    update properties;
    properties[0].Status__c = 'Active';
    update properties;
    lightning_Controller.deleteRecord(properties.remove(0));
    lightning_Controller.deleteRecords(properties);

    Id i = lightning_Controller.saveAttachment(opp.Id, 'test', 'test', 'txt');
    lightning_Controller.saveTheChunk(opp.Id, 'test', 'test', 'text', '');
    lightning_Controller.saveTheChunk(opp.Id, 'test', 'test', 'text', i);
    Test.stopTest();
  }

  static testMethod void lightning_Tests_UnitTest2() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    List<Property__c> properties = test_Helper.createProperties(opp);

    properties[0].Status__c = 'Inactive';
    update properties;
    //properties[0].Active__c = true;
    //properties[0].Parent_Property__c = properties[1].Id;
    //update properties;
  }

  static testMethod void lightning_Tests_UnitTest3() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createOpportunity(acc, cont);
    List<Property__c> properties = test_Helper.createProperties(opp);

    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    Test.startTest();
    List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>) JSON.deserialize(
      documentUploader_Controller.getAttachments(opp.Id),
      List<documentUploader_Controller.AttachmentWrapper>.class
    );
    documentUploader_Controller.getPicklists(
      'Opportunity',
      'Term_Loan',
      'standard',
      null,
      null
    );
    documentUploader_Controller.getPicklists(
      'Opportunity',
      'Term_Loan',
      'borrower',
      null,
      null
    );
    documentUploader_Controller.getPicklists(
      'Opportunity',
      'Term_Loan',
      'vendor',
      null,
      'Legal Counsel'
    );
    wrapper[0].section = 'Due Diligence Document - Submission Documents';
    wrapper[0].documentType = 'Wire Confirmation';

    wrapper[1].section = 'Due Diligence Document - Submission Documents';
    wrapper[1].documentType = 'Wire Confirmation';

    wrapper[2].section = 'Due Diligence Document - Submission Documents';
    wrapper[2].documentType = 'Wire Confirmation';

    wrapper[3].section = 'Due Diligence Document - Submission Documents';
    wrapper[3].documentType = 'Wire Confirmation';

    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[0]),
      opp.Id,
      'Opportunity',
      'Term_Loan'
    );
    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[1]),
      opp.Id,
      'Opportunity',
      'Term_Loan'
    );
    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[2]),
      properties[0].Id,
      'Property__c',
      'Term_Loan'
    );
    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[3]),
      properties[0].Id,
      'Property__c',
      'Term_Loan'
    );
    lightning_Controller.getDocuments(
      String.valueOf(opp.Id),
      'vendor',
      String.valueOf(acc.Id),
      'Title and Escrow'
    );


    lightning_Controller.getDocuments(
      String.valueOf(opp.Id),
      'borrower',
      String.valueOf(acc.Id),
      'Title and Escrow'
    );
    Test.stopTest();

    //lightning_Controller.getDocuments(String.valueOf(opp.Id), 'internal', String.valueOf(acc.Id), 'Title and Escrow');
    //contentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
    //lightning_Controller.getDOcumentData(cv.Id);

    //delete [SELECT Id FROM ContentDocument];

    //documentUploader_Controller.saveFile(JSON.)
  }

  static testMethod void lightning_Tests4() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createLOCDeal(acc, cont);
    opp.StageName = 'Term Sheet Issued';
    opp.Term_Sheet_Issued__c = system.today();
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Draw_Period__c = '9 Months';
    opp.Repayment_Period__c = '12 Months';
    opp.Line_Expiration__c = '9 Months';
    opp.Requested_LTC_Max__c = 1;
    opp.Requested_LTV_Max__c = 1;
    opp.Requested_Origination_Fee__c = 1;
    opp.Requested_Draw_Fee__c = 1;
    opp.Requested_Exit_Fee__c = 1;
    opp.Requested_Interest_Type__c = 'Floating';
    opp.Requested_Revolving__c = 'No';
    opp.Requested_Draw_Fee_Cap__c = 'N/A';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Product_Sub_Type__c = 'Renovation';
    opp.Apex_Context__c = true;
    opp.Approval_Status__c = 'Pending';
    update opp;

    List<Property__c> property = new List<Property__c>();
    for (Integer i = 0; i < 20; i++) {
      property.add(
        new Property__c(
          Name = 'Test + ' + i,
          Deal__c = opp.Id,
          Escrow_Company_text__c = 'ESCROW',
          Insurance_Company_text__c = 'INSURANCE',
          Status__c = 'Pending'
        )
      );
    }

    // insert property;

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = opp.Id);
    insert adv;

    Deal_Document__c dd = new Deal_Document__c();
    dd.Deal__c = opp.id;
    dd.type__c = 'Ic Memo';
    insert dd;

    documentUploader_Controller.getPicklists(
      'Opportunity',
      '',
      'standard',
      null,
      null
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );

    List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>) JSON.deserialize(
      documentUploader_Controller.getAttachments(opp.Id),
      List<documentUploader_Controller.AttachmentWrapper>.class
    );
    wrapper[0].section = 'Funding Package';
    wrapper[0].documentType = '1';
    wrapper[1].section = 'Funding Package';
    wrapper[1].documentType = '1';
    wrapper[2].section = 'Funding Package';
    wrapper[2].documentType = '1';
    documentUploader_Controller.getAdvancePicklists(opp.Id);
    documentUploader_Controller.getPropertyPicklists(opp.Id);

    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[0]),
      adv.Id,
      'Advance__c',
      'LOC_Loan'
    );
    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[1]),
      adv.Id,
      'Advance__c',
      'LOC_Loan'
    );

    documentUploader_Controller.getRecordType(opp.id, 'Opportunity');
    documentUploader_Controller.getDocumentValidations(
      'Opportunity',
      'LOC_Loan',
      'standard',
      null,
      null
    );
    Test.stopTest();
  }

  static testMethod void lightning_Tests6A() {
    User u = [SELECT id FROM User WHERE id = :Userinfo.getUserId()];
    System.runAs(u) {
      EmailTemplate validEmailTemplate = new EmailTemplate();
      validEmailTemplate.isActive = true;
      validEmailTemplate.Name = 'name';
      validEmailTemplate.DeveloperName = 'Alston_Bird_Docs_Ready_For_Review_1612504237176';
      validEmailTemplate.TemplateType = 'text';
      validEmailTemplate.HtmlValue = 'text';
      validEmailTemplate.FolderId = UserInfo.getUserId();
      insert validEmailTemplate;
    }

    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createLOCDeal(acc, cont);
    opp.StageName = 'Term Sheet Issued';
    opp.Term_Sheet_Issued__c = system.today();
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Draw_Period__c = '9 Months';
    opp.Repayment_Period__c = '12 Months';
    opp.Line_Expiration__c = '9 Months';
    opp.Requested_LTC_Max__c = 1;
    opp.Requested_LTV_Max__c = 1;
    opp.Requested_Origination_Fee__c = 1;
    opp.Requested_Draw_Fee__c = 1;
    opp.Requested_Exit_Fee__c = 1;
    opp.Requested_Interest_Type__c = 'Floating';
    opp.Requested_Revolving__c = 'No';
    opp.Requested_Draw_Fee_Cap__c = 'N/A';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Product_Sub_Type__c = 'Renovation';
    opp.Apex_Context__c = true;
    opp.Approval_Status__c = 'Pending';
    update opp;

    List<Property__c> property = new List<Property__c>();
    for (Integer i = 0; i < 20; i++) {
      property.add(
        new Property__c(
          Name = 'Test + ' + i,
          Deal__c = opp.Id,
          Escrow_Company_text__c = 'ESCROW',
          Insurance_Company_text__c = 'INSURANCE',
          Status__c = 'Pending'
        )
      );
    }

    // insert property;

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = opp.Id);
    insert adv;

    List<Deal_Document__c> dealDocList = new List<Deal_Document__c>();

    Deal_Document__c dd = new Deal_Document__c();
    dd.Deal__c = opp.id;
    dd.type__c = 'Ic Memo';
    dd.Document_Type__c = 'Final IC Memo';
    dealDocList.add(dd);

    Deal_Document__c dd2 = new Deal_Document__c();
    dd2.Deal__c = opp.id;
    dd2.type__c = 'Loan Document';
    dd2.section__c = 'LDR';
    dd2.Document_Type__c = 'LDR Part A';
    dealDocList.add(dd2);

    Deal_Document__c dd3 = new Deal_Document__c();
    dd3.Deal__c = opp.id;
    dd3.type__c = 'Loan Document';
    dd3.section__c = 'LDR';
    dd3.Document_Type__c = 'LDR Part B';
    dealDocList.add(dd3);

    Deal_Document__c dd4 = new Deal_Document__c();
    dd4.Deal__c = opp.id;
    dd4.type__c = 'Loan Document';
    dd4.section__c = 'Principle Loan Documents';
    dd4.Document_Type__c = 'Sponsor Guaranty';
    dealDocList.add(dd4);

    Deal_Document__c dd5 = new Deal_Document__c();
    dd5.Deal__c = opp.id;
    dd5.type__c = 'Loan Document';
    dd5.section__c = 'Principle Loan Documents';
    dd5.Document_Type__c = 'Loan Agreement';
    dealDocList.add(dd5);

    insert dealDocList;

    List<Id> dealDocId = new List<Id>();
    for(Deal_Document__c ddoc : dealDocList) {
      dealDocId.add(ddoc.Id);
    }

    lightning_Controller.generateReadAccessMap(dealDocId);

    documentUploader_Controller.getPicklists(
      'Opportunity',
      '',
      'standard',
      null,
      null
    );

    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );

    List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>) JSON.deserialize(
      documentUploader_Controller.getAttachments(opp.Id),
      List<documentUploader_Controller.AttachmentWrapper>.class
    );
    wrapper[0].section = 'Funding Package';
    wrapper[0].documentType = '1';
    wrapper[1].section = 'Funding Package';
    wrapper[1].documentType = '1';
    wrapper[2].section = 'Funding Package';
    wrapper[2].documentType = '1';
    documentUploader_Controller.getAdvancePicklists(opp.Id);
    documentUploader_Controller.getPropertyPicklists(opp.Id);

    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[0]),
      opp.Id,
      'Deal__c',
      'LOC_Loan'
    );

    documentUploader_Controller.getRecordType(opp.id, 'Opportunity');
    documentUploader_Controller.getDocumentValidations(
      'Opportunity',
      'LOC_Loan',
      'standard',
      null,
      null
    );
    Test.stopTest();
  }

  static testMethod void lightning_Tests5() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createLOCDeal(acc, cont);
    opp.StageName = 'Closed Won';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Draw_Period__c = '9 Months';
    opp.Repayment_Period__c = '12 Months';
    opp.Line_Expiration__c = '9 Months';
    opp.Requested_LTC_Max__c = 1;
    opp.Requested_LTV_Max__c = 1;
    opp.Requested_Origination_Fee__c = 1;
    opp.Requested_Draw_Fee__c = 1;
    opp.Requested_Exit_Fee__c = 1;
    opp.Requested_Interest_Type__c = 'Fixed';
    opp.Requested_Rate_1_9_Months__c = 1;
    opp.Requested_Revolving__c = 'No';
    opp.Requested_Draw_Fee_Cap__c = 'N/A';
    opp.Interest_Rate_Type__c = 'Fixed';
    opp.Product_Sub_Type__c = 'Renovation';
    opp.Apex_Context__c = true;
    opp.Approval_Status__c = 'Pending';
    opp.Loan_Effective_Date__c = system.today();
    opp.Final_Loan_Amount__c = 4000000;
    opp.Final_Spread__c = 2;
    opp.Final_Swap__c = 2;
    update opp;

    List<Property__c> property = new List<Property__c>();
    for (Integer i = 0; i < 20; i++) {
      property.add(
        new Property__c(
          Name = 'Test + ' + i,
          Deal__c = opp.Id,
          Escrow_Company_text__c = 'ESCROW',
          Insurance_Company_text__c = 'INSURANCE',
          Status__c = 'Pending'
        )
      );
    }

    // insert property;

    Test.startTest();
    Advance__c adv = new Advance__c(Deal__c = opp.Id);
    insert adv;

    documentUploader_Controller.getPicklists(
      'Opportunity',
      'LOC_Loan',
      'standard',
      null,
      null
    );
    Attachment attc = new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert attc;
    
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );
    insert new Attachment(
      ParentId = opp.Id,
      Body = Blob.valueOf('saadsf'),
      Name = 'Test'
    );

    List<documentUploader_Controller.AttachmentWrapper> wrapper = (List<documentUploader_Controller.AttachmentWrapper>) JSON.deserialize(
      documentUploader_Controller.getAttachments(opp.Id),
      List<documentUploader_Controller.AttachmentWrapper>.class
    );
    wrapper[0].section = 'Funding Package';
    wrapper[0].documentType = '1';
    wrapper[1].section = 'Funding Package';
    wrapper[1].documentType = '1';
    documentUploader_Controller.getAdvancePicklists(opp.Id);
    documentUploader_Controller.getPropertyPicklists(opp.Id);

    documentUploader_Controller.saveFile(
      JSON.serialize(wrapper[2]),
      opp.id,
      'Opportunity',
      ''
    );

    Test.stopTest();
    lightning_Controller.reparentAttachment(attc.Id, adv.Id);
  }

  static testMethod void lightning_Tests7() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createLOCDeal(acc, cont);
    opp.StageName = 'Closed Won';
    opp.LOC_Loan_Type__c = 'Credit Line';
    opp.Loan_Size__c = 3000000;
    opp.Draw_Period__c = '9 Months';
    opp.Repayment_Period__c = '12 Months';
    opp.Line_Expiration__c = '9 Months';
    opp.Requested_LTC_Max__c = 1;
    opp.Requested_LTV_Max__c = 1;
    opp.Requested_Origination_Fee__c = 1;
    opp.Requested_Draw_Fee__c = 1;
    opp.Requested_Exit_Fee__c = 1;
    opp.Requested_Interest_Type__c = 'Floating';
    opp.Requested_Rate_1_9_Months__c = 1;
    opp.Requested_Revolving__c = 'No';
    opp.Requested_Draw_Fee_Cap__c = 'N/A';
    opp.Interest_Rate_Type__c = 'Floating';
    opp.Index__c = '1M LIBOR';
    opp.Index_Floor__c = '1.00%';
    opp.Index_Margin__c = 1.50;
    opp.Product_Sub_Type__c = 'Renovation';
    opp.Apex_Context__c = true;
    opp.Approval_Status__c = 'Pending';
    opp.Loan_Effective_Date__c = system.today();
    update opp;

    List<Property__c> property = new List<Property__c>();
    for (Integer i = 0; i < 20; i++) {
      property.add(
        new Property__c(
          Name = 'Test + ' + i,
          Deal__c = opp.Id,
          Escrow_Company_text__c = 'ESCROW',
          Insurance_Company_text__c = 'INSURANCE'
          // Status__c = 'Pending'
        )
      );
    }

    insert property;

    Test.startTest();
    lightning_Controller.calculateSmartyStreetsVerified(opp.Id);
    lightning_Controller.getDealIdFromProperty(property[0].Id);
    Test.stopTest();
  }
  static testMethod void lightning_small() {
    Test.startTest();
    lightning_Controller.queryUniversalSettings();
    lightning_Controller.getPicklistFieldValue('Opportunity', 'StageName');
    lightning_Controller.userHasPermission('Test');
    Test.stopTest();
  }

  static testMethod void dupeTests() {
    Account acc = test_Helper.createAccount();
    Contact cont = test_Helper.createContact(acc);
    Opportunity opp = test_Helper.createBridgeDeal(acc, cont);

    Account acc1 = acc.clone(false, false, false, false);
    acc1.Name = 'Steve';
    insert acc1;
    //Account acc1 = test_Helper.createAccount();
    Contact cont1 = test_Helper.createContact(acc1);
    Opportunity opp1 = test_Helper.createOpportunity(acc1, cont1);
    opp1.RecordTypeId = opp.RecordTypeId;

    update new List<Opportunity>{ opp, opp1 };


    // for (Integer i = 0; i < properties1.size(); i++) {
    // }

    Test.startTest();
    List<Property__c> properties = test_Helper.createProperties(opp);

    opp1.RecordTypeId = opp.RecordTypeId;
    List<Property__c> properties1 = test_Helper.createProperties(opp1);

    dupcheck__dcJob__c dupeJob = new dupcheck__dcJob__c();
    dupeJob.dupcheck__sourceObject__c = 'a19';
    dupeJob.dupcheck__name__c = 'Bingo';
    insert dupeJob;

    dupcheck__dcGroup__c dupeGroup = new dupcheck__dcGroup__c();
    dupeGroup.dupcheck__dcJob__c = dupeJob.Id;
    dupeGroup.dupcheck__group__c = 1;
    insert dupeGroup;

    List<dupcheck__dc3Duplicate__c> dupes = new List<dupcheck__dc3Duplicate__c>();
    for (Integer i = 0; i < properties.size() - 1; i++) {
      dupcheck__dc3Duplicate__c dupe = new dupcheck__dc3Duplicate__c();
      dupe.dupcheck__dcGroup__c = dupeGroup.Id;
      dupe.dupcheck__dcJob__c = dupeJob.Id;
      dupe.dupcheck__SourceObject__c = properties[i].Id;
      dupe.dupcheck__MatchObject__c = properties1[i].Id;
      dupe.dupcheck__Score__c = 100;
      dupes.add(dupe);
    }

    dupcheck__dc3Duplicate__c dupe = new dupcheck__dc3Duplicate__c();
    dupe.dupcheck__dcGroup__c = dupeGroup.Id;
    dupe.dupcheck__dcJob__c = dupeJob.Id;
    dupe.dupcheck__SourceObject__c = properties1[properties1.size() - 1].Id;
    dupe.dupcheck__MatchObject__c = properties[properties.size() - 1].Id;
    dupe.dupcheck__Score__c = 100;
    dupes.add(dupe);

    insert dupes;

    Map<String, String> newList = new Map<String, String>();
    for (Property__c property : properties) {
      newList.put(property.Id, property.Deal__c);
    }

    lightning_Controller.checkDuplicateFound(newList);
    lightning_Controller.getRelatedListPropertyForDupeCheck(
      opp.Id,
      'Deal__c',
      'Property__c',
      '',
      ''
    );
    //dupeJob.dupcheck__status__c = 'Completed';
    //update dupeJOb;
    //dupeJob.Status__c = ''

    Test.stopTest();
  }

  static testMethod void appraisal_Ltg_test() {
    StaticResource xml = [SELECT Id, Body FROM StaticResource WHERE Name = 'AppraisalXMLTest' LIMIT 1];
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.xml',
            VersionData = xml.Body,
            IsMajorVersion = true
        );

        insert cv;
        Account acc = Test_Helper.createAccount();
        Contact cont = Test_Helper.createContact( acc );
        Opportunity opp = Test_Helper.createOpportunity( acc, cont );
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Term_Loan' and sobjecttype = 'Opportunity'].Id;
        List<Property__c> properties = Test_Helper.createProperties(opp);
        Appraisal__c appraisal = Test_Helper.createAppraisal(opp, properties[0]);

        lightning_Controller.attachFileToParent(cv.Id, appraisal.Id);
  }
}