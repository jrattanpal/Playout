({
    displayMessages: function(component, helper, serverMessages){
        //Show success messages (if any)
        if(!$A.util.isUndefined(serverMessages) && !$A.util.isUndefined(serverMessages.Information)){
            var messages = Array();
            for(var i=0; i<serverMessages.Information.length; i++){
                messages.push(
                    ["markup://ui:message", {
                        'severity': 'information',
                        'body': serverMessages.Information[i],
                        'closable': true
                    }]
                );
            }

            component.find('utils').createComponents(messages, component.find('uiMessage'));
        }
    },
    removeFields: function(component, helper, field) {
        // if (helper.isValidate(component, helper) == true){

        var selectField = component.get('v.selectField');
        var orderField = component.get('v.orderField');

        var apexBridge = component.find("ETLC_ApexBridge");
        apexBridge.callApex({
            component: component,
            request: {
                controller: "Playout_Controller",
                method: "removeFields",
                input: {
                    'field': field,
                    'sObjectName': component.get('v.sObjectName')
                },
                doesCallout: false
            },
            forceRefresh: true,
            pleaseWait: {
                type: "None",
            },
            callBackMethod: function (serverResponse) {
                component.find('utils').log('Playout_Fields:h.removeFields:serverResponse:', serverResponse);

                if(!$A.util.isUndefined(serverResponse.messages) && !$A.util.isUndefined(serverResponse.messages.Information)){
                    var messages = Array();
                    for(var i=0; i<serverResponse.messages.Information.length; i++){
                        messages.push(
                            ["markup://ui:message", {
                                'severity': 'information',
                                'body': serverResponse.messages.Information[i],
                                'closable': true
                            }]
                        );
                    }
                    component.find('utils').createComponents(messages, component.find('uiMessage'));
                }

                var cmpEvent = component.getEvent('Evt_UserFieldsChanged');
                component.find('utils').log('Playout_Fields:h.saveFields:Firing Evt_UserFieldsChanged');
                cmpEvent.fire();
                component.find('utils').log('Playout_Fields:h.saveFields:Fired Evt_UserFieldsChanged');
            },
            errorHandler: function (serverResponse) {
                console.error('ERROR serverResponse:', serverResponse);
            }
        });
    },
    saveFields: function(component, helper) {
        // if (helper.isValidate(component, helper) == true){

        var selectField = component.get('v.selectField');
        var orderField = component.get('v.orderField');

        var apexBridge = component.find("ETLC_ApexBridge");
        apexBridge.callApex({
            component: component,
            request: {
                controller: "Playout_Controller",
                method: "saveFields",
                input: {
                    'field': selectField,
                    'order': orderField,
                    'sObjectName': component.get('v.sObjectName')
                },
                doesCallout: false
            },
            forceRefresh: true,
            pleaseWait: {
                type: "None",
            },
            callBackMethod: function (serverResponse) {
                component.find('utils').log('aseFieldManager_Fields:h.saveFields:serverResponse:', serverResponse);
                component.set('v.fields', serverResponse.output);

                if(!$A.util.isUndefined(serverResponse.messages) && !$A.util.isUndefined(serverResponse.messages.Information)){
                    var messages = Array();
                    for(var i=0; i<serverResponse.messages.Information.length; i++){
                        messages.push(
                            ["markup://ui:message", {
                                'severity': 'information',
                                'body': serverResponse.messages.Information[i],
                                'closable': true
                            }]
                        );
                    }
                    component.find('utils').createComponents(messages, component.find('uiMessage'));
                }
                var cmpEvent = component.getEvent('Evt_UserFieldsChanged');

                component.find('utils').log('Playout_Fields:h.saveFields:Firing Evt_UserFieldsChanged');
                cmpEvent.fire();
                component.find('utils').log('Playout_Fields:h.saveFields:Fired Evt_UserFieldsChanged');
            },
            errorHandler: function (serverResponse) {
                console.error('ERROR serverResponse:', serverResponse);
            }
        });
    },
    isValid: function(component, helper){
        var retValue = false;
        var selectField = component.get('v.selectField');
        var orderField = component.get('v.orderField');
        var userFields = component.get('v.userFields');


        component.find('utils').log('Playout_Fields:helper.isValid():namespace::', component.get('v.namespace'));
        component.find('utils').log('Playout_Fields:helper.isValid():selectField::', selectField);
        component.find('utils').log('Playout_Fields:helper.isValid():orderField::', orderField);
        component.find('utils').log('Playout_Fields:helper.isValid():userFields::', userFields);

        var message = Array();

        if ($A.util.isEmpty(selectField) || (selectField == '-1') || $A.util.isEmpty(orderField) || isNaN(orderField)) {
            message.push(
                ["markup://ui:message", {
                    'severity': 'error',
                    'body': 'Please select a field or provide order#',
                    'closable': true
                }]
            );
            component.find('utils').createComponents(message, component.find('uiMessage'));
        } else {
            //Check if the selected field is already on user list
            var userFieldsAsMap = [];
            for(var i=0; i < userFields.length; i++){
                //Using "order" as value to check if order changes when we try to submit same field again
                //If order is same and field is already on list then we should skip Apex call to save server time
                userFieldsAsMap[userFields[i]['apiname']] =
                    userFields[i]['order'];
            }

            //If field already exists in the list AND order is NOT different then we don't need to make any Apex calls
            if(!$A.util.isUndefined(userFieldsAsMap) && !$A.util.isUndefined(userFieldsAsMap[selectField])
                    && (userFieldsAsMap[selectField] == orderField)){
                message.push(
                    ["markup://ui:message", {
                        'severity': 'error',
                        'body': 'This field has already been selected',
                        'closable': true
                    }]
                );
                component.find('utils').createComponents(message, component.find('uiMessage'));
            }else if(userFields.length >= component.get('v.maxAllowedFields')){
                message.push(
                    ["markup://ui:message", {
                        'severity': 'error',
                        'body': 'Maximum allowed fields limit ('+ component.get('v.maxAllowedFields') + ') has reached. Contact your administrator to increase limit.',
                        'closable': true
                    }]
                );
                component.find('utils').createComponents(message, component.find('uiMessage'));
            }else{

                retValue = true;
            }

        }
        return retValue;
    },
})