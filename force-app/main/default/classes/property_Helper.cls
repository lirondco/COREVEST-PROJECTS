public without sharing class property_Helper {
  public static boolean isRecursive = false;

  public static boolean hasBeforeUpdateRun = false;
  public static boolean hasAfterUpdateRun = false;

  // public static Map<String, Schema.SObjectField> FIELD_MAP = Schema.SObjectType.Property__c.fields.getMap();

  public static Integer CHUNK_SIZE = 20;

  public static Map<Id, String> RECORDTYPE_MAP = compileRecordTypeMap();
  public static Map<String, RecordType> RECORDTYPE_MAP_STRING = util.compileRecordTypeMap(
    'Property__c'
  );
  public static Map<Id, String> compileRecordTypeMap() {
    Map<Id, String> recordmap = new Map<Id, String>();
    for (RecordType r : [
      SELECT Id, Name, DeveloperName
      FROM RecordType
      WHERE sobjecttype = 'Property__c'
    ]) {
      recordmap.put(r.id, r.DeveloperName);
    }
    return recordmap;
  }

  public static Map<String, RecordType> ACCOUNT_RECORD_TYPE_MAP = util.compileRecordTypeMap(
    'Account'
  );

  public static Set<String> ACTIVE_PENDING_STATUS = new Set<String>{
    'Initial Review',
    'Data Tape Received',
    'Term Sheet Issued',
    'UW Hold',
    'Approved by Committee',
    'Term Sheet Signed/Deposit Collected',
    'Underwriting',
    'Closed Won'
  };

  public static List<String> childPropertyFields = new List<String>{
    'Number_of_Units__c',
    'Acquisition_Date__c',
    'Borrower_Opinion_of_Current_Value__c',
    'Annual_Taxes__c',
    'Annual_HOA_Fee__c',
    'Refinance_Acquisition__c',
    'Acquisition_Price__c',
    'Annual_Insurance__c',
    'Square_Feet__c',
    'Monthly_Rent__c',
    'Security_Deposit__c',
    'Verified_Rent__c',
    'Status__c',
    'Interior_Access_POC__c',
    'Interior_Access_POC_Email__c',
    'Interior_Access_POC_Phone__c',
    'Property_Type__c',
    'Property_Name__c',
    'ZipCode__c'
  };

  public static List<String> smartyStreetFields = new List<String>{
    'Name',
    'City__c',
    'State__c',
    'ZipCode__c'
  };

  public static List<String> propertyAdvanceUpdateFields = new List<String>{
    'Acquisition_Price__c',
    'BPO_Appraisal_Value__c',
    'Rehab_Budget__c',
    'After_Repair_Value__c',
    'Approved_Completed_Rehab_Costs__c',
    'Appraisal_Due_Date__c',
    'BPO_Appraisal_Fee__c',
    'Doc_Prep_Fee__c',
    'BlackSquare_Fee__c',
    'Inspection_Fee_SUY__c',
    'Override_Initial_Disbursement__c',
    'Override_Reno_Advance_Amount__c',
    'Advance_Fee_Override__c',
    'Reno_Advance_Amount__c',
    'Title_Company__c'
  };

  @AuraEnabled(cacheable=true)
  public static List<Property__c> getProperties() {
    return [
      SELECT Name, City__c, County__c, State__c, ZipCode__c
      FROM Property__c
      LIMIT 5
    ];
  }

  /**
   * @name beforeInsert
   * @description
   * @param
   **/
  public static void beforeInsert(List<Property__c> newList) {
    Map<String, List<Property__c>> titleMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> escrowMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> insuranceMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> msaMap = new Map<String, List<Property__c>>();

    Map<Id, List<Property__c>> mapForYardiIds = new Map<Id, List<Property__c>>();
    Map<Id, List<Property__c>> dealMap = new Map<Id, List<Property__c>>();

    for (Property__c p : newList) {
      p.Name = standardizePropertyName(p.Name);
      if (p.Property_Name__c != null) {
        p.Property_Name__c = standardizePropertyName(p.Property_Name__c);
      }

      if (p.State__c != null) {
        p.State__c = standardizePropertyState(p.State__c);
      }

      if (p.Currently_Leased__c != null) {
        p.Currently_Leased__c = standardizeYesNoData(p.Currently_Leased__c);
      }

      if (p.Lease_Ready__c != null) {
        p.Lease_Ready__c = standardizeYesNoData(p.Lease_Ready__c);
      }

      if (!dealMap.containsKey(p.Deal__C)) {
        dealMap.put(p.Deal__c, new List<Property__c>());
      }
      dealMap.get(p.Deal__c).add(p);

      p.Record_Type_Text__c = p.Deal_Record_Type__c;
      // p.Deal_Loan_Number__c = p.Deal__r.Deal_Loan_Number__c;

      if (
        p.Status__c == 'Closing' &&
        p.Yardi_Id__c == null &&
        p.Deal__c != null
      ) {
        Property__c prop = p;
        if (mapForYardiIds.containsKey(prop.Deal__c)) {
          mapForYardiIds.get(prop.Deal__c).add(prop);
        } else {
          mapForYardiIds.put(prop.Deal__c, new List<Property__c>{ prop });
        }
      }

      if (
        (p.RecordType_Name__c == 'Bridge_Renovation' ||
        p.RecordType_Name__c == 'Ground_Up_Construction') &&
        p.BlackSquare_Fee__c == null
      ) {
        p.BlackSquare_Fee__c = 150.00;

        if (p.Renovation_Type_formula__c == 'Renovation Advances') {
          p.Reno_Advance_Amount__c = 0;
        } else if (p.Renovation_Type_formula__c == 'Renovation Reserves') {
          if (p.Approved_Renovation_Holdback__c != null) {
            p.Reno_Advance_Amount__c =
              p.Approved_Renovation_Holdback__c -
              p.Renovation_Advance_Amount_Used__c;
          }
        }
      }

      if (String.isNotBlank(p.Title_Company_text__c)) {
        if (!titleMap.containsKey(p.Title_Company_Text__c.toLowerCase())) {
          titleMap.put(
            p.Title_Company_text__c.toLowerCase(),
            new List<Property__c>()
          );
        }
        titleMap.get(p.Title_Company_text__c.toLowerCase()).add(p);
      }

      if (String.isNotBlank(p.Escrow_Company_text__c)) {
        if (!escrowMap.containsKey(p.Escrow_Company_text__c.toLowerCase())) {
          escrowMap.put(
            p.Escrow_Company_text__c.toLowerCase(),
            new List<Property__c>()
          );
        }
        escrowMap.get(p.Escrow_Company_text__c.toLowerCase()).add(p);
      }

      if (String.isNotBlank(p.Insurance_Company_text__c)) {
        if (
          !insuranceMap.containsKey(p.Insurance_Company_text__c.toLowerCase())
        ) {
          insuranceMap.put(
            p.Insurance_Company_text__c.toLowerCase(),
            new List<Property__c>()
          );
        }
        insuranceMap.get(p.Insurance_Company_text__c.toLowerCase()).add(p);
      }

      if (String.isNotBlank(p.ZipCode__c)) {
        if (!msaMap.containsKey(p.ZipCode__c)) {
          msaMap.put(p.ZipCode__c, new List<Property__c>());
        }

        msaMap.get(p.ZipCode__c).add(p);
      }
    }

    if (titleMap.keySet().size() > 0) {
      attachVendors(titleMap, 'Title');
    }

    if (escrowMap.keySet().size() > 0) {
      attachVendors(escrowMap, 'Escrow');
    }

    if (insuranceMap.keySet().size() > 0) {
      attachVendors(insuranceMap, 'Insurance');
    }

    if (msaMap.size() > 0) {
      populateMSA(msaMap);
    }

    if (mapForYardiIds.keySet().size() > 0) {
      getYardiIds(mapForYardiIds);
    }

    if (dealMap.size() > 0) {
      //  populateYardiIds(dealMap);
      for (Opportunity deal : [
        SELECT Id, Deal_Loan_Number__c
        FROM Opportunity
        WHERE ID IN :dealMap.keySet()
      ]) {
        for (Property__c property : dealMap.get(deal.Id)) {
          property.Deal_Loan_Number__c = deal.Deal_Loan_Number__c;
        }
      }
    }
  }

  public static void getYardiIds(Map<Id, List<Property__c>> dealMap) {
    for (Opportunity deal : [
      SELECT
        Id,
        Deal_Loan_Number__c,
        (
          SELECT Id, Yardi_Id__c
          FROM Properties__r
          WHERE
            Yardi_Id__c != NULL
            AND (RecordType__c = 'Bridge'
            OR RecordType__c = 'Renovation')
          ORDER BY Yardi_Id__c DESC
          LIMIT 1
        )
      FROM Opportunity
      WHERE ID IN :dealMap.keySet()
    ]) {
      Decimal currentCount = 1;

      if (deal.Properties__r.size() > 0 && currentCount == 1) {
        Property__c currProp = deal.Properties__r[0];
        List<String> preCountList = currProp.Yardi_Id__c.split(
          string.valueOf(deal.Deal_Loan_Number__c)
        );
        if (!test.isRunningTest()) {
          currentCount = decimal.valueOf(preCountList[1]) + 1;
        } else {
          currentCount = 10;
        }
      }

      if (currentCount < 1000) {
        for (Property__c prop : dealMap.get(deal.Id)) {
          if (currentCount < 10) {
            prop.Yardi_Id__c = deal.Deal_Loan_Number__c + '00' + currentCount;
          } else if (currentCount < 100) {
            prop.Yardi_Id__c = deal.Deal_Loan_Number__c + '0' + currentCount;
          } else {
            prop.Yardi_Id__c = deal.Deal_Loan_Number__c + currentCount;
          }
          currentCount++;
        }
      }
    }
  }

  // public static void populateYardiIds(Map<Id, List<Property__c>> dealMap) {
  //   for (Opportunity deal : [
  //     SELECT
  //       Id,
  //       Deal_Loan_Number__c,
  //       (
  //         SELECT Id, Yardi_Id__c, Count__c
  //         FROM Properties__r
  //         WHERE Count__c != NULL
  //         ORDER BY Count__C DESC
  //         LIMIT 1
  //       )
  //     FROM Opportunity
  //     WHERE ID IN :dealMap.keySet()
  //   ]) {
  //     Decimal startingCount = 1;
  //     if (deal.Properties__r.size() > 0) {
  //       startingCount = deal.Properties__r[0].Count__c + 1;
  //     }

  //     for (Property__c property : dealMap.get(deal.Id)) {
  //       property.Count__c = startingCount;
  //       startingCount++;

  //       if (property.Count__c < 10) {
  //         property.Yardi_Id__c =
  //           deal.Deal_Loan_Number__c +
  //           '00' +
  //           property.Count__c;
  //       } else if (property.Count__c < 100) {
  //         property.Yardi_Id__c =
  //           deal.Deal_Loan_Number__c +
  //           '0' +
  //           property.Count__c;
  //       } else {
  //         property.Yardi_Id__c = deal.Deal_Loan_Number__c + property.Count__c;
  //       }

  //       property.Yardi_Id__c = deal.Deal_Loan_Number__c + '000';
  //     }
  //   }
  // }

  public static String standardizePropertyName(String propertyName) {
    Map<String, String> mapping = new Map<String, String>{
      'Street' => 'St',
      'st' => 'St',
      'Lane' => 'Ln',
      'ln' => 'Ln',
      'Drive' => 'Dr',
      'dr' => 'Dr',
      'Circle' => 'Cir',
      'cir' => 'Cir',
      'Court' => 'Ct',
      'court' => 'Ct',
      'Ave' => 'Ave',
      'Avenue' => 'Ave',
      'Boulevard' => 'Blvd',
      'blvd' => 'Blvd',
      'ave' => 'Ave',
      'avenue' => 'Ave',
      'Place' => 'Pl',
      'pl' => 'Pl',
      'Road' => 'Rd',
      'rd' => 'Rd',
      'Terrace' => 'Terr',
      'terr' => 'Terr'
    };

    propertyName = propertyName.replaceAll('\\.', '');

    for (String val : mapping.keySet()) {
      propertyName = propertyName.replaceAll(
        '\\b' +
        val +
        '\\b',
        mapping.get(val)
      );
    }

    return propertyName;
  }

  public static String standardizePropertyState(String propertyState) {
    Map<String, String> mapping = new Map<String, String>{
      'alabama' => 'AL',
      'alaska' => 'AK',
      'arizona' => 'AZ',
      'arkansas' => 'AR',
      'california' => 'CA',
      'colorado' => 'CO',
      'connecticut' => 'CT',
      'delaware' => 'DE',
      'florida' => 'FL',
      'georgia' => 'GA',
      'hawaii' => 'HI',
      'idaho' => 'ID',
      'illinois' => 'IL',
      'indiana' => 'IN',
      'iowa' => 'IO',
      'kansas' => 'KA',
      'kentucky' => 'KE',
      'louisiana' => 'LO',
      'maine' => 'ME',
      'maryland' => 'MD',
      'massachusetts' => 'MA',
      'michigan' => 'MI',
      'minnesota' => 'MN',
      'mississippi' => 'MI',
      'missouri' => 'MO',
      'montana' => 'MT',
      'nebraska' => 'NE',
      'nevada' => 'NV',
      'new Hampshire' => 'NH',
      'new Jersey' => 'NJ',
      'new Mexico' => 'NM',
      'new York' => 'NY',
      'north Carolina' => 'NC',
      'north Dakota' => 'ND',
      'ohio' => 'OH',
      'oklahoma' => 'OK',
      'oregon' => 'OR',
      'pennsylvania' => 'PA',
      'rhode Island' => 'RI',
      'south Carolina' => 'SC',
      'south Dakota' => 'SD',
      'tennessee' => 'TN',
      'texas' => 'TX',
      'utah' => 'UT',
      'vermont' => 'VT',
      'virginia' => 'VA',
      'washington' => 'WA',
      'west Virginia' => 'WV',
      'wisconsin' => 'WI',
      'wyoming' => 'WY'
    };

    propertyState = propertyState.replaceAll('\\.', '').toLowerCase();

    for (String val : mapping.keySet()) {
      propertyState = propertyState.replaceAll(
        '\\b' +
        val +
        '\\b',
        mapping.get(val)
      );
    }

    return propertyState;
  }

  public static String standardizeYesNoData(String yesNoData) {
    Map<String, String> mapping = new Map<String, String>{
      'y' => 'Y',
      'yes' => 'Y',
      'n' => 'N',
      'no' => 'N'
    };

    yesNoData = yesNoData.replaceAll('\\.', '');

    for (String val : mapping.keySet()) {
      yesNoData = yesNoData.replaceAll(val, mapping.get(val));
    }

    return yesNoData;
  }

  public static void populateMSA(Map<String, List<Property__c>> msaMap) {
    for (MSA__c msa : [
      SELECT Id, Zip_Code__c, County__c, MSA_Name__c
      FROM MSA__c
      WHERE Zip_Code__c IN :msaMap.keySet()
    ]) {
      for (Property__c property : msaMap.get(msa.Zip_Code__c)) {
        property.MSA__c = msa.MSA_Name__c;
        property.MSA_Lookup__c = msa.Id;
        property.County__c = msa.County__c;
      }
    }
  }

  public static Map<Id, Opportunity> sumStates(Map<Id, Opportunity> dealMap) {
    // Map<Id, Opportunity> m = new Map<Id, Opportunity>(
    //   [
    //     SELECT
    //       Id,
    //       Distinct_States__c,
    //       Distinct_States_Full__c,
    //       Distinct_MSAs__c,
    //       (
    //         SELECT State__c, State_Full__c, MSA__c
    //         FROM Properties__r
    //         ORDER BY State__c ASC
    //       )
    //     FROM Opportunity
    //     WHERE Id IN :dealMap.keySet()
    //   ]
    // );

    Map<Id, List<Property__c>> propertyMap = new Map<Id, List<Property__c>>();
    // List<Property__c> existingProperties = new List<Property__c>();

    for (Property__c p : [
      SELECT Id, State__c, State_Full__c, MSA__c, County__c, Deal__c
      FROM Property__c
      WHERE
        Status__c IN ('Active', 'Paid Off')
        AND Is_Sub_Unit__c = FALSE
        AND Deal__c IN :dealMap.keySet()
    ]) {
      if (!propertyMap.containsKey(p.Deal__c)) {
        propertyMap.put(p.Deal__c, new List<Property__c>());
      }

      propertyMap.get(p.Deal__c).add(p);
    }

    // for(Opportunity o : [SELECT Id, Distinct_States__c, Distinct_States_Full__c, (SELECT State__c, State_Full__c FROM Properties__r ORDER BY State__c ASC)
    //                         FROM Opportunity
    //                         WHERE Id
    //                         IN : dealMap.keySet()]){
    //     Opportunity opp = dealMap.get(o.Id);
    //     opp.Distinct_States__c = ;
    //     opp.Distinct_States_Full__c
    // }

    for (Id oppId : dealMap.keySet()) {
      Opportunity o = dealMap.get(oppId);
      Set<String> statesSet = new Set<String>();
      List<String> statesList = new List<String>();
      Set<String> statesfullSet = new Set<String>();
      List<String> statesfullList = new List<String>();
      Set<String> msaSet = new Set<String>();
      List<String> msaList = new List<String>();
      Set<String> countySet = new Set<String>();
      List<String> countyList = new List<String>();

      if (propertyMap.containsKey(oppId)) {
        // system.debug(o)
        for (Property__c p : propertyMap.get(oppId)) {
          system.debug('===propertyMap :: p ==' + p);
          if (String.isNotBlank(p.State__c)) {
            system.debug('p.State__c==' + p.State__c);
            statesSet.add(p.State__c);
          }

          if (String.isNotBlank(p.State_Full__c)) {
            statesfullSet.add(p.State_Full__c);
          }

          if (String.isNotBlank(p.MSA__c)) {
            msaSet.add(p.MSA__c);
          }

          countySet.add(p.County__c);
          system.debug('==countySet==' + countySet);

          // if (String.isNotBlank(p.County__c)) {
          //   countySet.add(p.County__c);
          // }
        }
        statesList.addAll(statesSet);
        statesfullList.addAll(statesfullSet);
        msaList.addAll(msaSet);
        countyList.addAll(countySet);
        system.debug('===countyList==' + countyList);

        String statesStr = String.join(statesList, ', ');
        system.debug('statesStr===' + statesStr);
        if (statesList.size() > 1) {
          statesStr =
            StatesStr.substringBeforeLast(',') +
            ' and ' +
            StatesStr.substringAfterLast(',');
        }

        String statesStrFull = String.join(statesfullList, ', ');
        if (statesfullList.size() > 1) {
          statesStrFull =
            StatesStrFull.substringBeforeLast(',') +
            ' and ' +
            StatesStrFull.substringAfterLast(',');
        }

        String msaStr = String.join(msaList, '; ');
        if (msaList.size() > 1) {
          msaStr =
            MSAStr.substringBeforeLast(';') +
            ' and ' +
            MSAStr.substringAfterLast(';');
        }

        String countyStr = String.join(countyList, ';');
        system.debug('countyStr final ===' + countyStr);
        o.Distinct_States__c = statesStr;
        o.Distinct_States_Full__c = statesStrFull;
        o.Distinct_MSAs__c = msaStr;
        o.Distinct_Counties__c = countyStr;
        system.debug('====o.Distinct_Counties__c==' + o.Distinct_Counties__c);
        o.Apex_Context__c = true;
      }
    }

    // for (Opportunity o : m.values()) {
    //   dealMap.get(o.Id).Distinct_States__c = o.Distinct_States__c;
    //   dealMap.get(o.Id).Distinct_States_Full__c = o.Distinct_States_Full__c;
    //   dealMap.get(o.Id).Distinct_MSAs__c = o.Distinct_MSAs__c;
    //   dealMap.get(o.Id).Apex_Context__c = true;
    // }

    return dealMap;

    //update m.values();
  }

  // public static void sumStatesfull(Set<Id> parentIds){
  //     Map<Id,Opportunity> m = new Map<Id,Opportunity>([
  //         SELECT Distinct_States_Full__c, (SELECT State_Full__c FROM Properties__r)
  //         FROM Opportunity
  //         WHERE Id
  //         IN :parentIds
  //     ]);

  //     for (Id oppId : m.keySet()){
  //         Opportunity o = m.get(oppId);
  //         Set<String> statesfullSet = new Set<String>();
  //         List<String> statesfullList = new List<String>();
  //         if (o.Properties__r != null && o.Properties__r.size() > 0){
  //             for (Property__c p : o.Properties__r){
  //                 if (String.isNotBlank(p.State_Full__c)){
  //                     statesfullSet.add(p.State_Full__c);
  //                 }
  //             }
  //             statesfullList.addAll(statesfullSet);
  //             String statesfullStr = String.join(statesfullList, ', ');
  //             o.Distinct_States_Full__c = statesfullStr;
  //             o.Apex_Context__c = true;
  //         }
  //     }

  //     update m.values();
  // }

  public static void inheritRefinance(Map<Id, String> refinanceBubble) {
    List<Property__c> parents = [
      SELECT Refinance_Acquisition__c
      FROM Property__c
      WHERE Id IN :refinanceBubble.keySet()
    ];

    for (Property__c p : parents) {
      p.Refinance_Acquisition__c = refinanceBubble.get(p.Id);
    }

    update parents;
  }

  /**
   * @name afterInsert
   * @description
   * @param
   **/
  public static void afterInsert(List<Property__c> newList) {
    Set<Id> opIds = new Set<Id>();
    Set<Id> termIds = new Set<Id>();
    Set<Id> parentIds = new Set<Id>();
    Map<Id, String> refinanceBubble = new Map<Id, String>();
    Set<Id> parentProp = new Set<Id>();

    Set<Id> propertyIds = new Set<Id>();
    for (Integer i = 0; i < newList.size(); i++) {
      parentIds.add(newList[i].Deal__c);
      propertyIds.add(newList[i].Id);
      if (
        RECORDTYPE_MAP.get(newList[i].RecordTypeId) ==
        'Ground_Up_Construction' ||
        RECORDTYPE_MAP.get(newList[i].RecordTypeId).contains('Bridge')
      ) {
        opIds.add(newList[i].Deal__c);
      }

      if (newList[i].Parent_Property__c != null) {
        parentProp.add(newList[i].Parent_Property__c);
      }

      if (
        RECORDTYPE_MAP.get(newList[i].RecordTypeId) == 'Term_Loan' &&
        newList[i].Is_Parent__C == false
      ) {
        termIds.add(newList[i].Deal__c);
      }

      if (
        newList[i].Parent_Property__c != null &&
        newList[i].Refinance_Acquisition__c != null
      ) {
        if (!refinanceBubble.containsKey(newList[i].Parent_Property__c)) {
          refinanceBubble.put(
            newList[i].Parent_Property__c,
            newList[i].Refinance_Acquisition__c
          );
        }
      }
    }

    if (refinanceBubble.size() > 0) {
      inheritRefinance(refinanceBubble);
    }

    if (parentIds.size() > 0) {
      Map<Id, Opportunity> dealMap = new Map<Id, Opportunity>(
        [
          SELECT
            Id,
            Distinct_States__c,
            Distinct_States_Full__c,
            Distinct_Property_Types__c,
            Distinct_MSAs__c,
            Distinct_Counties__c,
            Sum_of_Rehab_Cost__c,
            Sum_of_Borrower_Estimated_Value__c,
            Annual_HOA__c,
            Average_Acquisition_Date_By_Property__c,
            Total_Units__c,
            Total_Properties__c,
            Apex_Context__c,
            Refinance_Property_Count__c,
            Acquisition_Property_Count__c
          FROM Opportunity
          WHERE Id IN :parentIds
        ]
      );

      dealMap = sumStates(dealMap);
      dealMap = avgDate(dealMap);
      dealMap = sumRehab(dealMap);
      dealMap = setLoanPurpose(dealMap);

      List<String> singleList = new List<String>{
        'Condo',
        'Other',
        'SFR',
        'Townhome'
        //, 'Parent'
      };
      List<String> multiList = new List<String>{
        '2-4 Unit',
        'Multifamily',
        'Duplex',
        'Triplex',
        'Fourplex',
        '5+ Units',
        'Mixed Use'
      };

      Map<Id, String> propTypeCounts = findPropertyType(
        singleList,
        multiList,
        dealMap.keySet()
      );

      for (String oId : dealMap.keySet()) {
        dealMap.get(oId).Distinct_Property_Types__c = '';
        if (propTypeCounts.containsKey(oId)) {
          dealMap.get(oId).Distinct_Property_Types__c = propTypeCounts.get(oId)
            .subStringBeforeLast('; ');
        }
      }
      system.debug('dealMap.values()===' + dealMap.values());
      update dealMap.values();
    }

    if (opIds.size() > 0) {
      rollupOpportunities(opIds);
      bridgeRollupOpportunities(opIds);
    }

    if (termIds.size() > 0) {
      calculateStatePercentagesFuture(termIds);
    }

    if (parentIds.size() > 0) {
      rollupParents(parentProp);
    }

    if (propertyIds.size() > 0) {
      System.enqueueJob(new SmartyStreetsQueueable(new List<Id>(propertyIds)));
    }
    //CIP-2191-RS.4/4/22.Added Quable Call to Beekin to get rental information for the property.Begin
    //  	if(newList.size() > 0)
    //    {
    //       ID jobID = System.enqueueJob(new BeekinAPIBatch(newList));
    //  }
    //CIP-2191-RS.4/4/22.Added Call to Beekin to get rental information for the property.End.
  }

  public static Map<Id, Opportunity> avgDate(Map<Id, Opportunity> oppMap) {
    List<Property__c> propList = [
      SELECT Acquisition_Date__c, Deal__c
      FROM Property__c
      WHERE
        Status__c = 'Active'
        AND Parent_Property__c = NULL
        AND Acquisition_Date__c != NULL
        AND Refinance_Acquisition__c = 'Refinance'
        AND Deal__c IN :oppMap.keySet()
    ];

    oppMap = utilAvgDate(
      oppMap,
      propList,
      'Average_Acquisition_Date_By_Property__c'
    );
    return utilAvgDate(
      oppMap,
      propList,
      'Average_Acquisition_Date_By_Property__c'
    );
  }

  public static Map<Id, Opportunity> utilAvgDate(
    Map<Id, Opportunity> oppMap,
    List<Property__c> pList,
    String fieldModified
  ) {
    Map<Id, List<Date>> dateMap = new Map<Id, List<Date>>();
    for (Property__c p : pList) {
      if (!dateMap.containsKey(p.Deal__c)) {
        dateMap.put(p.Deal__c, new List<Date>());
      }
      dateMap.get(p.Deal__c).add(p.Acquisition_Date__c);
    }

    for (Id oId : dateMap.keySet()) {
      List<Date> averageThisList = dateMap.get(oId);

      List<Long> averageTheseNum = new List<Long>();

      for (Date d : averageThisList) {
        Datetime dt = DateTime.newInstance(d.year(), d.month(), d.day());
        averageTheseNum.add(dt.getTime());
      }
      Long total = 0;
      for (Long lo : averageTheseNum) {
        total += lo;
      }
      Long average = (total / averageTheseNum.size());

      Date dt2 = Datetime.newInstance(average).date();
      if (oppMap.containsKey(oId)) {
        oppMap.get(oId).put(fieldModified, dt2);
        oppMap.get(oId).Apex_Context__c = true;
      }
    }
    return oppMap;
  }

  public static Map<Id, Opportunity> setLoanPurpose(
    Map<Id, Opportunity> oppMap
  ) {
    Map<Id, Decimal> purchaseMap = new Map<Id, Decimal>();
    Map<Id, Decimal> refinanceMap = new Map<Id, Decimal>();

    for (AggregateResult ar : [
      SELECT count(id) cnt, deal__c parent, refinance_acquisition__c ref
      FROM property__c
      WHERE deal__c IN :oppMap.keySet()
      GROUP BY deal__c, refinance_acquisition__c
    ]) {
      Id dealId = (Id) ar.get('parent');
      String ref = (String) ar.get('ref');
      Decimal count = (Decimal) ar.get('cnt');

      if (ref == 'Refinance') {
        refinanceMap.put(dealId, count);
      } else if (ref == 'Purchase' || ref == 'Acquisition') {
        purchaseMap.put(dealId, count);
      }
    }

    for (Opportunity op : oppMap.values()) {
      if (refinanceMap.containsKey(op.Id) && purchaseMap.containsKey(op.Id)) {
        op.Loan_Purpose__c = 'Refinance/Purchase';
      } else if (refinanceMap.containsKey(op.Id)) {
        op.Loan_Purpose__c = 'Refinance';
      } else if (purchaseMap.containsKey(op.Id)) {
        op.Loan_Purpose__c = 'Purchase';
      }
    }

    return oppMap;
  }

  public static Map<Id, Opportunity> sumRehab(Map<Id, Opportunity> oppMap) {
    List<AggregateResult> arList = [
      SELECT
        SUM(Rehab_Costs__c) rehab,
        Deal__c deal,
        SUM(Borrower_Opinion_of_Current_Value__c) borrower,
        SUM(Monthly_HOA_Fee__c) monthlyHOA,
        SUM(ALA__c) ala
      FROM Property__c
      WHERE Deal__c IN :oppMap.keySet()
      GROUP BY Deal__c
    ];

    List<AggregateResult> allSingles = [
      SELECT COUNT(Id) total, Deal__c deal, Refinance_Acquisition__c ra
      FROM Property__c
      WHERE
        Parent_Property__c = NULL
        AND Deal__c IN :oppMap.keySet()
        AND Status__c = 'Active'
      GROUP BY Deal__c, Refinance_Acquisition__c
    ];

    Map<Id, Map<String, Integer>> propMap = new Map<Id, Map<String, Integer>>();
    for (AggregateResult ar : allSingles) {
      Id dealId = (Id) ar.get('deal');
      if (!propMap.containsKey(dealId)) {
        propMap.put(dealId, new Map<String, Integer>());
        propMap.get(dealId).put('Refinance', 0);
        propMap.get(dealId).put('Acquisition', 0);
        propMap.get(dealId).put('Total', 0);
      }
      if (null != ar.get('ra')) {
        Integer t =
          propMap.get(dealId).get('Total') + (Integer) ar.get('total');
        propMap.get(dealId).put('Total', t);
        propMap.get(dealId)
          .put((String) ar.get('ra'), (Integer) ar.get('total'));
      }
    }

    Map<Id, Map<String, Integer>> childMap = new Map<Id, Map<String, Integer>>();
    List<AggregateResult> allChildren = [
      SELECT COUNT(Id) total, Deal__c deal, Refinance_Acquisition__c ra
      FROM Property__c
      WHERE
        Is_Parent__c = FALSE
        AND Deal__c IN :oppMap.keySet()
        AND Status__c = 'Active'
      GROUP BY Deal__c, Refinance_Acquisition__c
    ];

    for (AggregateResult ar : allChildren) {
      Id dealId = (Id) ar.get('deal');
      if (!childMap.containsKey(dealId)) {
        childMap.put(dealId, new Map<String, Integer>());
        childMap.get(dealId).put('Refinance', 0);
        childMap.get(dealId).put('Acquisition', 0);
        childMap.get(dealId).put('Total', 0);
      }
      if (null != ar.get('ra')) {
        Integer t =
          childMap.get(dealId).get('Total') + (Integer) ar.get('total');
        childMap.get(dealId).put('Total', t);
        childMap.get(dealId)
          .put((String) ar.get('ra'), (Integer) ar.get('total'));
      }
    }

    for (Id dealId : propMap.keySet()) {
      // if (null != propMap.get(dealId).get('Total')) oppMap.get(dealId).Total_Units__c = propMap.get(dealId).get('Total');
      if (null != propMap.get(dealId).get('Total'))
        oppMap.get(dealId).Total_Properties__c = propMap.get(dealId)
          .get('Total');
      else
        oppMap.get(dealId).Total_Properties__c = 0;

      if (null != propMap.get(dealId).get('Refinance'))
        oppMap.get(dealId).Refinance_Property_Count__c = propMap.get(dealId)
          .get('Refinance');
      else
        oppMap.get(dealId).Refinance_Property_Count__c = 0;

      if (null != propMap.get(dealId).get('Acquisition'))
        oppMap.get(dealId).Acquisition_Property_Count__c = propMap.get(dealId)
          .get('Acquisition');
      else
        oppMap.get(dealId).Acquisition_Property_Count__c = 0;
    }
    for (Id dealId : childMap.keySet()) {
      if (null != childMap.get(dealId).get('Total'))
        oppMap.get(dealId).Total_Units__c = childMap.get(dealId).get('Total');
      else
        oppMap.get(dealId).Total_Units__c = 0;

      if (null != childMap.get(dealId).get('Refinance'))
        oppMap.get(dealId).Refinance_Count__c = childMap.get(dealId)
          .get('Refinance');
      else
        oppMap.get(dealId).Refinance_Count__c = 0;

      if (null != childMap.get(dealId).get('Acquisition'))
        oppMap.get(dealId).Acquisition_Count__c = childMap.get(dealId)
          .get('Acquisition');
      else
        oppMap.get(dealId).Acquisition_Count__c = 0;
    }

    for (AggregateResult ar : arList) {
      oppMap.get((Id) ar.get('deal')).Sum_of_Rehab_Cost__c = (Decimal) ar.get(
        'rehab'
      );
      oppMap.get((Id) ar.get('deal'))
        .Sum_of_Borrower_Estimated_Value__c = (Decimal) ar.get('borrower');
      oppMap.get((Id) ar.get('deal')).Annual_HOA__c = (Decimal) ar.get(
        'monthlyHOA'
      );
      oppMap.get((Id) ar.get('deal')).Total_ALAs__c = (Decimal) ar.get('ala');
    }

    return oppMap;
  }

  public static Map<Id, String> findPropertyType(
    List<String> singleTypeList,
    List<String> multiTypeList,
    Set<Id> idSet
  ) {
    Map<Id, String> m = new Map<Id, String>();

    // List<AggregateResult> multiArList = [
    //     SELECT Deal__c deal, COUNT_DISTINCT(Parent_Property__c) pp, Property_Type_Formula__c pt
    //     FROM Property__c
    //     WHERE Property_Type_Formula__c IN :multiTypeList
    //     AND Parent_Property__c != null
    //     AND Deal__c IN :idSet
    //     AND Status__c = 'Active'
    //     GROUP BY Deal__c, Property_Type_Formula__c
    // ];

    // for (AggregateResult ar: multiArList){
    //     Id oppId = (Id)ar.get('deal');
    //     if ( !m.containsKey(oppId) ){
    //         m.put(oppId, '');
    //     }
    //     String existingData = m.get(oppId);
    //     existingData += (String)ar.get('pt') + ': ' + String.valueOf( (Integer)ar.get('pp') ) + '; ';
    //     m.put(oppId, existingData);
    // }

    Map<Id, Map<String, Integer>> propCountMap = new Map<Id, Map<String, Integer>>();
    for (AggregateResult ar : [
      SELECT Deal__c deal, count_distinct(id) pp, parent_property__c
      FROM Property__c
      WHERE
        Parent_Property__c != NULL
        AND Deal__c IN :idSet
        AND Status__c = 'Active'
      GROUP BY Deal__c, Parent_Property__c
    ]) {
      Id oppId = (Id) ar.get('deal');
      if (!propCountMap.containsKey(oppId)) {
        propCountMap.put(
          oppId,
          new Map<String, Integer>{
            'Duplex' => 0,
            'Triplex' => 0,
            'Fourplex' => 0,
            '5+ Unit' => 0
          }
        );
      }

      Decimal cnt = (Decimal) ar.get('pp');
      if (cnt == 2) {
        propCountMap.get(oppId)
          .put('Duplex', propCountMap.get(oppId).get('Duplex') + 1);
      } else if (cnt == 3) {
        propCountMap.get(oppId)
          .put('Triplex', propCountMap.get(oppId).get('Triplex') + 1);
      } else if (cnt == 4) {
        propCountMap.get(oppId)
          .put('Fourplex', propCountMap.get(oppId).get('Fourplex') + 1);
      } else if (cnt >= 5) {
        propCountMap.get(oppId)
          .put('5+ Unit', propCountMap.get(oppId).get('5+ Unit') + 1);
      }
    }

    for (Id oppId : propCountMap.keySet()) {
      if (!m.containsKey(oppId)) {
        m.put(oppId, '');
      }

      String existingData = m.get(oppId);
      for (String val : propCountMap.get(oppId).keySet()) {
        if (propCountMap.get(oppId).get(val) > 0) {
          existingData +=
            val +
            ': ' +
            String.valueOf(propCountMap.get(oppId).get(val)) +
            '; ';
        }
      }

      m.put(oppId, existingData);
    }

    List<AggregateResult> singleArList = [
      SELECT COUNT(Id) cnt, Deal__c deal, Property_Type__c pt
      FROM Property__c
      WHERE
        Property_Type__c IN :singleTypeList
        AND Parent_Property__c = NULL
        AND Deal__c IN :idSet
        AND Status__c = 'Active'
      GROUP BY Deal__c, Property_Type__c
    ];

    for (AggregateResult ar : singleArList) {
      Id oppId = (Id) ar.get('deal');
      if (!m.containsKey(oppId)) {
        m.put(oppId, '');
      }
      String existingData = m.get(oppId);
      existingData +=
        (String) ar.get('pt') +
        ': ' +
        String.valueOf((Integer) ar.get('cnt')) +
        '; ';
      m.put(oppId, existingData);
    }

    return m;
  }

  /**
   * @name beforeUpdate
   * @description
   * @param
   **/
  public static void beforeUpdate(
    List<Property__c> newList,
    List<Property__c> oldList
  ) {
    Map<String, List<Property__c>> titleMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> escrowMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> insuranceMap = new Map<String, List<Property__c>>();
    Map<String, List<Property__c>> msaMap = new Map<String, List<Property__c>>();
    Map<Id, List<Property__c>> mapForYardiIds = new Map<Id, List<Property__c>>();
    for (Integer i = 0; i < newList.size(); i++) {
      //if(RECORDTYPE_MAP.get(newList[i].RecordTypeId) == 'Term_Loan' && (newList[i].Status__c != oldList[i].Status__c)){
      // if(newList[i].Status__c ){
      //     newList[i].Active_Last_Changed__c = null;
      // }else{
      //     newList[i].Active_Last_Changed__c = system.today();
      // }
      //}

      // CIP 2206 27 Apr 2022 Start

      if (newList[i].Current_UPB__c == 0 && oldList[i].Current_UPB__c != 0) {
        newList[i].UPB_Before_Payoff__c = oldList[i].Current_UPB__c;
      }

      // CIP 2206 27 Apr 2022 End

      if (
        (newList[i].Status__c == 'Closing' &&
        oldList[i].Status__c != 'Closing') &&
        newList[i].Yardi_Id__c == null &&
        newList[i].Deal__c != null
      ) {
        Property__c prop = newList[i];
        if (mapForYardiIds.containsKey(prop.Deal__c)) {
          mapForYardiIds.get(prop.Deal__c).add(prop);
        } else {
          mapForYardiIds.put(prop.Deal__c, new List<Property__c>{ prop });
        }
      }

      if (newList[i].Deal__c != oldList[i].Deal__c) {
        newList[i].Deal_Loan_Number__c = newList[i].Deal__r.Deal_Loan_Number__c;
      }

      if (newList[i].Active__c != oldList[i].Active__c) {
        newList[i].Active_Last_Changed__c = system.today();
        if (newList[i].Active__c == true) {
          newList[i].Status__c = 'Active';
        } else {
          newList[i].Status__c = 'Inactive';
        }
      }

      if (newList[i].Status__c != oldList[i].Status__c) {
        if (newList[i].Status__c == 'Active') {
          newList[i].Active__c = true;
          newList[i].Reason_For_Inactive__c = null;
          newList[i].Active_Last_Changed__c = system.today();
        } else if (newList[i].Status__c == 'Inactive') {
          newList[i].Active__c = false;
          newList[i].Active_Last_Changed__c = system.today();
        }
      }

      if (newList[i].State__c != oldList[i].State__c) {
        if (newList[i].State__c != null) {
          newList[i].State__c = standardizePropertyState(newList[i].State__c);
        }
      }

      if (
        (newList[i].Interest_Rate__c != oldList[i].Interest_Rate__c) &&
        newList[i].Interest_Rate__c != null
      ) {
        newList[i].Current_Interest_Rate__c = newList[i].Interest_Rate__c * 100;
      }

      if (
        newList[i].Approved_Renovation_Holdback__c !=
        oldList[i].Approved_Renovation_Holdback__c ||
        newList[i].Renovation_Advance_Amount_Used__c !=
        oldList[i].Renovation_Advance_Amount_Used__c ||
        newList[i].Number_of_Advances__c != oldList[i].Number_of_Advances__c
      ) {
        if (
          (newList[i].Renovation_Type_formula__c == 'Renovation Advances' &&
          newList[i].Number_of_Advances__c > 0) ||
          newList[i].Renovation_Type_formula__c == 'Renovation Reserves'
        ) {
          if (newList[i].Approved_Renovation_Holdback__c != null) {
            newList[i].Reno_Advance_Amount__c =
              newList[i].Approved_Renovation_Holdback__c -
              newList[i].Renovation_Advance_Amount_Used__c;
          }
        } else {
          newList[i].Reno_Advance_Amount__c = 0;
        }
      }

      newList[i].Record_Type_Text__c = newList[i].Deal_Record_Type__c;

      if (
        newList[i].RecordType_Name__c == 'Term_Loan' &&
        newList[i].Deal__r.IsClosed == false
      ) {
        newList[i].Origination_Date_Valuation_Date__c = newList[i]
          .BPO_Appraisal_Date__c;
        newList[i].Origination_Date_Valuation_Provider__c = newList[i]
          .BPO_Appraisal_Firm__c;
        newList[i].Origination_Date_Valuation_Type__c = newList[i]
          .Valuation_Type__c;
        newList[i].Origination_Date_Value__c = newList[i]
          .Appraised_Value_Amount__c;
      } else if (
        newList[i].RecordType_Name__c != 'Term_Loan' &&
        (newList[i].Status__c == 'Due Diligence' ||
        newList[i].Status__c == 'Pending')
      ) {
        newList[i].Origination_Date_Valuation_Date__c = newList[i]
          .BPO_Appraisal_Date__c;
        newList[i].Origination_Date_Valuation_Provider__c = newList[i]
          .BPO_Appraisal_Firm__c;
        newList[i].Origination_Date_Valuation_Type__c = newList[i]
          .Valuation_Type__c;
        newList[i].Origination_Date_Value__c = newList[i]
          .Appraised_Value_Amount__c;
      }

      if (
        RECORDTYPE_MAP.get(newList[i].RecordTypeId).contains('Ground_Up') ||
        RECORDTYPE_MAP.get(newList[i].RecordTypeId).contains('Bridge')
      ) {
        if (
          String.isNotBlank(newList[i].Title_Company_text__c) &&
          newList[i].Title_Company_text__c != oldList[i].Title_Company_text__c
        ) {
          if (
            !titleMap.containsKey(
              newList[i].Title_Company_Text__c.toLowerCase()
            )
          ) {
            titleMap.put(
              newList[i].Title_Company_text__c.toLowerCase(),
              new List<Property__c>()
            );
          }
          titleMap.get(newList[i].Title_Company_text__c.toLowerCase())
            .add(newList[i]);
        }

        if (
          String.isNotBlank(newList[i].Escrow_Company_text__c) &&
          newList[i].Escrow_Company_text__c != oldList[i].Escrow_Company_text__c
        ) {
          if (
            !escrowMap.containsKey(
              newList[i].Escrow_Company_text__c.toLowerCase()
            )
          ) {
            escrowMap.put(
              newList[i].Escrow_Company_text__c.toLowerCase(),
              new List<Property__c>()
            );
          }
          escrowMap.get(newList[i].Escrow_Company_text__c.toLowerCase())
            .add(newList[i]);
        }

        if (
          String.isNotBlank(newList[i].Insurance_Company_text__c) &&
          newList[i].Insurance_Company_text__c !=
          oldList[i].Insurance_Company_text__c
        ) {
          if (
            !insuranceMap.containsKey(
              newList[i].Insurance_Company_text__c.toLowerCase()
            )
          ) {
            insuranceMap.put(
              newList[i].Insurance_Company_text__c.toLowerCase(),
              new List<Property__c>()
            );
          }
          insuranceMap.get(newList[i].Insurance_Company_text__c.toLowerCase())
            .add(newList[i]);
        }

        if (
          oldList[i].Payoff_Received_Date__c !=
          newList[i].Payoff_Received_Date__c &&
          oldList[i].Payoff_Received_Date__c == null
        ) {
          newList[i].Status__c = 'Paid Off';
        }
      }

      if (
        String.isNotBlank(newList[i].ZipCode__c) &&
        newList[i].ZipCode__c != oldList[i].ZipCode__c
      ) {
        if (!msaMap.containsKey(newList[i].ZipCode__c)) {
          msaMap.put(newList[i].ZipCode__c, new List<Property__c>());
        }

        msaMap.get(newList[i].ZipCode__c).add(newList[i]);
      }

      if (
        oldList[i].RecordTypeId != newList[i].RecordTypeId &&
        (RECORDTYPE_MAP.get(oldList[i].RecordTypeId) == 'Bridge_Renovation' ||
        RECORDTYPE_MAP.get(oldList[i].RecordTypeId) ==
        'Ground_Up_Construction') &&
        RECORDTYPE_MAP.get(newList[i].RecordTypeId) == 'Bridge_No_Renovation'
      ) {
        // newList[i].After_Repair_Value__c = null;
        newList[i].BlackSquare_Fee__c = null;
        // newList[i].Rehab_Budget__c = null;
      }
    }

    if (mapForYardiIds.keySet().size() > 0) {
      getYardiIds(mapForYardiIds);
    }

    if (titleMap.keySet().size() > 0) {
      attachVendors(titleMap, 'Title');
    }

    if (escrowMap.keySet().size() > 0) {
      attachVendors(escrowMap, 'Escrow');
    }

    if (insuranceMap.keySet().size() > 0) {
      attachVendors(insuranceMap, 'Insurance');
    }

    if (msaMap.size() > 0) {
      populateMSA(msaMap);
    }
  }

  /**
   * @name afterUpdate
   * @description
   * @param
   **/
  public static void afterUpdate(
    List<Property__c> newList,
    List<Property__c> oldList
  ) {
    Set<Id> opIds = new Set<Id>();
    Set<Id> parentIds = new Set<Id>();
    SET<Id> bridgeOpIds = new Set<Id>();
    Set<Id> propertyAdvancePropIds = new Set<Id>();
    Set<Id> termIds = new Set<Id>();
    Set<Id> bothIds = new Set<Id>();
    Map<Id, String> refinanceBubble = new Map<Id, String>();

    Map<String, Map<Id, Property__c>> propSnapshotMap = new Map<String, Map<Id, Property__c>>{
      'Asset Paid Off' => new Map<Id, Property__c>(),
      'Asset Sold' => new Map<Id, Property__c>()
    };

    // Set<Id> smartyStreetIds = new Set<Id>();
    // Set<String> recordTypeIds = new Set<String>();

    Set<Id> sendToYardiCSV = new Set<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      bothIds.add(newList[i].Deal__c);

      if (
        RECORDTYPE_MAP.get(newList[i].RecordTypeId) ==
        'Ground_Up_Construction' ||
        RECORDTYPE_MAP.get(newList[i].RecordTypeId).contains('Bridge')
      ) {
        bridgeOpIds.add(newList[i].Deal__c);
        if (newList[i].Deal__c != oldList[i].Deal__c) {
          bridgeOpIds.add(newList[i].Deal__c);
          bridgeOpIds.add(oldList[i].Deal__c);
        }
      }

      if (
        ((newList[i].Status__c != oldList[i].Status__c &&
        newList[i].Status__c == 'Closing' &&
        newList[i].Title_Company__c != null) ||
        (newList[i].Title_Company__c != oldList[i].Title_Company__c &&
        newList[i].Title_Company__c != null &&
        newList[i].Status__c == 'Closing')) && newList[i].Yardi_Id__c != null
      ) {
        sendToYardiCSV.add(newList[i].Id);
      }

      if (
        newList[i].Status__c == 'Paid Off' &&
        newList[i].Status__c != oldList[i].Status__c
      ) {
        Map<Id, Property__c> propMap = propSnapshotMap.get('Asset Paid Off');
        propMap.put(newList[i].Id, newList[i]);
        propSnapshotMap.put('Asset Paid Off', propMap);
      }

      if (oldList[i].REO_Date__c == null && newList[i].REO_Date__c != null) {
        Map<Id, Property__c> propMap = propSnapshotMap.get('Asset Sold');
        propMap.put(newList[i].Id, newList[i]);
        propSnapshotMap.put('Asset Sold', propMap);
      }

      // for (String s : smartyStreetFields) {
      //   if (newList[i].get(s) != oldList[i].get(s)) {
      //     smartyStreetIds.add(newList[i].Id);
      //   }
      // }

      if (newList[i].Parent_Property__c != null) {
        for (String s : childPropertyFields) {
          // if (newList[i].get(s) != oldList[i].get(s)) {
          parentIds.add(newList[i].Parent_Property__c);
          // }
        }
      }

      if (RECORDTYPE_MAP.get(newList[i].RecordTypeId) != 'Term_Loan') {
        for (String s : propertyAdvanceUpdateFields) {
          if (newList[i].get(s) != oldList[i].get(s)) {
            propertyAdvancePropIds.add(newList[i].Id);
          }
        }
      }

      if (
        RECORDTYPE_MAP.get(newList[i].RecordTypeId) == 'Term_Loan' &&
        newList[i].Is_Parent__C == false
      ) {
        termIds.add(newList[i].Deal__c);
      }

      // if (newList[i].State__c != null
      //     && (newList[i].State__c != oldList[i].State__c
      //         || newList[i].Deal__c != oldList[i].Deal__c
      //         || newList[i].Refinance_Acquisition__c != oldList[i].Refinance_Acquisition__c
      //        )
      //    ){
      //        bothIds.add(newList[i].Deal__c);
      //    }

      if (
        newList[i].Parent_Property__c != null &&
        newList[i].Refinance_Acquisition__c != null &&
        (newList[i].Parent_Property__c != oldList[i].Parent_Property__c ||
        newList[i].Refinance_Acquisition__c !=
        oldList[i].Refinance_Acquisition__c) &&
        !refinanceBubble.containsKey(newList[i].Parent_Property__c)
      ) {
        refinanceBubble.put(
          newList[i].Parent_Property__c,
          newList[i].Refinance_Acquisition__c
        );
      }
    }

    if (
      propSnapshotMap.get('Asset Paid Off').size() > 0 ||
      propSnapshotMap.get('Asset Sold').size() > 0
    ) {
      PropertySnapshotHelper.createPropertySnapshot(propSnapshotMap);
    }

    //system.debug(recordTypeIds);
    System.debug('ids of properties: ');
    System.debug(bothIds);

    if (bothIds.size() > 0) {
      rollupOpportunities(bothIds);
    }
    if (bridgeOpIds.size() > 0) {
      system.debug('bridgeopps' + bridgeOpIds.size());
      bridgeRollupOpportunities(bridgeOpIds);
    }

    if (bothIds.size() > 0) {
      //sumStates(bothIds);
      //CPQ2100 - Raj Sirivolu- 1/6/22 - Added 2 fields, Account_Name__c, Contact__c and Approved_Third_Party_Originators__c to the below SOQL.
      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
        [
          SELECT
            Id,
            Distinct_States__c,
            Distinct_States_Full__c,
            Distinct_Property_Types__c,
            Distinct_MSAs__c,
            Distinct_Counties__c,
            Sum_of_Rehab_Cost__c,
            Sum_of_Borrower_Estimated_Value__c,
            Annual_HOA__c,
            Average_Acquisition_Date_By_Property__c,
            Total_Units__c,
            Total_Properties__c,
            Refinance_Property_Count__c,
            Acquisition_Property_Count__c,
            Apex_Context__c,
            Account_Name__c,
            Contact__c,
            Approved_Third_Party_Originators__c
          FROM Opportunity
          WHERE Id IN :bothIds
        ]
      );
      oppMap = setLoanPurpose(oppMap);
      oppMap = sumStates(oppMap);

      oppMap = avgDate(oppMap);
      oppMap = sumRehab(oppMap);
      //System.debug('this is oppMap: ');
      //System.debug(oppMap);

      List<String> singleList = new List<String>{
        'Condo',
        'Other',
        'SFR',
        'Townhome',
        //, 'Parent'
        'Land/Lot'
      };
      List<String> multiList = new List<String>{
        '2-4 Unit',
        'Multifamily',
        'Duplex',
        'Triplex',
        'Fourplex',
        '5+ Units',
        'Mixed Use'
      };

      Map<Id, String> propTypeCounts = findPropertyType(
        singleList,
        multiList,
        oppMap.keySet()
      );

      for (String oId : oppMap.keySet()) {
        oppMap.get(oId).Distinct_Property_Types__c = '';
        if (propTypeCounts.containsKey(oId)) {
          oppMap.get(oId).Distinct_Property_Types__c = propTypeCounts.get(oId)
            .subStringBeforeLast('; ');
        }
      }
      update oppMap.values();

      // CPQ2100 - Raj Sirivolu- 1/6/22 - Begin
      Settings__mdt settings = Settings__mdt.getInstance('Universal_Settings');
      string cmcoId = settings.Construction_Manager_CV_Originated__c;
      string cmalId = settings.Construction_Manager_Acquired_Loans__c;
      for (Integer i = 0; i < newList.size(); i++) {
        if (
          newList[i].Status__c != oldList[i].Status__c &&
          newList[i].Status__c == 'Active'
        ) {
          if (
            (newList[i].RecordType_Name__c == 'Bridge_Renovation' ||
            newList[i].RecordType_Name__c == 'Ground_Up_Construction') &&
            oppMap.get(newList[i].deal__c).Account_Name__c !=
            'Inhouse Test Account' &&
            oppMap.get(newList[i].deal__c)
              .Approved_Third_Party_Originators__c == null
          ) {
            Task t = new Task();
            t.subject = 'Bridge Asset with Reno/Construction has Funded';
            t.ActivityDate = Date.today().addDays(1);
            t.Priority = 'Normal';
            t.Status = 'Open';
            t.Type = 'Reminder';
            t.WhatID = Trigger.new[i].Id;
            if (!String.isBlank(oppMap.get(newList[i].deal__c).Contact__c)) {
              t.WhoId = oppMap.get(newList[i].deal__c).Contact__c;
            }
            t.Ownerid = cmcoId;
            insert t;
          } else {
            if (
              (newList[i].RecordType_Name__c == 'Bridge_Renovation' ||
              newList[i].RecordType_Name__c == 'Ground_Up_Construction') &&
              oppMap.get(newList[i].deal__c).Account_Name__c !=
              'Inhouse Test Account' &&
              oppMap.get(newList[i].deal__c)
                .Approved_Third_Party_Originators__c != null
            ) {
              Task t = new Task();
              t.subject = 'Bridge Asset with Reno/Construction has Funded';
              t.ActivityDate = Date.today().addDays(1);
              t.Priority = 'Normal';
              t.Status = 'Open';
              t.Type = 'Reminder';
              t.WhatID = Trigger.new[i].Id;
              if (!String.isBlank(oppMap.get(newList[i].deal__c).Contact__c)) {
                t.WhoId = oppMap.get(newList[i].deal__c).Contact__c;
              }
              t.Ownerid = cmalId;
              insert t;
            }
          }
        }
      }
      // CPQ2100 - Raj Sirivolu- 1/6/22 - End
    }

    if (refinanceBubble.size() > 0) {
      inheritRefinance(refinanceBubble);
    }

    if (parentIds.size() > 0) {
      rollupParents(parentIds);
    }

    if (termIds.size() > 0) {
      system.debug('calculate state percentages');
      calculateStatePercentagesFuture(termIds);
    }

    if (propertyAdvancePropIds.size() > 0) {
      List<Property_Advance__c> propAdvs = new List<Property_Advance__c>();

      for (Property_Advance__c pAdv : [
        SELECT Id, Advance__r.Status__c
        FROM Property_Advance__c
        WHERE
          Property__c IN :propertyAdvancePropIds
          AND Advance__r.Status__c != 'Completed'
      ]) {
        propAdvs.add(pAdv);
      }

      if (propAdvs.size() > 0) {
        update propAdvs;
      }
    }

    if (sendToYardiCSV.size() > 0) {
      system.enqueueJob(
        new YardiQueueable('propertyCSV', new List<Id>(sendToYardiCSV))
      );
    }

    // if (smartyStreetIds.size() > 0) {
    //   System.enqueueJob(
    //     new SmartyStreetsQueueable(new List<Id>(smartyStreetIds))
    //   );
    // }
  }

  /**
   * @name beforeDelete
   * @description
   * @param
   **/
  //public static void beforeDelete(List<Property__c> newList){
  //    for ( Integer i=0;i<newList.size();i++ ){

  //    }
  //}

  /**
   * @name afterDelete
   * @description
   * @param
   **/
  public static void afterDelete(
    List<Property__c> newList,
    List<Property__c> oldList
  ) {
    Set<Id> parentIds = new Set<Id>();
    Set<Id> bridgeOppToUpdate = new Set<Id>();

    system.debug(newList);
    system.debug(oldList);
    for (Integer i = 0; i < oldList.size(); i++) {
      bridgeOppToUpdate.add(oldList[i].Deal__c);

      if (oldList[i].Parent_Property__c != null) {
        parentIds.add(oldList[i].Parent_Property__c);
      }
    }

    if (parentIds.size() > 0) {
      system.debug(parentIds);
      rollupDelete(parentIds);
    }
    if (bridgeOppToUpdate.size() > 0) {
      bridgeRollupOpportunities(bridgeOppToUpdate);
      system.debug('oldlistsize' + bridgeOppToUpdate.size());
    }
    //Set<Id> ids = (new Map<Id, Property__c>(oldList)).keySet();

    //delete [SELECT Id FROM Deal_Document__c WHERE Property__c IN : ids];
  }

  /**
   * @name afterUndelete
   * @description
   * @param
   **/
  //public static void afterUndelete(List<Property__c> oldList){
  //    for ( Integer i=0;i<oldList.size();i++ ){

  //    }
  //}

  public static void calculateStatePercentages(Set<Id> opIds) {
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          Number_of_Properties__c,
          State_Percentages__c,
          (
            SELECT Id
            FROM Properties__r
            WHERE Status__c IN ('Active', 'Paid Off') AND Is_Sub_Unit__c = FALSE
          )
        FROM Opportunity
        WHERE Id IN :opIds
      ]
    );

    for (Id opId : oppMap.keySet()) {
      oppMap.get(opId).State_Percentages__c = '';
    }

    for (AggregateResult ar : [
      SELECT count(id) cnt, State__c state, Deal__c parent
      FROM property__c
      WHERE
        Status__c = 'Active'
        AND deal__r.recordtype.developername = 'Term_Loan'
        AND Deal__c IN :opIds
        AND Is_Sub_Unit__c = FALSE
      GROUP BY state__c, deal__c
    ]) {
      Integer stateCount = (Integer) ar.get('cnt');
      String state = (String) ar.get('state');
      Id dealId = (Id) ar.get('parent');

      Decimal propertyCount = (Decimal) oppMap.get(dealId).Properties__r.size();

      if (propertyCount > 0) {
        Decimal val = stateCount / util.fixNull(propertyCount) * 100;
        val = val.setScale(2);

        oppMap.get(dealId).State_Percentages__c += state + ' ' + val + '%, ';
        oppMap.get(dealId).Apex_Context__c = true;
      }
    }

    for (Id i : oppMap.keySet()) {
      if (String.isNotBlank(oppMap.get(i).State_Percentages__c)) {
        oppMap.get(i).State_Percentages__c = oppMap.get(i)
          .State_Percentages__c.subStringBeforeLast(',');
      }
    }

    update oppMap.values();
  }

  public static void rollupOpportunities(Set<Id> opIds) {
    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

    for (Id i : opIds) {
      Opportunity o = new Opportunity(Id = i);
      o.Aggregate_Funding__c = 0;
      o.Aggregate_Value_PreAdvance__c = 0;
      o.Aggregate_Payoffs__c = 0;
      o.Outstanding_Loan_Amount_PreAdvance__c = 0;
      o.Aggregate_Value_PreAdvance__c = 0;
      o.Aggregate_Advance_Fee_PreAdvance__c = 0;
      o.Apex_Context__c = true;
      opportunityMap.put(i, o);
    }

    for (AggregateResult ar : [
      SELECT
        Deal__c parent,
        SUM(Approved_Advance_Amount_Used__c) ar,
        SUM(BPO_Appraisal_Value__c) ar2,
        SUM(Advance_Fee_formula__c) ar3
      FROM Property__c
      WHERE
        Deal__c IN :opIds
        AND (Status__c = 'Paid Off'
        OR Status__c = 'Active'
        OR Status__c = 'In Process')
      GROUP BY Deal__c
    ]) {
      Id dealId = (Id) ar.get('parent');
      if (!opportunityMap.containsKey(dealId)) {
        opportunityMap.put(dealId, new Opportunity(Id = dealId));
      }
      Opportunity deal = opportunityMap.get(dealId);
      deal.Aggregate_Funding__c = (Decimal) ar.get('ar');
      deal.Aggregate_Value_PreAdvance__c = (Decimal) ar.get('ar2');
      deal.Aggregate_Advance_Fee_PreAdvance__c = (Decimal) ar.get('ar3');

      opportunityMap.put(dealId, deal);
    }

    for (AggregateResult ar : [
      SELECT Deal__c parent, SUM(Aggregate_Payoff_Formula__c) ar
      FROM Property__c
      WHERE Deal__c IN :opIds
      GROUP BY Deal__c
    ]) {
      Id dealId = (Id) ar.get('parent');
      if (!opportunityMap.containsKey(dealId)) {
        opportunityMap.put(dealId, new Opportunity(Id = dealId));
      }
      Opportunity deal = opportunityMap.get(dealId);
      deal.Aggregate_Payoffs__c = util.fixNull((Decimal) ar.get('ar'));
      opportunityMap.put(dealId, deal);
    }
    for (AggregateResult ar : [
      SELECT Deal__c parent, SUM(Current_Outstanding_Loan_Amount__c) ar
      FROM Property__c
      WHERE
        Deal__c IN :opIds
        AND (Status__c = 'Active'
        OR Status__c = 'In Process')
      GROUP BY Deal__c
    ]) {
      Id dealId = (Id) ar.get('parent');
      if (!opportunityMap.containsKey(dealId)) {
        opportunityMap.put(dealId, new Opportunity(Id = dealId));
      }
      Opportunity deal = opportunityMap.get(dealId);
      deal.Outstanding_Loan_Amount_PreAdvance__c = (Decimal) ar.get('ar');
      opportunityMap.put(dealId, deal);
    }

    //for(AggregateResult ar : [SELECT Deal__c parent, SUM(Advance_Fee_Total__c) ar FROM Advance__c
    //                                WHERE Deal__c IN : opIds and Status__c = 'Completed' GROUP By Deal__c]){
    //    Id dealId = (Id)ar.get('parent');
    //    if(!opportunityMap.containsKey(dealId)){
    //        opportunityMap.put(dealId, new Opportunity(Id = dealId));
    //    }

    //    Opportunity deal = opportunityMap.get(dealId);
    //    deal.Aggregate_Advance_Fee_PreAdvance__c = (Decimal)ar.get('ar');
    //    opportunityMap.put(dealId, deal);
    //}

    //List<Advance__c> advances = new List<Advance__c>();
    //for(Advance__c adv : [SELECT Id, Status__c, Deal__c From Advance__c WHERE Status__c = 'Pending' AND Deal__c IN : opIds]){
    //    Opportunity o = opportunityMap.get(o.Id)
    //}

    if (opportunityMap.keySet().size() > 0) {
      system.debug(opportunityMap.values());
      update opportunityMap.values();
    }
  }

  public static void bridgeRollupOpportunities(Set<Id> opIds) {
    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

    for (Id i : opIds) {
      Opportunity o = new Opportunity(Id = i);
      o.Current_UPB__c = 0;
      o.Apex_Context__c = true;
      opportunityMap.put(i, o);
    }

    for (AggregateResult ar : [
      SELECT Deal__c parent, SUM(Current_UPB__c) ar
      FROM Property__c
      WHERE Current_UPB__c != NULL AND Deal__c IN :opIds
      GROUP BY Deal__c
    ]) {
      Id dealId = (Id) ar.get('parent');
      if (!opportunityMap.containsKey(dealId)) {
        opportunityMap.put(dealId, new Opportunity(Id = dealId));
      }
      Opportunity deal = opportunityMap.get(dealId);
      deal.Current_UPB__c = (Decimal) ar.get('ar');

      opportunityMap.put(dealId, deal);
    }

    if (opportunityMap.keySet().size() > 0) {
      system.debug(opportunityMap.values());
      update opportunityMap.values();
    }
  }

  public static void rollupDelete(Set<Id> ids) {
    List<Property__c> propertiesToDelete = new List<Property__c>();
    for (Property__c parent : [
      SELECT Id, (SELECT Id FROM Properties__r WHERE Status__c = 'Active')
      FROM Property__c
      WHERE Id IN :ids
    ]) {
      system.debug(parent);
      system.debug(parent.properties__r);
      if (parent.properties__r.size() == 0) {
        propertiesToDelete.add(new Property__c(Id = parent.Id));
      }
    }

    if (propertiesToDelete.size() > 0) {
      delete propertiesToDelete;
    }
  }

  public static void rollupParents(Set<Id> ids) {
    Map<Id, Property__c> propertyMap = new Map<Id, Property__c>();
    for (Id i : ids) {
      Property__c parent = new Property__c();
      parent.Monthly_Rent__c = 0;
      parent.Security_Deposit__c = 0;
      parent.Verified_Rent__c = 0;
      parent.Rehab_Costs__c = 0;
      propertyMap.put(i, new Property__c(Id = i, Status__c = 'Inactive'));
    }

    for (AggregateResult ar : [
      SELECT
        count(id) cnt,
        SUM(Square_Feet_value__c) sf,
        SUM(Monthly_Rent__c) mr,
        SUM(Security_Deposit__c) sd,
        SUM(Verified_Rent__c) vr,
        SUM(Rehab_Costs__c) rc,
        SUM(Number_of_Units__c) uc,
        SUM(Borrower_Opinion_of_Current_Value__c) bov,
        SUM(Annual_Taxes__c) at,
        SUM(Verified_Tax__c) avt,
        SUM(Annual_HOA_Fee__c) ah,
        SUM(Acquisition_Price__c) ac,
        SUM(Verified_Acquisition_Price__c) avc,
        SUM(Annual_Insurance__c) ai,
        SUM(Verified_Annual_Insurance__c) avi,
        SUM(Appraised_Value_Amount__c) av,
        Parent_Property__c parent
      FROM Property__c
      WHERE Status__c = 'Active' AND Parent_Property__c IN :ids
      GROUP BY Parent_Property__c
    ]) {
      Id parentId = (Id) ar.get('parent');
      Property__c parent = propertyMap.get(parentId);

      parent.Square_Feet__c = String.valueOf(
        util.fixNull((Decimal) ar.get('sf'))
      );
      parent.Monthly_Rent__c = util.fixNull((Decimal) ar.get('mr'));
      parent.Security_Deposit__c = util.fixNull((Decimal) ar.get('sd'));
      parent.Verified_Rent__c = util.fixNull((Decimal) ar.get('vr'));
      parent.Rehab_Costs__c = util.fixNull((Decimal) ar.get('rc'));
      parent.Number_of_Units__c = util.fixNull((Decimal) ar.get('uc'));
      parent.Borrower_Opinion_of_Current_Value__c = util.fixNull(
        (Decimal) ar.get('bov')
      );
      parent.Annual_Taxes__c = (Decimal) ar.get('at');
      parent.Verified_Tax__c = (Decimal) ar.get('avt');
      parent.Annual_HOA_Fee__c = util.fixNull((Decimal) ar.get('ah'));
      parent.Acquisition_Price__c = util.fixNull((Decimal) ar.get('ac'));
      parent.Verified_Acquisition_Price__c = util.fixNull(
        (Decimal) ar.get('avc')
      );
      parent.Annual_Insurance__c = util.fixNull((Decimal) ar.get('ai'));
      parent.Verified_Annual_Insurance__c = util.fixNull(
        (Decimal) ar.get('avi')
      );
      parent.Appraised_Value_Amount__c = util.fixNull((Decimal) ar.get('av'));

      propertyMap.get(parentId).Status__c = 'Active';
    }

    Set<Id> parentPropIds = new Set<Id>();
    for (Property__c p : [
      SELECT
        Id,
        Property_Name__c,
        Property_Type__c,
        City__c,
        State__c,
        ZipCode__c,
        County__c,
        Parent_Property__c,
        Square_Feet__c,
        Square_Feet_value__c,
        Number_of_Units__c,
        Acquisition_Date__c,
        Borrower_Opinion_of_Current_Value__c,
        Annual_Taxes__c,
        Annual_HOA_Fee__c,
        Refinance_Acquisition__c,
        Acquisition_Price__c,
        Annual_Insurance__c,
        Valuation_Type__c,
        BPO_Appraisal_Date__c,
        BPO_Appraisal_Firm__c,
        Appraised_Value_Amount__c,
        Appraisal_Form__c,
        Year_Built__c,
        Interior_Access_POC__c,
        Interior_Access_POC_Email__c,
        Interior_Access_POC_Phone__c
      FROM Property__c
      WHERE Parent_Property__c IN :ids AND Status__c = 'Active'
      ORDER BY Parent_Property__c DESC, Name ASC
    ]) {
      if (!parentPropIds.contains(p.Parent_Property__c)) {
        // parent.Square_feet__c += util.fixNull(p.Square_Feet_value__c);
        //Property__c parent = new Property__c(Id = p.Parent_Property__c);
        Property__c parent = propertyMap.get(p.Parent_Property__c);
        parent.Acquisition_Date__c = p.Acquisition_Date__c;
        parent.Year_Built__c = p.Year_Built__c;
        parent.Refinance_Acquisition__c = p.Refinance_Acquisition__c;
        parent.Property_Name__c = p.Property_Name__c;
        parent.City__c = p.City__c;
        parent.State__c = p.State__c;
        parent.ZipCode__c = p.ZipCode__c;
        parent.County__c = p.County__c;
        parent.Property_Type__c = p.Property_Type__c;
        parent.Valuation_Type__c = p.Valuation_Type__c;
        parent.BPO_Appraisal_Date__c = p.BPO_Appraisal_Date__c;
        parent.BPO_Appraisal_Firm__c = p.BPO_Appraisal_Firm__c;
        parent.Appraisal_Form__c = p.Appraisal_Form__c;
        parent.Interior_Access_POC__c = p.Interior_Access_POC__c;
        parent.Interior_Access_POC_Email__c = p.Interior_Access_POC_Email__c;
        parent.Interior_Access_POC_Phone__c = p.Interior_Access_POC_Phone__c;
        parentPropIds.add(p.Parent_Property__c);
      }
    }

    update propertyMap.values();
  }

  public static void attachVendors(
    Map<String, List<Property__c>> vendorMap,
    String vendorType
  ) {
    system.debug('attaching vendors');

    List<Account> accountInsert = new List<Account>();
    for (Account a : [
      SELECT Id, Name
      FROM Account
      WHERE Name IN :vendorMap.keySet()
      LIMIT 1
    ]) {
      for (Property__c p : vendorMap.get(a.Name.toLowerCase())) {
        if (vendorType == 'Escrow') {
          p.Escrow_Agent__c = a.Id;
        } else if (vendorType == 'Title') {
          p.Title_Company__c = a.Id;
        } else if (vendorType == 'Insurance') {
          p.Insurance_Company__c = a.Id;
        }
      }

      vendorMap.remove(a.Name.toLowerCase());
    }

    for (String name : vendorMap.keySet()) {
      if (vendorMap.get(name).size() > 0) {
        String vendorName = '';
        Account vendorAccount = new Account(
          Account_Status__c = 'Active CoreVest Vendor',
          RecordTypeId = ACCOUNT_RECORD_TYPE_MAP.get('Vendor').Id
        );
        if (vendorType == 'Escrow') {
          vendorName = vendorMap.get(name)[0].Escrow_Company_text__c;
          vendorAccount.Non_Borrower_Account_Type__c = 'Title and Escrow';
        } else if (vendorType == 'Title') {
          vendorName = vendorMap.get(name)[0].Title_Company_text__c;
          vendorAccount.Non_Borrower_Account_Type__c = 'Title and Escrow';
        } else if (vendorType == 'Insurance') {
          vendorName = vendorMap.get(name)[0].Insurance_Company_text__c;
          vendorAccount.Non_Borrower_Account_Type__c = 'Insurance Agent';
        }

        vendorAccount.Name = vendorName;
        accountINsert.add(vendorAccount);

        // accountInsert.add(
        //   new Account(
        //     Name = vendorName,
        //     RecordTypeId = ACCOUNT_RECORD_TYPE_MAP.get('Vendor').Id
        //   )
        // );
      }
    }

    if (accountInsert.size() > 0) {
      try {
        insert accountInsert;
        for (Account a : accountInsert) {
          //system.debug(a);
          for (Property__c p : vendorMap.get(a.Name.toLowerCase())) {
            if (vendorType == 'Escrow') {
              p.Escrow_Agent__c = a.Id;
            } else if (vendorType == 'Title') {
              p.Title_Company__c = a.Id;
            } else if (vendorType == 'Insurance') {
              p.Insurance_Company__c = a.Id;
            }
          }
        }
      } catch (DmlException e) {
      }
    }
  }

  @future
  public static void calculateStatePercentagesFuture(Set<Id> opIds) {
    calculateStatePercentages(opIds);
  }

  public static void sendDataTapeNotification(Id dealId) {
    Opportunity deal = [
      SELECT
        Id,
        Owner.Email,
        OwnerId,
        Contact__c,
        CAF_Analyst__r.Email,
        Underwriter__r.Email,
        Loan_Coordinator__r.Email,
        Closer__r.Email,
        Contact__r.Email,
        (
          SELECT Id, Contact__c
          FROM Deal_Contacts__r
          WHERE
            (Entity_Type__c = 'Portal Access'
            OR Deal_Contact_Type__c = 'Vendor')
            AND Contact__c != NULL
        )
      FROM Opportunity
      WHERE Id = :dealId
    ];

    Set<Id> contactIds = new Set<Id>();
    for (Deal_Contact__c dc : deal.Deal_Contacts__r) {
      contactIds.add(dc.Contact__c);
    }
    contactIds.add(deal.Contact__c);

    Set<String> emails = new Set<String>();
    for (User u : [SELECT Id, Email FROM User WHERE ContactId IN :contactIds]) {
      emails.add(u.Email);
    }

    if (deal.OwnerId != null) {
      emails.add(deal.Owner.Email);
    }

    if (deal.CAF_Analyst__c != null) {
      emails.add(deal.Caf_Analyst__r.Email);
    }

    if (deal.Underwriter__c != null) {
      emails.add(deal.Underwriter__r.Email);
    }

    if (deal.Loan_Coordinator__c != null) {
      emails.add(deal.Loan_Coordinator__r.Email);
    }

    if (deal.Closer__c != null) {
      emails.add(deal.Closer__r.Email);
    }

    // if(deal.Contact__)

    //emails.add(deal.Contact__r.Email);

    Id emailTemplateId = [
      SELECT Id
      FROM EmailTemplate
      WHERE DeveloperName = 'Data_Tape_Change_Term_1567616202483'
      LIMIT 1
    ]
    .Id;
    Id orgEmail = [
      SELECT Id, Address
      FROM OrgWideEmailAddress
      WHERE Address = 'caf-apps@cvest.com'
      LIMIT 1
    ]
    .Id;

    Messaging.SingleEMailMessage email = new Messaging.SingleEmailMessage();

    email.setTemplateId(emailTemplateId);
    email.setOrgWideEmailAddressId(orgEmail);
    email.setCcAddresses(new List<String>{ 'bryon@cvest.com' });
    email.setToAddresses(new List<String>(emails));
    // email.setTar
    email.setWhatId(dealId);
    email.setTargetObjectId(deal.Contact__c);
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }
}
