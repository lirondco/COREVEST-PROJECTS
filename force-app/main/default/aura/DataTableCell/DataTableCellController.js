({
    doInit : function( component, event, helper ) {

        //console.log('--cell init--');

        var row = component.get( 'v.row' );


        console.log('rows:::: datatable cell:::',row);
        console.log('Clear_Result__c:::: datatable cell:::',row['Clear_Result__r']);
		
        var clearResult = row['Clear_Result__r'];
        if(clearResult != '' && clearResult != null){
            //component.set('v.class','slds-alert_error');
            
            var classname = component.get('v.class');
            console.log('classname::::',classname);
            //component.set('v.class', className + ' slds-alert_error')
             
        }
        
        var column = component.get( 'v.column' );
        if($A.util.isEmpty(column.get('v.isReadable'))) {
            component.set('v.isReadable', true);
        } else { 
            let key = column.get('v.isReadable');
            let childKey;
            if(key.includes('.')) {
                key = key.split('.')[0];
                childKey = key.split('.')[1];
            }
            if(row.hasOwnProperty(key)) {
                let value;
                if(childKey != null){
                    value = row[key][childKey];
                } else {
                    value = row[key];
                }
                
                component.set('v.isReadable', value);
            }
        }
        //console.log(!$A.util.isEmpty(row['Parent_Property__c']));
        //console.log(column.get('v.name'))

        //if(column.)

        component.set('v.displayType', column.get('v.displayType'));
        component.set('v.userAccountVendorType', column.get('v.userAccountVendorType'));
        component.set('v.isEditable', column.get('v.isEditable'));
        // component.set('v.isReadable', column.get('v.isReadable'));
        if(component.get('v.displayType') == 'select' ){
            var select = component.find('select');
            select.set('v.options', column.get('v.selectOptions'));
        }
        // the column's name might be a single property on the object
        // like 'Subject' or it might be a compound reference
        // like 'Who.Name' so we split the string into its parts
        // and try to traverse the object graph through the properties.
        //
        // if the row does not have the full property graph
        // then null is returned, otherwise the value at the end of the rainbow.
        component.set( 'v.value', helper.parseFieldValue( component, row, column.get( 'v.name' ) ) );



        if(component.get('v.displayType') == 'select' ){
            var select = component.find('select');

            var opts = JSON.parse(JSON.stringify(column.get('v.selectOptions')));

            select.set('v.options', opts);
        }
        component.set( 'v.oldValue', component.get('v.value'))
        // set css class from column definition
        component.set( 'v.class', column.get( 'v.valueClass' ) );

        if(!$A.util.isEmpty(row['Parent_Property__c']) && column.get('v.name') == 'Name' ){
            var className = component.get('v.class');
            component.set('v.class', className + ' indent')
        }



        // determine ui theme
        //var uiTheme = helper.getUITheme();
        //component.set( 'v.uiTheme', uiTheme );
        uiTheme = 'Lightning';
        // determine type of links to use
        var linkToRecord = column.get( 'v.linkToRecord' );
        var linkToURL = column.get( 'v.linkToURL' );
        
                // if linking to a record we first check if the expression evaluates to a field on the row object
        // that holds the value to link to, otherwise will use the value as-is for linking.
        // since this is intended to be an sobject record id, for classic theme only then we ensure
        // there's a leading '/'.
        if ( !$A.util.isEmpty( linkToRecord ) && $A.util.isEmpty( linkToURL ) ) {
            
            var parsedLinkToRecord = helper.parseFieldValue( component, row, linkToRecord );

            if ( !$A.util.isUndefinedOrNull( parsedLinkToRecord ) ) {
                component.set( 'v.linkToRecord', ( uiTheme === 'Classic' ? '/' : '' ) + parsedLinkToRecord );
            } else {
                component.set( 'v.linkToRecord', ( uiTheme === 'Classic' ? '/' : '' ) + linkToRecord );
            }

            if ( uiTheme === 'Classic' ) {
                component.set( 'v.classicLink', component.get( 'v.linkToRecord' ) );
            }

        }else
        // if linking to a record we first check if the expression evaluates to a field on the row object
        // that holds the value to link to, otherwise will use the value as-is for linking
        if ( !$A.util.isEmpty( linkToURL ) && $A.util.isEmpty( linkToRecord ) ) {

            var parsedLinkToURL = helper.parseFieldValue( component, row, linkToURL );

            if ( !$A.util.isUndefinedOrNull( parsedLinkToURL ) ) {
                component.set( 'v.linkToURL', parsedLinkToURL );
            } else {
                component.set( 'v.linkToURL', linkToURL );
            }

            if ( uiTheme === 'Classic' ) {
                component.set( 'v.classicLink', component.get( 'v.linkToURL' ) );
            }

        }else if( !$A.util.isEmpty( linkToURL ) && !$A.util.isEmpty( linkToRecord )){
            var parsedLinkToRecord = helper.parseFieldValue( component, row, linkToRecord );
            //console.log(linkToRecord);
            //console.log(linkToURL);
            //console.log(parsedLinkToRecord);
            // if ( !$A.util.isUndefinedOrNull( parsedLinkToURL ) ) {
            //     component.set( 'v.linkToURL', parsedLinkToURL );
            // } else {
            //     component.set( 'v.linkToURL', linkToURL );
            // }

            // if ( uiTheme === 'Classic' ) {
            //     component.set( 'v.classicLink', component.get( 'v.linkToURL' ) );
            // }

            component.set('v.classicLink', linkToURL + parsedLinkToRecord);
            component.set('v.linkToURL', linkToURL + parsedLinkToRecord);
            // console.log(component.get('v.classicLink'))
        }



        //var autocomplete_attributes
        if(column.get('v.displayType') == 'lookup'){
            component.set('v.lookup', JSON.parse(JSON.stringify(column.get('v.lookup'))) );
            //console.log('--v.lookup--');
            //console.log(component.get('v.lookup'));

        }
        //console.log('--lookup--');
        //console.log(component.get('v.lookup'));


    },

    handleChange : function(component, event, helper){
        //console.log(component.get('v.value'))

        var oldValue = event.getParam('oldValue');
        var currentValue = event.getParam('value');

        if(oldValue != currentValue){
            //console.log('value changed');
            //console.log(currentValue);

            helper.bindValue(component, currentValue);
        }

    },

    toggleEdit : function(component, event, helper){
        //console.log('double click');
        if(component.get('v.isEditable')){
            component.set('v.editMode', true);
        }

    },

    handleReview : function(component, event, helper){
        const recId = event.getSource().get("v.value");
        const cmpEvent = component.getEvent("reviewEvent");
        cmpEvent.setParams({
            'documentId' : recId
        });
        cmpEvent.fire();
    },


    /**
     * For Salesforce1 and Lightning themes, action handler
     * for navigating to record or arbitrary URL.
     */
    handleOnClick : function( component, event, helper ) {

        var linkToRecord = component.get( 'v.linkToRecord' );
        var linkToURL = component.get( 'v.linkToURL' );

        if ( !$A.util.isUndefinedOrNull( linkToRecord ) ) {
            helper.navigateToRecord( linkToRecord );
        } else if ( !$A.util.isUndefinedOrNull( linkToURL ) ) {
            helper.navigateToURL( linkToURL );
        } else {
            console.warn( 'Unexpected click event. No value for v.linkToRecord or v.linkToURL' );
            console.log( event );
        }

    },

    toggleCellFocus : function( component, event, helper){
        var cell = component.find('cell');
        $A.util.toggleClass(cell, 'slds-has-focus');
    },

    viewFile : function(component, event, helper){
        $A.get('e.lightning:openFiles').fire({
            recordIds: [component.get("v.value")]
        });
    },

    lookupClick : function(component, event, helper){
        if(!$A.util.isUndefinedOrNull(component.get('v.value'))){
            helper.navigateToRecord ( component.get('v.value') );
        }
    }
})