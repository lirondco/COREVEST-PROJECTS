public without sharing class BorrowerChecklistController {
  public static community_Controller.userResource userResource = new community_Controller.UserResource(
    UserInfo.getUserId()
  );
  // public static dealId =
  @AuraEnabled
  public static void saveDocInfo(Document_Information__c docInfo) {
    update docInfo;
  }

  @AuraEnabled
  public static String initScreen(String recordId) {
    Map<String, Object> resp = new Map<String, Object>();
    List<ChecklistSection> sections = new List<ChecklistSection>();

    community_Controller.UserResource user = (community_Controller.UserResource) JSON.deserialize(
      community_Controller.getUser(),
      community_Controller.UserResource.class
    );

    if (CommunityController.checkAccess(recordId)) {
      Set<String> docStrings = new Set<String>();
      String recordType = CommunityController.getRecordType(recordId);
      if (
        recordType.contains('Bridge') &&
        recordType != 'Single_Asset_Bridge_Loan'
      ) {
        recordType = 'LOC_Loan';
      } else if (recordType.contains('Term')) {
        recordType = 'Term_Loan';
      }
      String queryString = compileQueryString();
      queryString += ' WHERE ID =: recordId';
      Opportunity deal = ((List<Opportunity>) database.query(queryString))[0];

      resp.put('recordType', recordType);
      system.debug(recordType);
      Map<Id, List<Document_Structure__mdt>> docStructMap = new Map<Id, List<Document_Structure__mdt>>();
      for (Document_Structure__mdt docStruct : [
        SELECT
          Id,
          Borrower_Checklist__r.RecordType__c,
          Borrower_Checklist__r.Is_Subtab__C,
          Borrower_Checklist__c,
          Document_Type__c,
          Folder_Structure_String__c,
          Additional_Borrower_Checklist_Filtering__c,
          Required__c,
          Default_Exclude_from_Loan_Status__c,
          Borrower_Access__c,
          Vendor_Access__c,
          Vendor_Type_Access__c
        FROM Document_Structure__mdt
        WHERE
          Borrower_Checklist__c != NULL
          AND Borrower_Checklist__r.Is_Subtab__c = FALSE
        ORDER BY Sort__c DESC
      ]) {
        //
        if (
          docStruct.Borrower_Checklist__r.RecordType__c == recordType &&
          docStruct.Borrower_Checklist__r.Is_Subtab__c == false
        ) {
          if (!docStructMap.containsKey(docStruct.Borrower_Checklist__c)) {
            docStructMap.put(
              docStruct.Borrower_Checklist__c,
              new List<Document_Structure__mdt>()
            );
          }
          docStructMap.get(docStruct.Borrower_Checklist__c).add(docStruct);
        }
      }

      system.debug(docStructMap);

      for (
        Borrower_Checklist__mdt checklist : [
          SELECT Id, Label, Section_Order__c
          //   (
          //     SELECT
          //       Id,
          //       Document_Type__c,
          //       Folder_Structure_String__c,
          //       Additional_Borrower_Checklist_Filtering__c,
          //       Required__c,
          //       Default_Exclude_from_Loan_Status__c
          //     FROM Document_Structures__r
          //     ORDER BY Sort__c DESC
          //   )
          FROM Borrower_Checklist__mdt
          WHERE RecordType__c = :recordType AND Is_Subtab__c = FALSE
          ORDER BY Section_Order__c ASC
        ]
      ) {
        // system.debug(checklist.Document_Structures__r.size());
        // system.debug(
        //   docStructMap.containsKey(checklist.Id)
        //     ? docStructMap.get(checklist.Id).size()
        //     : -1
        // );

        List<Document_Structure__mdt> mapStruct = docStructMap.containsKey(
            checklist.Id
          )
          ? docStructMap.get(checklist.Id)
          : new List<Document_Structure__mdt>();

        List<Document_Structure__mdt> structs = new List<Document_Structure__mdt>();
        for (Integer i = 0; i < mapStruct.size(); i++) {
          Document_Structure__mdt docStructure = mapStruct[i];
          if (
            String.isNotBlank(
              docStructure.Additional_Borrower_Checklist_Filtering__c
            )
          ) {
            Set<String> dealTypes = opportunity_Helper.compileDealType(deal);
            Set<String> filters = new Set<String>(
              docStructure.Additional_Borrower_Checklist_Filtering__c.split(';')
            );
            // system.debug(docStructure.Document_Type__c);
            // system.debug('--dealtypes--');
            // system.debug(dealTypes);
            // system.debug('--filters--');
            // system.debug(filters);

            dealTypes.retainAll(filters);
            // system.debug(dealTypes);
            // system.debug(dealTypes.size());
            // system.debug('--------');
            if (dealTypes.size() > 0) {
              Boolean addDoc = false;

              if (user.userType == 'borrower') {
                if (docStructure.Borrower_Access__c) {
                  addDoc = true;
                }
              } else if (user.UserType == 'vendor') {
                if (
                  docStructure.Vendor_Access__c &&
                  String.isNotBlank(docStructure.Vendor_Type_Access__c)
                ) {
                  String vendorType = user.accountType;
                  String accountId = user.accountId;

                  List<String> vendorFilters = docStructure.Vendor_Type_Access__c.split(
                    ';'
                  );

                  addDoc =
                    vendorFilters.contains(accountId) ||
                    vendorFilters.contains(vendorType);
                }
              } else {
                // structs.add(mapStruct[i]);

                addDoc = true;
              }
              if (addDoc) {
                docStrings.add(
                  docStructure.Folder_Structure_String__c +
                  '|' +
                  docStructure.Document_Type__c
                );
                structs.add(mapStruct[i]);
              }
            }
          } else {
            Boolean addDoc = false;

            if (user.userType == 'borrower') {
              if (docStructure.Borrower_Access__c) {
                addDoc = true;
              }
            } else if (user.UserType == 'vendor') {
              if (
                docStructure.Vendor_Access__c &&
                String.isNotBlank(docStructure.Vendor_Type_Access__c)
              ) {
                String vendorType = user.accountType;
                String accountId = user.accountId;

                List<String> vendorFilters = docStructure.Vendor_Type_Access__c.split(
                  ';'
                );

                addDoc =
                  vendorFilters.contains(accountId) ||
                  vendorFilters.contains(vendorType);
              }
            } else {
              // structs.add(mapStruct[i]);

              addDoc = true;
            }
            if (addDoc) {
              docStrings.add(
                docStructure.Folder_Structure_String__c +
                '|' +
                docStructure.Document_Type__c
              );
              structs.add(mapStruct[i]);
            }
          }
        }

        sections.add(new ChecklistSection(checklist.Label, structs));
        sections[sections.size() - 1].recordId = recordId;
      }

      for (Deal_Document__c document : [
        SELECT
          Id,
          Attachment_Id__c,
          Is_Viewable__c,
          Is_Deleted__c,
          Document_Type__c,
          Property__c,
          Folder_String__c,
          Document_Loaded__c,
          Reviewed_On__c,
          Reviewed__c,
          Doc_String__c,
          Deal__c,
          Added_On__c,
          Comments__c,
          Confidential__c,
          Private__c
        FROM Deal_Document__c
        WHERE
          Deal__c = :recordId
          AND Document_Loaded__c = TRUE
          AND Is_Deleted__c = FALSE
          AND Doc_String__c IN :docStrings
        ORDER BY Added_On__c ASC
      ]) {
        for (ChecklistSection section : sections) {
          section.addDocument(document);
        }
      }

      Integer totalDocuments = 0;
      Integer totalDocumentsUploaded = 0;
      Integer totalDocumentsReviewed = 0;

      for (ChecklistSection section : sections) {
        section.setDocInfos();
        section.documentWrappers = section.documents.values();

        Boolean exclude = true;
        for (DocumentWrapper wrapper : section.documentWrappers) {
          if (!wrapper.excludeFromLoanStatus) {
            exclude = false;
          }
        }

        section.excludeSection = exclude;

        totalDocuments += section.getTotalDocuments();
        totalDocumentsUploaded += section.getTotalUploaded();
        totalDocumentsReviewed += section.getTotalReviewed();
      }

      System.debug(recordId + ' ' + recordType);
      List<ChecklistSection> subtabs = compileSubtabs(recordId, recordType);
      System.debug('@@@@@' + ' ' + recordType);

      resp.put('wrappers', sections);

      resp.put('subtabs', subtabs);
      resp.put('totalDocs', totalDocuments);
      resp.put('totalDocumentsUploaded', totalDocumentsUploaded);
      resp.put('totalDocumentsReviewed', totalDocumentsReviewed);
      resp.put('userId', UserInfo.getUserId());
      // resp.put('user', community_Controller.getUser());
      // for(ChecklistSection section : sections)
    }

    return JSON.serialize(resp);
  }

  public class ChecklistSection {
    String section;
    public Id recordId { get; set; }
    public Boolean excludeSection = false;
    Map<String, DocumentWrapper> documents;
    List<DocumentWrapper> documentWrappers;

    List<Document_Information__c> toInsert;

    public ChecklistSection(
      String section,
      List<DocumentWrapper> documentWrappers
    ) {
      this.section = section;
      this.documentWrappers = documentWrappers;
      this.documents = new Map<String, DocumentWrapper>();
    }

    public ChecklistSection(
      String section,
      List<Document_Structure__mdt> docStructures
    ) {
      this.section = section;
      documents = new Map<String, DocumentWrapper>();

      for (Document_Structure__mdt structure : docStructures) {
        DocumentWrapper docW = new DocumentWrapper(structure);
        String docString =
          structure.Folder_Structure_String__c +
          '|' +
          structure.Document_Type__c;
        documents.put(docString, docW);
      }
    }

    public ChecklistSection(
      String section,
      List<DocumentWrapper> documentWrappers,
      Id i
    ) {
      this.section = section;
      this.documentWrappers = documentWrappers;
      this.documents = new Map<String, DocumentWrapper>();
      this.recordId = i;
    }

    public ChecklistSection(
      String section,
      List<Document_Structure__mdt> docStructures,
      Id i
    ) {
      this.section = section;
      documents = new Map<String, DocumentWrapper>();
      this.recordId = i;

      for (Document_Structure__mdt structure : docStructures) {
        DocumentWrapper docW = new DocumentWrapper(structure, i);
        String docString =
          structure.Folder_Structure_String__c +
          '|' +
          structure.Document_Type__c;
        documents.put(docString, docW);
      }
    }

    public void setDocInfos() {
      system.debug(documents);
      for (Document_Information__c docInfo : [
        SELECT
          Id,
          Doc_String__c,
          Deal__c,
          External_Comments__c,
          Exclude_From_Loan_Status__c,
          Internal_Comments__c
        FROM Document_Information__c
        WHERE Deal__c = :this.recordId AND Property__c = NULL
      ]) {
        //system.debug(docInfo);
        //system.debug(documents.get(docInfo.Doc_String__c));

        if (documents.get(docInfo.Doc_String__c) != null) {
          documents.get(docInfo.Doc_String__c).addDocInfo(docInfo);
        }
      }

      List<Document_Information__c> infosToAdd = new List<Document_Information__c>();
      for (String docString : documents.keySet()) {
        DocumentWrapper wrapper = documents.get(docString);
        if (String.isBlank(wrapper.docInfoId)) {
          infosToAdd.add(
            new Document_Information__c(
              Deal__c = this.recordId,
              Doc_String__c = docString,
              Required_for_Clear_to_Close__c = wrapper.structure.Required__c,
              Exclude_From_Loan_Status__c = wrapper.structure.Default_Exclude_from_Loan_Status__c
            )
          );
        }
      }

      if (infosToAdd.size() > 0) {
        insert infosToAdd;
        for (Document_Information__c docInfo : infosToAdd) {
          documents.get(docInfo.Doc_String__c).addDocInfo(docInfo);
        }
      }

      //for()
    }

    public void setDocInfosProp(
      List<Document_Information__c> docInfos,
      String dealId
    ) {
      for (Document_Information__c docInfo : docInfos) {
        if (documents.get(docInfo.Doc_String__c) != null) {
          documents.get(docInfo.Doc_String__c).addDocInfo(docInfo);
        }
      }

      List<Document_Information__c> infosToAdd = new List<Document_Information__c>();
      for (String docString : documents.keySet()) {
        DocumentWrapper wrapper = documents.get(docString);
        if (String.isBlank(wrapper.docInfoId)) {
          infosToAdd.add(
            new Document_Information__c(
              Deal__c = dealId,
              Property__c = this.recordId,
              Doc_String__c = docString
            )
          );
        }
      }

      this.toInsert = infosToAdd;
    }

    public void setDocInfosProp() {
      if (this.toInsert.size() > 0) {
        //insert this.toInsert;
        for (Document_Information__c docInfo : this.toInsert) {
          documents.get(docInfo.Doc_String__c).addDocInfo(docInfo);
        }
      }
    }

    public void addDocument(Deal_Document__c doc) {
      if (documents.containsKey(doc.Doc_String__c)) {
        documents.get(doc.Doc_String__c).updateDocument(doc);
      }
    }

    public Boolean containsDocString(String docString) {
      return documents.containsKey(docString);
    }

    public Integer getTotalDocuments() {
      Integer total = 0;
      for (DocumentWrapper doc : documentWrappers) {
        if (!doc.excludeFromLoanStatus) {
          total++;
        }
      }

      return total;
    }
    public Integer getTotalReviewed() {
      Integer total = 0;
      for (DocumentWrapper doc : documentWrappers) {
        if (doc.reviewedOn != null && !doc.excludeFromLoanStatus) {
          total++;
        }
      }

      return total;
    }
    public Integer getTotalUploaded() {
      Integer total = 0;
      for (DocumentWrapper doc : documentWrappers) {
        if (doc.addedOn != null && !doc.excludeFromLoanStatus) {
          total++;
        }
      }

      return total;
    }
  }

  public class DocumentWrapper {
    Document_Structure__mdt structure;
    //Document_Information__c docInfo;
    String docInfoId;
    //Boolean includeInChecklist;
    Boolean excludeFromLoanStatus = false;
    String comments;
    String internalComments;
    DateTime addedOn;
    DateTime reviewedOn;
    String status;
    String documentType;
    String structureString;
    String propertyId;
    String documentId;
    Integer documentCount = 0;
    Boolean isConfidential = false;

    public DocumentWrapper(Document_Structure__mdt structure) {
      this.structure = structure;
      this.documentType = structure.Document_Type__c;
      this.structureString = structure.Folder_Structure_String__c;
    }

    public DocumentWrapper(Document_Structure__mdt structure, Id i) {
      this.structure = structure;
      this.documentType = structure.Document_Type__c;
      this.structureString = structure.Folder_Structure_String__c;
      this.propertyId = i;
    }

    public void updateDocument(Deal_Document__c doc) {
      this.addedOn = doc.Added_On__c;
      this.reviewedOn = doc.Reviewed_On__c;
      // if(String.isNotBlank(doc.Comments__c)){
      //     this.comments = doc.Comments__c;
      // }

      if (doc.Is_Viewable__c) {
        this.documentCount++;
        this.documentId = doc.Attachment_Id__c;
      }

      this.isConfidential = doc.Confidential__c;
    }

    public void addDocInfo(Document_Information__c docInfo) {
      this.docInfoId = docInfo.Id;
      this.comments = docInfo.External_Comments__c;
      //this.includeInChecklist = docInfo.Required_for_Borrower_Checklist__c;

      if (userResource.isInternal) {
        this.internalComments = docInfo.Internal_Comments__c;
      }
      this.excludeFromLoanStatus = docInfo.Exclude_From_Loan_Status__C;
      //this.
    }
  }

  public static String compileQueryString() {
    String qs = 'SELECT Id,';
    for (String field : fieldMap.keySet()) {
      qs += field + ', ';
    }

    qs = qs.substringBeforeLast(',');
    qs += ' FROM Opportunity';

    return qs;
  }

  public static Map<String, List<String>> CHECKLIST_FIELDS = new Map<String, List<String>>{
    'LOC_Loan' => new List<String>{},
    'LOC_Construction' => new List<String>{},
    'Term_Loan' => new List<String>{}
  };

  public static Map<String, String[]> fieldMap = new Map<String, String[]>{
    'Name' => new List<String>{ 'Name', 'text' },
    'LOC_Loan_Type__c' => new List<String>{ 'Product Type', 'text' },
    'RecordType.DeveloperName' => new List<String>{ 'Record Type', 'text' },
    'Product_Sub_Type__c' => new List<String>{ 'Product Subtype', 'text' }
  };

  public static List<ChecklistSection> compileSubtabs(
    String recordId,
    String recordType
  ) {
    Set<String> docStrings = new Set<String>();
    List<ChecklistSection> sections = new List<ChecklistSection>();

    List<Property__c> properties = [
      SELECT Id, Name
      FROM Property__c
      WHERE Deal__c = :recordId
    ];

    Set<Id> propIds = new Set<Id>();
    for (Property__c prop : properties) {
      propIds.add(prop.Id);
    }

    for (Borrower_Checklist__mdt checklist : [
      SELECT
        Id,
        Label,
        Section_Order__c,
        (
          SELECT
            Id,
            Document_Type__c,
            Additional_Borrower_Checklist_Filtering__c,
            Folder_Structure_String__c,
            Required__c,
            Default_Exclude_from_Loan_Status__c
          FROM Document_Structures__r
        )
      FROM Borrower_Checklist__mdt
      WHERE RecordType__c = :recordType AND Is_Subtab__c = TRUE
      ORDER BY Section_Order__c ASC
    ]) {
      system.debug('mdt@@@' + checklist);
      for (Property__c props : properties) {
        sections.add(
          new ChecklistSection(
            props.Name,
            checklist.Document_Structures__r,
            props.Id
          )
        );
      }
      for (
        Document_Structure__mdt docStructure : checklist.Document_Structures__r
      ) {
        docStrings.add(
          docStructure.Folder_Structure_String__c +
          '|' +
          docStructure.Document_Type__c
        );
      }
    }

    Map<Id, ChecklistSection> propertySectionmap = new Map<Id, ChecklistSection>();
    for (Deal_Document__c document : [
      SELECT
        Id,
        Document_Type__c,
        Attachment_Id__c,
        Folder_String__c,
        Property__c,
        Property__r.Name,
        Document_Loaded__c,
        Reviewed_On__c,
        Reviewed__c,
        Doc_String__c,
        Deal__c,
        Added_On__c,
        Comments__c,
        Confidential__c,
        Is_Viewable__c,
        Private__c
      FROM Deal_Document__c
      WHERE
        Deal__c = :recordId
        AND Document_Loaded__c = TRUE
        AND Is_Deleted__c = FALSE
        AND Doc_String__c IN :docStrings
      ORDER BY Added_On__c ASC
    ]) {
      for (ChecklistSection section : sections) {
        if (section.section == document.Property__r.Name) {
          section.addDocument(document);
        }
      }
    }

    Map<String, List<Document_Information__c>> docInfosMap = new Map<String, List<Document_Information__c>>();

    // Set<Id> propIds = new Set<Id>();
    for (Property__c prop : properties) {
      //propIds.add(prop.Id);
      docInfosMap.put(prop.Id, new List<Document_Information__c>());
    }

    List<Document_Information__c> toAdd = new List<Document_Information__c>();
    for (Document_Information__c docInfo : [
      SELECT
        Id,
        Doc_String__c,
        Deal__c,
        External_Comments__c,
        Exclude_From_Loan_Status__c,
        Property__c,
        Internal_Comments__c
      FROM Document_Information__c
      WHERE Property__c IN :propIds
    ]) {
      // if(docInfosMap.containsKey(docInfo.Property__c)){
      //     docInfosMap.put(docInfo.Property__c, new List<Document_Information__c>());
      // }

      docInfosMap.get(docInfo.Property__c).add(docInfo);
    }

    for (ChecklistSection section : sections) {
      section.setDocInfosProp(docInfosMap.get(section.recordId), recordId);
      section.documentWrappers = section.documents.values();

      Boolean exclude = true;
      for (DocumentWrapper wrapper : section.documentWrappers) {
        // if(wrapper !=)
        system.debug(wrapper);
        // system.debug(wrappe)
        if (wrapper != null && !wrapper.excludeFromLoanStatus) {
          exclude = false;
        }
      }

      section.excludeSection = exclude;

      toAdd.addAll(section.toInsert);
    }

    if (toAdd.size() > 0) {
      insert toAdd;

      for (ChecklistSection section : sections) {
        section.setDocInfosProp();
      }
    }

    return sections;
  }

  @AuraEnabled
  public static List<Deal_Document__c> createDealDocs(
    String recordId,
    List<String> docIds,
    String docString,
    String propertyId,
    String appraisalId
  ) {
    system.debug(docString);

    List<String> docStringSplit = docString.split('\\|');
    String docType = docStringSplit[1];
    List<String> structStringSplit = docStringSplit[0].split(';');
    String sectionType = structStringSplit[0];
    String section = structStringSplit.size() > 1 ? structStringSplit[1] : '';

    List<Deal_Document__c> dealDocs = new List<Deal_Document__c>();

    List<Document_Structure__mdt> docStructure = [
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
        Required__c,
        Default_Exclude_from_Loan_Status__c,
        Upload_Notification_Closer__c,
        Upload_Notification_Loan_Coordinator__c,
        Upload_Notification_Originations__c,
        Upload_Notification_Underwriter__c,
        Legal_Review__c
      FROM Document_Structure__mdt
      WHERE
        Folder_Structure_String__c = :docStringSplit[0]
        AND Document_Type__c = :docType
    ];

    Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>(
      [
        SELECT id, LatestPublishedVersion.title, latestpublishedversionid
        FROM contentdocument
        WHERE ID IN :docIds
      ]
    );

    for (String docId : docIds) {
      Deal_Document__c dealDoc = new Deal_Document__c();
      dealDoc.Document_Loaded__c = true;
      dealDoc.Added_On__c = system.now();
      dealDoc.Document_Type__c = docType;
      dealDoc.Active__c = true;
      dealDoc.Deal__c = recordId;
      dealDoc.Type__c = sectionType;
      dealDoc.Section__c = section;
      dealDoc.Property__c = propertyId;
      dealDoc.Added_By__c = UserInfo.getUserId();
      dealDoc.File_Name__c = docMap.get(docId).LatestPublishedVersion.title;
      dealDoc.ContentVersion_Id__c = docMap.get(docId).LatestPublishedVersionId;
      dealDoc.Appraisal__c = appraisalId;
      if (docStructure.size() > 0) {
        dealDoc.Public__c = docStructure[0].Public__c;
        dealDoc.Vendor_Access__c = docStructure[0].Vendor_Access__c;
        dealDoc.Borrower_Access__c = docStructure[0].Borrower_Access__c;
        dealDoc.Vendor_Type_Access__c = docStructure[0].Vendor_Type_Access__c;
        dealDoc.Confidential__c = docStructure[0].Confidential__c;
        dealDoc.Private__c = docStructure[0].Private__c;
        dealDoc.Include_for_Term_Sheet_Approval__c = docStructure[0]
          .Include_for_Term_Sheet_Approval__c;
        dealDoc.Upload_Notification_Closer__c = docStructure[0]
          .Upload_Notification_Closer__c;
        dealDoc.Upload_Notification_Loan_Coordinator__c = docStructure[0]
          .Upload_Notification_Loan_Coordinator__c;
        dealDoc.Upload_Notification_Originations__c = docStructure[0]
          .Upload_Notification_Originations__c;
        dealDoc.Upload_Notification_Underwriter__c = docStructure[0]
          .Upload_Notification_Underwriter__c;
        dealDoc.Legal_Review__c = docStructure[0]
          .Legal_Review__c;
      }

      dealDoc.Attachment_Id__c = docId;
      dealDocs.add(dealDoc);
    }

    insert dealDocs;

    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    for (Deal_Document__c doc : dealDocs) {
      ContentDocumentLink link = new ContentDocumentLink();
      link.ShareType = 'I';
      link.LinkedEntityId = doc.Id;
      link.ContentDocumentId = doc.Attachment_Id__c;
      link.Visibility = 'AllUsers';

      links.add(link);
    }

    insert links;

    return dealDocs;
  }

  @AuraEnabled
  public static string getFiles(String dealId, String docInfoId) {
    Map<String, String> resp = new Map<String, String>();

    Document_Information__c docInfo = [
      SELECT Id, Doc_String__c, Document_Type__c
      FROM Document_Information__c
      WHERE Id = :docInfoId
      LIMIT 1
    ];

    List<Deal_Document__c> docs = [
      SELECT
        id,
        Attachment_Id__c,
        File_Name__c,
        Reviewed_On__c,
        Reviewed_By__c,
        Reviewed_By__r.Name
      FROM Deal_Document__c
      WHERE
        Deal__c = :dealId
        AND doc_string__c = :docInfo.Doc_String__c
        AND Is_Viewable__c = TRUE
        AND Is_Deleted__c = FALSE
    ];

    // system.debug(docInfoId);

    return JSON.serialize(docs);
  }

  @AuraEnabled
  public static string reviewDocuments(List<String> docIds) {
    if (
      [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]
      .ContactId != null
    ) {
      return JSON.serialize(new List<Deal_Document__c>());
    }

    List<Deal_Document__c> docs = new List<Deal_Document__c>();

    for (String docId : docIds) {
      Deal_Document__c doc = new Deal_Document__c();
      doc.Id = docId;
      doc.Reviewed_On__c = system.now();
      doc.Reviewed_By__c = UserInfo.getUserId();
      doc.Reviewed__c = true;

      docs.add(doc);
    }

    if (docs.size() > 0) {
      update docs;
    }

    docs = [
      SELECT
        id,
        Attachment_Id__c,
        File_Name__c,
        Reviewed_On__c,
        Reviewed_By__c,
        Reviewed_By__r.Name
      FROM deal_document__c
      WHERE id IN :docIds
    ];

    return JSON.serialize(docs);
  }
}