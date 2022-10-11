module infamous::infamous_weapon_wear {


    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::option::{Self, Option};


    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_token::token::{Self, TokenId};
    use aptos_token::property_map;

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_weapon_nft;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const WEAPON_NOT_OWNED_BY_SENDER: u64 = 2;
    const OLD_WEAPON_MISSED: u64 = 3;
    
    
    struct WeaponWearEvent has drop, store {
        owner: address,
        token_id: TokenId,
        weapon_token_id: TokenId,
        start_time: u64,
    }



    // store in manager account
    struct TokenWearWeapon has key {
        weapon_wear_events: EventHandle<WeaponWearEvent>,
    }


    public entry fun wear_weapon(sender: &signer, token_name: String, weapon_name: String)  acquires TokenWearWeapon {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);
        let sender_addr = signer::address_of(sender);
        assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));


        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        let weapon_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, weapon_name);
        assert!(token::balance_of(sender_addr, weapon_token_id) == 1, error::invalid_argument(WEAPON_NOT_OWNED_BY_SENDER));


        let weapon = get_token_weapon(sender_addr, token_id);
        if (option::is_some(&weapon)) {
            let old_weapon_name = option::extract(&mut weapon);
            let old_weapon_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, old_weapon_name);
            assert!(token::balance_of(manager_addr, old_weapon_token_id) == 1, error::invalid_state(OLD_WEAPON_MISSED));
            // transfer back old weapon
            token::direct_transfer(&manager_signer, sender, old_weapon_token_id, 1);
        };
        // change token weapon property
        update_weapon(token_id, weapon_name);
        // lock weapon
        token::direct_transfer(sender, &manager_signer, weapon_token_id, 1);

        initialize_wear_weapon_event(&manager_signer);
        emit_minted_event(manager_addr, sender_addr, token_id, weapon_token_id);
        
    }


    
    fun emit_minted_event(account: address, owner: address, token_id: TokenId, weapon_token_id: TokenId) acquires TokenWearWeapon {
        
        let token_wear_weapon_info = borrow_global_mut<TokenWearWeapon>(account);
        event::emit_event<WeaponWearEvent>(
            &mut token_wear_weapon_info.weapon_wear_events,
            WeaponWearEvent {
                owner,
                token_id,
                weapon_token_id,
                start_time: timestamp::now_seconds(),
            });
    }

    

    fun initialize_wear_weapon_event(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenWearWeapon>(account_addr)) {
            move_to(
                account,
                TokenWearWeapon {
                    weapon_wear_events: account::new_event_handle<WeaponWearEvent>(account),
                }
            );
        }
    }



    
    public fun get_token_weapon(owner: address, token_id: TokenId): Option<String> { 
        let properties = token::get_property_map(owner, token_id);
        let weapon_key = &infamous_common::infamous_weapon_key();
        let cur_weapon = option::none();
        if(property_map::contains_key(&properties, weapon_key)) {
            cur_weapon = option::some(property_map::read_string(&properties, weapon_key));
        };
        cur_weapon
    }

    

    fun update_weapon(token_id: TokenId, weapon_name: String) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);

        let keys = vector<String>[infamous_common::infamous_weapon_key()];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&weapon_name)];
        let types = vector<String>[string::utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }





}