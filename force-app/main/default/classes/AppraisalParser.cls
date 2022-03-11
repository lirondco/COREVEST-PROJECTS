public without sharing class AppraisalParser implements Queueable {
  List<Deal_Document__c> documents;
  // APILoggerQueueable apiLogger;

  public AppraisalParser(List<Deal_Document__c> documents) {
    this.documents = documents;
  }

  // public AppraisalParser(
  //   List<Deal_Document__c> documents,
  //   APILoggerQueueable logger
  // ) {
  //   this.documents = documents;
  //   this.apiLogger = logger;
  // }

  public void execute(QueueableContext context) {
    system.debug('inside parser');

    parseXML(documents.remove(0));

    if (documents.size() > 0) {
      system.enqueueJob(new AppraisalParser(documents));
    }

    // if (apiLogger != null) {
    //   system.enqueueJob(apiLogger);
    // }
  }

  public static void parseXML(Deal_Document__c dealDocument) {
    ContentDocument document = [
      SELECT Id, LatestPublishedVersion.VersionData
      FROM ContentDocument
      WHERE Id = :dealDocument.Attachment_Id__c
      LIMIT 1
    ];

    Dom.Document doc = new Dom.Document();
    doc.load(document.LatestPublishedVersion.VersionData.toString());

    Appraisal__c appraisal = new Appraisal__c(
      Deal__c = dealDocument.Deal__c,
      Property__c = dealDocument.Property__c,
      Deal_Document__c = dealDocument.Id,
      Id = dealDocument.Appraisal__c,
      Delivery_Method__c = 'XML Upload',
      Status__c = 'Complete-Delivered'
    );

    DOM.XMLNode root = doc.getRootElement();
    DOM.XMLNode reportNode = root.getChildElement('REPORT', null);

    if (reportNode != null) {
      root = null;
      parseXMLStandard(doc, appraisal, dealDocument);
    } else {
      root = null;
      parseXMLBBG(doc, appraisal, dealDocument);
    }
  }

  public static void parseXMLStandard(
    Dom.Document doc,
    Appraisal__c appraisal,
    Deal_Document__c dealDocument
  ) {
    DOM.XMLNode root = doc.getRootElement();
    DOM.XMLNode reportNode = root.getChildElement('REPORT', null);
    appraisal.Appraisal_Form__c = reportNode.getAttribute(
      'AppraisalFormType',
      null
    );

    if (appraisal.Appraisal_Form__c == 'Other') {
      //appraisal.Appraisal_Form__c == 'Clarocity MVP';
      appraisal.APpraisal_Form__c = appraisal.Appraisal_Form__c = reportNode.getAttribute(
        'AppraisalFormVersionIdentifier',
        null
      );
    }

    Dom.XMLNode valuationNode = root.getChildElement('VALUATION', null);
    String appraisalValueAmount = valuationNode.getAttribute(
      'PropertyAppraisedValueAmount',
      null
    );
    appraisal.Appraised_Value_Amount__c = String.isNotBlank(
        appraisalValueAmount
      )
      ? Decimal.ValueOf(appraisalValueAmount.replaceAll('[^0-9.]', ''))
      : null;

    //Date theDate;
    String appraisalEffectiveDate = valuationNode.getAttribute(
      'AppraisalEffectiveDate',
      null
    );
    try {
      // parse works in the case of 10/11/1983
      appraisal.Appraisal_Effective_Date__c = Date.parse(
        appraisalEffectiveDate
      );
    } catch (Exception e) {
    }
    if (appraisal.Appraisal_Effective_Date__c == null) {
      try {
        // valueof works in the case of 1983-10-11
        appraisal.Appraisal_Effective_Date__c = Date.valueOf(
          appraisalEffectiveDate
        );
      } catch (Exception e) {
      }
    }
    if (appraisal.Appraisal_Effective_Date__c == null) {
      // couldn't parse
    }

    //appraisal.Appraisal_Effective_Date__c = appraisalEffectiveDate != null  ? Date.parse(appraisalEffectiveDate) : null;

    Dom.XMlNode conditionOfAppraisalNode = valuationNOde.getChildElement(
      '_RECONCILIATION',
      null
    );

    if (conditionOfAppraisalNode != null) {
      conditionOfAppraisalNode.getChildElement('_CONDITION_OF_APPRAISAL', null);
      appraisal.This_Appraisal_is_Made__c = conditionOfAppraisalNode.getAttribute(
        '_Type',
        null
      );
    }

    //for(DOM.XMLNode children : root.getChildElements()){
    //  system.debug(children.getName());
    //}

    DOM.XMLNode property_node = root.getChildElement('PROPERTY', null);

    String streetaddress = property_node.getAttribute('_StreetAddress', null)
      .toLowerCase();
    List<String> addressSplit = streetaddress.split(' ');
    for (Integer i = 0; i < addressSplit.size(); i++) {
      addressSplit[i] = addressSplit[i].capitalize();
    }
    streetaddress = String.join(addressSplit, ' ');

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
      appraisal.No_of_Stories__c = gseStories;
    }

    DOM.XMLNode unit_node = structure_node_new.getChildElement('_UNIT', null);
    system.debug('unit_node==' + unit_node);
    String unitidentifier = '';
    if (unit_node != null) {
      unitidentifier = unit_node.getAttribute('UnitIdentifier', null);
    }
    system.debug('streetaddress===' + streetaddress);
    system.debug('unitidentifier===' + unitidentifier);
    if (unitidentifier == '' || unitidentifier == null) {
      appraisal.Property_Address__c = streetaddress;
    } else {
      appraisal.Property_Address__c = streetaddress + ' #' + unitidentifier;
    }

    String city = property_node.getAttribute('_City', null).toLowerCase();
    List<String> cityNames = city.split(' ');
    for (Integer i = 0; i < cityNames.size(); i++) {
      cityNames[i] = cityNames[i].capitalize();
    }
    city = String.join(cityNames, ' ');
    appraisal.City__c = city;
    appraisal.State__c = property_node.getAttribute('_State', null);
    appraisal.Zip__c = property_node.getAttribute('_PostalCode', null);

    String county = property_node.getAttribute('_County', null).toLowerCase();
    List<String> countyNames = county.split(' ');
    for (Integer i = 0; i < countyNames.size(); i++) {
      countyNames[i] = countyNames[i].capitalize();
    }
    county = String.join(countyNames, ' ');
    appraisal.County__c = county;
    // This section will be all children objects under SITE
    DOM.XMLNode site_node = property_node.getChildElement('SITE', null);

    if (site_node != null) {
      appraisal.Lot_Area__c = site_node.getAttribute('_AreaDescription', null);
      appraisal.Zoning_Compliance__c = site_node.getAttribute(
        '_ZoningComplianceType',
        null
      );

      if (appraisal.Zoning_Compliance__c == 'Nonconforming') {
        appraisal.Zoning_Compliance__c = 'Legal Nonconforming';
      } else if (appraisal.Zoning_Compliance__c == 'NoZoning') {
        appraisal.Zoning_Compliance__c = 'No Zoning';
      }

      appraisal.Zoning_Classification__c = site_node.getAttribute(
        '_ZoningClassificationIdentifier',
        null
      );
      appraisal.Zoning_Description__c = site_node.getAttribute(
        '_ZoningClassificationDescription',
        null
      );
      DOM.XMLNode flood_node = site_node.getChildElement('FLOOD_ZONE', null);
      if (flood_node != null) {
        appraisal.Special_Flood_Hazard_Area__c = flood_node.getAttribute(
          'SpecialFloodHazardAreaIndicator',
          null
        );
        if (appraisal.Special_Flood_Hazard_Area__c == 'Y') {
          appraisal.Flood_Zone__c = flood_node.getAttribute(
            'NFIPFloodZoneIdentifier',
            null
          );
        } else {
          appraisal.Flood_Zone__c = '';
        }
      }
    }

    DOM.XMLNode ident_node = property_node.getChildElement(
      '_IDENTIFICATION',
      null
    );
    if (ident_node != null) {
      appraisal.APN_Assessor_s_Parcel__c = ident_node.getAttribute(
        'AssessorsParcelIdentifier',
        null
      );
    }

    DOM.XMLNode structure_node = property_node.getChildElement(
      'STRUCTURE',
      null
    );
    if (structure_node != null) {
      String livingCount = structure_node.getAttribute('LivingUnitCount', null);
      appraisal.Units__c = String.isNotBlank(livingCount)
        ? Decimal.valueOf(livingCount.replaceAll('[^0-9.]', ''))
        : null;
      appraisal.Year_Built__c = structure_node.getAttribute(
        'PropertyStructureBuiltYear',
        null
      );

      String totalBeds = structure_node.getAttribute('TotalBedroomCount', null);
      appraisal.Bedrooms__c = String.isNotBlank(totalBeds)
        ? Decimal.ValueOf(totalBeds.replaceAll('[^0-9.]', ''))
        : null;

      String totalBaths = structure_node.getAttribute(
        'TotalBathroomCount',
        null
      );
      appraisal.Baths__c = String.isNotBlank(totalBaths)
        ? Decimal.ValueOf(totalBaths.replaceAll('[^0-9.]', ''))
        : null;

      String gla = structure_node.getAttribute(
        'GrossLivingAreaSquareFeetCount',
        null
      );
      appraisal.Gross_Living_Area__c = String.isNotBlank(gla)
        ? Decimal.ValueOf(gla.replaceAll('[^0-9.]', ''))
        : null;
      appraisal.Design_Style__c = structure_node.getAttribute(
        '_DesignDescription',
        null
      );
      appraisal.Attachment_Type__c = structure_node.getAttribute(
        'AttachmentType',
        null
      );

      DOM.XMLNode cooling_node = structure_node.getChildElement(
        'COOLING',
        null
      );

      if (cooling_node != null) {
        String coolingExists = cooling_Node.getAttribute(
          '_CentralizedIndicator',
          null
        );
        appraisal.Cooling__c = coolingExists == 'Y' ? true : false;
      }
    }

    DOM.XMLNode legal_node = property_node.getChildElement(
      '_LEGAL_DESCRIPTION',
      null
    );
    if (legal_node != null) {
      appraisal.Legal_Description__c = legal_node.getAttribute(
        '_TextDescription',
        null
      );
    }

    while (structure_node.getChildElement('AMENITY', null) != null) {
      DOM.XMLNode amenityNode = structure_node.getChildElement('AMENITY', null);

      String existsIndicator = amenityNode.getAttribute(
        '_ExistsIndicator',
        null
      );
      if (amenityNode.getAttribute('_Type', null) == 'Pool') {
        appraisal.pool__c = existsIndicator == 'Y' ? true : false;
      }

      structure_node.removeChild(amenityNode);
    }

    while (property_node.getChildElement('PROPERTY_ANALYSIS', null) != null) {
      DOM.XMLNode analysisNode = property_node.getChildElement(
        'PROPERTY_ANALYSIS',
        null
      );

      if (analysisNode.getAttribute('_Type', null) == 'QualityAndAppearance') {
        appraisal.Condition_Description__c = analysisNode.getAttribute(
          '_Comment',
          null
        );
      }

      if (
        analysisNode.getAttribute('_Type', null) == 'ConformsToNeighborhood'
      ) {
        appraisal.Conforms_to_Neighborhood__c = analysisNode.getAttribute(
          '_ExistsIndicator',
          null
        );
      }

      property_node.removeChild(analysisNode);
    }

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

      appraisal.Appraisal_Replacement_Cost_Value__c = String.isNotBlank(
          newImprovementTotalCostAmount
        )
        ? Decimal.ValueOf(
            newImprovementTotalCostAmount.replaceAll('[^0-9.]', '')
          )
        : null;

      Dom.XMLNode salesComparisonNode = valuationMethodsNOde.getChildElement(
        'SALES_COMPARISON',
        null
      );

      if (salesComparisonNode != null) {
        while (
          salesComparisonNode.getChildElement('COMPARABLE_SALE', null) != null
        ) {
          DOM.XMLNode compSaleNode = salesComparisonNode.getChildElement(
            'COMPARABLE_SALE',
            null
          );

          String saleamount = compSaleNode.getAttribute(
            'PropertySalesAmount',
            null
          );
          String sf = '';
          String carStorage = '';
          String condition = '';
          Decimal age = null;
          while (
            compSaleNode.getChildElement('SALE_PRICE_ADJUSTMENT', null) != null
          ) {
            DOM.XMLNode saleAdjustNode = compSaleNode.getChildElement(
              'SALE_PRICE_ADJUSTMENT',
              null
            );

            if (saleAdjustNode.getAttribute('_Type', null) == 'SiteArea') {
              sf = saleAdjustNode.getAttribute('_Description', null);
            } else if (
              saleAdjustNode.getAttribute('_Type', null) == 'CarStorage'
            ) {
              carStorage = saleAdjustNode.getAttribute('_Description', null);
            } else if (
              saleAdjustNode.getAttribute('_Type', null) == 'Condition'
            ) {
              condition = saleAdjustNode.getAttribute('_Description', null);
            } else if (saleAdjustnode.getAttribute('_Type', null) == 'Age') {
              //system.debug('--age sale price--');
              //system.debug(saleAdjustNode.getAttribute('_Description', null));
              //system.debug(saleAdjustNode.getAttribute('_Description', null).replaceAll('[^0-9.]', ''));
              if (
                String.isNotBlank(
                  saleAdjustNode.getAttribute('_Description', null)
                )
              ) {
                age = Decimal.valueOf(
                  saleAdjustNode.getAttribute('_Description', null)
                    .replaceAll('[^0-9.]', '')
                );
              }
            }

            compSaleNode.removeChild(saleAdjustNode);
          }
          if (
            compSaleNode.getAttribute('PropertySequenceIdentifier', null) == '0'
          ) {
            appraisal.Car_Storage__c = carStorage;
            appraisal.Condition__c = condition;
            appraisal.Age__c = age;
          } else if (
            compSaleNode.getAttribute('PropertySequenceIdentifier', null) == '1'
          ) {
            appraisal.Comp_1_Sales_Price__c = Decimal.valueOf(
              saleamount.replaceAll('[^0-9.]', '')
            );
            appraisal.Comp_1_Sq_Ft__c = sf;
          } else if (
            compSaleNode.getAttribute('PropertySequenceIdentifier', null) == '2'
          ) {
            appraisal.Comp_2_Sales_Price__c = Decimal.valueOf(
              saleamount.replaceAll('[^0-9.]', '')
            );
            appraisal.Comp_2_Sq_Ft__c = sf;
          } else if (
            compSaleNode.getAttribute('PropertySequenceIdentifier', null) == '3'
          ) {
            appraisal.Comp_3_Sales_Price__c = Decimal.valueOf(
              saleamount.replaceAll('[^0-9.]', '')
            );
            appraisal.Comp_3_Sq_Ft__c = sf;
          }

          salesComparisonNode.removeChild(compSaleNode);
        }
      }
    }

    Dom.XMLNode partiesNode = root.getChildElement('PARTIES', null);
    if (partiesNode != null) {
      Dom.XMLNode managementCompanyExtensionNode = partiesNode.getChildElement(
        'MANAGEMENT_COMPANY_EXTENSION',
        null
      );

      Dom.XMLNode lenderNode = partiesNode.getChildElement('LENDER', null);

      if (lenderNode != null) {
        Dom.XMLNode appraiserNode = lenderNode.getChildElement(
          'CONTACT_DETAIL',
          null
        );

        if (appraiserNode != null) {
          appraisal.Valuation_Provider__c = appraiserNode.getAttribute(
            '_Name',
            null
          );
        }
      }

      if (managementCompanyExtensionNode != null) {
        Dom.XMLNode mcesNode = managementCompanyExtensionNode.getChildElement(
          'MANAGEMENT_COMPANY_EXTENSION_SECTION',
          null
        );
        if (mcesNode != null) {
          DOM.XMLNode mcesdNode = mcesNode.getChildElement(
            'MANAGEMENT_COMPANY_EXTENSION_SECTION_DATA',
            null
          );
          if (mcesNode != null) {
            DOM.XMLNode managementNode = mcesdNode.getChildElement(
              'MANAGEMENT_COMPANY',
              null
            );

            appraisal.Management_Company_text__c = managementNode.getAttribute(
              'GSEManagementCompanyName',
              null
            );

            if (appraisal.Management_Company_text__c == 'NO AMC') {
              appraisal.Management_Company_text__c = 'Clarocity Valuation Services';
            }
          }
        }
      }
    }

    if (appraisal.Valuation_Provider__c == null) {
      appraisal.Valuation_Provider__c = appraisal.Management_Company_text__c;
    }
    //insert appraisal;

    switch on appraisal.Appraisal_Form__c {
      // Interior SFR/Townhome
      when 'FNM1004' {
        appraisal.Valuation_Type__c = 'Interior Appraisal';
      }
      // Interior Condo
      when 'FNM1073' {
        appraisal.Valuation_Type__c = 'Interior Appraisal';
        appraisal.Units__c = 1;
      }
      // 2-4 Unit
      when 'FNM1025' {
        appraisal.Valuation_Type__c = 'Interior Appraisal';
      }
      // Exterior SFR/Townhome
      when 'FNM2055' {
        appraisal.Valuation_Type__c = 'Exterior Appraisal';
      }
      // Exterior Condo
      when 'FNM1075' {
        appraisal.Valuation_Type__c = 'Exterior Appraisal';
        appraisal.Units__c = 1;
      }
      // Appraisal Update
      when 'FNM1004D' {
        appraisal.Valuation_Type__c = 'Addendum';
      }
      when 'Clarocity MVP' {
        appraisal.Valuation_Type__c = 'Clarocity MVP';
      }

      // when 'Clarocity MVP'
    }

    if (appraisal.Appraisal_Form__c == 'FNM1025') {
      Property__c childProperty = [
        SELECT Id, Name, Parent_Property__c
        FROM Property__c
        WHERE Id = :dealDocument.Property__c
        LIMIT 1
      ];

      if (childProperty.Parent_Property__c != null) {
        Property__c parent_property = [
          SELECT
            Id,
            Name,
            (SELECT id, name FROM properties__r ORDER BY Name ASC)
          FROM Property__c
          WHERE Id = :childProperty.Parent_Property__c
          LIMIT 1
        ];

        appraisal.Property__c = parent_property.Id;
        upsert appraisal;

        if (
          structure_node != null &&
          parent_property.properties__r.size() > 0
        ) {
          List<Appraisal__c> appraisals = new List<Appraisal__c>();
          for (Integer i = 0; i < parent_property.properties__r.size(); i++) {
            DOM.XMLNode unitNode = structure_node.getChildElement(
              '_UNIT_GROUP',
              null
            );
            if (unitNode != null) {
              system.debug(unitNode.getAttributeCount());

              if (unitNode.getAttributeCount() > 1) {
                Appraisal__c unitAppraisal = appraisal.clone(
                  false,
                  false,
                  false,
                  false
                );

                if (unitNode.getAttribute('TotalBedroomCount', null) != '') {
                  unitAppraisal.Bedrooms__c = Decimal.valueOf(
                    unitNode.getAttribute('TotalBedroomCount', null)
                      .replaceAll('[^0-9.]', '')
                  );
                }

                if (unitNode.getAttribute('TotalBathroomCount', null) != '') {
                  unitAppraisal.Baths__c = Decimal.valueOf(
                    unitNode.getAttribute('TotalBathroomCount', null)
                      .replaceAll('[^0-9.]', '')
                  );
                }

                if (
                  unitNode.getAttribute(
                    'GrossLivingAreaSquareFeetCount',
                    null
                  ) != ''
                ) {
                  unitAppraisal.Gross_Living_Area__c = Decimal.valueOf(
                    unitNode.getAttribute(
                        'GrossLivingAreaSquareFeetCount',
                        null
                      )
                      .replaceAll('[^0-9.]', '')
                  );
                }

                unitAppraisal.Property__c = parent_property.properties__r[i].Id;
                unitAppraisal.Property_Address__c =
                  appraisal.Property_Address__c +
                  ' Unit ' +
                  (i + 1); //parent_property.properties__r[i].Name;
                if (i != 0) {
                  unitAppraisal.Appraisal_Effective_Date__c = null;
                  unitAppraisal.Appraised_Value_Amount__c = null;
                  unitAppraisal.Units__c = null;
                  unitAppraisal.Year_Built__c = null;
                  // unitAppraisal.Appraisal_Form__c = null;
                  unitAppraisal.Condition__c = null;
                }
                appraisals.add(unitAppraisal);
              }
              structure_node.removeChild(unitNode);
            }
          }
          if (appraisals.size() > 0) {
            upsert appraisals;
          }
        }
      } else {
        Property__c parent_property = [
          SELECT
            Id,
            Name,
            (SELECT id, name FROM properties__r ORDER BY Name ASC)
          FROM Property__c
          WHERE Id = :dealDocument.Property__c
          LIMIT 1
        ];

        appraisal.Property__c = parent_property.Id;
        upsert appraisal;

        if (
          structure_node != null &&
          parent_property.properties__r.size() > 0
        ) {
          List<Appraisal__c> appraisals = new List<Appraisal__c>();
          for (Integer i = 0; i < parent_property.properties__r.size(); i++) {
            DOM.XMLNode unitNode = structure_node.getChildElement(
              '_UNIT_GROUP',
              null
            );
            if (unitNode != null) {
              system.debug(unitNode.getAttributeCount());

              if (unitNode.getAttributeCount() > 1) {
                Appraisal__c unitAppraisal = appraisal.clone(
                  false,
                  false,
                  false,
                  false
                );

                if (unitNode.getAttribute('TotalBedroomCount', null) != '') {
                  unitAppraisal.Bedrooms__c = Decimal.valueOf(
                    unitNode.getAttribute('TotalBedroomCount', null)
                      .replaceAll('[^0-9.]', '')
                  );
                }

                if (unitNode.getAttribute('TotalBathroomCount', null) != '') {
                  unitAppraisal.Baths__c = Decimal.valueOf(
                    unitNode.getAttribute('TotalBathroomCount', null)
                      .replaceAll('[^0-9.]', '')
                  );
                }

                if (
                  unitNode.getAttribute(
                    'GrossLivingAreaSquareFeetCount',
                    null
                  ) != null &&
                  unitNode.getAttribute(
                    'GrossLivingAreaSquareFeetCount',
                    null
                  ) != ''
                ) {
                  unitAppraisal.Gross_Living_Area__c = Decimal.valueOf(
                    unitNode.getAttribute(
                        'GrossLivingAreaSquareFeetCount',
                        null
                      )
                      .replaceAll('[^0-9.]', '')
                  );
                }

                unitAppraisal.Property__c = parent_property.properties__r[i].Id;
                unitAppraisal.Property_Address__c =
                  appraisal.Property_Address__c +
                  ' Unit ' +
                  (i + 1); //parent_property.properties__r[i].Name;
                if (i != 0) {
                  unitAppraisal.Appraisal_Effective_Date__c = null;
                  unitAppraisal.Appraised_Value_Amount__c = null;
                  unitAppraisal.Units__c = null;
                  unitAppraisal.Year_Built__c = null;
                  // unitAppraisal.Appraisal_Form__c = null;
                  unitAppraisal.Condition__c = null;
                }
                appraisals.add(unitAppraisal);
              }
              structure_node.removeChild(unitNode);
            }
          }
          if (appraisals.size() > 0) {
            upsert appraisals;
          }
        }
      }
    } else {
      upsert appraisal;
    }

    //Dom.XMLNode EMBEDDED_FILE = root.getChildElement('REPORT', null)
    //.getChildElement('EMBEDDED_FILE', null);
    //if (EMBEDDED_FILE != null) {
    //DOM.XMLNode fileNode = EMBEDDED_FILE.getChildElement('DOCUMENT', null);

    // ContentVersion pdfFile = new ContentVersion();
    // pdfFile.Title = 'AppraisalReport';
    // pdfFIle.PathOnClient = 'AppraisalReport.pdf';
    // pdfFile.ContentLocation = 'S';
    // pdfFile.VersionData = EncodingUtil.base64Decode(fileNode.getText());
    // //if(String.isNotBlank(Network.getNetworkId())){
    // //pdfFile.NetworkId = Network.getNetworkId();
    // User u = [SELECT Id, ContactId FROM User WHERE ID =: UserInfo.getUserId()];

    // if(String.isNotBlank(u.ContactId)){
    //   pdfFile.NetworkId = '0DB0a000000fxevGAA';
    // }
    // //
    // //}

    // insert pdfFile;

    // ContentVersion newCV = [
    //   SELECT Id, ContentDocumentId
    //   FROM ContentVersion
    //   WHERE ID = :pdfFile.Id
    // ];

    // List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
    // cdls.add(
    //   new ContentDocumentLink(
    //     ContentDocumentId = dealDocument.Attachment_Id__c,
    //     LinkedEntityId = appraisal.Id,
    //     ShareType = 'V',
    //     Visibility = 'AllUsers'
    //   )
    // );
    // cdls.add(
    //   new ContentDocumentLink(
    //     ContentDocumentId = newCV.ContentDocumentId,
    //     LinkedEntityId = appraisal.Id,
    //     ShareType = 'V',
    //     Visibility = 'AllUsers'
    //   )
    // );
    // insert cdls;
    //}
  }

  // This section will parse the BBG XML Appraisals
  public static void parseXMLBBG(
    Dom.Document doc,
    Appraisal__c appraisal,
    Deal_Document__c dealDocument
  ) {
    DOM.XMLNode propertyValuationNode = doc.getRootElement();
    Property__c prop = [
      SELECT Id, Parent_Property__c
      FROM Property__c
      WHERE Id = :appraisal.Property__c
    ];
    if (prop.Parent_Property__c != null) {
      appraisal.Property__c = prop.Parent_Property__c;
    }

    DOM.XmlNode appraisalProviderNode = propertyValuationNode.getChildElement(
      'FirmName',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    if (appraisalProviderNode != null) {
      appraisal.Valuation_Provider__c = appraisalProviderNode.getText();
    }

    DOM.XmlNode appraisalTypeNode = propertyValuationNode.getChildElement(
      'AppraisalTypeCd',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    if (appraisalTypeNode != null) {
      appraisal.Valuation_Type__c = appraisalTypeNode.getText();
    }

    DOM.XmlNode addressNode = propertyValuationNode.getChildElement(
      'Address1',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Property_Address__c = addressNode.getText();

    DOM.XmlNode cityNode = propertyValuationNode.getChildElement(
      'City',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.City__c = cityNode.getText();

    DOM.XmlNode stateNode = propertyValuationNode.getChildElement(
      'StateCd',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.State__c = stateNode.getText();

    DOM.XmlNode zipNode = propertyValuationNode.getChildElement(
      'ZipCode',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Zip__c = zipNode.getText();

    DOM.XmlNode countyNode = propertyValuationNode.getChildElement(
      'County',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.County__c = countyNode.getText();

    DOM.XmlNode grossLandArea = propertyValuationNode.getChildElement(
      'GrossLandArea',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Lot_Area__c = grossLandArea.getText();

    DOM.XmlNode msaNode = propertyValuationNode.getChildElement(
      'MSA',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    if (msaNode != null) {
      appraisal.MSA__c = msaNode.getText();
    }

    DOM.XmlNode zoningClassificationNOde = propertyValuationNode.getChildElement(
      'Zoning',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Zoning_Classification__c = propertyValuationNode.getText();

    DOM.XmlNode zoningComplianceNode = propertyValuationNode.getChildElement(
      'ZoningComplianceCd',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Zoning_Compliance__c = zoningComplianceNode.getText();

    DOM.XmlNode zoningDescriptingNode = propertyValuationNode.getChildElement(
      'ZoningComments',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Zoning_Description__c = zoningDescriptingNode.getText();

    DOM.XmlNode yearBuiltNode = propertyValuationNode.getChildElement(
      'YearBuilt',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Year_Built__c = yearBuiltNode.getText();

    DOM.XmlNode unitsNode = propertyValuationNode.getChildElement(
      'Units',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Units__c = Decimal.ValueOf(unitsNode.getText());

    DOM.XmlNode apnNode = propertyValuationNode.getChildElement(
      'AssessorParcelNumber',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.APN_Assessor_s_Parcel__c = apnNode.getText();

    DOM.XmlNode conditionNode = propertyValuationNode.getChildElement(
      'OverallConditionCd',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Condition__c = conditionNode.getText();

    DOM.XmlNode conditionDescNode = propertyValuationNode.getChildElement(
      'PropertyComments',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Condition_Description__c = conditionDescNode.getText();

    Dom.XMLNode appraisalNode = propertyValuationNode.getChildElement(
      'Appraisal',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    Dom.XmlNode appraisalValues = appraisalNode.getChildElement(
      'AppraisalValues',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    //Date appraisalDate = null;
    appraisal.This_Appraisal_Is_Made__c = 'As Is';

    DOM.XmlNode appraisedAmountNode = appraisalNode.getChildElement(
      'FinalAppraisedValue',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    Decimal finalAppraisedValue = appraisedAmountNode != null
      ? Decimal.ValueOf(appraisedAmountNode.getText())
      : null;

    while (
      appraisalValues.getChildElement(
        'AppraisalValue',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      ) != null
    ) {
      DOM.XMLNode AppraisalValueNode = appraisalValues.getChildElement(
        'AppraisalValue',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      );

      DOM.XmlNode appraisalEffectiveDateNode = appraisalValueNode.getChildElement(
        'ValueAsOfDate',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      );

      Date appraisalEffectiveDate = Date.valueOf(
        appraisalEffectiveDateNode.getText()
      );

      DOM.XmlNode valueCDNode = AppraisalValueNode.getChildElement(
        'ValueCd',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      );
      String valueCd = valueCDNode.getText();

      DOM.XmlNOde valueMethodCDNode = AppraisalValueNode.getChildElement(
        'ValueMethodCd',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      );
      String appraisedValueMethodCD = valueMethodCDNode.getText();

      Dom.XmlNOde appraisedValueNode = appraisalValueNode.getChildElement(
        'AppraisedValue',
        'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
      );

      String appraisedValue = appraisedValueNode == null
        ? null
        : appraisedValueNode.getText();

      if (
        valueCd.containsIgnoreCase('As Is') && appraisedValueMethodCD == 'IC'
      ) {
        appraisal.Appraisal_Effective_Date__c = appraisalEffectiveDate;
        appraisal.Appraised_Value_Amount__c = appraisedValue == null
          ? finalAppraisedValue
          : Decimal.valueOf(appraisedValue);
      } else if (
        valueCd.containsIgnoreCase('As Is') && appraisedValueMethodCD == 'SC'
      ) {
        appraisal.Appraisal_Effective_Date__c = appraisalEffectiveDate;
        appraisal.Appraised_Value_Amount__c = appraisedValue == null
          ? finalAppraisedValue
          : Decimal.valueOf(appraisedValue);
      }

      if (valueCd == 'As Complete' && appraisedValueMethodCD == 'IC') {
        appraisal.Appraised_After_Repair_Value__c = appraisedValue == null
          ? finalAppraisedValue
          : Decimal.valueOf(appraisedValue);
        appraisal.This_Appraisal_Is_Made__c = 'As Repaired';
      }

      if (
        valueCd == 'As Complete & Stabilized Encumbered' &&
        appraisedValueMethodCD == 'IC'
      ) {
        appraisal.Appraised_After_Repair_Value__c = appraisedValue == null
          ? finalAppraisedValue
          : Decimal.valueOf(appraisedValue);
        appraisal.This_Appraisal_Is_Made__c = 'As Repaired';
      }

      if (
        valueCd.containsIgnoreCase('As Stabilized') &&
        appraisedValueMethodCD == 'IC'
      ) {
        appraisal.Appraised_As_Stabilized_Value__c = appraisedValue == null
          ? finalAppraisedValue
          : Decimal.valueOf(appraisedValue);
      }

      // if(appraisaedValueAmont == 'As Complete' && appraisedValueMethod == '')

      // if (appraisalDate == null || appraisalDate < appraisalEffectiveDate) {
      //   appraisalDate = appraisalEffectiveDate;

      //   appraisal.Appraisal_Effective_Date__c = appraisalEffectiveDate;

      //   appraisal.This_Appraisal_Is_Made__c = appraisedValueAmount;
      // }

      appraisalValues.removeChild(AppraisalValueNode);
    }

    // appraisal.Appraised_Value_Amount__C = Decimal.ValueOf(
    //   appraisedAmountNode.getText()
    // );

    DOM.XmlNode appraisalCompletionNode = appraisalNode.getChildElement(
      'AppraisalDate',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );

    appraisal.Appraisal_Completion_Date__c = Date.valueOf(
      appraisalCompletionNode.getText()
    );

    // appraisal.Appraisal_Effective_Date__c = Date.valueOf(
    //   appraisalEffectiveDateNode.getText()
    // );

    DOM.XmlNode grossLivingNOde = propertyValuationNode.getChildElement(
      'GrossBuildingArea',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Gross_Living_Area__c = Decimal.ValueOf(grossLivingNOde.getText());

    DOM.XmlNode floodZoneNode = propertyValuationNode.getChildElement(
      'FloodZoneCd',
      'http://schemas.datacontract.org/2004/07/CJC.Xpi.Vendor.Models'
    );
    appraisal.Flood_Zone__c = floodZoneNode.getText();

    Map<String, String> stateMap = new Map<String, String>{
      'Alabama' => 'AL',
      'Alaska' => 'AK',
      'Arizona' => 'AZ',
      'Arkansas' => 'AR',
      'California' => 'CA',
      'Colorado' => 'CO',
      'Connecticut' => 'CT',
      'Delaware' => 'DE',
      'Washington DC' => 'DC',
      'Florida' => 'FL',
      'Georgia' => 'GA',
      'Hawaii' => 'HI',
      'Idaho' => 'ID',
      'Illinois' => 'IL',
      'Indiana' => 'IN',
      'Iowa' => 'IA',
      'Kansas' => 'KS',
      'Kentucky' => 'KY',
      'Louisiana' => 'LA',
      'Maine' => 'ME',
      'Maryland' => 'MD',
      'Massachusetts' => 'MA',
      'Michigan' => 'MI',
      'Minnesota' => 'MN',
      'Mississippi' => 'MS',
      'Missouri' => 'MO',
      'Montana' => 'MT',
      'North Dakota' => 'ND',
      'Nebraska' => 'NE',
      'New Hampshire' => 'NH',
      'New Jersey' => 'NJ',
      'New Mexico' => 'NM',
      'Nevada' => 'NV',
      'New York' => 'NY',
      'North Carolina' => 'NC',
      'Ohio' => 'OH',
      'Oklahoma' => 'OK',
      'Oregon' => 'OR',
      'Pennsylvania' => 'PA',
      'Rhode Island' => 'RI',
      'South Carolina' => 'SC',
      'South Dakota' => 'SD',
      'Tennessee' => 'TN',
      'Texas' => 'TX',
      'Utah' => 'UT',
      'Vermont' => 'VT',
      'Virginia' => 'VA',
      'Washington' => 'WA',
      'West Virginia' => 'WV',
      'Wisconsin' => 'WI',
      'Wyoming' => 'WY'
    };

    appraisal.State__c = stateMap.get(appraisal.State__c);

    upsert appraisal;
  }

  public static void sendXMLDownloadErrorEmail() {
    return;
  }
}