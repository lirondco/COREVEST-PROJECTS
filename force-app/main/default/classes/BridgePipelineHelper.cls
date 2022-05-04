public without sharing class BridgePipelineHelper {
  private static final String TEMPLATE_NAME = 'BridgePipelineTemplate';

  private static final List<String> DEALRECTYPES = new List<String>{
    'LOC_Loan',
    'Single_Asset_Bridge_Loan',
    'Table_Funded_Bridge_Loan_Active',
    'Table_Funded_Bridge_Loan',
    'Acquired_Bridge_Loan',
    'Acquired_Bridge_Loan_Active'
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
    'projStrat' => 'string',
    'warehouseLine' => 'string',
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

  public virtual class BridgePipeLineColumns {
    public String data;
    public String type;
  }

  public virtual class BridgePipelineObject {
    public String template;
    public List<BridgePipeLineColumns> columns;
    public List<Map<String, String>> data;
  }

  @AuraEnabled
  public static String retrieveAllData() {
    try {
      BridgePipelineObject retObj = new BridgePipelineObject();
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

  private static List<BridgePipeLineColumns> generateColumns() {
    List<BridgePipeLineColumns> retColumns = new List<BridgePipeLineColumns>();

    for (String key : COLUMN_MAPPING.keySet()) {
      BridgePipeLineColumns col = new BridgePipeLineColumns();
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
        Requested_Funding_Date__c,
        Deal__c,
        Deal__r.Name,
        Deal__r.Deal_Loan_Number__c,
        Deal__r.StageName,
        Deal__r.LOC_Loan_Type__c,
        Deal__r.CloseDate,
        Deal__r.Project_Strategy__c,
        Deal__r.Warehouse_Line__c,
        Initial_Advance__c,
        Initial_Advance__r.Name,
        Initial_Advance__r.Target_Advance_Date__c,
        Initial_Advance__r.Advance_Group_Name__c
      FROM Property__c
      WHERE
        Deal__r.RecordType.DeveloperName IN :DEALRECTYPES
        AND Status__c IN :PROPSTATUSES
        AND (Initial_Advance__r.Target_Advance_Date__c = NEXT_N_DAYS:60
        OR Initial_Advance__r.Target_Advance_Date__c < TODAY
        OR Requested_Funding_Date__c = NEXT_N_DAYS:60
        OR Requested_Funding_Date__c < TODAY)
      ORDER BY
        Initial_Advance__r.Target_Advance_Date__c ASC NULLS LAST,
        Requested_Funding_Date__c ASC NULLS LAST,
        Initial_Advance__r.Advance_Group_Name__c ASC NULLS LAST,
        Name ASC
    ];

    for (Property__c p : props) {
      Id key = p.Id;
      if (p.Initial_Advance__c != null) {
        key = p.Initial_Advance__c;
        if (!parsedData.containsKey(p.Initial_Advance__c)) {
          parsedData.put(key, generateMapKey());
        }
        if (!advPropTypes.containsKey(p.Initial_Advance__c)) {
          advPropTypes.put(key, new Set<String>());
        }
        if (!advPropStates.containsKey(p.Initial_Advance__c)) {
          advPropStates.put(key, new Set<String>());
        }
        if (!refinanceCt.containsKey(p.Initial_Advance__c)) {
          refinanceCt.put(key, 0);
        }
        if (!acqCt.containsKey(p.Initial_Advance__c)) {
          acqCt.put(key, 0);
        }
      } else {
        if (!parsedData.containsKey(p.Id)) {
          parsedData.put(p.Id, generateMapKey());
        }
        if (!advPropTypes.containsKey(p.Id)) {
          advPropTypes.put(p.Id, new Set<String>());
        }
        if (!advPropStates.containsKey(p.Id)) {
          advPropStates.put(p.Id, new Set<String>());
        }
        if (!refinanceCt.containsKey(p.Id)) {
          refinanceCt.put(p.Id, 0);
        }
        if (!acqCt.containsKey(p.Id)) {
          acqCt.put(p.Id, 0);
        }
      }

      Map<String, String> rowData = parsedData.get(key);
      Set<String> propTypes = advPropTypes.get(key);
      Set<String> propStates = advPropStates.get(key);
      Integer refCt = refinanceCt.get(key);
      Integer ac = acqCt.get(key);
      Date reqFundDate = p.Initial_Advance__c != null &&
        p.Initial_Advance__r.Target_Advance_Date__c != null
        ? p.Initial_Advance__r.Target_Advance_Date__c
        : p.Requested_Funding_Date__c;
      if (reqFundDate != null) {
        rowData.put(
          'reqFundDate',
          reqFundDate.month() +
          '/' +
          reqFundDate.day() +
          '/' +
          reqFundDate.year()
        );
      }

      rowData.put(
        'advGroupOrPropName',
        p.Initial_Advance__c != null &&
          String.isNotEmpty(p.Initial_Advance__r.Advance_Group_Name__c)
          ? p.Initial_Advance__r.Advance_Group_Name__c
          : p.Name
      );

      rowData.put('dealLoanNumber', p.Deal__r.Deal_Loan_Number__c);
      rowData.put('dealName', p.Deal__r.Name);
      rowData.put('dealStage', p.Deal__r.StageName);
      rowData.put('prodType', p.Deal__r.LOC_Loan_Type__c);
      rowData.put('projStrat', p.Deal__r.Project_Strategy__c);
      rowData.put('warehouseLine', p.Deal__r.Warehouse_Line__c);

      propTypes.add(p.Property_Type__c);
      rowData.put('propType', String.join(new List<String>(propTypes), ','));
      advPropTypes.put(key, propTypes);

      rowData.put('propStatus', p.Status__c);
      rowData.put(
        'propCity',
        String.isEmpty(rowData.get('propCity')) ? p.City__c : 'Multiple'
      );

      propStates.add(p.State__c);
      rowData.put('propState', String.join(new List<String>(propStates), ','));
      advPropStates.put(key, propStates);

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
      refinanceCt.put(key, refCt);
      acqCt.put(key, ac);

      rowData.put(
        'acqPrice',
        p.Acquisition_Price__c != null
          ? String.isEmpty(rowData.get('acqPrice'))
              ? String.valueOf(p.Acquisition_Price__c)
              : String.valueOf(
                  p.Acquisition_Price__c +
                  Decimal.valueOf(rowData.get('acqPrice'))
                )
          : '0'
      );

      rowData.put(
        'initAdv',
        p.Initial_Disbursement__c != null
          ? String.isEmpty(rowData.get('initAdv'))
              ? String.valueOf(p.Initial_Disbursement__c)
              : String.valueOf(
                  p.Initial_Disbursement__c +
                  Decimal.valueOf(rowData.get('initAdv'))
                )
          : '0'
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
        p.Projected_Initial_Disbursement__c != null
          ? String.isEmpty(rowData.get('projectedInitialDisbursement'))
              ? String.valueOf(p.Projected_Initial_Disbursement__c)
              : String.valueOf(
                  p.Projected_Initial_Disbursement__c +
                  Decimal.valueOf(rowData.get('projectedInitialDisbursement'))
                )
          : '0'
      );

      parsedData.put(key, rowData);
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
