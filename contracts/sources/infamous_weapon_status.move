/// This module provides Infamous Weapon Token binding status. (for resolve cycle dependency)
module infamous::infamous_weapon_status {

    use std::signer;
    use std::string::{String};
    use std::option::{Self, Option};
    
    use aptos_std::table::{Self, Table};


    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_token::token::{TokenId};

    use infamous::infamous_manager_cap;

    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_weapon_wear;


    struct WeaponWearEvent has drop, store, copy {
        operator: address,
        token_id: TokenId,
        weapon_token_id: TokenId,
        time: u64,
    }


    // store in manager account
    struct TokenWearWeapon has key {
        token_weapon_table: Table<TokenId, String>,
        token_wear_events_table: Table<TokenId, EventHandle<WeaponWearEvent>>,
    }

    
    public fun get_token__weapon_token_name(token_id: TokenId): Option<String> acquires TokenWearWeapon { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_weapon = option::none();
        if(exists<TokenWearWeapon>(manager_addr)) {
            let token_weapon_table = &borrow_global<TokenWearWeapon>(manager_addr).token_weapon_table;
            if(table::contains(token_weapon_table, token_id)) {
                cur_weapon = option::some(*table::borrow(token_weapon_table, token_id));
            }
            
        };
        cur_weapon
    }

    
    public(friend) fun update_token__weapon_token_name(token_id: TokenId, weapon_token_name: String) acquires TokenWearWeapon { 

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_token_wear_weapon(&manager_signer);

        let token_weapon_table = &mut borrow_global_mut<TokenWearWeapon>(manager_addr).token_weapon_table;
        if(table::contains(token_weapon_table, token_id)) {
            table::remove(token_weapon_table, token_id);
        };
        table::add(token_weapon_table, token_id, weapon_token_name);
    }

    
    public(friend) fun emit_wear_event(account: &signer, owner: address, token_id: TokenId, weapon_token_id: TokenId) acquires TokenWearWeapon {
        let account_addr = signer::address_of(account);
        let token_wear_events_table_mut = &mut borrow_global_mut<TokenWearWeapon>(account_addr).token_wear_events_table;

        if(!table::contains(token_wear_events_table_mut, token_id)) {
            table::add(token_wear_events_table_mut, token_id, account::new_event_handle<WeaponWearEvent>(account));
        };
        let wear_events_mut = table::borrow_mut(token_wear_events_table_mut, token_id);
        event::emit_event<WeaponWearEvent>(
            wear_events_mut,
            WeaponWearEvent {
                operator: owner,
                token_id,
                weapon_token_id,
                time: timestamp::now_seconds(),
            });
    }

    
    
    fun initialize_token_wear_weapon(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenWearWeapon>(account_addr)) {
            move_to(
                account,
                TokenWearWeapon {
                    token_weapon_table: table::new<TokenId, String>(),
                    token_wear_events_table: table::new<TokenId, EventHandle<WeaponWearEvent>>(), 
                }
            );
        }
    }


}