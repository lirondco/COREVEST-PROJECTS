public with sharing class TermSheetPDF_Controller {
  public Opportunity record { get; set; }
  public Integer month { get; set; }
  public Integer day { get; set; }
  public Integer year { get; set; }
  public Integer todayMonth { get; set; }
  public Integer todayDay { get; set; }
  public Integer todayYear { get; set; }
  public String intStr { get; set; }
  public String base64Image { get; set; }
  public Opportunity dupeRecord { get; set; }

  public Boolean includeBrokerFee { get; set; }
  public Boolean includeCOBroker { get; set; }

  public String numPropertyText { get; set; }
  public String numPropertyTextCapitalized { get; set; }
  public String totalPropertiesText { get; set; }

  public String formattedStates { get; set; }

  public Property__c sabProperty { get; set; }
  public List<Property__c> allProperties { get; set; }

  public TermSheetPDF_Controller(
    ApexPages.standardController standardController
  ) {
    // <!-- application/msword#{!Opportunity.Name}_TermSheetv_{!intStr}.doc -->

    this.record = (Opportunity) standardController.getRecord();
    // this.dupeRecord = new Opportunity();
    if (record.Id != null) {
      List<StaticResource> sr = [
        SELECT Body
        FROM StaticResource
        WHERE Name = 'corevestLogo'
      ];

      // Opportunity dupeRecord = [SELECT Id, Term_Sheet_Expiration_Date__c, Include_Assumption__c, Include_Prop_Sub_Text__c, NY_Counsel_Required__c, Include_3_Months_Min_Interest__c
      // 							FROM Opportunity where Id =: record.Id LIMIT 1];
      // this.record.Term_Sheet_Expiration_Date__c = updatedOpp.Term_Sheet_Expiration_Date__c;

      if (sr.size() > 0) {
        base64Image = EncodingUtil.base64Encode(sr[0].Body);
      }
      record = (Opportunity) util.queryRecord(record.Id);
      month = Integer.valueOf(
        ApexPages.currentPage().getParameters().get('month')
      );
      day = Integer.valueOf(ApexPages.currentPage().getParameters().get('day'));
      year = Integer.valueOf(
        ApexPages.currentPage().getParameters().get('year')
      );
      todayMonth = Integer.valueOf(
        ApexPages.currentPage().getParameters().get('todaymonth')
      );
      todayDay = Integer.valueOf(
        ApexPages.currentPage().getParameters().get('todayday')
      );
      todayYear = Integer.valueOf(
        ApexPages.currentPage().getParameters().get('todayyear')
      );
      intStr = ApexPages.currentPage().getParameters().get('version');
      String strUrl = ApexPages.currentPage().getUrl();
      system.debug(strUrl);
      if (strUrl.contains('Doc')) {
        system.debug('in here');
        Apexpages.currentPage()
          .getHeaders()
          .put(
            'Content-Disposition',
            'attachment; filename="' +
            record.Name +
            '_Termsheetv_' +
            intStr +
            '.doc"'
          );
      }

      this.dupeRecord = [
        SELECT
          Id,
          Term_Sheet_Expiration_Date__c,
          Include_Assumption__c,
          Include_Prop_Sub_Text__c,
          NY_Counsel_Required__c,
          Include_3_Months_Min_Interest__c,
          RecordType.DeveloperName
        FROM Opportunity
        WHERE Id = :record.Id
        LIMIT 1
      ];

      if (
        this.dupeRecord.RecordType.DeveloperName == 'Single_Asset_Bridge_Loan'
      ) {
        List<Property__c> props = [
          SELECT
            Id,
            Property_Name__c,
            Name,
            City__c,
            State__c,
            ZipCode__c,
            Property_Type__c,
            County__c,
            Number_of_Units__c
          FROM Property__c
          WHERE
            Deal__c = :record.Id
            AND Status__c NOT IN ('Cancelled', 'Inactive')
          LIMIT 1
        ];
        system.debug(props);
        if (props.size() > 0) {
          this.sabProperty = props[0];
          system.debug('here');
        } else {
          this.sabProperty = new Property__c();
        }
      }

      List<Property__c> properties = new List<Property__c>();
      for (Property__c property : [
        SELECT
          Id,
          Property_Name__c,
          Name,
          City__c,
          State__c,
          ZipCode__c,
          Property_Type__c,
          County__c,
          Number_of_Units__c,
          Is_Parent__c
        FROM Property__c
        WHERE
          Deal__c = :record.Id
          AND Status__c NOT IN ('Cancelled', 'Inactive')
      ]) {
        if (
          property.Property_Type__c == '2-4 Unit' ||
          property.Property_Type__c == 'Multifamily'
        ) {
          if (property.Is_Parent__c == true) {
            properties.add(property);
          }
        } else {
          properties.add(property);
        }
      }

      this.allProperties = properties;

      if (ApexPages.currentPage().getParameters().containsKey('s')) {
        String str = ApexPages.currentPage().getParameters().get('s');
        Map<String, String> s = (Map<String, String>) JSON.deserialize(
          EncodingUtil.base64Decode(str).toString(),
          Map<String, String>.class
        );

        if (s.containsKey('Term_Sheet_Expiration_Date__c')) {
          this.dupeRecord.Term_Sheet_Expiration_Date__c = Date.valueOf(
            s.get('Term_Sheet_Expiration_Date__c')
          );
        }

        if (s.containsKey('Include_Assumption__c')) {
          this.dupeRecord.Include_Assumption__c = Boolean.valueOf(
            s.get('Include_Assumption__c')
          );
        }

        if (s.containsKey('Include_Prop_Sub_Text__c')) {
          this.dupeRecord.Include_Prop_Sub_Text__c = Boolean.valueOf(
            s.get('Include_Prop_Sub_Text__c')
          );
        }

        if (s.containsKey('NY_Counsel_Required__c')) {
          this.dupeRecord.NY_Counsel_Required__c = Boolean.valueOf(
            s.get('NY_Counsel_Required__c')
          );
        }

        if (s.containsKey('Include_3_Months_Min_Interest__c')) {
          this.dupeRecord.Include_3_Months_Min_Interest__c = Boolean.valueOf(
            s.get('Include_3_Months_Min_Interest__c')
          );
        }

        if (s.containsKey('Include_Broker_Fee__c')) {
          //this.dupeRecord.Include_Broker_Fee__c = Boolean.valueOf(s.get('Include_Broker_Fee__c'));
          this.includeBrokerFee = Boolean.valueOf(
            s.get('Include_Broker_Fee__c')
          );
        }

        if (s.containsKey('Include_CO_Broker_Text__c')) {
          //this.dupeRecord.Include_CO_Broker_Text__c = Boolean.valueOf(s.get('Include_CO_Broker_Text__c'));
          this.includeCOBroker = Boolean.valueOf(
            s.get('Include_CO_Broker_Text__c')
          );
        }
      }

      if (
        null != record.Number_of_Properties__c &&
        0 != record.Number_of_Properties__c
      ) {
        numPropertyTextCapitalized = formatCurrencyString(
          record.Number_of_Properties__c
        );
        //numPropertyTextCapitalized = numPropertyText.capitalize();
      } else {
        numPropertyText = 'zero';
      }

      if (
        null != record.Total_Properties__c &&
        0 != record.Total_Properties__c
      ) {
        totalPropertiesText = formatCurrencyString(record.Total_Properties__c);
      } else {
        totalPropertiesText = 'zero';
      }

      if (String.isNotBlank(record.Active_States__c)) {
        this.formattedStates = multiSelectToText(record.Active_States__c);
      }
    }
  }

  public Map<Integer, String> thousandsMap = new Map<Integer, String>{
    1 => 'one thousand,',
    2 => 'two thousand,',
    3 => 'three thousand,',
    4 => 'four thousand,',
    5 => 'five thousand,',
    6 => 'six thousand,',
    7 => 'seven thousand,',
    8 => 'eight thousand,',
    9 => 'nine thousand,',
    10 => 'ten thousand,'
  };

  public Map<Integer, String> hundredsMap = new Map<Integer, String>{
    1 => 'one hundred and',
    2 => 'two hundred and',
    3 => 'three hundred and',
    4 => 'four hundred and',
    5 => 'five hundred and',
    6 => 'six hundred and',
    7 => 'seven hundred and',
    8 => 'eight hundred and',
    9 => 'nine hundred and'
  };

  public Map<Integer, String> tensMap = new Map<Integer, String>{
    2 => 'twenty',
    3 => 'thirty',
    4 => 'forty',
    5 => 'fifty',
    6 => 'sixty',
    7 => 'seventy',
    8 => 'eighty',
    9 => 'ninety'
  };

  public Map<Integer, String> tensOneMap = new Map<Integer, String>{
    10 => 'ten',
    11 => 'eleven',
    12 => 'twelve',
    13 => 'thirteen',
    14 => 'fourteen',
    15 => 'fifteen',
    16 => 'sixteen',
    17 => 'seventeen',
    18 => 'eighteen',
    19 => 'nineteen'
  };

  public Map<Integer, String> onesMap = new Map<Integer, String>{
    0 => 'zero',
    1 => 'one',
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine'
  };

  public Integer getMonth() {
    return month;
  }

  public Integer getDay() {
    return day;
  }

  public Integer getYear() {
    return year;
  }

  public Integer todayMonth() {
    return todayMonth;
  }

  public Integer todayDay() {
    return todayDay;
  }

  public Integer todayYear() {
    return todayYear;
  }

  public String convertText(Decimal d) {
    Integer total = d.intValue();
    String intStr = '';
    System.debug('this is the total: ' + total);

    Integer thousandsCnt = loopPosition(total, 1000);
    total -= thousandsCnt * 1000;

    System.debug('this is the total: ' + total);
    System.debug('this is thousandsCnt: ' + thousandsCnt);

    Integer hundredsCnt = loopPosition(total, 100);
    total -= hundredsCnt * 100;

    System.debug('this is the total: ' + total);
    System.debug('this is hundredsCnt: ' + hundredsCnt);

    Integer tensCnt = loopPosition(total, 10);
    total -= tensCnt * 10;

    System.debug('this is the total: ' + total);
    System.debug('this is tensCnt: ' + tensCnt);

    Integer onesCnt = total;
    System.debug('this is onesCnt: ' + onesCnt);

    intStr += thousandsCnt > 0 ? thousandsMap.get(thousandsCnt) + ' ' : '';
    System.debug('this is intStr: ' + intStr);

    intStr += hundredsCnt > 0 ? hundredsMap.get(hundredsCnt) + ' ' : '';
    System.debug('this is intStr: ' + intStr);

    if (tensCnt > 1) {
      intStr += tensMap.get(tensCnt);
      intStr += onesCnt > 0 ? ' ' + onesMap.get(onesCnt) : '';
      System.debug('this is intStr: ' + intStr);
    } else if (tensCnt == 1) {
      System.debug('inside tenCnt is 1');
      Integer sum = (tensCnt * 10) + onesCnt;
      intStr += tensOneMap.get(sum);
      System.debug('this is intStr: ' + intStr);
    } else if (tensCnt == 0) {
      intStr += onesCnt > 0 ? onesMap.get(onesCnt) : '';
      System.debug('this is intStr: ' + intStr);
    }

    return intStr;
  }

  public Integer loopPosition(Integer i, Integer unit) {
    Integer cnt = 0;
    for (Integer j = i; j >= unit; j -= unit) {
      cnt += 1;
    }
    // System.debug(cnt);
    return cnt;
  }

  public PageReference save() {
    upsert record;
    if (!ApexPages.hasMessages()) {
      return new ApexPages.standardController(record).view().setRedirect(true);
    }
    return null;
  }

  public static string formatCurrencyString(Decimal n) {
    Integer nn = Integer.valueOf(n);
    String val = String.valueOf(nn);
    List<String> units;
    List<String> tens;
    List<String> scales;
    Integer start;
    Integer endl;
    List<String> chunks;
    Integer chunksLen;
    Integer chunk;
    List<Integer> ints;
    Integer i;
    String word;
    List<String> words;
    String andS = 'and';

    // val = val.replace('/[, ]/g', '');
    val = val.replaceAll(' ', '');
    val = val.replaceAll(',', '');

    if (Decimal.valueOf(val) == 0) {
      return 'zero';
    }

    units = new List<String>{
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen'
    };

    tens = new List<String>{
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety'
    };

    scales = new List<String>{
      '',
      'thousand',
      'million',
      'billion',
      'trillion',
      'quadrillion',
      'quintillion',
      'sextillion',
      'septillion',
      'octillion',
      'nonillion',
      'decillion',
      'undecillion',
      'duodecillion',
      'tredecillion',
      'quatttuor-decillion',
      'quindecillion',
      'sexdecillion',
      'septen-decillion',
      'octodecillion',
      'novemdecillion',
      'vigintillion',
      'centillion'
    };

    start = val.length();
    chunks = new List<String>();

    while (start > 0) {
      endl = start;
      start = Math.max(0, start - 3);
      chunks.add(val.substring(start, endl));
    }

    chunksLen = chunks.size();
    if (chunksLen > scales.size()) {
      return '';
    }

    words = new List<String>();

    for (i = 0; i < chunksLen; i++) {
      chunk = Integer.valueOf(chunks[i]);

      if (chunk != null) {
        ints = new List<Integer>();
        List<String> intsTemp = chunks[i].split('');
        system.debug(intsTemp);
        for (Integer j = intsTemp.size() - 1; j >= 0; j--) {
          system.debug(j);
          ints.add(Integer.valueOf(intsTemp[j]));
        }

        try {
          if (ints[1] == 1) {
            ints[0] += 10;
          }
        } catch (Exception e) {
        }

        try {
          word = scales[i];
          words.add(word);
        } catch (Exception e) {
        }

        try {
          word = units[ints[0]];
          words.add(word);
        } catch (Exception e) {
        }

        try {
          word = tens[ints[1]];
          words.add(word);
        } catch (Exception e) {
        }

        try {
          if (ints[0] > 0 || ints[1] > 0) {
            if (ints[2] > 0 || (i == 0 && chunksLen > 0)) {
              words.add(andS);
            }
          }
        } catch (Exception e) {
        }

        try {
          word = units[ints[2]];
          words.add(word + ' hundred');
        } catch (Exception e) {
        }
      }
    }
    String res = '';
    for (i = words.size() - 1; i >= 0; i--) {
      res += words[i] + ' ';

      if (
        words[i] != '' &&
        tens.contains(words[i]) &&
        i != 0 &&
        words[i - 1] != ''
      ) {
        res = res.substringBeforeLast(' ') + '-';
      }
    }

    return res;
  }

  public static String multiSelectToText(String value) {
    String textValue = '';
    List<String> splitValues = value.split(';');

    if (splitValues.size() == 1) {
      textValue = splitValues[0];
    } else if (splitValues.size() == 2) {
      textValue = splitValues[0] + ' and ' + splitValues[1];
    } else {
      for (Integer i = 0; i < splitValues.size(); i++) {
        if (i == splitValues.size() - 1) {
          textValue =
            textValue.substringBeforeLast(',') +
            ' and ' +
            splitValues[i];
        } else {
          textValue += splitValues[i] + ', ';
        }
      }
    }

    return textValue;
  }
}