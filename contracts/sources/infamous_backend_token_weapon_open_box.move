/// This module provides weapon open box.
/// InfamousBackendTokenWeaponOpenBox used to mutate weapon nft's property by authed account 
module infamous::infamous_backend_token_weapon_open_box {

    use std::signer;
    use std::error;
    use std::string::{ String};
    use aptos_std::table::{Self, Table};
    use aptos_token::token::{Self, TokenId};
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_weapon_nft;

    //
    // Errors
    //
    /// Error when some fun need backend authed, but called with no authed account.
    const EACCOUNT_MUSTBE_AUTHED: u64 = 1;
    /// Error when call open_box multi times
    const EWEAPON_BOX_ALREADY_OPENED: u64 = 2;

    struct OpenBoxStatus has key {
        // store the token open status
        open_status: Table<TokenId, bool>
    }

    /// open weapon box, mutate infamous weapon nft with certain properties.
    public entry fun open_box(sender: &signer, weapon_token_name: String, name: String, grade: String, attributes: String,) acquires OpenBoxStatus {

        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        initialize_open_box_status(&manager_signer);

        
        // resolve token id
        let creator = manager_addr;
        let collection_name = infamous_common::infamous_weapon_collection_name();
        let token_id = infamous_weapon_nft::resolve_token_id(creator, collection_name, weapon_token_name);

        // check opened
        assert!(!is_box__opened(token_id), error::invalid_state(EWEAPON_BOX_ALREADY_OPENED));

        // update weapon token properties
        let token_data_id = token::create_token_data_id(creator, collection_name, weapon_token_name);
        infamous_weapon_nft::mutate_token_properties(&manager_signer, token_data_id, name, grade, attributes,);
        update_box_opened(token_id);
    }

    /// check box opened
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

    /// update infamous weapon token open status 
    fun update_box_opened(token_id: TokenId) acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_open_box_status(&manager_signer);

        let open_status = &mut borrow_global_mut<OpenBoxStatus>(manager_addr).open_status;
        if(!table::contains(open_status, token_id)) {
            table::add(open_status, token_id, true);
        };
    }

    /// init openboxstatus store to account
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

    

}