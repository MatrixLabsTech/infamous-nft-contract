/// This module provides the stake of Infamous Token.
module infamous::infamous_stake {

    use std::string::{String};
    use std::error;
    use std::signer;
    use std::vector;
    use std::option::{Self, Option};

    use aptos_std::table::{Self, Table};

    use aptos_framework::timestamp;

    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_backend_auth;

    friend infamous::infamous_upgrade_level;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const ESTAKER_INFO_NOT_PUBLISHED: u64 = 2;
    const ETOKEN_NOT_STAKE: u64 = 3;
    const ETOKEN_ALREADY_STAKED: u64 = 4;
    const ESTAKE_TIME_NOT_ENOUGH: u64 = 5;
    const ACCOUNT_MUSTBE_AUTHED: u64 =6;
    const TOKEN_NOT_STAKED_BY_THIS_ACCOUNT: u64 =6;
    
    


    
    struct StakingTime has store, drop {
        start: u64,
        stake_time_used: u64,
    }

    // store in staker account
    struct TokenStakes has key {
        staking: vector<TokenId>,
    }


    // store in manager account
    struct TokenStakesData has key {
        staking_tokens: vector<TokenId>,
        staking_token_address: Table<TokenId, address>,
        staking_time: Table<TokenId, StakingTime>,
    }


    public entry fun stake_infamous_nft_script(sender: &signer, token_name: String,) acquires TokenStakes, TokenStakesData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        token::opt_in_direct_transfer(sender, true);
        

        let sender_addr = signer::address_of(sender);
        assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));
        token::direct_transfer(sender, &manager_signer, token_id, 1);
        add_token_stakes(sender, sender_addr, token_id);
        add_token_stakes_data(&manager_signer, manager_addr, sender_addr, token_id);
        
    }

    public entry fun unstake_infamous_nft_script(sender: &signer, token_name: String,) acquires TokenStakes, TokenStakesData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        let staking_token_address = &borrow_global<TokenStakesData>(manager_addr).staking_token_address;
        let staker_addr = *table::borrow(staking_token_address, token_id);
        let sender_addr = signer::address_of(sender);
        assert!(staker_addr == sender_addr, error::unauthenticated(TOKEN_NOT_STAKED_BY_THIS_ACCOUNT));

        remove_token_stakes(staker_addr, token_id);
        remove_token_stakes_data(manager_addr, token_id);
        token::direct_transfer(&manager_signer, sender, token_id, 1);
    }

    public entry fun unstake_infamous_nft_admin(sender: &signer, token_name: String,) acquires TokenStakes, TokenStakesData {
        
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        let staking_token_address = &borrow_global<TokenStakesData>(manager_addr).staking_token_address;
        let staker_addr = *table::borrow(staking_token_address, token_id);

        remove_token_stakes(staker_addr, token_id);
        remove_token_stakes_data(manager_addr, token_id);
        
        token::transfer(&manager_signer, token_id, staker_addr, 1);
    }


    public fun get_all_stakes(): vector<TokenId> acquires TokenStakesData  {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        if(exists<TokenStakesData>(manager_addr)) {
            let stakes_data = borrow_global<TokenStakesData>(manager_addr);
            stakes_data.staking_tokens
        } else {
            vector<TokenId>[]
        }
    }

    public fun token_stake_address(token_id: TokenId): Option<address> acquires TokenStakesData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenStakesData>(manager_addr), error::invalid_argument(ESTAKER_INFO_NOT_PUBLISHED));
        let staking_token_address = &borrow_global<TokenStakesData>(manager_addr).staking_token_address;
        let staker_addr = option::none();
        if(table::contains(staking_token_address, token_id)) {
            staker_addr = option::some(*table::borrow(staking_token_address, token_id));
        };
        staker_addr
    }

    public fun get_available_time(token_id: TokenId): u64 acquires TokenStakesData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenStakesData>(manager_addr), error::invalid_argument(ESTAKER_INFO_NOT_PUBLISHED));
        let staking_time = &borrow_global<TokenStakesData>(manager_addr).staking_time;
        assert!(table::contains(staking_time, token_id), error::invalid_argument(ETOKEN_NOT_STAKE));
        let stake_time = table::borrow(staking_time, token_id);
        let avaliable = timestamp::now_seconds() - stake_time.start - stake_time.stake_time_used;
        avaliable
    }

    public(friend) fun take_times_to_use(token_id: TokenId, seconds: u64) acquires TokenStakesData {
        let available_time = get_available_time(token_id);
        assert!(available_time >= seconds, error::invalid_argument(ESTAKE_TIME_NOT_ENOUGH));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenStakesData>(manager_addr), error::invalid_argument(ESTAKER_INFO_NOT_PUBLISHED));
        let staking_time = &mut borrow_global_mut<TokenStakesData>(manager_addr).staking_time;
        assert!(table::contains(staking_time, token_id), error::invalid_argument(ETOKEN_NOT_STAKE));
        let stake_time = table::borrow_mut(staking_time, token_id);
        stake_time.stake_time_used = stake_time.stake_time_used + seconds;
    }


    fun remove_token_stakes(sender_addr: address, token_id: TokenId) acquires TokenStakes {
        assert!(exists<TokenStakes>(sender_addr), error::not_found(ETOKEN_NOT_STAKE));

        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        infamous_common::remove_element(staking, &token_id);

    }


    fun remove_token_stakes_data(manager_addr: address, token_id: TokenId) acquires TokenStakesData {
        assert!(exists<TokenStakesData>(manager_addr), error::not_found(ETOKEN_NOT_STAKE));

        let stakes_data = borrow_global_mut<TokenStakesData>(manager_addr);
        let staking_tokens = &mut stakes_data.staking_tokens;
        infamous_common::remove_element(staking_tokens, &token_id);

        let staking_token_address = &mut stakes_data.staking_token_address;
        assert!(table::contains(staking_token_address, token_id), error::not_found(ETOKEN_NOT_STAKE));
        let _address = table::remove(staking_token_address, token_id);

        let staking_time = &mut stakes_data.staking_time;
        assert!(table::contains(staking_time, token_id), error::not_found(ETOKEN_NOT_STAKE));
        let _stake_time = table::remove(staking_time, token_id);
    }

    fun add_token_stakes(sender: &signer, sender_addr: address, token_id: TokenId) acquires TokenStakes {
        initialize_token_stakes(sender);
        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        assert!(!vector::contains(staking, &token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        infamous_common::add_element(staking, token_id);
    }

    fun add_token_stakes_data(manager: &signer, manager_addr: address, staker_addr:address, token_id: TokenId) acquires TokenStakesData {
        initialize_token_stakes_data(manager);
        let stakes_data = borrow_global_mut<TokenStakesData>(manager_addr);
        let staking_tokens = &mut stakes_data.staking_tokens;
        assert!(!vector::contains(staking_tokens, &token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        infamous_common::add_element(staking_tokens, token_id);

        let staking_token_address = &mut stakes_data.staking_token_address;
        assert!(!table::contains(staking_token_address, token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        table::add(staking_token_address, token_id, staker_addr);

        let staking_time = &mut stakes_data.staking_time;
        assert!(!table::contains(staking_time, token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        table::add(staking_time, token_id, StakingTime{
                 start: timestamp::now_seconds(),
                 stake_time_used: 0,
             });
    }



    fun initialize_token_stakes(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenStakes>(account_addr)) {
            move_to(
                account,
                TokenStakes {
                    staking: vector::empty<TokenId>(),
                }
            );
        }
    }

    fun initialize_token_stakes_data(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenStakesData>(account_addr)) {
            move_to(
                account,
                TokenStakesData {
                    staking_tokens: vector::empty<TokenId>(),
                    staking_token_address: table::new<TokenId, address>(),
                    staking_time: table::new<TokenId, StakingTime>(),
                }
            );
        }
    }


    

    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun end_to_end(user: &signer, receiver: &signer, framework: &signer) acquires TokenStakes, TokenStakesData { 

        use aptos_framework::account; 

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


        stake_infamous_nft_script(receiver, token_index_1_name);

        let time = get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(1000);
        let time1 = get_available_time(token_id);
        assert!(time1 == 1000, 1);


        take_times_to_use(token_id, 33);
        let time2 = get_available_time(token_id);
        assert!(time2 == 967, 1);

        unstake_infamous_nft_script(receiver, token_index_1_name);

    


    }


}