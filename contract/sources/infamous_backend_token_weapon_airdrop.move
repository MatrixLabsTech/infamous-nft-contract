module infamous::infamous_backend_token_weapon_airdrop {

    use std::bcs;
    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8};
    use std::option;



    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

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

    public entry fun airdrop_level_four(sender: &signer, token_name: String, receiver_addr: address, weapon: String, meterial: String) {
        airdrop(sender, token_name, receiver_addr, weapon, meterial, utf8(b"4"), 4);
    }


    public entry fun airdrop_level_five(sender: &signer, token_name: String, receiver_addr: address, weapon: String, meterial: String) {
        airdrop(sender, token_name, receiver_addr, weapon, meterial, utf8(b"5"), 5);
    }


    fun airdrop(sender: &signer, token_name: String, receiver_addr: address, weapon: String, meterial: String, weapon_level: String, airdrop_level: u64 ) {
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
            let token_level = infamous_upgrade_level::get_token_level(manager_addr, token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(LEVEL_MUST_GREATER));            

            // 3.check token airdroped
            assert!(!is_token__airdroped(manager_addr, token_id, level_key), error::invalid_argument(TOKEN_AIRDROPED));

            infamous_weapon_nft::airdrop(receiver_addr, weapon, meterial, weapon_level);
            update_token_airdroped(token_id, level_key);
        } else {
            // 1. check the receiver is the owner
            assert!(token::balance_of(receiver_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_RECEIVER));

            
            // check level greater
            let token_level = infamous_upgrade_level::get_token_level(receiver_addr, token_id);
            assert!(token_level >= airdrop_level, error::invalid_argument(LEVEL_MUST_GREATER));
            
            // 3.check token airdroped
            assert!(!is_token__airdroped(receiver_addr, token_id, level_key), error::invalid_argument(TOKEN_AIRDROPED));

            infamous_weapon_nft::airdrop(receiver_addr, weapon, meterial, weapon_level);
            update_token_airdroped(token_id, level_key);
        }



    }

    fun is_token__airdroped(owner: address, token_id: TokenId, level_key: String): bool { 
        let properties = token::get_property_map(owner, token_id);
        property_map::contains_key(&properties, &level_key)
    }

      

    fun update_token_airdroped(token_id: TokenId, level_key: String) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);

        let keys = vector<String>[level_key];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&utf8(b"yes"))];
        let types = vector<String>[utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }



    

}