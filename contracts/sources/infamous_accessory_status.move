/// This module provides Infamous Weapon Token binding status. (for resolve cycle dependency)
module infamous::infamous_accessory_status {

    use std::signer;
    use std::error;
    use std::string::{String};
    use std::option::{Self, Option};
    
    use aptos_std::table::{Self, Table};


    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_token::token::{TokenId};

    use infamous::infamous_manager_cap;

    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_accessory_wear;

    const ECHANGE_ACCESSORY_ONLY_CANBE_CALLED_ONECE_ADAY: u64 = 1;

    const CHANGE_ACCESSORY_GAP: u64 = 60;


    struct AccessoryChangeEvent has drop, store, copy {
        operator: address,
        token_id: TokenId,
        accessory_token_id: TokenId,
        accessory_name: String,
        time: u64,
    }


    // store in manager account
    struct TokenChangeAccessory has key {
        token_accessory_table: Table<TokenId, Table<String, String>>,
        token_change_events_table: Table<TokenId, EventHandle<AccessoryChangeEvent>>,
        tokon_change_accessory_time_table: Table<TokenId, u64>,
        token_change_accessory_events: EventHandle<AccessoryChangeEvent>,
    }

    
    public fun get_token__accessory_token_id(token_id: TokenId, kind: String): Option<TokenId> acquires TokenChangeAccessory { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_accessory = option::none();
        if(exists<TokenChangeAccessory>(manager_addr)) {
            let token_accessory_table = &borrow_global<TokenChangeAccessory>(manager_addr).token_accessory_table;
            if(table::contains(token_accessory_table, token_id)) {
                let accessory_table = *table::borrow(token_accessory_table, token_id);
                if (accessory_table::contains(token_accessory_table, kind)) {
                    cur_accessory = option::some(*table::borrow(accessory_table, kind));
                }
            }
            
        };
        cur_accessory
    }

    
    public(friend) fun update_token__accessory_token_ids(token_id: TokenId, kinds: vector<String>, token_ids: vector<string>) acquires TokenChangeAccessory { 

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_token_change_accessory(&manager_signer);

        // control time
        let tokon_change_accessory_time_table = &mut borrow_global_mut<TokenChangeAccessory>(manager_addr).tokon_change_accessory_time_table;
        let now = timestamp::now_seconds();
        if(table::contains(tokon_change_accessory_time_table, token_id)) {
            let last_time = *table::borrow(tokon_change_accessory_time_table, token_id);
            assert!(now - last_time >= CHANGE_ACCESSORY_GAP, error::aborted(ECHANGE_ACCESSORY_ONLY_CANBE_CALLED_ONECE_ADAY));
            table::remove(tokon_change_accessory_time_table, token_id);
        };
        table::add(tokon_change_accessory_time_table, token_id, now);

        // control tokenids
        let token_accessory_table = &mut borrow_global_mut<TokenChangeAccessory>(manager_addr).token_accessory_table;
        if(table::contains(token_accessory_table, token_id)) {
            table::remove(token_accessory_table, token_id);
        } else {
            table::add(token_accessory_table, token_id, accessory_token_name);
        }
        
    }

    
    public(friend) fun emit_change_event(account: &signer, owner: address, token_id: TokenId, accessory_token_id: TokenId, accessory_name: String) acquires TokenChangeAccessory {
        let account_addr = signer::address_of(account);
        let token_change_events_table_mut = &mut borrow_global_mut<TokenChangeAccessory>(account_addr).token_change_events_table;

        if(!table::contains(token_change_events_table_mut, token_id)) {
            table::add(token_change_events_table_mut, token_id, account::new_event_handle<AccessoryChangeEvent>(account));
        };
        let change_events_mut = table::borrow_mut(token_change_events_table_mut, token_id);
        event::emit_event<AccessoryChangeEvent>(
            change_events_mut,
            AccessoryChangeEvent {
                operator: owner,
                token_id,
                accessory_token_id,
                accessory_name,
                time: timestamp::now_seconds(),
            });
        
        
        let token_change_accessory_events = &mut borrow_global_mut<TokenChangeAccessory>(account_addr).token_change_accessory_events;
        event::emit_event<AccessoryChangeEvent>(
            token_change_accessory_events,
            AccessoryChangeEvent {
                operator: owner,
                token_id,
                accessory_token_id,
                accessory_name,
                time: timestamp::now_seconds(),
            });
    }

    
    
    fun initialize_token_change_accessory(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenChangeAccessory>(account_addr)) {
            move_to(
                account,
                TokenChangeAccessory {
                    token_accessory_table: table::new<TokenId, Table<String, String>>(),
                    token_change_events_table: table::new<TokenId, EventHandle<AccessoryChangeEvent>>(), 
                    tokon_change_accessory_time_table: table::new<TokenId, u64>(), 
                    token_change_accessory_events: account::new_event_handle<AccessoryChangeEvent>(account),
                }
            );
        }
    }


}