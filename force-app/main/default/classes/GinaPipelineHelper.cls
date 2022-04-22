public without sharing class GinaPipelineHelper {
  private static final String TEMPLATE_NAME = 'BridgePipelineTemplate';

  private static final List<String> DEALRECTYPES = new List<String>{
    'LOC_Loan',
    'Single_Asset_Bridge_Loan'
  };

  private static final List<String> PROPSTATUSES = new List<String>{
    'Due Diligence',
    'Pending',
    'Closing'
  };

  private static final Map<String, String> COLUMN_MAPPING = new Map<String, String>{
    'reqFundDate' => 'date',
    'advGroupOrPropName' => 'string',
    'dealLoanNumber' => 'string',
    'dealName' => 'string',
    'dealStage' => 'string',
    'prodType' => 'string',
    'propType' => 'string',
    'propStatus' => 'string',
    'propCity' => 'string',
    'propState' => 'string',
    'acqOrRef' => 'string',
    'acqPrice' => 'number',
    'initAdv' => 'number',
    'closeDate' => 'date',
    'fundingProb' => 'string',
    'projectedInitialDisbursement' => 'number'
  };

  public virtual class GinaPipeLineColumns {
    public String data;
    public String type;
  }

  public virtual class GinaPipelineObject {
    public String template;
    public List<GinaPipeLineColumns> columns;
    public List<Map<String, String>> data;
  }

  @AuraEnabled
  public static String retrieveAllData() {
    try {
      GinaPipelineObject retObj = new GinaPipelineObject();
      if (test.isRunningTest()) {
        retObj.template = 'LKSDJFSLDKJFS';
      } else {
        retObj.template = lightning_Controller.getTemplate(TEMPLATE_NAME);
      }
      retObj.columns = generateColumns();
      retObj.data = returnData();
      return JSON.serialize(retObj);
    } catch (Exception e) {
      System.debug(e.getMessage() + ' on line ' + e.getLineNumber());
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static List<GinaPipeLineColumns> generateColumns() {
    List<GinaPipeLineColumns> retColumns = new List<GinaPipeLineColumns>();

    for (String key : COLUMN_MAPPING.keySet()) {
      GinaPipeLineColumns col = new GinaPipeLineColumns();
      col.data = key;
      col.type = COLUMN_MAPPING.get(key);
      retColumns.add(col);
    }

    return retColumns;
  }

  private static List<Map<String, String>> returnData() {
    Map<Id, Map<String, String>> parsedData = new Map<Id, Map<String, String>>();
    Map<Id, Set<String>> advPropTypes = new Map<Id, Set<String>>();
    Map<Id, Set<String>> advPropStates = new Map<Id, Set<String>>();

    Map<Id, Integer> refinanceCt = new Map<Id, Integer>();
    Map<Id, Integer> acqCt = new Map<Id, Integer>();

    List<Property__c> props = [
      SELECT
        Id,
        Name,
        Property_Type__c,
        Status__c,
        City__c,
        State__c,
        Refinance_Acquisition__c,
        Acquisition_Price__c,
        Funding_Probability__c,
        Projected_Initial_Disbursement__c,
        Initial_Disbursement__c,
        Deal__c,
        Deal__r.Name,
        Deal__r.Deal_Loan_Number__c,
        Deal__r.StageName,
        Deal__r.LOC_Loan_Type__c,
        Deal__r.CloseDate,
        Initial_Advance__c,
        Initial_Advance__r.Name,
        Initial_Advance__r.Target_Advance_Date__c,
        Initial_Advance__r.Advance_Group_Name__c
      FROM Property__c
      WHERE
        Deal__r.RecordType.DeveloperName IN :DEALRECTYPES
        AND Status__c IN :PROPSTATUSES
        AND Initial_Advance__r.Target_Advance_Date__c = NEXT_N_DAYS:60
      ORDER BY
        Initial_Advance__r.Target_Advance_Date__c ASC,
        Initial_Advance__r.Advance_Group_Name__c ASC,
        Name ASC
    ];

    for (Property__c p : props) {
      if (!parsedData.containsKey(p.Initial_Advance__c)) {
        parsedData.put(p.Initial_Advance__c, generateMapKey());
      }
      if (!advPropTypes.containsKey(p.Initial_Advance__c)) {
        advPropTypes.put(p.Initial_Advance__c, new Set<String>());
      }
      if (!advPropStates.containsKey(p.Initial_Advance__c)) {
        advPropStates.put(p.Initial_Advance__c, new Set<String>());
      }
      if (!refinanceCt.containsKey(p.Initial_Advance__c)) {
        refinanceCt.put(p.Initial_Advance__c, 0);
      }
      if (!acqCt.containsKey(p.Initial_Advance__c)) {
        acqCt.put(p.Initial_Advance__c, 0);
      }
      Map<String, String> rowData = parsedData.get(p.Initial_Advance__c);
      Set<String> propTypes = advPropTypes.get(p.Initial_Advance__c);
      Set<String> propStates = advPropStates.get(p.Initial_Advance__c);
      Integer refCt = refinanceCt.get(p.Initial_Advance__c);
      Integer ac = acqCt.get(p.Initial_Advance__c);

      rowData.put(
        'reqFundDate',
        p.Initial_Advance__r.Target_Advance_Date__c.month() +
        '/' +
        p.Initial_Advance__r.Target_Advance_Date__c.day() +
        '/' +
        p.Initial_Advance__r.Target_Advance_Date__c.year()
      );

      rowData.put(
        'advGroupOrPropName',
        String.isNotEmpty(p.Initial_Advance__r.Advance_Group_Name__c)
          ? p.Initial_Advance__r.Advance_Group_Name__c
          : p.Name
      );

      rowData.put('dealLoanNumber', p.Deal__r.Deal_Loan_Number__c);
      rowData.put('dealName', p.Deal__r.Name);
      rowData.put('dealStage', p.Deal__r.StageName);
      rowData.put('prodType', p.Deal__r.LOC_Loan_Type__c);

      propTypes.add(p.Property_Type__c);
      rowData.put('propType', String.join(new List<String>(propTypes), ','));
      advPropTypes.put(p.Initial_Advance__c, propTypes);

      rowData.put('propStatus', p.Status__c);
      rowData.put(
        'propCity',
        String.isEmpty(rowData.get('propCity')) ? p.City__c : 'Multiple'
      );

      propStates.add(p.State__c);
      rowData.put('propState', String.join(new List<String>(propStates), ','));
      advPropStates.put(p.Initial_Advance__c, propStates);

      if (p.Refinance_Acquisition__c == 'Refinance') {
        refCt++;
      } else {
        ac++;
      }
      rowData.put(
        'acqOrRef',
        'Refinance(' +
        refCt +
        ') / Acquisition(' +
        ac +
        ')'
      );
      refinanceCt.put(p.Initial_Advance__c, refCt);
      acqCt.put(p.Initial_Advance__c, ac);

      rowData.put(
        'acqPrice',
        String.isEmpty(rowData.get('acqPrice'))
          ? String.valueOf(p.Acquisition_Price__c)
          : String.valueOf(
              p.Acquisition_Price__c + Decimal.valueOf(rowData.get('acqPrice'))
            )
      );
      rowData.put(
        'initAdv',
        String.isEmpty(rowData.get('initAdv'))
          ? String.valueOf(p.Initial_Disbursement__c)
          : String.valueOf(
              p.Initial_Disbursement__c +
              Decimal.valueOf(rowData.get('initAdv'))
            )
      );
      rowData.put(
        'closeDate',
        p.Deal__r.CloseDate.month() +
        '/' +
        p.Deal__r.CloseDate.day() +
        '/' +
        p.Deal__r.CloseDate.year()
      );
      rowData.put('fundingProb', p.Funding_Probability__c);
      rowData.put(
        'projectedInitialDisbursement',
        String.isEmpty(rowData.get('projectedInitialDisbursement'))
          ? String.valueOf(p.Projected_Initial_Disbursement__c)
          : String.valueOf(
              p.Projected_Initial_Disbursement__c +
              Decimal.valueOf(rowData.get('projectedInitialDisbursement'))
            )
      );

      parsedData.put(p.Initial_Advance__c, rowData);
    }

    return parsedData.values();
  }

  private static Map<String, String> generateMapKey() {
    Map<String, String> retMap = new Map<String, String>();
    for (String key : COLUMN_MAPPING.keySet()) {
      retMap.put(key, '');
    }
    return retMap;
  }
}
