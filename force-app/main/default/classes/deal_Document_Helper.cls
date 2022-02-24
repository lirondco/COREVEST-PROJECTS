public class deal_Document_Helper {
  public static Integer CHUNK_SIZE = 4;

  public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Deal_Document__c.fields.getMap();

  /**
   * @name beforeInsert
   * @description
   * @param
   **/
  public static void beforeInsert(List<Deal_Document__c> newList) {
    Map<Id, List<Deal_Document__c>> oppMap = new Map<Id, List<Deal_Document__c>>();

    Map<Id, List<Deal_Document__c>> needDealAdvances = new Map<Id, List<Deal_Document__c>>();
    Map<Id, List<Deal_Document__c>> needDealProperty = new Map<Id, List<Deal_Document__c>>();

    for (Deal_Document__c doc : newList) {
      if (doc.Deal__c == null) {
        if (doc.Advance__c != null) {
          if (!needDealAdvances.containsKey(doc.Advance__c)) {
            needDealAdvances.put(doc.Advance__c, new List<Deal_Document__c>());
          }
          needDealAdvances.get(doc.Advance__c).add(doc);
        }

        if (doc.Property__c != null) {
          if (!needDealProperty.containsKey(doc.Property__c)) {
            needDealProperty.put(doc.Property__c, new List<Deal_Document__c>());
          }
          needDealProperty.get(doc.Property__c).add(doc);
        }
      }
    }

    if (needDealAdvances.size() > 0) {
      for (Advance__c adv : [
        SELECT Id, Deal__c
        FROM Advance__c
        WHERE Id IN :needDealAdvances.keySet()
      ]) {
        for (Deal_Document__c doc : needDealAdvances.get(adv.Id)) {
          doc.Deal__c = adv.Deal__c;
        }
      }
    }

    if (needDealProperty.size() > 0) {
      for (Property__c property : [
        SELECT Id, Deal__c
        FROM Property__c
        WHERE Id IN :needDealProperty.keySet()
      ]) {
        for (Deal_Document__c doc : needDealProperty.get(property.Id)) {
          doc.Deal__c = property.Deal__c;
        }
      }
    }

    Set<Id> docStructureIds = new Set<Id>();
    for (Deal_Document__c doc : newList) {
      if (doc.Deal__c != null) {
        if (!oppMap.containsKey(doc.Deal__c)) {
          oppMap.put(doc.Deal__c, new List<Deal_Document__c>());
        }
        oppMap.get(doc.Deal__c).add(doc);
      }

      if (String.isNotBlank(doc.Document_Structure_Id__c)) {
        docStructureIds.add(doc.Document_Structure_Id__c);
      }
    }

    if (oppMap.size() > 0) {
      Map<Id, Map<String, Checklist_Item__c>> itemMap = new Map<Id, Map<String, Checklist_Item__c>>();
      for (Checklist_Item__c item : [
        SELECT Id, Document_Type__c, Checklist_Section__r.Checklist__r.Deal__c
        FROM Checklist_Item__c
        WHERE Checklist_Section__r.Checklist__r.Deal__c IN :oppMap.keySet()
      ]) {
        if (
          !itemMap.containsKey(item.Checklist_Section__r.Checklist__r.Deal__c)
        ) {
          itemMap.put(
            item.Checklist_Section__r.Checklist__r.Deal__c,
            new Map<String, Checklist_Item__c>()
          );
        }

        itemMap.get(item.Checklist_Section__r.Checklist__r.Deal__c)
          .put(item.Document_Type__c, item);
      }

      for (Deal_Document__c doc : newList) {
        if (doc.Checklist_Item__c == null && doc.Deal__c != null) {
          if (
            itemMap.containsKey(doc.Deal__c) &&
            itemMap.get(doc.Deal__c).containsKey(doc.Document_Type__c)
          ) {
            doc.Checklist_Item__c = itemMap.get(doc.Deal__c)
              .get(doc.Document_Type__c)
              .Id;
          }
        }
      }
    }

    for (Opportunity o : [
      SELECT
        Id,
        Underwriter__c,
        Closer__c,
        Loan_Coordinator__c,
        OwnerId,
        CAF_Analyst__c
      FROM Opportunity
      WHERE Id IN :oppMap.keySet()
    ]) {
      for (Deal_Document__c doc : oppMap.get(o.Id)) {
        doc.Underwriter__c = o.Underwriter__c;
        doc.Closer__C = o.Closer__c;
        doc.Loan_Coordinator__c = o.Loan_Coordinator__c;
        doc.Originator__c = o.OwnerId;
        doc.Sales_Analyst__c = o.CAF_Analyst__c;
      }
    }

    if (docStructureIds.size() > 0) {
      Map<Id, Document_Structure__mdt> docStructureMap = new Map<Id, Document_Structure__mdt>(
        [
          SELECT
            Id,
            Folder_Structure_String__c,
            Confidential__c,
            Private__c,
            Public__c,
            Borrower_Access__c,
            Vendor_Access__c,
            Vendor_Type_Access__c,
            Include_for_Term_Sheet_Approval__c,
            Upload_Notification_Closer__c,
            Upload_Notification_Loan_Coordinator__c,
            Upload_Notification_Originations__c,
            Upload_Notification_Underwriter__c,
            Document_Type__c
          FROM Document_Structure__mdt
          WHERE Id IN :docStructureIds
        ]
      );

      for (Deal_Document__c doc : newList) {
        if (String.isNotBlank(doc.Document_Structure_Id__c)) {
          Document_Structure__mdt docStructure = docStructureMap.get(
            doc.Document_Structure_Id__c
          );
          doc.Document_Type__c = docStructure.Document_Type__c;

          List<String> folders = docStructure.Folder_Structure_String__c.split(
            ';'
          );

          doc.Type__c = folders[0];
          if (folders.size() > 1) {
            doc.Section__c = folders[1];
          }

          doc.Public__c = docStructure.Public__c;
          doc.Vendor_Access__c = docStructure.Vendor_Access__c;
          doc.Borrower_Access__c = docStructure.Borrower_Access__c;
          doc.Vendor_Type_Access__c = docStructure.Vendor_Type_Access__c;
          doc.Confidential__c = docStructure.Confidential__c;
          doc.Private__c = docStructure.Private__c;
          doc.Include_for_Term_Sheet_Approval__c = docStructure
            .Include_for_Term_Sheet_Approval__c;
          doc.Upload_Notification_Closer__c = docStructure
            .Upload_Notification_Closer__c;
          doc.Upload_Notification_Loan_Coordinator__c = docStructure
            .Upload_Notification_Loan_Coordinator__c;
          doc.Upload_Notification_Originations__c = docStructure
            .Upload_Notification_Originations__c;
          doc.Upload_Notification_Underwriter__c = docStructure
            .Upload_Notification_Underwriter__c;
        }
      }
    }
  }

  /**
   * @name afterInsert
   * @description
   * @param
   **/

  public static void afterInsert(List<Deal_Document__c> newList) {
    Set<Id> itemIds = new Set<Id>();
    for (Deal_Document__c doc : newList) {
      if (doc.Checklist_Item__c != null) {
        itemIds.add(doc.Checklist_Item__c);
      }
    }

    List<Checklist_Item__c> items = new List<Checklist_Item__c>();
    if (itemIds.size() > 0) {
      for (Checklist_Item__c item : [
        SELECT Id, Status__c
        FROM Checklist_Item__c
        WHERE Id IN :itemIds
      ]) {
        item.Status__c = 'Pending';
        items.add(item);
      }

      update items;
    }
  }

  /**
   * @name beforeUpdate
   * @description
   * @param
   **/
  public static void beforeUpdate(
    List<Deal_Document__c> newList,
    List<Deal_Document__c> oldList
  ) {
    Map<Id, Deal_Document__c> docMap = new Map<Id, Deal_Document__c>();

    Map<String, List<Deal_Document__c>> folderMap = new Map<String, List<Deal_Document__c>>();
    Map<String, List<Deal_Document__c>> folderMapBridge = new Map<String, List<Deal_Document__c>>();

    List<Deal_Document__c> needAppraisals = new List<Deal_Document__c>();

    for (Integer i = 0; i < newList.size(); i++) {
      if (newList[i].Reviewed__c != oldList[i].Reviewed__c) {
        if (newList[i].Reviewed__c) {
          if (newList[i].Document_Loaded__c) {
            newList[i].Reviewed_On__c = system.now();
            newList[i].Reviewed_By__c = UserInfo.getUserId();
          } else {
            newList[i].Reviewed_On__c = null;
            newList[i].Reviewed_By__c = null;
            newList[i].Reviewed__c = false;
          }
        } else if (!newList[i].Reviewed__c) {
          newList[i].Reviewed_By__c = null;
          newList[i].Reviewed_On__c = null;
        }
      }

      // if (
      //   newList[i].Document_Type__c != oldList[i].Document_Type__c ||
      //   newList[i].Type__c != oldList[i].Type__c ||
      //   newList[i].Section__c != oldList[i].Section__c
      // ) {
      //   newList[i].Added_By__c = UserInfo.getUserId();
      //   newList[i].Added_On__c = system.now();
      // }

      if (newList[i].Recorded_Date__c != oldList[i].Recorded_Date__c) {
        if (newList[i].Recorded_Date__c != null) {
          newList[i].Recorded__c = true;
        } else {
          newList[i].Recorded__c = false;
        }
      }

      if (
        newList[i].Attachment_Id__c != oldList[i].Attachment_Id__c &&
        newList[i].Attachment_Id__c != null
      ) {
        newList[i].Added_By__c = UserInfo.getUserId();
        docMap.put(newList[i].Attachment_Id__c, newList[i]);
      }

      system.debug(newList[i].Folder_String__c);
      if (
        (newList[i].Folder_String__c != oldList[i].Folder_String__c ||
        newList[i].Document_Type__c != oldList[i].Document_Type__c)
      ) {
        String fs = newList[i].Folder_String__c;
        //fs = fs.subStringBeforeLast(';');
        if (fs.contains(';')) {
          List<String> fsArr = fs.split(';');
          if (fsArr[0] == fsArr[1]) {
            fs = fsArr[0];
          }
        }

        if (newList[i].Deal_RecordType__C == 'Term_Loan') {
          if (!folderMap.containsKey(fs)) {
            folderMap.put(fs, new List<Deal_Document__c>());
          }

          folderMap.get(fs).add(newList[i]);
        } else if (
          newList[i].Deal_RecordType__c.contains('Bridge') ||
          newList[i].Deal_recordType__c == 'LOC_Loan'
        ) {
          if (!folderMapBridge.containsKey(fs)) {
            folderMapBridge.put(fs, new List<Deal_Document__c>());
          }

          folderMapBridge.get(fs).add(newList[i]);
        }
      }
    }
    system.debug(folderMap);
    // system.debug(folderMapBridge);
    for (Document_Structure__mdt fs : [
      SELECT
        Id,
        Folder_Structure_String__c,
        Vendor_Type_Access__c,
        Vendor_Access__c,
        Confidential__c,
        Private__c,
        Public__c,
        Document_Type__c,
        Borrower_Access__c,
        RecordType__c,
        sObject__c
      FROM Document_Structure__mdt
      WHERE
        RecordType__c = 'Term_Loan'
        AND Folder_Structure_String__c IN :folderMap.keySet()
    ]) {
      for (
        Deal_Document__c doc : folderMap.get(fs.Folder_Structure_String__c)
      ) {
        if (doc.Document_Type__c == fs.Document_Type__c) {
          doc.Borrower_Access__c = fs.Borrower_Access__c;
          doc.Vendor_Type_Access__c = fs.Vendor_Type_Access__c;
          doc.Vendor_Access__c = fs.Vendor_Access__c;
          doc.Public__c = fs.Public__c;
          doc.Confidential__c = fs.Confidential__c;
          doc.Private__c = fs.Private__c;
        }
      }
    }

    for (Document_Structure__mdt fs : [
      SELECT
        Id,
        Folder_Structure_String__c,
        Vendor_Type_Access__c,
        Vendor_Access__c,
        Confidential__c,
        Private__c,
        Public__c,
        Document_Type__c,
        Borrower_Access__c,
        RecordType__c,
        sObject__c
      FROM Document_Structure__mdt
      WHERE
        RecordType__c = 'LOC_Loan'
        AND Folder_Structure_String__c IN :folderMapBridge.keySet()
    ]) {
      //system.debug('do we get here?');
      //system.debug(fs);
      //system.debug(folderMapBridge.get(fs.Folder_Structure_String__c));

      for (
        Deal_Document__c doc : folderMapBridge.get(
          fs.Folder_Structure_String__c
        )
      ) {
        system.debug(doc.Document_Type__c);
        system.debug(fs.Document_Type__c);
        if (doc.Document_Type__c == fs.Document_Type__c) {
          system.debug(fs);
          doc.Borrower_Access__c = fs.Borrower_Access__c;
          doc.Vendor_Type_Access__c = fs.Vendor_Type_Access__c;
          doc.Vendor_Access__c = fs.Vendor_Access__c;
          doc.Public__c = fs.Public__c;
          doc.Confidential__c = fs.Confidential__c;
          doc.Private__c = fs.Private__c;
        }
      }
    }

    for (ContentVersion cv : [
      SELECT Id, Title, ContentDocumentId, FileExtension
      FROM ContentVersion
      WHERE ContentDocumentId IN :docMap.keySet()
    ]) {
      docMap.get(cv.ContentDocumentId).File_Name__c = cv.title;
      docMap.get(cv.ContentDocumentId).ContentVersion_Id__c = cv.Id;

      if (
        cv.FileExtension == 'xml' &&
        docMap.get(cv.ContentDocumentId).Document_Type__c == 'Valuations'
      ) {
        needAppraisals.add(docMap.get(cv.ContentDocumentId));
      }
    }

    //for ( Integer i=0;i<newList.size();i++ ){
    //    if(newList[i].ContentVersion_Id__c != )
    //}

    if (needAppraisals.size() > 0) {
      system.enqueueJob(new AppraisalParser(needAppraisals));
    }
  }

  /**
   * @name afterUpdate
   * @description
   * @param
   **/
  public static void afterUpdate(
    List<Deal_Document__c> newList,
    List<Deal_Document__c> oldList
  ) {
    Set<Id> updateAppraisals = new Set<Id>();

    Map<Id,Deal_Document__c> updateFileNamesMap = new Map<Id,Deal_Document__c>();//CIP 2152. 1/25/2022. Raj Sirivolu.

    for (Integer i = 0; i < newList.size(); i++) {
      if (
        newList[i].Property__c != oldList[i].Property__c &&
        newList[i].Property__c != null
      ) {
        updateAppraisals.add(newList[i].Id);
      }

        //CIP 2152. 1/25/2022. Raj Sirivolu.Begin
	    if ((newList[i].File_Name__c  != oldList[i].File_Name__c ) && !String.isblank(newList[i].File_Name__c) 
      && !String.isblank(oldList[i].File_Name__c))
      {
          updateFileNamesMap.put(newList[i].Attachment_Id__c ,newList[i]); 
      }
        //CIP 2152. 1/25/2022. Raj Sirivolu.End  

      if (
        newList[i].Document_Type__c == 'Term Sheet' &&
        newList[i].Executive_Approval_Date__c != null &&
        newList[i].Executive_Approval_Date__c !=
        oldList[i].Executive_Approval_Date__c
      ) {
        AlchemyAPI.sendTermSheet(newList[i].Deal__c, newList[i].Id);
      }
    }

    if (updateAppraisals.size() > 0) {
      List<Appraisal__c> appraisalsToUpdate = new List<Appraisal__c>();
      for (Appraisal__c appraisal : [
        SELECT Id, Property__c, Deal_Document__c, Deal_Document__r.Property__c
        FROM Appraisal__c
        WHERE Deal_Document__c IN :updateAppraisals
      ]) {
        appraisal.property__c = appraisal.deal_Document__r.Property__c;
        appraisalsToUpdate.add(appraisal);
      }

      if (appraisalsToUpdate.size() > 0) {
        update appraisalsToUpdate;
      }
    }

       //CIP 2152. 1/25/2022. Raj Sirivolu.Begin
   List<ContentDocument > contentdocList = new List<ContentDocument >();

   for (ContentDocument contentdoc : [SELECT Id,Title from ContentDocument  where id in :updateFileNamesMap.keyset()])          
   {
                  contentdoc.Title = updateFileNamesMap.get(contentdoc.id).File_Name__c ;
       			  contentdocList.add(contentdoc);
   }
   
   update contentdocList;
   //CIP 2152. 1/25/2022. Raj Sirivolu.End   
  }

  /**
   * @name beforeDelete
   * @description
   * @param
   **/
  //public static void beforeDelete(List<Deal_Document__c> newList){
  //    for ( Integer i=0;i<newList.size();i++ ){

  //    }
  //}

  /**
   * @name afterDelete
   * @description
   * @param
   **/
  /*public static void afterDelete(List<Deal_Document__c> newList, List<Deal_Document__c> oldList){
        /*Set<String> boxFileIds = new Set<String>();
        for ( Integer i=0;i<newList.size();i++ ){
            if(newList[i].Box_File_Id__c != null){
                boxFileIds.add(newList[i].Box_File_Id__c);
            }
        }

        if(boxFileIds.size() > 0){
            box_Api box = box_Api.getInstance();
            for(String s : boxFileIds){
                BoxFile file = new BoxFile(box.api, 'file-id');
                file.deleteFile();
            }
        }
    }*/

  /**
   * @name afterUndelete
   * @description
   * @param
   **/
  /*public static void afterUndelete(List<Deal_Document__c> oldList){
        for ( Integer i=0;i<oldList.size();i++ ){

        }
    }*/
}