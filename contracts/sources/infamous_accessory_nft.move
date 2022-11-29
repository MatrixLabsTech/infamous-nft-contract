/// This module provides Infamous Accessory Token manager.
module infamous::infamous_accessory_nft {

    use std::bcs;
    use std::signer;
    use std::string::{Self, String, utf8};

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId, TokenDataId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;

    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_backend_token_accessory_open_box;
    friend infamous::infamous_upgrade_level;

    const ECOLLECTION_NOT_PUBLISHED: u64 = 1;


    const MAXIMUM: u64 = 0;


    struct TokenMintedEvent has drop, store {
        token_receiver_address: address,
        token_id: TokenId,
    }


    // the collection mint infos
    struct CollectionInfo has key {
        counter: u64,
        token_minted_events: EventHandle<TokenMintedEvent>,
    }


    fun init_module(source: &signer) {
        let collection_name = infamous_common::infamous_accessory_collection_name();
        let collection_uri = infamous_common::infamous_accessory_collection_uri();
        let description = infamous_common::infamous_accessory_description();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        token::create_collection_script(&manager_signer, collection_name, description, collection_uri, MAXIMUM, vector<bool>[false, true, false]);

        move_to(source, CollectionInfo {
            counter: 0, 
            token_minted_events: account::new_event_handle<TokenMintedEvent>(&manager_signer),
        });

       
    }

    public(friend) fun airdrop_box(receiver_addr: address, access: String): TokenId acquires CollectionInfo {

        let source_addr = @infamous;
        let collection_info = borrow_global_mut<CollectionInfo>(source_addr);

        // token infos
        let collection_name = infamous_common::infamous_accessory_collection_name();
        let base_token_name = infamous_common::infamous_accessory_base_token_name();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let prev_count = collection_info.counter;
        let cur = prev_count + 1;
        let name = infamous_common::append_num(base_token_name, cur);
        let uri = infamous_common::infamous_accessory_token_uri();
        let keys = vector<String>[];
        let values = vector<vector<u8>>[];
        let types = vector<String>[];


        if(!string::is_empty(&access)){
            uri = infamous_common::infamous_accessory_earlybird_token_uri();
            keys = vector<String>[utf8(b"access"), ];
            values = vector<vector<u8>>[bcs::to_bytes<String>(&access), ];
            types = vector<String>[ utf8(b"0x1::string::String"), ];
        };

        create_token_and_transfer_to_receiver(&manager_signer, receiver_addr, collection_name, name, uri, keys, values, types, );
        emit_minted_event(collection_info, receiver_addr, manager_addr, collection_name, name);

        // change CollectionInfo status
        let counter_ref = &mut collection_info.counter;
        *counter_ref = cur;
        resolve_token_id(manager_addr, collection_name, name)
    }

    public(friend) fun airdrop(receiver_addr: address, accessory: String, kind: String, gender: String, attributes: String,): TokenId acquires CollectionInfo {

        let source_addr = @infamous;
        let collection_info = borrow_global_mut<CollectionInfo>(source_addr);

        // token infos
        let collection_name = infamous_common::infamous_accessory_collection_name();
        let base_token_name = infamous_common::infamous_accessory_base_token_name();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let prev_count = collection_info.counter;
        let cur = prev_count + 1;
        let name = infamous_common::append_num(base_token_name, cur);
        let base_uri = infamous_common::infamous_accessory_base_token_uri();
        let uri = base_uri;
        let image = infamous::infamous_common::escape_whitespace(accessory);
        string::append(&mut uri, image);
        string::append(&mut uri, utf8(b".png"));

        create_token_and_transfer_to_receiver(&manager_signer, receiver_addr, collection_name, name, uri, 
        vector<String>[ utf8(b"name"), utf8(b"kind"), utf8(b"gender"), utf8(b"attributes") ], 
        vector<vector<u8>>[bcs::to_bytes<String>(&accessory), bcs::to_bytes<String>(&kind), bcs::to_bytes<String>(&gender), bcs::to_bytes<String>(&attributes)], 
        vector<String>[ utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String")],
        );
        emit_minted_event(collection_info, receiver_addr, manager_addr, collection_name, name);

        // change CollectionInfo status
        let counter_ref = &mut collection_info.counter;
        *counter_ref = cur;
        resolve_token_id(manager_addr, collection_name, name)
    }

    public(friend) fun mutate_token_properties(creator: &signer, 
        token_data_id: TokenDataId, 
        name: String, kind: String, gender: String, attributes: String,) {
        let keys = vector<String>[utf8(b"name"), utf8(b"kind"), utf8(b"gender"), utf8(b"attributes") ];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&name), bcs::to_bytes<String>(&kind), bcs::to_bytes<String>(&gender), bcs::to_bytes<String>(&attributes)];
        let types = vector<String>[ utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String")];

        token::mutate_tokendata_property(creator,
        token_data_id,
        keys, values, types
        );

        let base_uri = infamous_common::infamous_accessory_base_token_uri();
        let uri = base_uri;
        let image = infamous::infamous_common::escape_whitespace(name);
        string::append(&mut uri, image);
        string::append(&mut uri, utf8(b".png"));
        
        token::mutate_tokendata_uri(creator, token_data_id, uri);
     }


    public fun resolve_token_id(creator_addr: address, collection_name: String, token_name: String): TokenId {
        token::create_token_id_raw(creator_addr, collection_name, token_name, 0)
    }

    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }
    
    fun create_token_and_transfer_to_receiver(minter: &signer, receiver_addr: address, 
    collection_name: String, 
    token_name: String, 
    token_uri: String, 
    property_keys: vector<String>, 
    property_values: vector<vector<u8>>, 
    property_types: vector<String>) {
        
        let balance = 1;
        let maximum = 1;
        let minter_addr = signer::address_of(minter);
        let description = infamous_common::infamous_accessory_description();
        token::create_token_script(minter, collection_name, token_name, description, balance,
        maximum,
        token_uri,
        minter_addr,
        0,
        0,
        vector<bool>[true, true, true, true, true],
        property_keys, 
        property_values, 
        property_types,);

        if(receiver_addr != minter_addr) {
            let token_id = resolve_token_id(minter_addr, collection_name, token_name);
            token::transfer(minter, token_id, receiver_addr, balance);
        }
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


    #[test(user = @infamous, receiver = @0xBB, minter = @0xCC, framework = @0x1,)]
    public fun airdrop_test(user: &signer, receiver: &signer, minter: &signer, framework: &signer) acquires CollectionInfo {

        use aptos_framework::account;
        use aptos_framework::timestamp;
        use infamous::infamous_backend_auth;
        
        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        init_module(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);

        let minter_addr = signer::address_of(minter);
        account::create_account_for_test(minter_addr);


        infamous_backend_auth::delegate(user, minter_addr);

        token::opt_in_direct_transfer(receiver, true);



        airdrop(receiver_addr, utf8(b"blue"), utf8(b"background"), utf8(b"female"), utf8(b"3"));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_accessory_collection_name();

        let base_token_name = infamous_common::infamous_accessory_base_token_name();
        let token_index_1_name = infamous_common::append_num(base_token_name, 1);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_1_name)) == 1, 1);

        
        airdrop(receiver_addr, utf8(b"blue"), utf8(b"background"), utf8(b"female"), utf8(b"3"));

    }


}
