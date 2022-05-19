public with sharing class ExecSummaryController {
  private static final List<String> IC_TYPES = new List<String>{
    'Draft IC Memo',
    'Committee Memo'
  };
  // @AuraEnabled(cacheable=true)
  // public static String queryChildrenRecords(Id recordId) {
  //   Map<String, List<Object>> resMap = new Map<String, List<Object>>();

  //   List<Deal_Contact__c> sponsors = [
  //     SELECT
  //       Id,
  //       Account_Entity__c,
  //       Contact_Name__c,
  //       Net_Worth__c,
  //       Liquidity__c,
  //       Rental_Units_Owned__c,
  //       Middle_Credit_Score__c,
  //       Cash_Equivalent__c,
  //       Cash_Position__c,
  //       Years_of_Experience__c,
  //       Annual_Income_Last_Year__c,
  //       Contact__r.Sponsor_Tier__c,
  //       Contact__r.Repeat_Borrower__c,
  //       Contact__r.Borrowed_on_Bridge_Loans__c,
  //       Contact__r.Borrowed_on_Term_Loans__c,
  //       Contact__r.CurrentPayoffAmount__c,
  //       Contact__r.Deliquency_History__c,
  //       Contact__r.Est_Payoff_Amt_by_Lender_LR__c
  //     FROM Deal_Contact__c
  //     WHERE Deal__c = :recordId AND entity_type__c = 'sponsor'
  //   ];
  //   resMap.put('Sponsors', sponsors);

  //   List<Deal_Contact__c> guarantors = [
  //     SELECT
  //       Id,
  //       Contact__c,
  //       Name,
  //       Contact_Name__c,
  //       Rental_Units_Owned__c,
  //       Cash_Equivalent__c,
  //       Cash_Position__c,
  //       Net_Worth__c,
  //       Annual_Income_Last_Year__c,
  //       Annual_Income_2_Years_Ago__c,
  //       Middle_Credit_Score__c,
  //       Contact__r.Middle_Credit_Score__c,
  //       Contact__r.Name,
  //       Contact__r.Phone,
  //       Contact__r.Email,
  //       Contact__r.Experience__c,
  //       Contact__r.Liquidity__c,
  //       Contact__r.Sponsor_Tier__c,
  //       Contact__r.Deliquency_History__c,
  //       Contact__r.Years_of_Experience__c,
  //       Years_of_Experience__c,
  //       Contact__r.Repeat_Borrower__c
  //     FROM Deal_Contact__c
  //     WHERE Deal__c = :recordId AND entity_type__c = 'Guarantor'
  //     ORDER BY Percentage_Owned__c DESC, Middle_Credit_Score__c DESC
  //   ];
  //   resMap.put('Guarantors', guarantors);

  //   List<AggregateResult> propertyTypes = [
  //     SELECT Count(Id) ct, Property_Type__c
  //     FROM Property__c
  //     WHERE Deal__c = :recordId
  //     GROUP BY Property_Type__c
  //   ];

  //   Deal_Document__c dealDoc = [
  //     SELECT ContentVersion_Id__c, Attachment_Id__c
  //     FROM Deal_Document__c
  //     WHERE
  //       Document_Type__c IN :IC_TYPES
  //       AND Deal__c = :recordId
  //       AND File_Name__c LIKE '%.pdf'
  //     ORDER BY CreatedDate DESC
  //     LIMIT 1
  //   ];

  //   ContentVersion cv = [
  //     SELECT VersionData
  //     FROM ContentVersion
  //     WHERE Id = :dealDoc.ContentVersion_Id__c
  //   ];
  //   String fileLink =
  //     'data:application/pdf;base64,' +
  //     EncodingUtil.base64Encode(cv.VersionData);

  //   resMap.put('FileLink', new List<Object>{ fileLink });

  //   List<Map<String, Object>> propTypes = new List<Map<String, Object>>();
  //   for (AggregateResult p : propertyTypes) {
  //     Map<String, Object> pT = new Map<String, Object>{
  //       'Type' => p.get('Property_Type__c'),
  //       'Count' => p.get('ct')
  //     };
  //     propTypes.add(pT);
  //   }
  //   resMap.put('PropTypes', propTypes);
  //   resMap.put('FileId', new List<Object>{ dealDoc.Attachment_Id__c });

  //   AggregateResult floodZone = [
  //     SELECT Count(Id) ct
  //     FROM Property__c
  //     WHERE Deal__c = :recordId AND Flood_Coverage_Needed__c = 'Yes'
  //   ];
  //   resMap.put('FloodZone', new List<Object>{ floodZone.get('ct') });

  //   return JSON.serialize(resMap);
  // }

  @AuraEnabled(cacheable=true)
  public static String getFileId(Id recordId) {
    List<Deal_Document__c> dealDoc = [
      SELECT ContentVersion_Id__c, Attachment_Id__c
      FROM Deal_Document__c
      WHERE
        Document_Type__c IN :IC_TYPES
        AND Deal__c = :recordId
        AND File_Name__c LIKE '%.pdf'
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    return dealDoc.size() > 0 && String.isNotEmpty(dealDoc[0].Attachment_Id__c) ? dealDoc[0].Attachment_Id__c : '';
  }
}