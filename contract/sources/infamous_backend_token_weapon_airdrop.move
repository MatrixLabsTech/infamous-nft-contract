module infamous::infamous_backend_token_weapon_airdrop {

    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8};
    use std::option;

    
    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_weapon_nft;
    use infamous::infamous_stake;
     use infamous::infamous_upgrade_level;

    const TOKEN_STAKED_MISSED: u64 = 1;
    const TOKEN_NOT_OWNED_BY_RECEIVER: u64 = 2;
    const TOKEN_AIRDROPED: u64 = 3;
    const ACCOUNT_MUSTBE_AUTHED: u64 = 4;
    const LEVEL_MUST_GREATER: u64 = 5;


    
    struct AirdropInfo has key {
        token_level4_airdroped: Table<TokenId, TokenId>,
        token_level5_airdroped: Table<TokenId, TokenId>
    }

    fun initialize_airdrop_info(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<AirdropInfo>(account_addr)) {
            move_to(
                account,
                AirdropInfo {
                    token_level4_airdroped: table::new<TokenId, TokenId>(),
                    token_level5_airdroped: table::new<TokenId, TokenId>(),
                }
            );
        }
    }


    public entry fun airdrop_level_four(sender: &signer, token_name: String, receiver_addr: address, weapon: String, material: String) acquires AirdropInfo {
        airdrop(sender, token_name, receiver_addr, weapon, material, utf8(b"4"), 4);
    }


    public entry fun airdrop_level_five(sender: &signer, token_name: String, receiver_addr: address, weapon: String, material: String) acquires AirdropInfo {
        airdrop(sender, token_name, receiver_addr, weapon, material, utf8(b"5"), 5);
    }


    fun airdrop(sender: &signer, token_name: String, receiver_addr: address, weapon: String, material: String, weapon_level: String, airdrop_level: u64 ) acquires AirdropInfo {
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let collection_name = infamous_common::infamous_collection_name();
        let creator = manager_addr;
        let token_id = infamous_weapon_nft::resolve_token_id(creator, collection_name, token_name);

        let level_key = utf8(b"level_key");
        string::append(&mut level_key, weapon_level);

        
        let option_stake_addr = infamous_stake::token_stake_address(token_id);
        // token staked ?
        if(option::is_some(&option_stake_addr)) { // airdrop token under stake

            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(TOKEN_STAKED_MISSED));

            // 2.check token staked by receiver
            let staked_addr = option::extract(&mut option_stake_addr);
            assert!(receiver_addr == staked_addr, error::invalid_argument(TOKEN_NOT_OWNED_BY_RECEIVER));

            // check level greater
            let token_level = infamous_upgrade_level::get_token_level(token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(LEVEL_MUST_GREATER));            

            // 3.check token airdroped
            assert!(!is_token__airdroped(token_id, airdrop_level), error::invalid_argument(TOKEN_AIRDROPED));

            let weapon_token_id = infamous_weapon_nft::airdrop(receiver_addr, weapon, material, weapon_level);
            update_token_airdroped(token_id, airdrop_level, weapon_token_id);
        } else {
            // 1. check the receiver is the owner
            assert!(token::balance_of(receiver_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_RECEIVER));

            
            // check level greater
            let token_level = infamous_upgrade_level::get_token_level(token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(LEVEL_MUST_GREATER));
            
            // 3.check token airdroped
            assert!(!is_token__airdroped(token_id, airdrop_level), error::invalid_argument(TOKEN_AIRDROPED));

            let weapon_token_id = infamous_weapon_nft::airdrop(receiver_addr, weapon, material, weapon_level);
            update_token_airdroped(token_id, airdrop_level, weapon_token_id);
        }



    }

    fun is_token__airdroped(token_id: TokenId, airdrop_level: u64): bool acquires AirdropInfo { 
      let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let box_airdroped = false;
        if(exists<AirdropInfo>(manager_addr)) {
            if(airdrop_level == 4) {
                let token_level4_airdroped = &borrow_global<AirdropInfo>(manager_addr).token_level4_airdroped;
                box_airdroped = table::contains(token_level4_airdroped, token_id);
            } else if (airdrop_level == 5) {
                let token_level5_airdroped = &borrow_global<AirdropInfo>(manager_addr).token_level5_airdroped;
                box_airdroped = table::contains(token_level5_airdroped, token_id);
            }
        };
        box_airdroped
    }

      

    fun update_token_airdroped(token_id: TokenId, airdrop_level: u64, weapon_token_id: TokenId) acquires AirdropInfo {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_airdrop_info(&manager_signer);

        if(airdrop_level == 4) {
            let token_level4_airdroped = &mut borrow_global_mut<AirdropInfo>(manager_addr).token_level4_airdroped;
            if(!table::contains(token_level4_airdroped, token_id)) {
                table::add(token_level4_airdroped, token_id, weapon_token_id);
            };
        } else if(airdrop_level == 5) {
            let token_level5_airdroped = &mut borrow_global_mut<AirdropInfo>(manager_addr).token_level5_airdroped;
            if(!table::contains(token_level5_airdroped, token_id)) {
                table::add(token_level5_airdroped, token_id, weapon_token_id);
            };
        }
    }



    

}