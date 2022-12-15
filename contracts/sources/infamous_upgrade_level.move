/// This module provides level info and the upgrade of Infamous Token.
/// It record the token level, and upgrade operator
module infamous::infamous_upgrade_level {
    
    use std::signer;
    use std::error;
    use std::string::{utf8};
    use std::option::{Self};
    use std::vector;
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
    use infamous::infamous_weapon_nft;
    use infamous::infamous_accessory_nft;

    //
    // Errors
    //
    /// Error when not enough time to upgrade
    const EEXP_NOT_ENOUGH_TO_UPGRADE: u64 = 1;
    /// Error when the level retch 5
    const ETOKEN_IS_FULL_LEVEL: u64 = 2;
    /// Error when the token is not locked
    const ETOKEN_NOT_LOCKED: u64 = 3;

    
    //
    // Contants
    //
    const FULL_LEVEL: u64 = 5;
    const FILVE_LEVEL_AIRDROP: u64 = 5;
    // each level need locked seconds, 
    // @Todo change to 86400(1 day) when prod
    const EACH_LEVEL_EXP_OF_PRESALE: u64 = 60;


    struct AirdropEvent has drop, store {
        // airdrop receiver addr
        receiver_addr: address,
        // airdroped for infamous tokenId
        token_id: TokenId,
        // airdroped tokenId
        airdrop_token_id: TokenId,
        // airdrop time
        time: u64,
    }

    struct TokenUpgradeEvent has drop, store {
        // upgrade tokenId
        token_id: TokenId,
        // upgrade time
        upgrade_time: u64,
        //  upgrade level
        level: u64,
    }
    
    struct UpgradeInfo has key {
        // token level map
        token_level: Table<TokenId, u64>,
        // airdroped award tokenId
        airdroped: Table<TokenId, Table<u64, vector<TokenId>>>,
        // upgrade events
        token_upgrade_events: EventHandle<TokenUpgradeEvent>,
        // airdrop events
        airdrop_events: EventHandle<AirdropEvent>,
    }

    // (1~5 upgrade), when full level -> do airdrop
    // name: infamous token name, eg: `infamous #1`
    public entry fun upgrade(name: String) acquires UpgradeInfo {

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        // resolve token id
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        
        let available_time = infamous_lock::get_available_time(token_id);
        assert!(available_time >= EACH_LEVEL_EXP_OF_PRESALE, error::invalid_argument(EEXP_NOT_ENOUGH_TO_UPGRADE));

        let cur_level = get_token_level(token_id);
        assert!(cur_level < FULL_LEVEL, error::invalid_argument(ETOKEN_IS_FULL_LEVEL));

        let available_level = available_time / EACH_LEVEL_EXP_OF_PRESALE;
        let new_level = available_level + cur_level;
        if(new_level > FULL_LEVEL) {
            new_level = FULL_LEVEL;
        };
        let need_exp = (new_level - cur_level) * EACH_LEVEL_EXP_OF_PRESALE;
        infamous_lock::take_times_to_use(token_id, need_exp);
        update_level(token_id, new_level);

        airdrop(token_id, new_level);
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

    fun airdrop(token_id: TokenId, new_level: u64) acquires UpgradeInfo {
        if(new_level >= 5 && !is_token__airdroped(token_id, 5)) { // level 5 airdrop
            let option_lock_addr = infamous_lock::token_lock_address(token_id);
            assert!(option::is_some(&option_lock_addr), error::invalid_state(ETOKEN_NOT_LOCKED));
            let receiver_addr = option::extract(&mut option_lock_addr);
            let token_ids = airdrop_level_five(receiver_addr);
            update_token_airdroped(token_id, 5, token_ids);

            let manager_signer = infamous_manager_cap::get_manager_signer();
            let manager_addr = signer::address_of(&manager_signer);
            let upgrade_info = borrow_global_mut<UpgradeInfo>(manager_addr);
            let i = 0;
            while (i < vector::length<TokenId>(&token_ids)) {
                let airdrop_token_id = *vector::borrow<TokenId>(&token_ids, i);
                emit_airdrop_event(upgrade_info, receiver_addr, token_id, airdrop_token_id);
                i = i + 1;
            };
        };
    }


    fun airdrop_level_five(receiver_addr: address): vector<TokenId> { 

        let token_ids = vector::empty<TokenId>();
        // airdrop weapon
        let weapon_token_id = infamous_weapon_nft::airdrop_box(receiver_addr,  utf8(b"Lv 5"), utf8(b""));
        vector::push_back<TokenId>(&mut token_ids, weapon_token_id);

        // airdrop early bird weapon
        let weapon_early_bird_id = infamous_weapon_nft::airdrop_box(receiver_addr,  utf8(b"Lv 15"), utf8(b"early bird"));
        vector::push_back<TokenId>(&mut token_ids, weapon_early_bird_id);

        // airdrop early bird accessory
        let accessory_early_bird_id = infamous_accessory_nft::airdrop_box(receiver_addr, utf8(b"early bird"));
        vector::push_back<TokenId>(&mut token_ids, accessory_early_bird_id);

        token_ids

    }

    fun is_token__airdroped(token_id: TokenId, airdrop_level: u64): bool acquires UpgradeInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let box_airdroped = false;
        if(exists<UpgradeInfo>(manager_addr)) {
            let airdroped = &borrow_global<UpgradeInfo>(manager_addr).airdroped;
            if(table::contains(airdroped, token_id)) {
                let token_airdroped = table::borrow(airdroped, token_id);
                box_airdroped = table::contains(token_airdroped, airdrop_level);
            }
        };
        box_airdroped
    }

    

    fun update_token_airdroped(token_id: TokenId, airdrop_level: u64, token_ids: vector<TokenId>) acquires UpgradeInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let upgrade_info = borrow_global_mut<UpgradeInfo>(manager_addr);

        let airdroped = &mut upgrade_info.airdroped;
        if(!table::contains(airdroped, token_id)) {
            table::add(airdroped, token_id, table::new<u64, vector<TokenId>>());
        };
        let token_airdroped = table::borrow_mut(airdroped, token_id);
        if(!table::contains(token_airdroped, airdrop_level)) {
            table::add(token_airdroped, airdrop_level, token_ids);
        };

        
    }


    
    fun emit_airdrop_event(upgrade_info: &mut UpgradeInfo, receiver_addr: address, token_id: TokenId, airdrop_token_id: TokenId) {
        event::emit_event<AirdropEvent>(
           &mut upgrade_info.airdrop_events,
            AirdropEvent {
                receiver_addr,
                token_id,
                airdrop_token_id,
                time: timestamp::now_seconds(),
            });
    }


    fun init_upgrade_info(account: &signer) {
        let addr = signer::address_of(account);
        if(!exists<UpgradeInfo>(addr)) {
            move_to(account, UpgradeInfo {
                token_level: table::new<TokenId, u64>(),
                airdroped: table::new<TokenId, Table<u64, vector<TokenId>>>(),
                token_upgrade_events: account::new_event_handle<TokenUpgradeEvent>(account),
                airdrop_events: account::new_event_handle<AirdropEvent>(account),
            });
        };
    }



    
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun upgrade_test(user: &signer, receiver: &signer, framework: &signer) acquires UpgradeInfo { 

        use aptos_framework::account; 
        use infamous::infamous_backend_open_box;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_accessory_nft;
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


        timestamp::fast_forward_seconds(180);

            
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
        let attributes = utf8(b"100");

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

        timestamp::fast_forward_seconds(180);
        let time1 = infamous_lock::get_available_time(token_id);
        assert!(time1 == 180, 1);

        upgrade(token_index_1_name);
        let after = get_token_level(token_id);
        assert!(after == 4, 1);

        
        timestamp::fast_forward_seconds(60);
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