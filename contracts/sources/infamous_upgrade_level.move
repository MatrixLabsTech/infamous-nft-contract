/// This module provides level info and the upgrade of Infamous Token.
module infamous::infamous_upgrade_level {
    
    use std::signer;
    use std::error;
    use aptos_std::string::{String};

    
    use aptos_std::table::{Self, Table};

    use aptos_token::token::{TokenId};

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    
    use infamous::infamous_manager_cap;
    use infamous::infamous_lock;
    use infamous::infamous_nft;
    use infamous::infamous_common;

    const EEXP_NOT_ENOUGH_TO_UPGRADE: u64 = 1;
    const ETOKEN_IS_FULL_LEVEL: u64 = 2;

    
    const FULL_LEVEL: u64 = 5;
    const EACH_LEVEL_EXP: u64 = 300;


    struct TokenUpgradeEvent has drop, store {
        token_id: TokenId,
        upgrade_time: u64,
        level: u64,
    }
    
    struct UpgradeInfo has key {
        token_level: Table<TokenId, u64>,
        token_upgrade_events: EventHandle<TokenUpgradeEvent>,
    }

    fun init_upgrade_info(account: &signer) {
        let addr = signer::address_of(account);
        if(!exists<UpgradeInfo>(addr)) {
            move_to(account, UpgradeInfo {
                token_level: table::new<TokenId, u64>(),
                token_upgrade_events: account::new_event_handle<TokenUpgradeEvent>(account),
            });
        };
    }


    // upgrade when under lock
    public entry fun upgrade(name: String) acquires UpgradeInfo {

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        // resolve token id
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        
        let available_time = infamous_lock::get_available_time(token_id);
        assert!(available_time >= EACH_LEVEL_EXP, error::invalid_argument(EEXP_NOT_ENOUGH_TO_UPGRADE));

        let cur_level = get_token_level(token_id);
        assert!(cur_level < FULL_LEVEL, error::invalid_argument(ETOKEN_IS_FULL_LEVEL));

        let available_level = available_time / EACH_LEVEL_EXP;
        let new_level = available_level + cur_level;
        if(new_level > FULL_LEVEL) {
            new_level = FULL_LEVEL;
        };
        let need_exp = (new_level - cur_level) * EACH_LEVEL_EXP;

        infamous_lock::take_times_to_use(token_id, need_exp);

        update_level(token_id, new_level);
    }







    public fun get_token_level(token_id: TokenId): u64 acquires UpgradeInfo { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_level = 1;
        if(exists<UpgradeInfo>(manager_addr)) {
            let token_level = &borrow_global<UpgradeInfo>(manager_addr).token_level;
            if(table::contains(token_level, token_id)){
                cur_level = *table::borrow(token_level, token_id);
            }
        };
        cur_level
    }

    fun update_level(token_id: TokenId, level: u64) acquires UpgradeInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        init_upgrade_info(&manager_signer);
        let token_level = &mut borrow_global_mut<UpgradeInfo>(manager_addr).token_level;
        if(table::contains(token_level, token_id)) {
            table::remove(token_level, token_id);
        };
        table::add(token_level, token_id, level);
        emit_upgrade_event(token_id, level);
    }

    
    fun emit_upgrade_event(token_id: TokenId, level: u64) acquires UpgradeInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let upgrade_info = borrow_global_mut<UpgradeInfo>(manager_addr);
        event::emit_event<TokenUpgradeEvent>(
            &mut upgrade_info.token_upgrade_events,
            TokenUpgradeEvent {
                token_id,
                upgrade_time: timestamp::now_seconds(),
                level,
            });
    }


    
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun upgrade_test(user: &signer, receiver: &signer, framework: &signer) acquires UpgradeInfo { 

        use aptos_framework::account; 
        use infamous::infamous_backend_open_box;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_properties_url_encode_map;
        use aptos_token::token;
        use aptos_std::string::{utf8};
        use infamous::infamous_common;




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


        timestamp::fast_forward_seconds(180);

            
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
        let weapon = utf8(b"dagger");
        let material = utf8(b"iron");
        let gender = utf8(b"female");

         infamous_backend_open_box::open_box(user,
         token_index_1_name,
         background, clothing, ear, eyebrow, 
         accessories, eyes, hair, mouth,
         neck, tattoo,
         weapon, material, gender
         );


        infamous_lock::lock_infamous_nft(receiver, token_index_1_name);

        let time = infamous_lock::get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(1000);
        let time1 = infamous_lock::get_available_time(token_id);
        assert!(time1 == 1000, 1);

        upgrade(token_index_1_name);
        let after = get_token_level(token_id);
        assert!(after == 4, 1);

        
        timestamp::fast_forward_seconds(200);
        upgrade(token_index_1_name);
        let after1 = get_token_level(token_id);
        assert!(after1 == 5, 1);

    }



    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun update_level_test(user: &signer, receiver: &signer, framework: &signer) acquires UpgradeInfo { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_nft;
        use aptos_token::token;
        use infamous::infamous_common;

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);

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
    
        let level = get_token_level(token_id);
        assert!(level == 1, 1);

        let new_level = 3;
        update_level(token_id, new_level);
        let after = get_token_level(token_id);
        assert!(after == new_level, 1);

    }

}