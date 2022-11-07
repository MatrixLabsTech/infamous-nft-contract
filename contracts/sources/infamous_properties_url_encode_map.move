module infamous::infamous_properties_url_encode_map {

    use std::signer;
    use std::error;
    use std::string::{String };
    use std::vector;


    use aptos_std::table::{Self, Table};


    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;


    const ELENGTH_NOT_EQUAL: u64 = 1;
    const EACCOUNT_MUSTBE_AUTHED: u64 = 2;
    const EPROPORTY_URL_ENCODE_NOT_SET: u64 = 3;


    struct PropertyValueUrlMap has key {
        properties: Table<String, String>
    }


    public entry fun set_property_map(sender: &signer, 
    property_values: vector<String>, 
    property_url_encodes: vector<String>) acquires PropertyValueUrlMap {
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let property_values_len = vector::length<String>(&property_values);
        let property_encode_len = vector::length<String>(&property_url_encodes);

        assert!(property_values_len == property_encode_len, error::invalid_argument(ELENGTH_NOT_EQUAL));


        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        if(!exists<PropertyValueUrlMap>(manager_addr)) {
            move_to(&manager_signer, PropertyValueUrlMap {
                properties: table::new<String, String>(),
            });
        };

        let properties_mut = &mut borrow_global_mut<PropertyValueUrlMap>(manager_addr).properties;

        let i = 0;
        while (i < property_values_len) {
            let property_value = *vector::borrow<String>(&property_values, i);
            let property_url_encode = *vector::borrow<String>(&property_url_encodes, i);
            if(table::contains(properties_mut, property_value)){
                table::remove(properties_mut, property_value);
            };
            table::add(properties_mut, property_value, property_url_encode);
            i = i + 1;
        }
    }

    public fun get_property_value_encode(property_value: String): String acquires PropertyValueUrlMap {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<PropertyValueUrlMap>(manager_addr), error::invalid_state(EPROPORTY_URL_ENCODE_NOT_SET));
        let properties = &borrow_global<PropertyValueUrlMap>(manager_addr).properties;
        *table::borrow(properties, property_value)
    }

    
    #[test_only]
    public fun initialize(user: &signer) acquires PropertyValueUrlMap {
        use std::string::{ utf8 };
        
        set_property_map(
            user,
            vector<String>[utf8(b"femalegenderfemale"), utf8(b"femalebackgroundblue"), utf8(b"femaleclothinghoodie"), utf8(b"femaleearringsnull"), utf8(b"femaleeyebrowsextended eyebrowss"), 
            utf8(b"femaleface-accessoriesnull"), utf8(b"femaleeyesblack eyes"), utf8(b"femalehairbob cut 1 (navy blue)"), utf8(b"femalemouthclosed"), 
            utf8(b"femalenecklacenull"), utf8(b"femaletattoonull"), utf8(b"femaleweapondagger"), 
            utf8(b"femalegradeiron"), utf8(b"femaleweaponkarambit"), utf8(b"femaleweaponrevolver")], 
            vector<String>[utf8(b"0"), utf8(b"0"), utf8(b"0"), utf8(b"0"), utf8(b"0"), 
            utf8(b"0"), utf8(b"0"), utf8(b"0"), utf8(b"0"), 
            utf8(b"0"), utf8(b"0"), utf8(b"0"), 
            utf8(b"0"), utf8(b"1"), utf8(b"2")]
        );

    }

       
    #[test(framework = @0x1, user = @infamous, manager = @0xBB)]
    public fun set_test(user: &signer, manager: &signer, framework: &signer) acquires PropertyValueUrlMap { 

        use aptos_framework::account; 
        use infamous::infamous_backend_auth;
        use aptos_framework::timestamp;
        use std::string::{ utf8 };
        

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        let manager_addr = signer::address_of(manager);
        account::create_account_for_test(manager_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_backend_auth::delegate(user, manager_addr);



        set_property_map(
            user,
            vector<String>[utf8(b"femalebackgroundblue"), utf8(b"femaleeyeblack")], 
            vector<String>[utf8(b"00"), utf8(b"01")]
        );


        assert!(get_property_value_encode(utf8(b"femalebackgroundblue")) == utf8(b"00"), 1);
        assert!(get_property_value_encode(utf8(b"femaleeyeblack")) == utf8(b"01"), 1);

    }



}