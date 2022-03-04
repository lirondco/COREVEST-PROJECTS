public class AppraisalParseBatch implements Database.Batchable<sObject> {
  public static List<String> appraisalFields = new List<String>{
    'Id',
    'Deal__c',
    'Property__c',
    'Deal_Document__c',
    'Appraisal_Replacement_Cost_Value__c',
    'No_of_Stories__c',
    'Deal_Document__r.Attachment_Id__c'
  };
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String appraisalQuery = 'SELECT ' + String.join(appraisalFields, ',');
    appraisalQuery += ' FROM Appraisal__c';
    appraisalQuery += ' WHERE Appraisal_Replacement_Cost_Value__c = null';
    appraisalQuery += ' AND Deal_Document__c != null';
    appraisalQuery += ' AND No_of_Stories__c = null';
    appraisalQuery += ' LIMIT 100';
    return Database.getQueryLocator(appraisalQuery);
  }
  public void execute(Database.BatchableContext bc, List<Appraisal__c> scope) {
    List<Property__c> properties = new List<Property__c>();
    List<Appraisal__c> appraisals = new List<Appraisal__c>();
    List<String> attachmentIds = new List<String>();

    for (Appraisal__c s : scope) {
      if (String.isNotEmpty(s.Deal_Document__r.Attachment_Id__c)) {
        attachmentIds.add(s.Deal_Document__r.Attachment_Id__c);
      }
    }

    Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>(
      [
        SELECT Id, LatestPublishedVersion.VersionData
        FROM ContentDocument
        WHERE Id = :attachmentIds
        LIMIT 200
      ]
    );
    

    for (Appraisal__c s : scope) {
      Appraisal__c app = s;
      Property__c prop = new Property__c(Id = s.Property__c);
      app.Appraisal_Replacement_Cost_Value__c = 0;
      prop.Appraisal_Replacement_Cost_Value__c = 0;
      app.No_of_Stories__c = 0;
      prop.No_of_Stories__c = 0;

      if (documents.containsKey(s.Deal_Document__r.Attachment_Id__c)) {
        Map<String, Decimal> parsedXML = parseXML(s, documents);
        app.Appraisal_Replacement_Cost_Value__c = parsedXML.get('costVal');
        prop.Appraisal_Replacement_Cost_Value__c = parsedXML.get('costVal');
        app.No_of_Stories__c = parsedXML.get('storiesCount');
        prop.No_of_Stories__c = parsedXML.get('storiesCount');
      }

      properties.add(prop);
      appraisals.add(app);
    }

    Database.update(properties, false);
    Database.update(appraisals, false);
  }

  public void finish(Database.BatchableContext bc) {
    // execute any post-processing operations
  }

  public static Map<String, Decimal> parseXML(
    Appraisal__c s,
    Map<Id, ContentDocument> documents
  ) {
    Map<String, Decimal> retMap = new Map<String, Decimal>{
      'costVal' => 0,
      'storiesCount' => 0
    };
    ContentDocument document = documents.get(
      s.Deal_Document__r.Attachment_Id__c
    );
    Dom.Document doc = new Dom.Document();
    doc.load(document.LatestPublishedVersion.VersionData.toString());
    DOM.XMLNode root = doc.getRootElement();

    DOM.XMLNode valuationMethodsNode = root
      .getChildElement('VALUATION_METHODS', null);
    if (valuationMethodsNode != null) {
      Dom.XMLNode costAnalysisNode = valuationMethodsNode.getChildElement(
        'COST_ANALYSIS',
        null
      );

      String newImprovementTotalCostAmount = costAnalysisNode != null
        ? costAnalysisNode.getAttribute('NewImprovementTotalCostAmount', null)
        : null;

      Decimal repValue = String.isNotBlank(newImprovementTotalCostAmount)
        ? Decimal.ValueOf(
            newImprovementTotalCostAmount.replaceAll('[^0-9.]', '')
          )
        : 0;
      retMap.put('costVal', repValue);
    }

    DOM.XMLNode property_node = root.getChildElement('PROPERTY', null);

    DOM.XMLNode structure_node_new = property_node.getChildElement(
      'STRUCTURE',
      null
    );
    DOM.XMLNode structureExtensonNode = null;
    DOM.XMLNode stExtSectionNode = null;
    DOM.XMLNode stExtSectionDataNode = null;
    DOM.XMLNode structureInformationNode = null;
    if (structure_node_new != null) {
      structureExtensonNode = structure_node_new.getChildElement(
        'STRUCTURE_EXTENSION',
        null
      );
    }

    if (structureExtensonNode != null) {
      stExtSectionNode = structureExtensonNode.getChildElement(
        'STRUCTURE_EXTENSION_SECTION',
        null
      );
    }

    if (stExtSectionNode != null) {
      stExtSectionDataNode = stExtSectionNode.getChildElement(
        'STRUCTURE_EXTENSION_SECTION_DATA',
        null
      );
    }

    if (stExtSectionDataNode != null) {
      structureInformationNode = stExtSectionDataNode.getChildElement(
        'STRUCTURE_INFORMATION',
        null
      );
    }

    if (
      structureInformationNode != null &&
      String.isNotEmpty(
        structureInformationNode.getAttribute('GSEStoriesCount', null)
      )
    ) {
      Decimal gseStories = Decimal.ValueOf(
        structureInformationNode.getAttribute('GSEStoriesCount', null)
          .replaceAll('[^0-9.]', '')
      );
      retMap.put('storiesCount', gseStories);
    }

    return retMap;
  }
}
