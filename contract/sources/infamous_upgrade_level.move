module infamous::infamous_upgrade_level {
    
    use std::bcs;
    use std::signer;
    use std::error;
    use std::string::{Self, String};

    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_stake;

    const EXP_NOT_ENOUGH_TO_UPGRADE: u64 = 1;
    const TOKEN_IS_FULL_LEVEL: u64 = 2;

    
    const FULL_LEVEL: u64 = 5;
    const EACH_LEVEL_EXP: u64 = 300;



    public entry fun upgrade(creator: address, collection: String, name: String) {
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);
        let available_time = infamous_stake::get_available_time(token_id);
        assert!(available_time >= EACH_LEVEL_EXP, error::invalid_argument(EXP_NOT_ENOUGH_TO_UPGRADE));

        
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_level = get_token_level(manager_addr, token_id);
        assert!(cur_level < FULL_LEVEL, error::invalid_argument(TOKEN_IS_FULL_LEVEL));

        let available_level = available_time / EACH_LEVEL_EXP;
        let new_level = available_level + cur_level;
        if(new_level > FULL_LEVEL) {
            new_level = FULL_LEVEL;
        };
        let need_exp = (new_level - cur_level) * EACH_LEVEL_EXP;

        update_level(token_id, new_level);
        infamous_stake::take_times_to_use(token_id, need_exp);
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

    
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun upgrade_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_nft;

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        infamous_nft::mint(receiver, 3);





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