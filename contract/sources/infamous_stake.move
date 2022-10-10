module infamous::stake {

    use std::string::{String};
    use std::error;
    use std::signer;
    use std::vector;
    // use std::option::{Self, Option};

    use aptos_std::table::{Self, Table};

    use aptos_framework::timestamp;

    use aptos_token::token::{Self, TokenId};

    use infamous::common;
    use infamous::manager_cap;
    use infamous::infamous_nft;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const ESTAKER_INFO_NOT_PUBLISHED: u64 = 2;
    const ETOKEN_NOT_STAKE: u64 = 3;
    const ETOKEN_ALREADY_STAKED: u64 = 4;
    const EEXP_NOT_ENOUGH_FOR_ONE_LEVEL: u64 = 5;
    const ETOKEN_LEVEL_FULL: u64 = 6;

    const FULL_LEVEL: u64 = 5;
    const EACH_LEVEL_EXP: u64 = 300;

    
    struct StakingTime has store, drop {
        start: u64,
        stake_time_used: u64,
    }

    // store in staker account
    struct TokenStakes has key {
        staking: vector<TokenId>,
        staking_time: Table<TokenId, StakingTime>,
    }


    // store in manager account
    struct TokenStakesData has key {
        staking_tokens: vector<TokenId>,
        staking_token_address: Table<TokenId, address>,
    }


    public entry fun stake_infamous_nft_script(sender: &signer, token_name: String,) acquires TokenStakes, TokenStakesData {
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        let sender_addr = signer::address_of(sender);
        assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));
        token::direct_transfer(sender, &manager_signer, token_id, 1);
        add_token_stakes(sender, sender_addr, token_id);
        add_token_stakes_data(&manager_signer, manager_addr, sender_addr, token_id);
        
    }

    public entry fun unstake_infamous_nft_script(sender: &signer, token_name: String,) acquires TokenStakes, TokenStakesData {
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        let sender_addr = signer::address_of(sender);
        remove_token_stakes(sender_addr, token_id);
        remove_token_stakes_data(manager_addr, token_id);
        token::direct_transfer(&manager_signer, sender, token_id, 1);
    }


    public fun get_all_stakes(): vector<TokenId> acquires TokenStakesData  {
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        if(exists<TokenStakesData>(manager_addr)) {
            let stakes_data = borrow_global<TokenStakesData>(manager_addr);
            stakes_data.staking_tokens
        } else {
            vector<TokenId>[]
        }
    }

    // public fun get_available_time(token_id: TokenId): Option<u64> {
    //     let manager_signer = manager_cap::get_manager_signer();
    //     let manager_addr = signer::address_of(&manager_signer);
    //     let available_time = option::none();
    //     // if(exists<TokenStakesData>(manager_addr)) {
    //     //     let stakes_data = borrow_global<TokenStakesData>(manager_addr);

    //     // }
    //     available_time
    // }

    // public(friend) fun take_times_to_use(token_id: TokenId, seconds: u64)  {
       
    // }


    fun remove_token_stakes(sender_addr: address, token_id: TokenId) acquires TokenStakes {
        assert!(exists<TokenStakes>(sender_addr), error::not_found(ETOKEN_NOT_STAKE));

        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        common::remove_element(staking, &token_id);

        let staking_time = &mut stakes.staking_time;
        assert!(table::contains(staking_time, token_id), error::not_found(ETOKEN_NOT_STAKE));
        let _stake_time = table::remove(staking_time, token_id);
    }


    fun remove_token_stakes_data(manager_addr: address, token_id: TokenId) acquires TokenStakesData {
        assert!(exists<TokenStakesData>(manager_addr), error::not_found(ETOKEN_NOT_STAKE));

        let stakes_data = borrow_global_mut<TokenStakesData>(manager_addr);
        let staking_tokens = &mut stakes_data.staking_tokens;
        common::remove_element(staking_tokens, &token_id);

        let staking_token_address = &mut stakes_data.staking_token_address;
        assert!(table::contains(staking_token_address, token_id), error::not_found(ETOKEN_NOT_STAKE));
        let _address = table::remove(staking_token_address, token_id);
    }

    fun add_token_stakes(sender: &signer, sender_addr: address, token_id: TokenId) acquires TokenStakes {
        initialize_token_stakes(sender);
        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        assert!(!vector::contains(staking, &token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        common::add_element(staking, token_id);

        let staking_time = &mut stakes.staking_time;
        assert!(!table::contains(staking_time, token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        table::add(staking_time, token_id, StakingTime{
                 start: timestamp::now_seconds(),
                 stake_time_used: 0,
             });
    }

    fun add_token_stakes_data(manager: &signer, manager_addr: address, staker_addr:address, token_id: TokenId) acquires TokenStakesData {
        initialize_token_stakes_data(manager);
        let stakes_data = borrow_global_mut<TokenStakesData>(manager_addr);
        let staking_tokens = &mut stakes_data.staking_tokens;
        assert!(!vector::contains(staking_tokens, &token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        common::add_element(staking_tokens, token_id);

        let staking_token_address = &mut stakes_data.staking_token_address;
        assert!(!table::contains(staking_token_address, token_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        table::add(staking_token_address, token_id, staker_addr);
    }



    fun initialize_token_stakes(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenStakes>(account_addr)) {
            move_to(
                account,
                TokenStakes {
                    staking: vector::empty<TokenId>(),
                    staking_time: table::new<TokenId, StakingTime>(),
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
                }
            );
        }
    }


    

    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun end_to_end(user: &signer, receiver: &signer, framework: &signer) acquires TokenStakes, TokenStakesData { 

        use aptos_framework::account; 
        use aptos_std::debug;

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        manager_cap::initialize(user);
        infamous_nft::initialize(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        infamous_nft::mint(receiver, 3);

        
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = common::infamous_collection_name();
        let token_index_1_name = common::infamous_token_name(1);
        assert!(token::balance_of(receiver_addr, infamous_nft::resolve_token_id(manager_addr, collection_name, token_index_1_name)) == 1, 1);


        stake_infamous_nft_script(receiver, token_index_1_name);

        let stakes = get_all_stakes();

        debug::print<vector<TokenId>>(&stakes);

        debug::print<u64>(&timestamp::now_seconds());
        timestamp::fast_forward_seconds(5);
        debug::print<u64>(&timestamp::now_seconds());

        
        unstake_infamous_nft_script(receiver, token_index_1_name);

    


    }


}