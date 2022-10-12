module infamous::infamous_weapon_wear {


    use std::bcs;
    use std::error;
    use std::signer;
    use std::string::{Self, String, utf8};
    use std::option::{Self, Option};


    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_token::token::{Self, TokenId};
     use aptos_token::property_map::{Self, PropertyMap};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_weapon_nft;


    const TOKEN_NOT_OWNED_BY_SENDER: u64 = 1;
    const WEAPON_NOT_OWNED_BY_SENDER: u64 = 2;
    const OLD_WEAPON_MISSED: u64 = 3;
    const WEAPON_DONT_HAVE_WEAPON_PROPERTY: u64 = 4;
    
    
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


    public entry fun wear_weapon(sender: &signer, token_name: String, weapon_name: String) acquires TokenWearWeapon {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_name);
        let sender_addr = signer::address_of(sender);
        assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_SENDER));


        let weapon_collection_name = infamous_common::infamous_weapon_collection_name();
        let weapon_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, weapon_name);
        assert!(token::balance_of(sender_addr, weapon_token_id) == 1, error::invalid_argument(WEAPON_NOT_OWNED_BY_SENDER));


        let weapon_token_name = get_token__weapon_token_name_property(sender_addr, token_id);
        if (option::is_some(&weapon_token_name)) {
            let old_weapon_name = option::extract(&mut weapon_token_name);
            let old_weapon_token_id = infamous_weapon_nft::resolve_token_id(manager_addr, weapon_collection_name, old_weapon_name);
            assert!(token::balance_of(manager_addr, old_weapon_token_id) == 1, error::invalid_state(OLD_WEAPON_MISSED));
            // transfer back old weapon
            if(manager_addr != sender_addr){
                token::direct_transfer(&manager_signer, sender, old_weapon_token_id, 1);
            };
        };
        // change token weapon property
        update_token_weapon(token_id, sender_addr, weapon_token_id, weapon_name);
        // lock weapon
        if(manager_addr != sender_addr){
            token::direct_transfer(sender, &manager_signer, weapon_token_id, 1);
        };

        update_token_uri_with_properties(sender_addr, token_name);

        initialize_wear_weapon_event(&manager_signer);
        emit_wear_event(manager_addr, sender_addr, token_id, weapon_token_id);
        
    }


     public fun update_token_uri_with_properties(owner_addr: address, name: String) {
      
        let creator = infamous_manager_cap::get_manager_signer();
        let creator_addr = signer::address_of(&creator);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator_addr, collection_name, name);
        let properties = token::get_property_map(owner_addr, token_id);
        let properties_string = utf8(b"");
        append_property(&mut properties_string, properties, utf8(b"background"));
        append_property(&mut properties_string, properties, utf8(b"clothing"));
        append_property(&mut properties_string, properties, utf8(b"ear"));
        append_property(&mut properties_string, properties, utf8(b"eyes"));
        append_property(&mut properties_string, properties, utf8(b"eyebrow"));
        append_property(&mut properties_string, properties, utf8(b"accessories"));
        append_property(&mut properties_string, properties, utf8(b"hear"));
        append_property(&mut properties_string, properties, utf8(b"mouth"));
        append_property(&mut properties_string, properties, utf8(b"neck"));
        append_property(&mut properties_string, properties, utf8(b"tatto"));
        append_property(&mut properties_string, properties, utf8(b"gender"));
        append_property(&mut properties_string, properties, utf8(b"weapon"));
        let hash_string = infamous_common::string_hash_string(properties_string);
        let base_uri = infamous_common::infamous_base_token_uri();
        string::append(&mut base_uri, hash_string);
        string::append(&mut base_uri, utf8(b".png"));

        let token_data_id = token::create_token_data_id(creator_addr, collection_name, name);
        token::mutate_tokendata_uri(&creator, token_data_id, base_uri);

     }

     

     fun append_property(properties_string: &mut String, properties: PropertyMap, property_key: String) {
        if(property_map::contains_key(&properties, &property_key)) {
            string::append(properties_string, property_map::read_string(&properties, &property_key));
        };
     }
    
    fun emit_wear_event(account: address, owner: address, token_id: TokenId, weapon_token_id: TokenId) acquires TokenWearWeapon {
        
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


    public fun get_token__weapon_token_name_property(owner: address, token_id: TokenId): Option<String> { 
        let properties = token::get_property_map(owner, token_id);
        let weapon_token_name_key = &infamous_common::infamous_weapon_token_name_key();
        let cur_weapon = option::none();
        if(property_map::contains_key(&properties, weapon_token_name_key)) {
            cur_weapon = option::some(property_map::read_string(&properties, weapon_token_name_key));
        };
        cur_weapon
    }

    
    public fun get_weapon__weapon_property(owner: address, weapon_token_id: TokenId): String { 
        let properties = token::get_property_map(owner, weapon_token_id);
        let weapon_key = &infamous_common::infamous_weapon_key();
        assert!(property_map::contains_key(&properties, weapon_key), error::invalid_state(WEAPON_DONT_HAVE_WEAPON_PROPERTY));
        property_map::read_string(&properties, weapon_key)
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





}