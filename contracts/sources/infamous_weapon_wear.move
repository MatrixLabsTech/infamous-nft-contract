/// This module provides Infamous Weapon Token binding functions.
module infamous::infamous_weapon_wear {


    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{String, utf8};
    use std::option::{Self, Option};
    



    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_weapon_nft;
    use infamous::infamous_lock;
    use infamous::infamous_weapon_status;


    const ETOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const EWEAPON_NOT_OWNED_BY_SENDER: u64 = 2;
    const EOLD_WEAPON_MISSED: u64 = 3;
    const EWEAPON_DONT_HAVE_WEAPON_PROPERTY: u64 = 4;
    const ETOKEN_NOT_REVEALED: u64 = 5;
    const ETOKEN_LOCKED_MISSED: u64 = 6;
    
    


    /// wear weapon called by weapon owner
    public entry fun wear_weapon(sender: &signer, token_name: String, weapon_name: String) {
        let sender_addr = signer::address_of(sender);

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        // check weapon owned by sender
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        let weapon_creator = manager_addr;
        let new_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, weapon_name);
        assert!(token::balance_of(sender_addr, new_weapon_token_id) == 1, error::invalid_argument(EWEAPON_NOT_OWNED_BY_SENDER));

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        
        let sender_addr = signer::address_of(sender);

        let option_lock_addr = infamous_lock::token_lock_address(token_id);
        // token lockd?
        if(option::is_some(&option_lock_addr)) { // wear weapon under lock
        
            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(ETOKEN_LOCKED_MISSED));
        

            // 2.check token lockd by sender or called by manager self
            let lockd_addr = option::extract(&mut option_lock_addr);
            assert!(sender_addr == lockd_addr, error::invalid_argument(ETOKEN_NOT_OWNED_BY_SENDER));

            // 3.check has old token
            let old_weapon_token_name = infamous_weapon_status::get_token__weapon_token_name(token_id);
            assert!(option::is_some(&old_weapon_token_name), error::invalid_argument(ETOKEN_NOT_REVEALED));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);
            

            
            infamous_weapon_status::update_token__weapon_token_name(token_id, weapon_name);
            let (_weapon, grade) = update_token_weapon(token_id, manager_addr, new_weapon_token_id);

            
            // update properties
            infamous_nft::update_token_uri_with_properties(manager_addr, token_name, grade);

            
        } else { // not under lock
            // 1. check the sender is the owner
            assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(ETOKEN_NOT_OWNED_BY_SENDER));
            
            // 2.check token revealed
            let old_weapon_token_name = infamous_weapon_status::get_token__weapon_token_name(token_id);
            assert!(option::is_some(&old_weapon_token_name), error::invalid_argument(ETOKEN_NOT_REVEALED));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);

            infamous_weapon_status::update_token__weapon_token_name(token_id, weapon_name);
            let (_weapon, grade) = update_token_weapon(token_id, manager_addr, new_weapon_token_id);


            // update properties
            infamous_nft::update_token_uri_with_properties(sender_addr, token_name, grade);


        };

        infamous_weapon_status::emit_wear_event(&manager_signer, sender_addr, token_id, new_weapon_token_id, weapon_name);
        
    }


     fun exchange__old_weapon__to__new_weapon(sender: &signer, manager_signer: &signer, old_weapon_token_name: Option<String>, new_weapon_token_id: TokenId) {
        let manager_addr = signer::address_of(manager_signer);
        let weapon_creator = manager_addr;
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        // 1.transfer back old weapon
        if (option::is_some(&old_weapon_token_name)) { // old weapon
            let old_weapon_name = option::extract(&mut old_weapon_token_name);
            let old_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, old_weapon_name);
            assert!(token::balance_of(manager_addr, old_weapon_token_id) == 1, error::invalid_state(EOLD_WEAPON_MISSED));
            // transfer back old weapon
            transfer(manager_signer, sender, old_weapon_token_id);
        };

        // 2. lock new weapon to manager
        transfer(sender, manager_signer, new_weapon_token_id);
     }


     fun transfer(from: &signer, to: &signer, token_id: TokenId) {
        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        if(from_addr != to_addr) {
         token::direct_transfer(from, to, token_id, 1);
        };
     }
     
    
    
    fun update_token_weapon(token_id: TokenId, weapon_owner_addr: address, weapon_token_id: TokenId): (String, String) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);
        // get weapon weapon
        let (weapon, grade) = get_weapon__weapon_property(weapon_owner_addr, weapon_token_id);
        let keys = vector<String>[infamous_common::infamous_weapon_key()];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&weapon)];
        let types = vector<String>[utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
        (weapon, grade)
    }

    
    
    fun get_weapon__weapon_property(owner: address, weapon_token_id: TokenId): (String, String) { 
        let properties = token::get_property_map(owner, weapon_token_id);
        let name_key = &utf8(b"name");
        assert!(property_map::contains_key(&properties, name_key), error::invalid_state(EWEAPON_DONT_HAVE_WEAPON_PROPERTY));
        let name = property_map::read_string(&properties, name_key);
        let grade_key = &utf8(b"grade");
        assert!(property_map::contains_key(&properties, grade_key), error::invalid_state(EWEAPON_DONT_HAVE_WEAPON_PROPERTY));
        let grade = property_map::read_string(&properties, grade_key);
        (name, grade)
    }

    
       
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun wear_weapon_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_lock;
        use infamous::infamous_nft;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_upgrade_level;
        use infamous::infamous_backend_open_box;
        use infamous::infamous_backend_token_weapon_airdrop;
        use infamous::infamous_properties_url_encode_map;


        timestamp::set_time_has_started_for_testing(framework);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);
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
        let ear = utf8(b"null");
        let eyebrow = utf8(b"extended eyebrows");
        let accessories = utf8(b"null");
        let eyes = utf8(b"black eyes");
        let hair = utf8(b"bob cut 1 (navy blue)");
        let mouth = utf8(b"closed");
        let neck = utf8(b"null");
        let tattoo = utf8(b"null");
        let gender = utf8(b"female");
        let weapon = utf8(b"dagger");
        let tier = utf8(b"1");
        let grade = utf8(b"iron");
        let attributes = utf8(b"iron");

         infamous_backend_open_box::open_box(user,
         token_index_1_name,
         background, clothing, ear, eyebrow, 
         accessories, eyes, hair, mouth,
         neck, tattoo, gender,
         weapon, tier, grade, attributes
         );


        infamous_lock::lock_infamous_nft(receiver, token_index_1_name);

        let time = infamous_lock::get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(2000);
        let time1 = infamous_lock::get_available_time(token_id);
        assert!(time1 == 2000, 1);

        infamous_upgrade_level::upgrade(token_index_1_name);
        let weapon_token_1_name = utf8(b"Equipment #1");

        infamous_backend_token_weapon_airdrop::airdrop_level_five(user, token_index_1_name, receiver_addr, utf8(b"revolver"), utf8(b"5"), utf8(b"iron"), utf8(b"normal revolver"));
        let weapon_token_2_name = utf8(b"Equipment #2");

         wear_weapon(receiver, token_index_1_name, weapon_token_2_name);
        timestamp::fast_forward_seconds(60);
         wear_weapon(receiver, token_index_1_name, weapon_token_1_name);

        timestamp::fast_forward_seconds(60);
         
         wear_weapon(receiver, token_index_1_name, weapon_token_2_name);



    }

    





}