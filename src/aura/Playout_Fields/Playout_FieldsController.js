({
    saveFields: function(component, event, helper){
        //Clear error message first (if any)
        component.find('utils').destroyComponents(component.find('uiMessage'));


        if(helper.isValid(component, helper) == true){
            helper.saveFields(component, helper);
        }


    },
    removeFields: function(component, event, helper){
        var button = event.getSource();
        helper.removeFields(component, helper, button.get('v.value'));
    }
})