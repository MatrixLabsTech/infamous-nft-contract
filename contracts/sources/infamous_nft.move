/// This module provides the Infamous Token manager.
module infamous::infamous_nft {

    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8 };
    
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use aptos_token::property_map;
    use aptos_token::token::{Self, TokenId, TokenDataId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_properties_url_encode_map;

    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_weapon_wear;

    const ECOLLECTION_NOT_PUBLISHED: u64 = 1;
    const EMINT_COUNT_OUT_OF_PER_MAX: u64 = 2;
    const EMINT_COUNT_OUT_OF_MAX: u64 = 3;


    const PER_MAX: u64 = 10;
    const MAXIMUM: u64 = 1000;


    struct TokenMintedEvent has drop, store {
        token_receiver_address: address,
        token_id: TokenId,
    }


    // the collection mint infos
    struct CollectionInfo has key {
        counter: u64,
        per_minted_table: Table<address, u64>,
        token_mint_time_table: Table<TokenId, u64>,
        token_minted_events: EventHandle<TokenMintedEvent>,
        gender_table: Table<TokenDataId, String>,
    }


    fun init_module(source: &signer) {
        let collection_name = infamous_common::infamous_collection_name();
        let collection_uri = infamous_common::infamous_collection_uri();
        let description = infamous_common::infamous_description();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        token::create_collection_script(&manager_signer, collection_name, description, collection_uri, MAXIMUM, vector<bool>[false, true, false]);

        move_to(source, CollectionInfo {
            counter: 0, 
            per_minted_table: table::new(),
            token_mint_time_table: table::new(),
            gender_table: table::new(),
            token_minted_events: account::new_event_handle<TokenMintedEvent>(&manager_signer),
        });

       
    }

    
    public entry fun mint(receiver: &signer, count: u64) acquires CollectionInfo {
        // check per max
        assert!(count <= PER_MAX, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));

        // check max
        let source_addr = @infamous;
        assert!(exists<CollectionInfo>(source_addr), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        let collection_info = borrow_global_mut<CollectionInfo>(source_addr);
        assert!(collection_info.counter + count <= MAXIMUM, error::out_of_range(EMINT_COUNT_OUT_OF_MAX));

        // check minted + count < per max
        let receiver_addr = signer::address_of(receiver);
        let used = minted_count(&collection_info.per_minted_table, receiver_addr);
        assert!(used + count <= PER_MAX, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));

        // token infos
        let collection_name = infamous_common::infamous_collection_name();
        let base_token_name = infamous_common::infamous_base_token_name();
        let description = infamous_common::infamous_description();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let prev_count = collection_info.counter;
        let i = 0;
        while (i < count) {
            i = i + 1;
            let cur = prev_count + i;
            let name = infamous_common::append_num(base_token_name, cur);
            let uri = infamous_common::infamous_token_uri();

            let token_id = create_token_and_transfer_to_receiver(&manager_signer, receiver, collection_name, name, uri, description);
            table::add(&mut collection_info.token_mint_time_table, token_id, timestamp::now_seconds());
            emit_minted_event(collection_info, receiver_addr, manager_addr, collection_name, name);
        };

        // change CollectionInfo status
        let counter_ref = &mut collection_info.counter;
        *counter_ref = prev_count + count;
        if (!table::contains(&collection_info.per_minted_table, receiver_addr)) {
            table::add(&mut collection_info.per_minted_table, receiver_addr, count);
        } else {
            let table_reciver_ref = table::borrow_mut(&mut collection_info.per_minted_table, receiver_addr);
            *table_reciver_ref = used + count;
        };
    }

    
    public fun resolve_token_id(creator_addr: address, collection_name: String, token_name: String): TokenId {
        token::create_token_id_raw(creator_addr, collection_name, token_name, 0)
    }

    public fun get_token_mint_time(token_id: TokenId): u64 acquires CollectionInfo {
        let source_addr = @infamous;
        assert!(exists<CollectionInfo>(source_addr), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        let token_mint_time_table = &borrow_global<CollectionInfo>(source_addr).token_mint_time_table;
        *table::borrow(token_mint_time_table, token_id)
     }

     public(friend) fun update_token_uri_with_properties(owner_addr: address, name: String, grade: String) acquires CollectionInfo {
      
        let creator = infamous_manager_cap::get_manager_signer();
        let creator_addr = signer::address_of(&creator);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = resolve_token_id(creator_addr, collection_name, name);
        let properties = &token::get_property_map(owner_addr, token_id);
        let token_data_id = token::create_token_data_id(creator_addr, collection_name, name);

        update_token_uri_with_known_properties(token_data_id,
        property_map::read_string(properties, &utf8(b"background")),
        property_map::read_string(properties, &utf8(b"clothing")),
        property_map::read_string(properties, &utf8(b"earrings")),
        property_map::read_string(properties, &utf8(b"eyebrows")),
        property_map::read_string(properties, &utf8(b"face-accessories")),
        property_map::read_string(properties, &utf8(b"eyes")),
        property_map::read_string(properties, &utf8(b"hair")),
        property_map::read_string(properties, &utf8(b"mouth")),
        property_map::read_string(properties, &utf8(b"necklace")),
        property_map::read_string(properties, &utf8(b"tattoo")),
        property_map::read_string(properties, &utf8(b"weapon")), 
        grade,
        get_token_gender(token_data_id));
     }

     public(friend) fun set_token_gender(token_data_id: TokenDataId, gender: String) acquires CollectionInfo {
        let source_addr = @infamous;
        assert!(exists<CollectionInfo>(source_addr), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        let gender_table_mut = &mut borrow_global_mut<CollectionInfo>(source_addr).gender_table;
        table::add(gender_table_mut, token_data_id, gender);
     }
     
     public fun get_token_gender(token_data_id: TokenDataId): String acquires CollectionInfo {
        let source_addr = @infamous;
        assert!(exists<CollectionInfo>(source_addr), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        let gender_table = &borrow_global<CollectionInfo>(source_addr).gender_table;
        *table::borrow(gender_table, token_data_id)
     }
     
     public(friend) fun update_token_uri_with_known_properties(token_data_id: TokenDataId,
        background: String, clothing: String, earrings: String, eyebrows: String,
        face_accessories: String, eyes: String, hair: String,  
        mouth: String, necklace: String, tattoo: String, 
        weapon: String, grade: String, gender: String) {
        let creator = infamous_manager_cap::get_manager_signer();
        let gender_code = resolve_property_value_encode(gender, utf8(b"gender"), gender);
        let background_code = resolve_property_value_encode(gender, utf8(b"background"), background);
        let clothing_code = resolve_property_value_encode(gender, utf8(b"clothing"), clothing);
        let earrings_code = resolve_property_value_encode(gender, utf8(b"earrings"), earrings);
        let eyebrows_code = resolve_property_value_encode(gender, utf8(b"eyebrows"), eyebrows);
        let face_accessories_code = resolve_property_value_encode(gender, utf8(b"face-accessories"), face_accessories);
        let eyes_code = resolve_property_value_encode(gender, utf8(b"eyes"), eyes);
        let hair_code = resolve_property_value_encode(gender, utf8(b"hair"), hair);
        let mouth_code = resolve_property_value_encode(gender, utf8(b"mouth"), mouth);
        let necklace_code = resolve_property_value_encode(gender, utf8(b"necklace"), necklace);
        let tattoo_code = resolve_property_value_encode(gender, utf8(b"tattoo"), tattoo);
        let weapon_code = resolve_property_value_encode(gender, utf8(b"weapon"), weapon);
        let grade_code = resolve_property_value_encode(gender, utf8(b"grade"), grade);
        let properties_code_string = utf8(b"");
        string::append(&mut properties_code_string, gender_code);
        string::append(&mut properties_code_string, background_code);
        string::append(&mut properties_code_string, clothing_code);
        string::append(&mut properties_code_string, earrings_code);
        string::append(&mut properties_code_string, eyebrows_code);
        string::append(&mut properties_code_string, face_accessories_code);
        string::append(&mut properties_code_string, eyes_code);
        string::append(&mut properties_code_string, hair_code);
        string::append(&mut properties_code_string, mouth_code);
        string::append(&mut properties_code_string, necklace_code);
        string::append(&mut properties_code_string, tattoo_code);
        string::append(&mut properties_code_string, weapon_code);
        string::append(&mut properties_code_string, grade_code);
        let base_uri = infamous_common::infamous_base_token_uri();
        string::append(&mut base_uri, properties_code_string);
        string::append(&mut base_uri, utf8(b".png"));

        token::mutate_tokendata_uri(&creator, token_data_id, base_uri);

     }

     fun resolve_property_value_encode(gender: String, value_key: String, value: String): String {
        let key = utf8(b"");
        string::append(&mut key, gender);
        string::append(&mut key, value_key);
        string::append(&mut key, value);
        infamous_properties_url_encode_map::get_property_value_encode(key)
     }


     
    


    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }
    

    fun create_token_and_transfer_to_receiver(minter: &signer, receiver:&signer, collection_name: String, token_name: String, token_uri: String, description: String,): TokenId {
        
        let balance = 1;
        let maximum = 1;
        let minter_addr = signer::address_of(minter);
        token::create_token_script(minter, collection_name, token_name, description, balance,
        maximum,
        token_uri,
        minter_addr,
        0,
        0,
        vector<bool>[false, true, false, false, true],
        vector<String>[], vector<vector<u8>>[], vector<String>[],);

        let token_id = resolve_token_id(minter_addr, collection_name, token_name);
        token::direct_transfer(minter, receiver, token_id, balance);
        token_id
    }

    fun emit_minted_event(collection_info: &mut CollectionInfo, receiver_addr: address, creator_addr: address, collection_name: String, token_name: String) {
        event::emit_event<TokenMintedEvent>(
            &mut collection_info.token_minted_events,
            TokenMintedEvent {
                token_receiver_address: receiver_addr,
                token_id: resolve_token_id(creator_addr, collection_name, token_name),
            });
    }


    #[test_only]
    public fun initialize(user: &signer) {
        init_module(user);
    }


    #[test(user = @infamous, receiver = @0xBB, framework = @0x1,)]
    public fun mint_test(user: &signer, receiver: &signer, framework:&signer) acquires CollectionInfo {

        use aptos_framework::account;
        use aptos_framework::timestamp;
        timestamp::set_time_has_started_for_testing(framework);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        init_module(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        mint(receiver, 3);

        
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();

        let base_token_name = infamous_common::infamous_base_token_name();
        let token_index_1_name = infamous_common::append_num(base_token_name, 1);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_1_name)) == 1, 1);

        let token_index_2_name = infamous_common::append_num(base_token_name, 2);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_2_name)) == 1, 1);

        let token_index_3_name = infamous_common::append_num(base_token_name, 3);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_3_name)) == 1, 1);

    }


}
