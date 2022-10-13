module infamous::infamous_upgrade_level {
    
    use std::bcs;
    use std::signer;
    use std::error;
    use std::string::{Self, String};

    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_stake;

    const EXP_NOT_ENOUGH_TO_UPGRADE: u64 = 1;
    const TOKEN_IS_FULL_LEVEL: u64 = 2;

    
    const FULL_LEVEL: u64 = 5;
    const EACH_LEVEL_EXP: u64 = 300;


    struct TokenUpgradeEvent has drop, store {
        token_id: TokenId,
        upgrade_time: u64,
        level: u64,
    }
    
    struct UpgradeInfo has key {
        token_upgrade_events: EventHandle<TokenUpgradeEvent>,
    }

    // upgrade when under stake
    public entry fun upgrade(name: String) acquires UpgradeInfo {
        let collection = infamous_common::infamous_collection_name();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let creator = signer::address_of(&manager_signer);

        let token_id = infamous_nft::resolve_token_id(creator, collection, name);
        let available_time = infamous_stake::get_available_time(token_id);
        assert!(available_time >= EACH_LEVEL_EXP, error::invalid_argument(EXP_NOT_ENOUGH_TO_UPGRADE));

        
        let cur_level = get_token_level(creator, token_id);
        assert!(cur_level < FULL_LEVEL, error::invalid_argument(TOKEN_IS_FULL_LEVEL));

        let available_level = available_time / EACH_LEVEL_EXP;
        let new_level = available_level + cur_level;
        if(new_level > FULL_LEVEL) {
            new_level = FULL_LEVEL;
        };
        let need_exp = (new_level - cur_level) * EACH_LEVEL_EXP;

        update_level(token_id, new_level);
        infamous_stake::take_times_to_use(token_id, need_exp);

        emit_upgrade_event(token_id, new_level);
    }







    public fun get_token_level(owner: address, token_id: TokenId): u64 { 
        let properties = token::get_property_map(owner, token_id);
        let level_key = &infamous_common::infamous_level_key();
        let cur_level = if(property_map::contains_key(&properties, level_key)) {
            property_map::read_u64(&properties, level_key)
        } else 0;
        cur_level
    }

    fun update_level(token_id: TokenId, level: u64) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);

        let keys = vector<String>[infamous_common::infamous_level_key()];
        let values = vector<vector<u8>>[bcs::to_bytes<u64>(&level)];
        let types = vector<String>[string::utf8(b"u64")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }

    
    fun emit_upgrade_event(token_id: TokenId, level: u64) acquires UpgradeInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        if(!exists<UpgradeInfo>(manager_addr)) {
            move_to(&manager_signer, UpgradeInfo {
                token_upgrade_events: account::new_event_handle<TokenUpgradeEvent>(&manager_signer),
            });
        };
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
        use infamous::infamous_nft;
        use aptos_std::debug;

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


        infamous_stake::stake_infamous_nft_script(receiver, token_index_1_name);

        

        let time = infamous_stake::get_available_time(token_id);
        debug::print<u64>(&time);

        timestamp::fast_forward_seconds(1000);
        let time1 = infamous_stake::get_available_time(token_id);
        debug::print<u64>(&time1);

        upgrade(token_index_1_name);
        let after = get_token_level(manager_addr, token_id);
        debug::print<u64>(&after);

        
        timestamp::fast_forward_seconds(200);
        upgrade(token_index_1_name);
        let after1 = get_token_level(manager_addr, token_id);
        debug::print<u64>(&after1);
        debug::print<u64>(&111111111111);

    }



    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun update_level_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use aptos_std::debug;
        use infamous::infamous_nft;

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
    
        let level = get_token_level(receiver_addr, token_id);
        debug::print<u64>(&level);


        let new_level = 3;
        update_level(token_id, new_level);
        let after = get_token_level(receiver_addr, token_id);
        debug::print<u64>(&after);

    }

}