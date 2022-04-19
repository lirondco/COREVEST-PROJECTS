public without sharing class AdvanceClearToFundController {
  public static List<String> docStructures = new List<String>{
    'Pro_Forma_MUC', //pro forma or muc
    //'Evidence_of_Insurance', //evidence of insurance
    'Advance_Funding_Request_for_Advance', //request for advance
    'LOC_Closing_Instructions', //closing instructions
    'Advance_Funding_Security_Instrument', //security instrument
    'Vesting_Deed', //executed vesting deed
    'Settlement_Statement', //settlement statement
    'Advance_Funding_Funding_Approval_Package', //corevest funding package
    //'Advance_Flood_Certificate', //Flood Certificate
    'Flood_Insurance_if_applicable', //flood insurance (if applicable)
    'HOA_Policy_if_applicable', // HOA Policy (if applicable)
    'LOC_Renovation_Cert' // Renovation Certificate (if applicable)
  };
  @AuraEnabled
  public static String init(Id advanceId) {
    Advance__c advance = [
      SELECT
        Id,
        Deal__c,
        Deal__r.Record_Type_Name__c,
        Closing_Funds_Checklist__c,
        Closing_Funds_Checklist_Date__c,
        Closing_Funds_Checklist_Comments__c,
        Closing_Funds_Checked_By__r.Name,
        Closing_Funds_Checked_By__c,
        Manager_Approval_Comments__c,
        Manager_Approval_Date__c,
        Manager_Approved__c,
        Manager_Approved_By__c,
        Manager_Approved_By__r.Name,
        Evidence_of_Insurance_Approval_Comments__c,
        Evidence_of_Insurance_Approval_Date__c,
        Evidence_of_Insurance_Approved__c,
        Evidence_of_Insurance_Approved_By__r.Name,
        Evidence_of_Insurance_Approved_By__c,
        Flood_Certificate_Approval_Comments__c,
        Flood_Certificate_Approval_Date__c,
        Flood_Certificate_Approved__c,
        Flood_Certificate_Approved_By__c,
        Flood_Certificate_Approved_By__r.Name
      FROM Advance__c
      WHERE Id = :advanceId
      LIMIT 1
    ];

    if(advance.Deal__r.Record_Type_Name__c == 'Single_Asset_Bridge_Loan') {
      List<String> newDocstructures = new List<String>();
      for(String ds : docStructures) {
        newDocstructures.add(ds + '_sab');
      }
      docStructures = newDocstructures;
    }

    Map<String, Map<String, Object>> response = new Map<String, Map<String, Object>>();

    Map<String, String> docStringMap = new Map<String, String>();
    for (Document_Structure__mdt docStructure : [
      SELECT Id, Folder_Structure_String__c, Document_Type__c, DeveloperName
      FROM Document_Structure__mdt
      WHERE sObject__c = 'Advance__c' AND DeveloperName IN :docStructures
    ]) {
      String docString =
        docStructure.Folder_Structure_String__c +
        '|' +
        docStructure.Document_Type__c;

      docStringMap.put(docString, docStructure.DeveloperName);

      response.put(docString, new Map<String, Object>());
      response.get(docString).put('files', new List<Deal_Document__c>());
      response.get(docString).put('docInfoId', '');
    }

    Map<String, Document_Information__c> docInfoMap = new Map<String, Document_Information__c>();
    for (Document_Information__c docInfo : [
      SELECT Id, Doc_String__c, Internal_Comments__c
      FROM Document_Information__c
      WHERE Doc_String__c IN :docStringMap.keySet() AND Advance__c = :advanceId
    ]) {
      String docString = docInfo.Doc_String__c;
      response.get(docString).put('documentInformation', docInfo);
      response.get(docString).put('docInfoId', docInfo.Id);
    }

    system.debug('--docStringMap--');
    system.debug(docStringMap.keySet());

    for (Deal_Document__c dealDoc : [
      SELECT
        Id,
        Doc_String__c,
        Reviewed__c,
        Reviewed_By__r.Name,
        Reviewed_By__c,
        File_Name__c,
        Attachment_Id__c,
        Reviewed_On__c
      FROM Deal_Document__c
      WHERE advance__c = :advanceId AND Doc_String__C IN :docStringMap.keySet()
      ORDER BY CreatedDate DESC
    ]) {
      String docString = dealDoc.Doc_String__c;
      Map<String, Object> castedMap = (Map<String, Object>) response.get(
        docString
      );
      List<Deal_Document__c> castedList = (List<Deal_Document__C>) castedMap.get(
        'files'
      );
      castedList.add(dealDoc);
    }

    List<Document_Information__c> docInfosToInsert = new List<Document_Information__c>();
    for (String docString : response.keySet()) {
      String docInfoId = (String) response.get(docString).get('docInfoId');

      if (String.isBlank(docInfoId)) {
        docInfosToInsert.add(
          new Document_Information__c(
            Advance__c = advance.Id,
            Deal__c = advance.Deal__c,
            Doc_String__c = docString,
            Internal_Comments__c = ''
          )
        );
      }
      // if(response.get(docString).get(''))
    }

    insert docInfosToInsert;

    for (Document_Information__c docInfo : docInfosToInsert) {
      response.get(docInfo.Doc_String__c).put('docInfoId', docInfo.Id);
      response.get(docInfo.Doc_String__c).put('documentInformation', docInfo);
    }

    Map<String, Map<String, Object>> finalResponse = new Map<String, Map<String, Object>>();

    for (String docString : response.keySet()) {
      String devName = docStringMap.get(docString).replace('_sab', '');
      finalResponse.put(devName, response.get(docString));

      List<Deal_Document__c> dealDocs = (List<Deal_Document__c>) (finalResponse.get(
          devName
        )
        .get('files'));
      finalResponse.get(devName).put('uploaded', dealDocs.size() > 0);
      finalResponse.get(devName).put('reviewed', false);
      finalResponse.get(devName).put('lastReviewed', '');
      finalResponse.get(devName).put('reviewedById', null);
      finalResponse.get(devName).put('reviewedBy', null);
      finalResponse.get(devName).put('filesLength', dealDocs.size());
      if (dealDocs.size() > 0) {
        Boolean allReviewed = true;
        DateTime lastReviewed = null;
        String reviewedBy = null;
        Id reviewedById = null;
        for (Deal_Document__c doc : dealDocs) {
          if (!doc.Reviewed__c) {
            allReviewed = false;
            lastReviewed = null;
          } else {
            reviewedBy = doc.Reviewed_By__r.Name;
            reviewedById = doc.Reviewed_By__c;
          }
          if (lastReviewed == null && allReviewed && doc.Reviewed__c) {
            lastReviewed = doc.Reviewed_On__c;
          }
        }

        if (reviewedBy != null) {
          finalResponse.get(devName).put('reviewedBy', reviewedBy);
          finalResponse.get(devName).put('reviewedById', reviewedById);
        }

        if (lastReviewed != null) {
          finalResponse.get(devName).put('lastReviewed', lastReviewed);
        }
        finalResponse.get(devName).put('reviewed', allReviewed);
      }
    }

    Map<String, Object> advanceObj = new Map<String, Object>();
    advanceObj.put('checklist', advance.Closing_Funds_Checklist__c);
    advanceObj.put('lastReviewed', advance.Closing_Funds_Checklist_Date__c);
    advanceObj.put('comments', advance.Closing_Funds_Checklist_Comments__c);
    advanceObj.put('reviewedById', advance.Closing_Funds_Checked_By__c);
    advanceObj.put('reviewedBy', advance.Closing_Funds_Checked_By__r.Name);
    finalResponse.put('advance', advanceObj);
    Map<String, Object> managerObj = new Map<String, Object>();
    managerObj.put('checklist', advance.Manager_Approved__c);
    managerObj.put('lastReviewed', advance.Manager_Approval_Date__c);
    managerObj.put('comments', advance.Manager_Approval_Comments__c);
    managerObj.put('reviewedById', advance.Manager_Approved_By__c);
    managerObj.put('reviewedBy', advance.Manager_Approved_By__r.Name);
    finalResponse.put('manager', managerObj);
    Map<String, Object> evidenceOfInsuranceObj = new Map<String, Object>();
    evidenceOfInsuranceObj.put(
      'checklist',
      advance.Evidence_of_Insurance_Approved__c
    );
    evidenceOfInsuranceObj.put(
      'lastReviewed',
      advance.Evidence_of_Insurance_Approval_Date__c
    );
    evidenceOfInsuranceObj.put(
      'comments',
      advance.Evidence_of_Insurance_Approval_Comments__c
    );
    evidenceOfInsuranceObj.put(
      'reviewedById',
      advance.Evidence_of_Insurance_Approved_By__c
    );
    evidenceOfInsuranceObj.put(
      'reviewedBy',
      advance.Evidence_of_Insurance_Approved_By__r.Name
    );
    finalResponse.put('evidenceOfInsurance', evidenceOfInsuranceObj);
    Map<String, Object> floodCertificateObj = new Map<String, Object>();
    floodCertificateObj.put('checklist', advance.Flood_Certificate_Approved__c);
    floodCertificateObj.put(
      'lastReviewed',
      advance.Flood_Certificate_Approval_Date__c
    );
    floodCertificateObj.put(
      'comments',
      advance.Flood_Certificate_Approval_Comments__c
    );
    floodCertificateObj.put(
      'reviewedById',
      advance.Flood_Certificate_Approved_By__c
    );
    floodCertificateObj.put(
      'reviewedBy',
      advance.Flood_Certificate_Approved_By__r.Name
    );
    finalResponse.put('floodCertificate', floodCertificateObj);

    //

    return JSON.serialize(finalResponse);
  }
}