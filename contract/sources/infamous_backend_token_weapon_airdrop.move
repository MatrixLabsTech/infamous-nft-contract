module infamous::infamous_backend_token_weapon_airdrop {

    use std::bcs;
    use std::signer;
    use std::error;
    use std::string::{String, utf8};
    use std::option;



    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_weapon_nft;
    use infamous::infamous_stake;

    const TOKEN_STAKED_MISSED: u64 = 1;
    const TOKEN_NOT_OWNED_BY_RECEIVER: u64 = 2;
    const TOKEN_AIRDROPED: u64 = 3;
    const ACCOUNT_MUSTBE_AUTHED: u64 = 4;


    public entry fun airdrop(sender: &signer, token_name: String, receiver_addr: address, weapon: String, meterial: String, level: String, ) {
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let collection_name = infamous_common::infamous_collection_name();
        let creator = manager_addr;
        let token_id = infamous_weapon_nft::resolve_token_id(creator, collection_name, token_name);

        
        let option_stake_addr = infamous_stake::token_stake_address(token_id);
        // token staked ?
        if(option::is_some(&option_stake_addr)) { // airdrop token under stake

            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(TOKEN_STAKED_MISSED));

            // 2.check token staked by receiver
            let staked_addr = option::extract(&mut option_stake_addr);
            assert!(receiver_addr == staked_addr, error::invalid_argument(TOKEN_NOT_OWNED_BY_RECEIVER));

            // 3.check token airdroped
            assert!(!is_token__airdroped(manager_addr, token_id), error::invalid_argument(TOKEN_AIRDROPED));

            infamous_weapon_nft::airdrop(receiver_addr, weapon, meterial, level);
            update_token_airdroped(token_id);
        } else {
            // 1. check the receiver is the owner
            assert!(token::balance_of(receiver_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_RECEIVER));
            
            // 3.check token airdroped
            assert!(!is_token__airdroped(receiver_addr, token_id), error::invalid_argument(TOKEN_AIRDROPED));

            infamous_weapon_nft::airdrop(receiver_addr, weapon, meterial, level);
            update_token_airdroped(token_id);
        }



    }

    fun is_token__airdroped(owner: address, token_id: TokenId): bool { 
        let properties = token::get_property_map(owner, token_id);
        property_map::contains_key(&properties, &utf8(b"airdroped"))
    }

      

    fun update_token_airdroped(token_id: TokenId) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);

        let keys = vector<String>[utf8(b"airdroped")];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&utf8(b"yes"))];
        let types = vector<String>[utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }



    

}