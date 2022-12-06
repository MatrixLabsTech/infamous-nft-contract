/// This module provides Infamous Accessory Token binding functions.
/// InfamousChangeAccessory used to change infamous accessory property & bind accessory nft to infamous nft
module infamous::infamous_change_accesory {


    use std::error;
    use std::signer;
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    use aptos_token::token::{Self, TokenId, TokenDataId};
    use aptos_token::property_map;
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_accessory_nft;
    use infamous::infamous_lock;
    use infamous::infamous_link_status;
    use infamous::infamous_backend_open_box;

    //
    // Errors
    //
    /// Error when then infamous token not owned by sender.
    const ETOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    /// Error when then accessory token not owned by sender.
    const EACCESSORY_NOT_OWNED_BY_SENDER: u64 = 2;
    /// Error when old accessory missed (never happen)
    const EOLD_ACCESSORY_MISSED: u64 = 3;
    /// Error when accessory not opened
    const EACCESSORY_BOX_NOT_OPENED: u64 = 4;
    /// Error when token not opened
    const ETOKEN_NOT_REVEALED: u64 = 5;
    /// Error when locked token missed (never happen)
    const ETOKEN_LOCKED_MISSED: u64 = 6;
    /// Error when weared weapon not opened (never happen)
    const EWEAPON_BOX_NOT_OPENED: u64 = 7;
    /// Error when accessory gender not same as token gender
    const EACCESSORY_GENDER_ERROR: u64 = 8;
    
    


    /// change accessory called by accessory owner
    public entry fun change_accessory(sender: &signer, token_name: String, accessory_name: String) {
        let sender_addr = signer::address_of(sender);

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        // check accessory owned by sender
        let accessory_collection_name = infamous_common::infamous_accessory_collection_name();
        let accessory_creator = manager_addr;
        let new_accessory_token_id = infamous_accessory_nft::resolve_token_id(accessory_creator, accessory_collection_name, accessory_name);
        assert!(token::balance_of(sender_addr, new_accessory_token_id) == 1, error::invalid_argument(EACCESSORY_NOT_OWNED_BY_SENDER));

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);
        let token_data_id = token::create_token_data_id(manager_addr, collection_name, token_name);

        
        assert!(infamous_backend_open_box::is_box__opened(token_id), error::invalid_argument(ETOKEN_NOT_REVEALED));

        let token_gender = infamous_nft::get_token_gender(token_data_id);

    
        let (accessory, kind, gender) = get_accessory__accessory_property(sender_addr, new_accessory_token_id);
        assert!(gender == token_gender, error::invalid_argument(EACCESSORY_GENDER_ERROR));

        
        let sender_addr = signer::address_of(sender);
        let option_lock_addr = infamous_lock::token_lock_address(token_id);
        // token locked?
        if(option::is_some(&option_lock_addr)) { // change accessory under lock
        
            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(ETOKEN_LOCKED_MISSED));
        

            // 2.check token lockd by sender or called by manager self
            let lockd_addr = option::extract(&mut option_lock_addr);
            assert!(sender_addr == lockd_addr, error::invalid_argument(ETOKEN_NOT_OWNED_BY_SENDER));

            // 3.check has old token
            let old_accessory_token_id = infamous_link_status::get_token__accessory_token_id(token_id, kind);

            exchange__old_accessory__to__new_accessory(sender, &manager_signer, old_accessory_token_id, new_accessory_token_id);
            
            
            // update token bind accessory
            infamous_link_status::update_token__accessory_token_ids(token_id, 
            vector<String>[kind],
            vector<TokenId>[new_accessory_token_id ]);
            infamous_nft::update_token_accessory_properties(token_id, accessory, kind);
            update_token_uri(manager_addr, manager_addr, token_id, token_data_id, gender);

            infamous_link_status::emit_change_accessory_event(&manager_signer, sender_addr, token_id, new_accessory_token_id, kind, accessory);

            
        } else { // not under lock
            // 1. check the sender is the owner
            assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(ETOKEN_NOT_OWNED_BY_SENDER));
            
            // 2.check token revealed
            let old_accessory_token_id = infamous_link_status::get_token__accessory_token_id(token_id, kind);

            // @todo: gender 
            exchange__old_accessory__to__new_accessory(sender, &manager_signer, old_accessory_token_id, new_accessory_token_id);

            // update token bind accessory
            infamous_link_status::update_token__accessory_token_ids(token_id, 
            vector<String>[kind],
            vector<TokenId>[new_accessory_token_id ]);
            infamous_nft::update_token_accessory_properties(token_id, accessory, kind);
            update_token_uri(manager_addr, sender_addr, token_id, token_data_id, gender);

            infamous_link_status::emit_change_accessory_event(&manager_signer, sender_addr, token_id, new_accessory_token_id, kind, accessory);


        };

        
    }

    /// update token uri with token properties
    fun update_token_uri(manager_addr: address, owner_addr: address, token_id: TokenId, token_data_id: TokenDataId, gender: String) {
        

        let properties = &token::get_property_map(owner_addr, token_id);

        let weapon_token_id = infamous_link_status::get_token__weapon_token_id(token_id);
        let (weapon, grade) = get_weapon__weapon_property(manager_addr, option::extract(&mut weapon_token_id));

        infamous_nft::update_token_uri_with_properties(token_data_id,
        property_map::read_string(properties, &utf8(b"background")),
        property_map::read_string(properties, &utf8(b"clothing")),
        property_map::read_string(properties, &utf8(b"earrings")),
        property_map::read_string(properties, &utf8(b"eyebrows")),
        property_map::read_string(properties, &utf8(b"face-accessory")),
        property_map::read_string(properties, &utf8(b"eyes")),
        property_map::read_string(properties, &utf8(b"hair")),
        property_map::read_string(properties, &utf8(b"mouth")),
        property_map::read_string(properties, &utf8(b"neck")),
        property_map::read_string(properties, &utf8(b"tattoo")),
        weapon, 
        grade,
        gender);
    }

    /// transfer old accessory to lock addr, and transfer back old accessory back
     fun exchange__old_accessory__to__new_accessory(sender: &signer, manager_signer: &signer, old_accessory_token_id: Option<TokenId>, new_accessory_token_id: TokenId) {
        let manager_addr = signer::address_of(manager_signer);

        // 1.transfer back old accessory
        if (option::is_some(&old_accessory_token_id)) { // old accessory
            let old_accessory_token_id_extract = option::extract(&mut old_accessory_token_id);
            assert!(token::balance_of(manager_addr, old_accessory_token_id_extract) == 1, error::invalid_state(EOLD_ACCESSORY_MISSED));
            // transfer back old accessory
            transfer(manager_signer, sender, old_accessory_token_id_extract);
        };

        // 2. lock new accessory to manager
        transfer(sender, manager_signer, new_accessory_token_id);
     }

    /// call token direct transfer
     fun transfer(from: &signer, to: &signer, token_id: TokenId) {
        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        if(from_addr != to_addr) {
         token::direct_transfer(from, to, token_id, 1);
        };
     }
     
    
    /// get accessory token property
    fun get_accessory__accessory_property(owner: address, accessory_token_id: TokenId): (String, String, String) { 
        let properties = token::get_property_map(owner, accessory_token_id);
        let name_key = &utf8(b"name");
        assert!(property_map::contains_key(&properties, name_key), error::invalid_state(EACCESSORY_BOX_NOT_OPENED));
        let name = property_map::read_string(&properties, name_key);
        let kind_key = &utf8(b"kind");
        let kind = property_map::read_string(&properties, kind_key);
        let gender_key = &utf8(b"gender");
        let gender = property_map::read_string(&properties, gender_key);
        (name, kind, gender)
    }

    /// get weapon token property
    fun get_weapon__weapon_property(owner: address, weapon_token_id: TokenId): (String, String) { 
        let properties = token::get_property_map(owner, weapon_token_id);
        let name_key = &utf8(b"name");
        assert!(property_map::contains_key(&properties, name_key), error::invalid_state(EWEAPON_BOX_NOT_OPENED));
        let name = property_map::read_string(&properties, name_key);
        let grade_key = &utf8(b"grade");
        assert!(property_map::contains_key(&properties, grade_key), error::invalid_state(EWEAPON_BOX_NOT_OPENED));
        let grade = property_map::read_string(&properties, grade_key);
        (name, grade)
    }


    
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun wear_accessory_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_lock;
        use infamous::infamous_nft;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_accessory_nft;
        use infamous::infamous_upgrade_level;
        use infamous::infamous_backend_open_box;
        use infamous::infamous_properties_url_encode_map;
        use infamous::infamous_backend_token_accessory_open_box;


        timestamp::set_time_has_started_for_testing(framework);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);
        infamous_accessory_nft::initialize(user);
        infamous_properties_url_encode_map::initialize(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        infamous_nft::mint(receiver, 3);

        
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();
        let base_token_name = infamous_common::infamous_base_token_name();
        let token_index_1_name = infamous_common::append_num(base_token_name, 1);

        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_index_1_name);
        assert!(token::balance_of(receiver_addr, token_id) == 1, 1);
       

        timestamp::fast_forward_seconds(300);

        let background = utf8(b"blue");
        let clothing = utf8(b"hoodie");
        let earrings = utf8(b"null");
        let eyebrows = utf8(b"extended eyebrowss");
        let face_accessory = utf8(b"null");
        let eyes = utf8(b"black eyes");
        let hair = utf8(b"bob cut 1 (navy blue)");
        let mouth = utf8(b"closed");
        let neck = utf8(b"null");
        let tattoo = utf8(b"null");
        let gender = utf8(b"female");
        let weapon = utf8(b"dagger");
        let tier = utf8(b"1");
        let grade = utf8(b"iron");
        let attributes = utf8(b"30");

         infamous_backend_open_box::open_box(user,
         token_index_1_name,
         background, 
         clothing, attributes, 
         earrings, attributes, eyebrows, 
         face_accessory, attributes, 
         eyes, hair, 
         mouth, attributes,
         neck, attributes, 
         tattoo, attributes, 
         gender,
         weapon, tier, grade, attributes
         );


        infamous_lock::lock_infamous_nft(receiver, token_index_1_name);

        let time = infamous_lock::get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(2000);
        let time1 = infamous_lock::get_available_time(token_id);
        assert!(time1 == 2000, 1);

        infamous_upgrade_level::upgrade(token_index_1_name);
        
        let base_token_name = infamous_common::infamous_accessory_base_token_name();
        let accessory_token_1_name = infamous_common::append_num(base_token_name, 1);

        let accessory_token_2_name = infamous_common::append_num(base_token_name, 3);

        infamous_backend_token_accessory_open_box::open_box(user, accessory_token_2_name, utf8(b"aloha shirt 1"), utf8(b"clothing"), gender, utf8(b"100"));

        change_accessory(receiver, token_index_1_name, accessory_token_2_name);
        timestamp::fast_forward_seconds(60);
        change_accessory(receiver, token_index_1_name, accessory_token_1_name);

        timestamp::fast_forward_seconds(60);
         
        change_accessory(receiver, token_index_1_name, accessory_token_2_name);



    }

    





}