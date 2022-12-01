/// This module provides Infamous Token binding status. (for resolve cycle dependency)
module infamous::infamous_link_status {

    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8};
    use std::option::{Self, Option};
    use std::vector;
    
    use aptos_std::table::{Self, Table};


    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_token::token::{TokenId};

    use infamous::infamous_manager_cap;

    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_weapon_wear;
    friend infamous::infamous_change_accesory;

    const EWEAR_WEAPON_ONLY_CANBE_CALLED_ONECE_ADAY: u64 = 1;
    const ECHANGE_ACCESSORY_ONLY_CANBE_CALLED_ONECE_ADAY: u64 = 2;

    const CHANGE_GAP: u64 = 60;


    struct LinkEvent has drop, store, copy {
        operator: address,
        type: String,
        token_id: TokenId,
        change_token_id: TokenId,
        name: String,
        time: u64,
    }


    // store in manager account
    struct TokenLink has key {
        token_accessory_table: Table<TokenId, Table<String, TokenId>>,
        token_weapon_table: Table<TokenId, TokenId>,

        tokon_wear_weapon_time_table: Table<TokenId, u64>,
        tokon_change_accessory_time_table: Table<TokenId, u64>,

        token_link_events_table: Table<TokenId, EventHandle<LinkEvent>>,
        token_link_events: EventHandle<LinkEvent>,
    }

    
    public fun get_token__weapon_token_id(token_id: TokenId): Option<TokenId> acquires TokenLink { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_weapon = option::none();
        if(exists<TokenLink>(manager_addr)) {
            let token_weapon_table = &borrow_global<TokenLink>(manager_addr).token_weapon_table;
            if(table::contains(token_weapon_table, token_id)) {
                cur_weapon = option::some(*table::borrow(token_weapon_table, token_id));
            }
            
        };
        cur_weapon
    }

    
    public(friend) fun update_token__weapon_token_id(token_id: TokenId, weapon_token_id: TokenId) acquires TokenLink { 

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_token_link(&manager_signer);

        
        let tokon_wear_weapon_time_table = &mut borrow_global_mut<TokenLink>(manager_addr).tokon_wear_weapon_time_table;
        let now = timestamp::now_seconds();
        if(table::contains(tokon_wear_weapon_time_table, token_id)) {
            let last_time = *table::borrow(tokon_wear_weapon_time_table, token_id);
            assert!(now - last_time >= CHANGE_GAP, error::aborted(EWEAR_WEAPON_ONLY_CANBE_CALLED_ONECE_ADAY));
            table::remove(tokon_wear_weapon_time_table, token_id);
        };
        table::add(tokon_wear_weapon_time_table, token_id, now);

        let token_weapon_table = &mut borrow_global_mut<TokenLink>(manager_addr).token_weapon_table;
        if(table::contains(token_weapon_table, token_id)) {
            table::remove(token_weapon_table, token_id);
        };
        table::add(token_weapon_table, token_id, weapon_token_id);
        
    }

    
    public fun get_token__accessory_token_id(token_id: TokenId, kind: String): Option<TokenId> acquires TokenLink { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let cur_accessory = option::none();
        if(exists<TokenLink>(manager_addr)) {
            let token_accessory_table = &borrow_global<TokenLink>(manager_addr).token_accessory_table;
            if(table::contains(token_accessory_table, token_id)) {
                let accessory_table = table::borrow(token_accessory_table, token_id);
                if (table::contains(accessory_table, kind)) {
                    cur_accessory = option::some(*table::borrow(accessory_table, kind));
                }
            }
            
        };
        cur_accessory
    }

    
    public(friend) fun update_token__accessory_token_ids(token_id: TokenId, kinds: vector<String>, token_ids: vector<TokenId>) acquires TokenLink { 

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_token_link(&manager_signer);

        // control time
        let tokon_change_accessory_time_table = &mut borrow_global_mut<TokenLink>(manager_addr).tokon_change_accessory_time_table;
        let now = timestamp::now_seconds();
        if(table::contains(tokon_change_accessory_time_table, token_id)) {
            let last_time = *table::borrow(tokon_change_accessory_time_table, token_id);
            assert!(now - last_time >= CHANGE_GAP, error::aborted(ECHANGE_ACCESSORY_ONLY_CANBE_CALLED_ONECE_ADAY));
            table::remove(tokon_change_accessory_time_table, token_id);
        };
        table::add(tokon_change_accessory_time_table, token_id, now);

        // control tokenids
        let token_accessory_table = &mut borrow_global_mut<TokenLink>(manager_addr).token_accessory_table;

        if(!table::contains(token_accessory_table, token_id)) {
            table::add(token_accessory_table, token_id, table::new<String, TokenId>());
        };

        let token_accessory_kind_table = table::borrow_mut(token_accessory_table, token_id);

        let i= 0;
        while (i < vector::length<String>(&kinds)) {
            let kind = *vector::borrow<String>(&kinds, i);
            let token_id = *vector::borrow<TokenId>(&token_ids, i);
            if(table::contains(token_accessory_kind_table, kind)) {
                table::remove(token_accessory_kind_table, kind);
            };
            table::add(token_accessory_kind_table, kind, token_id);
            i = i+ 1;
        }
        
    }


    
    public(friend) fun emit_wear_event(account: &signer, owner: address, token_id: TokenId, weapon_token_id: TokenId, weapon_name: String) acquires TokenLink {
        let account_addr = signer::address_of(account);
        let token_link_events_table_mut = &mut borrow_global_mut<TokenLink>(account_addr).token_link_events_table;

        if(!table::contains(token_link_events_table_mut, token_id)) {
            table::add(token_link_events_table_mut, token_id, account::new_event_handle<LinkEvent>(account));
        };
        let wear_events_mut = table::borrow_mut(token_link_events_table_mut, token_id);
        event::emit_event<LinkEvent>(
            wear_events_mut,
            LinkEvent {
                operator: owner,
                type: utf8(b"change equip"),
                token_id,
                change_token_id: weapon_token_id,
                name: weapon_name,
                time: timestamp::now_seconds(),
            });
        
        
        let token_link_events = &mut borrow_global_mut<TokenLink>(account_addr).token_link_events;
        event::emit_event<LinkEvent>(
            token_link_events,
            LinkEvent {
                operator: owner,
                type: utf8(b"change equip"),
                token_id,
                change_token_id: weapon_token_id,
                name: weapon_name,
                time: timestamp::now_seconds(),
            });
    }
    
    public(friend) fun emit_change_accessory_event(account: &signer, owner: address, token_id: TokenId, accessory_token_id: TokenId, kind: String, accessory_name: String) acquires TokenLink {
        let account_addr = signer::address_of(account);
        let token_link_events_table_mut = &mut borrow_global_mut<TokenLink>(account_addr).token_link_events_table;

        if(!table::contains(token_link_events_table_mut, token_id)) {
            table::add(token_link_events_table_mut, token_id, account::new_event_handle<LinkEvent>(account));
        };
        let wear_events_mut = table::borrow_mut(token_link_events_table_mut, token_id);

        let operate_to = kind;
        string::append(&mut operate_to, utf8(b":"));
        string::append(&mut operate_to, accessory_name);
        event::emit_event<LinkEvent>(
            wear_events_mut,
            LinkEvent {
                operator: owner,
                type: utf8(b"change accessory"),
                token_id,
                change_token_id: accessory_token_id,
                name: operate_to,
                time: timestamp::now_seconds(),
            });
        
        
        let token_link_events = &mut borrow_global_mut<TokenLink>(account_addr).token_link_events;
        event::emit_event<LinkEvent>(
            token_link_events,
            LinkEvent {
                operator: owner,
                type: utf8(b"change accessory"),
                token_id,
                change_token_id: accessory_token_id,
                name: operate_to,
                time: timestamp::now_seconds(),
            });
    }

    
    
    fun initialize_token_link(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenLink>(account_addr)) {
            move_to(
                account,
                TokenLink {
                    token_accessory_table: table::new<TokenId, Table<String, TokenId>>(),
                    token_weapon_table: table::new<TokenId, TokenId>(),
                    tokon_wear_weapon_time_table: table::new<TokenId, u64>(), 
                    tokon_change_accessory_time_table: table::new<TokenId, u64>(), 
                    token_link_events_table: table::new<TokenId, EventHandle<LinkEvent>>(), 
                    token_link_events: account::new_event_handle<LinkEvent>(account),
                }
            );
        }
    }


}