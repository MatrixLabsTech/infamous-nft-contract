/// This module provides accessory open box.
module infamous::infamous_backend_token_accessory_open_box {

    use std::signer;
    use std::error;
    use std::string::{ String};

    

    
    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_accessory_nft;

    const EACCOUNT_MUSTBE_AUTHED: u64 = 1;
    const EWEAPON_BOX_ALREADY_OPENED: u64 = 2;

    struct OpenBoxStatus has key {
        open_status: Table<TokenId, bool>
    }
    
    fun initialize_open_box_status(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<OpenBoxStatus>(account_addr)) {
            move_to(
                account,
                OpenBoxStatus {
                    open_status: table::new<TokenId, bool>(),
                }
            );
        }
    }


    public entry fun open_box(sender: &signer, accessory_token_name: String, name: String, kind: String, gender: String, attributes: String,) acquires OpenBoxStatus {

        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        initialize_open_box_status(&manager_signer);

        
        // resolve token id
        let creator = manager_addr;
        let collection_name = infamous_common::infamous_accessory_collection_name();
        let token_id = infamous_accessory_nft::resolve_token_id(creator, collection_name, accessory_token_name);

        // check opened
        assert!(!is_box__opened(token_id), error::invalid_state(EWEAPON_BOX_ALREADY_OPENED));

        // update accessory token properties
        let token_data_id = token::create_token_data_id(creator, collection_name, accessory_token_name);
        infamous_accessory_nft::mutate_token_properties(&manager_signer, token_data_id, name, kind, gender, attributes,);
        update_box_opened(token_id);
    }

     
    public fun is_box__opened(token_id: TokenId): bool acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let box_opend = false;
        if(exists<OpenBoxStatus>(manager_addr)) {
            let open_status = &borrow_global<OpenBoxStatus>(manager_addr).open_status;
            box_opend = table::contains(open_status, token_id);
        };
        box_opend
    }

     
    fun update_box_opened(token_id: TokenId) acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_open_box_status(&manager_signer);

        let open_status = &mut borrow_global_mut<OpenBoxStatus>(manager_addr).open_status;
        if(!table::contains(open_status, token_id)) {
            table::add(open_status, token_id, true);
        };
    }


    

}