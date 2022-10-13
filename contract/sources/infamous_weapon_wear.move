module infamous::infamous_weapon_wear {


    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{String, utf8};
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
    use infamous::infamous_stake;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const WEAPON_NOT_OWNED_BY_SENDER: u64 = 2;
    const OLD_WEAPON_MISSED: u64 = 3;
    const WEAPON_DONT_HAVE_WEAPON_PROPERTY: u64 = 4;
    const TOKEN_NOT_REVEALED: u64 = 5;
    const TOKEN_STAKED_MISSED: u64 = 6;
    
    
    struct WeaponWearEvent has drop, store {
        operator: address,
        token_id: TokenId,
        weapon_token_id: TokenId,
        time: u64,
    }



    // store in manager account
    struct TokenWearWeapon has key {
        weapon_wear_events: EventHandle<WeaponWearEvent>,
    }

    /// wear weapon called by weapon owner
    public entry fun wear_weapon(sender: &signer, token_name: String, weapon_name: String) acquires TokenWearWeapon {
        let sender_addr = signer::address_of(sender);

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        // check weapon owned by sender
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        let weapon_creator = manager_addr;
        let new_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, weapon_name);
        assert!(token::balance_of(sender_addr, new_weapon_token_id) == 1, error::invalid_argument(WEAPON_NOT_OWNED_BY_SENDER));

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);

        
        let sender_addr = signer::address_of(sender);

        let option_stake_addr = infamous_stake::token_stake_address(token_id);
        // token staked?
        if(option::is_some(&option_stake_addr)) { // wear weapon under stake
        
            // 1. check the manager is the owner
            assert!(token::balance_of(manager_addr, token_id) == 1, error::invalid_state(TOKEN_STAKED_MISSED));
        
            // 2.check token revealed
            let (revealed, old_weapon_token_name) = get_token__revealed__weapon_token_name(manager_addr, token_id);
            assert!(revealed, error::invalid_argument(TOKEN_NOT_REVEALED));

            // 3.check token staked by sender or called by manager self
            let staked_addr = option::extract(&mut option_stake_addr);
            assert!(sender_addr == staked_addr, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);

            
            // update properties
            infamous_nft::update_token_uri_with_properties(manager_addr, token_name);

            
        } else { // not under stake
            // 1. check the sender is the owner
            assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));
            
            // 2.check token revealed
            let (revealed, old_weapon_token_name) = get_token__revealed__weapon_token_name(sender_addr, token_id);
            assert!(revealed, error::invalid_argument(TOKEN_NOT_REVEALED));

            exchange__old_weapon__to__new_weapon(sender, &manager_signer, old_weapon_token_name, new_weapon_token_id);

            // update properties
            infamous_nft::update_token_uri_with_properties(sender_addr, token_name);


        };


        initialize_wear_weapon_event(&manager_signer);
        emit_wear_event(manager_addr, sender_addr, token_id, new_weapon_token_id);
        
    }


     fun exchange__old_weapon__to__new_weapon(sender: &signer, manager_signer: &signer, old_weapon_token_name: Option<String>, new_weapon_token_id: TokenId) {
        let manager_addr = signer::address_of(manager_signer);
        let weapon_creator = manager_addr;
        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        // 1.transfer back old weapon
        if (option::is_some(&old_weapon_token_name)) { // old weapon
            let old_weapon_name = option::extract(&mut old_weapon_token_name);
            let old_weapon_token_id = infamous_weapon_nft::resolve_token_id(weapon_creator, weapon_collection_name, old_weapon_name);
            assert!(token::balance_of(manager_addr, old_weapon_token_id) == 1, error::invalid_state(OLD_WEAPON_MISSED));
            // transfer back old weapon
            transfer(manager_signer, sender, old_weapon_token_id);
        };

        // 2. lock new weapon to manager
        transfer(sender, manager_signer, new_weapon_token_id);
     }


     fun transfer(from: &signer, to: &signer, token_id: TokenId) {
        let from_addr = signer::address_of(from);
        let to_addr = signer::address_of(to);
        if(from_addr != to_addr) {
         token::direct_transfer(from, to, token_id, 1);
        };
     }
     
    
    fun emit_wear_event(account: address, owner: address, token_id: TokenId, weapon_token_id: TokenId) acquires TokenWearWeapon {
        
        let token_wear_weapon_info = borrow_global_mut<TokenWearWeapon>(account);
        event::emit_event<WeaponWearEvent>(
            &mut token_wear_weapon_info.weapon_wear_events,
            WeaponWearEvent {
                operator: owner,
                token_id,
                weapon_token_id,
                time: timestamp::now_seconds(),
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


    fun get_token__revealed__weapon_token_name(owner: address, token_id: TokenId): (bool, Option<String>) { 
        let properties = token::get_property_map(owner, token_id);
        let weapon_token_name_key = &infamous_common::infamous_weapon_token_name_key();
        let revealed = property_map::contains_key(&properties, &utf8(b"revealed"));
        let cur_weapon = option::none();
        if(property_map::contains_key(&properties, weapon_token_name_key)) {
            cur_weapon = option::some(property_map::read_string(&properties, weapon_token_name_key));
        };
        (revealed, cur_weapon)
    }




    

    fun update_token_weapon(token_id: TokenId, owner_addr: address, weapon_token_id: TokenId, weapon_token_name: String) {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let (creator, collection, name, _property_version) = token::get_token_id_fields(&token_id);
        let token_data_id = token::create_token_data_id(creator, collection, name);

        // get weapon weapon
        let weapon = get_weapon__weapon_property(owner_addr, weapon_token_id);

        let keys = vector<String>[infamous_common::infamous_weapon_key(), infamous_common::infamous_weapon_token_name_key()];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&weapon), bcs::to_bytes<String>(&weapon_token_name)];
        let types = vector<String>[utf8(b"0x1::string::String"), utf8(b"0x1::string::String")];
        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
    }

    
    
    fun get_weapon__weapon_property(owner: address, weapon_token_id: TokenId): String { 
        let properties = token::get_property_map(owner, weapon_token_id);
        let weapon_key = &infamous_common::infamous_weapon_key();
        assert!(property_map::contains_key(&properties, weapon_key), error::invalid_state(WEAPON_DONT_HAVE_WEAPON_PROPERTY));
        property_map::read_string(&properties, weapon_key)
    }

    





}