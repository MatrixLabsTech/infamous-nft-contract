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
    use infamous::infamous_stake;
    use infamous::infamous_weapon_status;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const WEAPON_NOT_OWNED_BY_SENDER: u64 = 2;
    const OLD_WEAPON_MISSED: u64 = 3;
    const WEAPON_DONT_HAVE_WEAPON_PROPERTY: u64 = 4;
    const TOKEN_NOT_REVEALED: u64 = 5;
    const TOKEN_STAKED_MISSED: u64 = 6;
    
    


    /// wear weapon called by weapon owner
    public entry fun wear_weapon(sender: &signer, token_name: String, weapon_name: String) {
        let sender_addr = signer::address_of(sender);

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        // check weapon owned by sender
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        let weapon_creator = manager_addr;
        let new_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, weapon_name);
        assert!(token::balance_of(sender_addr, new_weapon_token_id) == 1, error::invalid_argument(WEAPON_NOT_OWNED_BY_SENDER));

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        
        let sender_addr = signer::address_of(sender);

        let option_stake_addr = infamous_stake::token_stake_address(token_id);
        // token staked?
        if(option::is_some(&option_stake_addr)) { // wear weapon under stake
        
            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(TOKEN_STAKED_MISSED));
        

            // 2.check token staked by sender or called by manager self
            let staked_addr = option::extract(&mut option_stake_addr);
            assert!(sender_addr == staked_addr, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));

            // 3.check has old token
            let old_weapon_token_name = infamous_weapon_status::get_token__weapon_token_name(token_id);
            assert!(option::is_some(&old_weapon_token_name), error::invalid_argument(TOKEN_NOT_REVEALED));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);
            

            
            infamous_weapon_status::update_token__weapon_token_name(token_id, weapon_name);
            update_token_weapon(token_id, manager_addr, new_weapon_token_id);

            
            // update properties
            infamous_nft::update_token_uri_with_properties(manager_addr, token_name);

            
        } else { // not under stake
            // 1. check the sender is the owner
            assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));
            
            // 2.check token revealed
            let old_weapon_token_name = infamous_weapon_status::get_token__weapon_token_name(token_id);
            assert!(option::is_some(&old_weapon_token_name), error::invalid_argument(TOKEN_NOT_REVEALED));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);

            infamous_weapon_status::update_token__weapon_token_name(token_id, weapon_name);
            update_token_weapon(token_id, manager_addr, new_weapon_token_id);


            // update properties
            infamous_nft::update_token_uri_with_properties(sender_addr, token_name);


        };

        infamous_weapon_status::emit_wear_event(manager_addr, sender_addr, token_id, new_weapon_token_id);
        
    }


     fun exchange__old_weapon__to__new_weapon(sender: &signer, manager_signer: &signer, old_weapon_token_name: Option<String>, new_weapon_token_id: TokenId) {
        let manager_addr = signer::address_of(manager_signer);
        let weapon_creator = manager_addr;
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        // 1.transfer back old weapon
        if (option::is_some(&old_weapon_token_name)) { // old weapon
            let old_weapon_name = option::extract(&mut old_weapon_token_name);
            let old_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, old_weapon_name);
            assert!(token::balance_of(manager_addr, old_weapon_token_id) == 1, error::invalid_state(OLD_WEAPON_MISSED));
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
     
    
    
    fun update_token_weapon(token_id: TokenId, weapon_owner_addr: address, weapon_token_id: TokenId) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);
        // get weapon weapon
        let weapon = get_weapon__weapon_property(weapon_owner_addr, weapon_token_id);
        let keys = vector<String>[infamous_common::infamous_weapon_key()];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&weapon)];
        let types = vector<String>[utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }

    
    
    fun get_weapon__weapon_property(owner: address, weapon_token_id: TokenId): String { 
        let properties = token::get_property_map(owner, weapon_token_id);
        let weapon_key = &infamous_common::infamous_weapon_key();
        assert!(property_map::contains_key(&properties, weapon_key), error::invalid_state(WEAPON_DONT_HAVE_WEAPON_PROPERTY));
        property_map::read_string(&properties, weapon_key)
    }

    
       
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun wear_weapon_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_stake;
        use infamous::infamous_nft;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_upgrade_level;
        use infamous::infamous_backend_open_box;
        use infamous::infamous_backend_token_weapon_airdrop;


        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);

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
        infamous_stake::stake_infamous_nft_script(receiver, token_index_1_name);

        let time = infamous_stake::get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(2000);
        let time1 = infamous_stake::get_available_time(token_id);
        assert!(time1 == 2000, 1);

        infamous_upgrade_level::upgrade(token_index_1_name);
        

        
        // infamous_stake::unstake_infamous_nft_script(receiver, token_index_1_name);-


        let background = utf8(b"blue");
        let clothing = utf8(b"hoodie");
        let ear = utf8(b"null");
        let eyebrow = utf8(b"extended eyebrows");
        let accessories = utf8(b"null");
        let eyes = utf8(b"black eyes");
        let hair = utf8(b"bob cut 1 (navy blue)");
        let mouth = utf8(b"choker");
        let neck = utf8(b"fox mask");
        let tattoo = utf8(b"danger");
        let weapon = utf8(b"danger");
        let material = utf8(b"iron");

         infamous_backend_open_box::open_box(user,
         token_index_1_name,
         background, clothing, ear, eyebrow, 
         accessories, eyes, hair, mouth,
         neck, tattoo,
         weapon, material
         );

         
        let weapon_token_1_name = utf8(b"Equipment #1");
        // let weapon_l3_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, weapon_token_1_name);

        infamous_backend_token_weapon_airdrop::airdrop_level_four(user, token_index_1_name, receiver_addr, utf8(b"knif"), utf8(b"normal knif"));

        let weapon_token_2_name = utf8(b"Equipment #2");
        // let weapon_l4_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, weapon_token_1_name);

        infamous_backend_token_weapon_airdrop::airdrop_level_five(user, token_index_1_name, receiver_addr, utf8(b"AK-47"), utf8(b"normal AK-47"));

        let weapon_token_3_name = utf8(b"Equipment #3");
        // let weapon_l5_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, weapon_token_1_name);

         wear_weapon(receiver, token_index_1_name, weapon_token_2_name);
         wear_weapon(receiver, token_index_1_name, weapon_token_1_name);
         wear_weapon(receiver, token_index_1_name, weapon_token_3_name);
         wear_weapon(receiver, token_index_1_name, weapon_token_1_name);

         
        // let weapon_collection_name = infamous_common::infamous_weapon_collection_name();


    }

    





}