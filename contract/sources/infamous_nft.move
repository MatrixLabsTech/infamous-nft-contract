module infamous::infamous_nft {

    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8 };

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use aptos_token::property_map::{Self, PropertyMap};
    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;

    friend infamous::infamous_backend_open_box;

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
        token_minted_events: EventHandle<TokenMintedEvent>,
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

            create_token_and_transfer_to_receiver(&manager_signer, receiver, collection_name, name, uri, description);
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

  

    

     public fun update_token_uri_with_properties(owner_addr: address, name: String,) {
      
        let creator = infamous_manager_cap::get_manager_signer();
        let creator_addr = signer::address_of(&creator);
        let collection_name = infamous_common::infamous_collection_name();
        let token_id = resolve_token_id(creator_addr, collection_name, name);
        let properties = token::get_property_map(owner_addr, token_id);
        let properties_string = utf8(b"");
        append_property(&mut properties_string, properties, utf8(b"background"));
        append_property(&mut properties_string, properties, utf8(b"clothing"));
        append_property(&mut properties_string, properties, utf8(b"ear"));
        append_property(&mut properties_string, properties, utf8(b"eyebrow"));
        append_property(&mut properties_string, properties, utf8(b"accessories"));
        append_property(&mut properties_string, properties, utf8(b"eyes"));
        append_property(&mut properties_string, properties, utf8(b"hair"));
        append_property(&mut properties_string, properties, utf8(b"mouth"));
        append_property(&mut properties_string, properties, utf8(b"neck"));
        append_property(&mut properties_string, properties, utf8(b"tattoo"));
        append_property(&mut properties_string, properties, utf8(b"weapon"));
        let hash_string = infamous_common::string_hash_string(properties_string);
        let base_uri = infamous_common::infamous_base_token_uri();
        string::append(&mut base_uri, hash_string);
        string::append(&mut base_uri, utf8(b".png"));

        let token_data_id = token::create_token_data_id(creator_addr, collection_name, name);
        token::mutate_tokendata_uri(&creator, token_data_id, base_uri);

     }

     
     public(friend) fun update_token_uri_with_known_properties(name: String,
     
        background: String, clothing: String, ear: String, eyebrow: String,
        accessories: String, eyes: String, hair: String,  
        mouth: String, neck: String, tattoo: String, 
        weapon: String,) {
      
        let creator = infamous_manager_cap::get_manager_signer();
        let creator_addr = signer::address_of(&creator);
        let collection_name = infamous_common::infamous_collection_name();
        let properties_string = utf8(b"");
        string::append(&mut properties_string, background);
        string::append(&mut properties_string, clothing);
        string::append(&mut properties_string, ear);
        string::append(&mut properties_string, eyebrow);
        string::append(&mut properties_string, accessories);
        string::append(&mut properties_string, eyes);
        string::append(&mut properties_string, hair);
        string::append(&mut properties_string, mouth);
        string::append(&mut properties_string, neck);
        string::append(&mut properties_string, tattoo);
        string::append(&mut properties_string, weapon);
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


    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }
    

    fun create_token_and_transfer_to_receiver(minter: &signer, receiver:&signer, collection_name: String, token_name: String, token_uri: String, description: String,) {
        
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
