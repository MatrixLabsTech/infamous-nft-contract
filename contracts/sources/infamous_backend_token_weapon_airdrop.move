/// This module provides airdrop control of weapon Token.
module infamous::infamous_backend_token_weapon_airdrop {

    use std::signer;
    use std::error;
    use std::string::{ String};
    use std::option;

    
    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_weapon_nft;
    use infamous::infamous_lock;
    use infamous::infamous_upgrade_level;

    const ETOKEN_LOCKED_MISSED: u64 = 1;
    const ETOKEN_NOT_OWNED_BY_RECEIVER: u64 = 2;
    const ETOKEN_AIRDROPED: u64 = 3;
    const EACCOUNT_MUSTBE_AUTHED: u64 = 4;
    const ELEVEL_MUST_GREATER: u64 = 5;


    
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

    public entry fun airdrop_level_five(sender: &signer, token_name: String, receiver_addr: address, weapon: String, tiers: String, grades: String, attributes: String,) acquires AirdropInfo {
        airdrop(sender, token_name, receiver_addr, weapon, tiers, grades, attributes, 5);
    }


    fun airdrop(sender: &signer, token_name: String, receiver_addr: address, weapon: String, tiers: String, grades: String, attributes: String, airdrop_level: u64 ) acquires AirdropInfo {
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let collection_name = infamous_common::infamous_collection_name();
        let creator = manager_addr;
        let token_id = infamous_weapon_nft::resolve_token_id(creator, collection_name, token_name);

        
        let option_lock_addr = infamous_lock::token_lock_address(token_id);
        // token lockd ?
        if(option::is_some(&option_lock_addr)) { // airdrop token under lock

            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(ETOKEN_LOCKED_MISSED));

            // 2.check token lockd by receiver
            let locked_addr = option::extract(&mut option_lock_addr);
            assert!(receiver_addr == locked_addr, error::invalid_argument(ETOKEN_NOT_OWNED_BY_RECEIVER));

            // check level greater
            let token_level = infamous_upgrade_level::get_token_level(token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(ELEVEL_MUST_GREATER));            

            // 3.check token airdroped
            assert!(!is_token__airdroped(token_id, airdrop_level), error::invalid_argument(ETOKEN_AIRDROPED));

            let weapon_token_id = infamous_weapon_nft::airdrop(receiver_addr, weapon, tiers, grades, attributes);
            update_token_airdroped(token_id, airdrop_level, weapon_token_id);
        } else {
            // 1. check the receiver is the owner
            assert!(token::balance_of(receiver_addr, token_id) == 1, error::invalid_argument(ETOKEN_NOT_OWNED_BY_RECEIVER));

            
            // check level greater
            let token_level = infamous_upgrade_level::get_token_level(token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(ELEVEL_MUST_GREATER));
            
            // 3.check token airdroped
            assert!(!is_token__airdroped(token_id, airdrop_level), error::invalid_argument(ETOKEN_AIRDROPED));

            let weapon_token_id = infamous_weapon_nft::airdrop(receiver_addr, weapon, tiers, grades, attributes);
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