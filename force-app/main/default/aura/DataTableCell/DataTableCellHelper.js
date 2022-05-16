({
    /**
     * Retrieves the field value from the JSON object
     * using dot notation to traverse the object graph.
     * If any part of the field path is not accessible then returns null.
     *
     * @param obj
     *      The JSON object (e.g. { 'Account' : { 'Name' : 'Burlington' } } )
     * @param fieldPath
     *      Uses dot notation to represent the JSON field value to retrieve (e.g. 'Account.Name' )
     */
	parseFieldValue : function( component, obj, fieldPath ) {

        var fields = fieldPath.split( '.' );
        console.log('fields:::::',fields);
        var value = null;
        console.log(obj);
        if ( obj.hasOwnProperty( fields[0] ) ) {

            value = obj[fields[0]];
			
            if ( fields.length > 1 ) {

                for ( var i = 1; i < fields.length; i++ ) {
                    if ( value != null && value.hasOwnProperty( fields[i] ) ) {
                        value = value[fields[i]];
                        console.log('vafields[i]e::',fields[i]);
                        if(fields[i] == 'Risk_Number__c'){
                            var riskNumber = component.set("v.riskNumber", true);
            				console.log('truthy::::', component.get( 'v.riskNumber' ));
                            console.log('value:::value',value);
                            if(value >= 1 && value <= 20){
                                component.set('v.addcss','changeColorgreen');
                            }
                            if(value >= 21 && value <= 50){
                                component.set('v.addcss','changeColorYellow');
                            }
                            if(value >= 51){
                                component.set('v.addcss','changeColorRed');
                            }
                            console.log('slds-alert_error::::',component.get('v.addcss'));
                        } else if (fields[i] == 'isReadable') {
                            console.log('isreadable:::value',value);
                            component.set('v.isReadable', value);
                        }
                    
                    } else {
                        value = null;
                        break;
                    }
                }

            }  else if (fields[i] == 'isReadable' ) {
                console.log('isreadable:::value',value);
                component.set('v.isReadable', value);
            }
        }else{
            //console.log(fields[0]);
            obj[fields[0]] = '';
            component.set('v.record', JSON.parse(JSON.stringify(obj)));

        }
        return value;
	},

    bindValue : function(component, value){
        //  console.log('--bind value--');
        // console.log(value);
        var row = component.get('v.row');
        var fieldPath = component.get('v.column').get('v.name');

        // console.log(row);
        // console.log(fieldPath);

        var fields = fieldPath.split('.');

        if( row.hasOwnProperty(fields[0]) ){
            //row[fields[0]] = value;

            var obj = row[fields[0]];
            if(fields.length > 1){
                // for(var i = 1; i < fields.length; i++){
                //     //if(  )
                // }
                row[fields[0]][fields[1]] = value;
            }else{
                row[fields[0]] = value;
            }
        }

        // component.set('v.row', JSON.parse(JSON.stringify(row)));
    },

    // ----------------------------------------------------------------------------

    /**
     * Quick and dirty check to determine if code is running in
     *      - Classic
     *      - Salesforce1
     *      - Lightning
     * based on the existence of certain features.
     */
    getUITheme : function() {

        var theme = null;

        var event = $A.get( 'e.force:navigateToSObject' );

        if ( event ) {

            theme = 'Lightning';

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            theme = 'Salesforce1';

        } else {

            theme = 'Classic'

        }

        return theme;
    },

    navigateToRecord : function( recordId ) {

        console.log( 'navigating to record: ' + recordId );

        var event = $A.get( 'e.force:navigateToSObject' );

        if ( event ) {

            event.setParams({
                'recordId' : recordId
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToSObject( recordId );

        } else {

            window.location.href = '/' + recordId;

        }

    },

    navigateToURL : function( url ) {

        console.log( 'navigating to url: ' + url );

        var event = $A.get( 'e.force:navigateToURL' );

        if ( event ) {

            event.setParams({
                'url' : url
            }).fire();

        } else if ( ( typeof sforce !== 'undefined' ) && ( typeof sforce.one !== 'undefined' ) ) {

            sforce.one.navigateToURL( url );

        } else {

            window.location.href = url;

        }

    }
})