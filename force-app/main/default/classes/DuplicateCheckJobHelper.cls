public without sharing class DuplicateCheckJobHelper {
  public static void afterUpdate(
    List<dupcheck__dcJob__c> newList,
    List<dupcheck__dcJob__c> oldList
  ) {
    Set<Id> propertyDupeJobIds = new Set<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (
        newList[i].dupcheck__Status__c != oldLIst[i].dupcheck__Status__c &&
        newList[i].dupcheck__Status__c == 'Completed'
      ) {
        if (newList[i].dupcheck__sourceObject__c == 'a19') {
          propertyDupeJobIds.add(newList[i].Id);
        }
      }
    }

    if (propertyDupeJobIds.size() > 0) {
      checkTermPropertyDupes(propertyDupeJobIds);
    }
  }

  public static void checkTermPropertyDupes(Set<Id> propertyDupeJobIds) {
    Set<Id> sourceIds = new Set<Id>();
    // Set<Id> matchIds
    for (dupcheck__dcJob__c job : [
      SELECT
        Id,
        (
          SELECT Id, dupcheck__SourceObject__c
          FROM dupcheck__Duplicate_Check_Duplicates__r
        )
      FROM dupcheck__dcJob__c
      WHERE Id IN :propertyDupeJobIds
    ]) {
      for (
        dupcheck__dc3Duplicate__c dupe : job.dupcheck__Duplicate_Check_Duplicates__r
      ) {
        sourceIds.add(dupe.dupcheck__SourceObject__c);
      }
    }

    Map<String, String> newList = new Map<String, String>();
    Map<String, List<Map<String, String>>> dupeListMap = new Map<String, List<Map<String, String>>>();
    Map<String, String> propDealMap = new Map<String, String>();
    for (Property__c prop : [
      SELECT Id, Deal__c, Deal__r.RecordType.DeveloperName
      FROM Property__c
      WHERE Id IN :sourceIds
    ]) {
      if (prop.Deal__r.RecordType.DeveloperName == 'Term_Loan') {
        if (!dupeListMap.containsKey(prop.Deal__c)) {
          dupeListMap.put(prop.Deal__c, new List<Map<String, String>>());
        }

        if (!propDealMap.containsKey(prop.Id)) {
          propDealMap.put(prop.Id, prop.Deal__c);
        }

        newList.put(prop.Id, prop.Deal__c);
      }
    }

    Map<String, List<dupcheck__dc3Duplicate__c>> dupeCheckMap = checkDuplicateListFoundByRecordType(
      newList,
      'Term_Loan'
    );

    // List<Map<String, String>> dupeList = new List<Map<String, String>>();
    // Map<Id, List<Map<String, String>>()
    for (String i : dupeCheckMap.keySet()) {
      for (dupcheck__dc3Duplicate__c dupe : dupeCheckMap.get(i)) {
        Map<String, String> dupeObj = new Map<String, String>();
        dupeObj.put('sourceId', i);
        dupeObj.put('matchId', dupe.dupcheck__MatchObject__c);

        String dealId = propDealMap.get(i);

        dupeListMap.get(dealId).add(dupeObj);
      }
    }

    //system.debug(dupeCheckMap);

    // lightning_Controller.

    for (String recordId : dupeListMap.keySet()) {
      if (dupeListMap.get(recordId).size() > 0) {
        sendDupeEmail(JSON.serialize(dupeListMap.get(recordId)), recordId);
      }
    }
  }

  @AuraEnabled
  public static void sendDupeEmail(String dupeListStr, String recordId) {
    Settings__mdt settings = [
      SELECT
        Id,
        Enable_Duplicate_Property_Email__c,
        Duplicate_Property_Alert_Email__c
      FROM Settings__mdt
      WHERE DeveloperName = :'Universal_Settings'
      LIMIT 1
    ]; //Settings__mdt.getInstance('Universal_Settings');

    system.debug(settings);

    if (!settings.Enable_Duplicate_Property_Email__c) {
      return;
    }

    List<Object> dupeList = (List<Object>) JSON.deserializeUntyped(dupeListStr);

    Set<Id> propertyIds = new Set<Id>();
    for (Object obj : dupeList) {
      Map<String, Object> objMap = (Map<String, Object>) obj;
      propertyIds.add((Id) objMap.get('sourceId'));
      propertyIds.add((Id) objMap.get('matchId'));
    }

    Map<Id, Property__c> propMap = new Map<Id, Property__c>(
      [
        SELECT
          Id,
          Deal__c,
          Deal__r.Name,
          Name,
          Deal__r.StageName,
          CreatedDate,
          Deal__r.CloseDate,
          Deal__r.CAF_Analyst__r.Name,
          Deal__r.CAF_Analyst__r.Email,
          Deal__r.Owner.Name,
          Deal__r.Owner.Email,
          Deal__r.Second_Production_analyst__r.Name,
          Deal__r.Second_Production_analyst__r.Email
        FROM Property__c
        WHERE Id IN :propertyIds
      ]
    );
    system.debug(propertyIds);

    Opportunity deal = [
      SELECT
        Id,
        Name,
        Owner.Email,
        Caf_Analyst__r.Email,
        Second_Production_analyst__r.Email,
        Owner.ManagerId,
        Owner.Manager.Email,
        CAF_Analyst__r.Name,
        Caf_Analyst__r.ManagerId,
        Caf_Analyst__r.Manager.EMail,
        Second_Production_analyst__r.Name,
        Second_Production_analyst__r.ManagerId,
        Second_Production_analyst__r.Manager.Email
      FROM Opportunity
      WHERE Id = :recordId
      LIMIT 1
    ];

    String htmlBody = '<body><p>Duplicate properties were saved on the following deal: ';
    htmlBody +=
      '<a href="' +
      System.Url.getOrgDomainUrl().toexternalform() +
      '/lightning/r/Opportunity/' +
      recordId +
      '/view/">' +
      deal.Name +
      '</a></p>';
    htmlBody += '<table style="width: 100%">';
    htmlBody += '<tr>';
    htmlBody += '<th style="text-align: left">Source Property</th><th style="text-align: left">Source Deal</th><th style="text-align: left">Source Stage</th>';
    htmlBody += '<th style="text-align: left">Source Close Date</th>';
    htmlBody += '<th style="text-align: left">Source CAF Originator</th>';
    htmlBody += '<th style="text-align: left">Source Production Analyst</th>';

    htmlBody += '<th style="text-align: left">Match Property</th><th style="text-align: left">Match Deal</th><th style="text-align: left">Match Stage</th>';
    htmlBody += '<th style="text-align: left">Match Close Date</th>';
    htmlBody += '<th style="text-align: left">Match CAF Originator</th>';
    htmlBody += '<th style="text-align: left">Match Production Analyst</th>';
    // htmlBody += '<th style="text-align: left">Match CreatedDate</th>';
    htmlBody += '</tr><tbody>';

    Set<String> emails = new Set<String>();
    for (Object dupe : dupeList) {
      Map<String, Object> objMap = (Map<String, Object>) dupe;
      Property__c sourceProp = propMap.get((Id) objMap.get('sourceId'));
      Property__c matchProp = propMap.get((Id) objMap.get('matchId'));

      emails.add(matchProp.Deal__r.Owner.Email);

      if (String.isNotBlank(matchProp.Deal__r.CAF_Analyst__r.Email)) {
        emails.add(matchProp.Deal__r.CAF_Analyst__r.Email);
      }

      // Map<String, Object> sourceObj = (Map<String, Object>) dupe.get('source');
      // Map<String, Object> matchObj = (Map<String, Object>) dupe.get('match');
      htmlBody += '<tr>';
      htmlBody += '<td>' + sourceProp.Name + '</td>';
      htmlBody += '<td>' + sourceProp.Deal__r.Name + '</td>';
      htmlBody += '<td>' + sourceProp.Deal__r.StageName + '</td>';
      htmlBody += '<td>' + sourceProp.Deal__r.CloseDate.format() + '</td>';
      htmlBody += '<td>' + sourceProp.Deal__r.Owner.Name + '</td>';
      htmlBody += '<td>' + sourceProp.Deal__r.CAF_Analyst__r.Name + '</td>';

      htmlBody += '<td>' + matchProp.Name + '</td>';
      htmlBody += '<td>' + matchProp.Deal__r.Name + '</td>';
      htmlBody += '<td>' + matchProp.Deal__r.StageName + '</td>';
      htmlBody += '<td>' + matchProp.Deal__r.CloseDate.format() + '</td>';
      htmlBody += '<td>' + matchProp.Deal__r.Owner.Name + '</td>';
      htmlBody += '<td>' + matchProp.Deal__r.CAF_Analyst__r.Name + '</td>';
      // htmlBody +=
      //   '<td>' +
      //   matchProp.CreatedDate.format('MM/dd/yy hh:mm:ss a') +
      //   '</td>';
      htmlBody += '</tr>';
    }
    htmlBody += '</tbody>';
    htmlBody += '</table>';

    if (String.isNotBlank(settings.Duplicate_Property_Alert_Email__c)) {
      // for(String email : )
      emails.addAll(settings.Duplicate_Property_Alert_Email__c.split(';'));
    }

    emails.add(deal.Owner.Email);

    // if (String.isNotBlank(deal.Owner.ManagerId)) {
    //   emails.add(deal.Owner.Manager.Email);
    // }

    if (String.isNotBlank(deal.CAF_Analyst__r.Email)) {
      emails.add(deal.CAF_Analyst__r.Email);
    }
    // if (String.isNotBlank(deal.CAF_Analyst__r.ManagerId)) {
    //   emails.add(deal.CAF_Analyst__r.Manager.Email);
    // }
    if (String.isNotBlank(deal.Second_Production_analyst__r.Email)) {
      emails.add(deal.Second_Production_analyst__r.Email);
    }

    // if (String.isNotBlank(deal.Second_Production_analyst__r.ManagerId)) {
    //   emails.add(deal.Second_Production_analyst__r.Manager.Email);
    // }

    // emails.add();

    messaging.singleEmailMessage em = new messaging.SingleEmailMessage();
    em.setHtmlBody(htmlBody);
    em.setToAddresses(new List<String>(emails));
    em.setSubject('Duplicate Term Properties Saved');

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ em });
  }

  @AuraEnabled
  public static List<Map<String, String>> getDupeListFromDeal(String dealId) {
    //query properties here
    Map<String, String> newList = new Map<String, String>();
    String recTypeDevName = [
      SELECT Id, RecordType.DeveloperName
      FROM Opportunity
      WHERE Id = :dealId
      LIMIT 1
    ]
    .RecordType.DeveloperName;
    for (Property__c property : [
      SELECT Id, Deal__c
      FROM Property__c
      WHERE
        Deal__c = :dealId
        AND Is_Parent__c = FALSE
        AND Status__c IN (
          'Due Diligence',
          'Pending',
          'Closing',
          'On Hold',
          'Active',
          'Sold',
          'Paid Off'
        )
      ORDER BY Property_Name__c ASC, Name ASC
    ]) {
      newList.put(property.Id, dealId);
    }

    system.debug(newList);
    system.debug(newList.size());

    Map<String, List<dupcheck__dc3Duplicate__c>> dupeListMap = checkDuplicateListFoundByRecordType(
      newList,
      recTypeDevName.containsIgnoreCase('term') ? 'Term_Loan' : (recTypeDevName.containsIgnoreCase('loc') || recTypeDevName.containsIgnoreCase('bridge') ? 'LOC_Loan' : recTypeDevName)
    );

    system.debug(dupeListMap);

    List<Map<String, String>> dupeList = new List<Map<String, String>>();
    for (String sourceId : dupeListMap.keySet()) {
      for (dupcheck__dc3Duplicate__c dupe : dupeListMap.get(sourceId)) {
        dupeList.add(
          new Map<String, String>{
            'sourceId' => sourceId,
            'matchId' => dupe.dupcheck__MatchObject__c
          }
        );
      }
    }

    return dupeList;
  }

  @AuraEnabled
  public static Map<String, List<dupcheck__dc3Duplicate__c>> checkDuplicateListFoundByRecordType(
    Map<String, String> newList,
    String recordType
  ) {
    Decimal score = 65.00;
    Dupecheck_Setting__mdt[] settings = [
      SELECT MasterLabel, dupecheckscore__c
      FROM Dupecheck_Setting__mdt
      WHERE MasterLabel = 'Default'
    ];
    if (settings != null && !settings.isEmpty()) {
      score = settings[0].dupecheckscore__c;
    }
    Map<String, List<dupcheck__dc3Duplicate__c>> duplicateCheckRecords = new Map<String, List<dupcheck__dc3Duplicate__c>>();
    Map<String, List<dupcheck__dc3Duplicate__c>> dupMap = new Map<String, List<dupcheck__dc3Duplicate__c>>();
    Set<String> propIds = new Set<String>(newList.keySet());
    for (dupcheck__dc3Duplicate__c dup : [
      SELECT
        Id,
        dupcheck__Score__c,
        dupcheck__MatchObject__c,
        dupcheck__SourceObject__c,
        dupcheck__SourceRecordType__c,
        dupcheck__MatchRecordType__c
      FROM dupcheck__dc3Duplicate__c
      WHERE
        dupcheck__Score__c >= :score
        AND dupcheck__SourceObject__c IN :newList.keyset()
        AND dupcheck__MatchObject__c NOT IN :newList.keySet()
    ]) {
      if (!dupMap.containsKey(dup.dupcheck__MatchObject__c)) {
        dupMap.put(
          dup.dupcheck__MatchObject__c,
          new List<dupcheck__dc3Duplicate__c>()
        );
        propIds.remove(dup.dupcheck__SourceObject__c);
      }

      dupMap.get(dup.dupcheck__MatchObject__c).add(dup);
    }

    for (Property__c duplicateProperty : [
      SELECT Id, Deal_Record_Type__c, Deal__c
      FROM Property__c
      WHERE
        Id IN :dupMap.keySet()
        AND Deal__r.StageName NOT IN ('Withdrawn', 'Rejected')
        AND Status__c IN (
          'Due Diligence',
          'Pending',
          'Closing',
          'On Hold',
          'Active',
          'Sold',
          'Paid Off'
        )
    ]) {
      if (duplicateProperty.Deal_Record_Type__c == recordType) {
        for (dupcheck__dc3Duplicate__c dup : dupMap.get(duplicateProperty.Id)) {
          Id sourceId = dup.dupcheck__SourceObject__c;
          if (!duplicateCheckRecords.containsKey(sourceId)) {
            duplicateCheckRecords.put(
              sourceId,
              new List<dupcheck__dc3Duplicate__c>()
            );
          }

          if (newList.get(sourceId) != duplicateProperty.Deal__c) {
            duplicateCheckRecords.get(sourceId).add(dup);
          }
        }
      }
    }

    if (propIds.size() > 0) {
      dupMap = new Map<String, List<dupcheck__dc3Duplicate__c>>();

      for (dupcheck__dc3Duplicate__c dup : [
        SELECT
          Id,
          dupcheck__Score__c,
          dupcheck__MatchObject__c,
          dupcheck__SourceObject__c,
          dupcheck__SourceRecordType__c,
          dupcheck__MatchRecordType__c
        FROM dupcheck__dc3Duplicate__c
        WHERE
          dupcheck__Score__c >= :score
          AND dupcheck__MatchObject__c IN :newList.keyset()
          AND dupcheck__SourceObject__c NOT IN :newList.keySet()
      ]) {
        if (!dupMap.containsKey(dup.dupcheck__SourceObject__c)) {
          dupMap.put(
            dup.dupcheck__SourceObject__c,
            new List<dupcheck__dc3Duplicate__c>()
          );
        }
        String temp1 = dup.dupcheck__SourceObject__c;
        dup.dupcheck__SourceObject__c = dup.dupcheck__MatchObject__c;
        dup.dupcheck__MatchObject__c = temp1;

        dupMap.get(temp1).add(dup);
      }

      for (Property__c duplicateProperty : [
        SELECT Id, Deal_Record_Type__c, Deal__c
        FROM Property__c
        WHERE
          Id IN :dupMap.keySet()
          AND Deal__r.StageName NOT IN ('Withdrawn', 'Rejected')
          AND Status__c IN (
            'Due Diligence',
            'Pending',
            'Closing',
            'On Hold',
            'Active',
            'Sold',
            'Paid Off'
          )
          AND Deal_Record_Type__c = :recordType
      ]) {
        if (duplicateProperty.Deal_Record_Type__c == recordType) {
          for (
            dupcheck__dc3Duplicate__c dup : dupMap.get(duplicateProperty.Id)
          ) {
            Id sourceId = dup.dupcheck__SourceObject__c;
            if (!duplicateCheckRecords.containsKey(sourceId)) {
              duplicateCheckRecords.put(
                sourceId,
                new List<dupcheck__dc3Duplicate__c>()
              );
            }
            if (newList.get(sourceId) != duplicateProperty.Deal__c) {
              duplicateCheckRecords.get(sourceId).add(dup);
            }
          }
        }
      }
    }

    return duplicateCheckRecords;
  }
}