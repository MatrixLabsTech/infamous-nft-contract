module infamous::infamous_nft {

    use std::signer;
    use std::error;
    use std::string::{String};
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId};

    use infamous::common;
    use infamous::manager_cap;

    const ECOLLECTION_NOT_PUBLISHED: u64 = 1;
    const EMINT_COUNT_OUT_OF_PER_MAX: u64 = 2;
    const EMINT_COUNT_OUT_OF_MAX: u64 = 3;


    const PER_MAX: u64 = 10;
    const MAXIMUM: u64 = 12;


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
        let collection_name = common::infamous_collection_name();
        let collection_uri = common::infamous_collection_uri();
        let description = common::infamous_description();
        let manager_signer = manager_cap::get_manager_signer();
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
        let collection_name = common::infamous_collection_name();
        let base_token_name = common::infamous_base_token_name();
        let base_token_uri = common::infamous_base_token_uri();
        let description = common::infamous_description();
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let prev_count = collection_info.counter;
        let i = 0;
        while (i < count) {
            i = i + 1;
            let cur = prev_count + i;
            let name = common::append_num(base_token_name, cur);
            let uri = common::append_num(base_token_uri, cur);

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
        token::create_token_id_raw(creator_addr, collection_name, token_name, 1)
    }


    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }
    

    fun create_token_and_transfer_to_receiver(minter: &signer, receiver:&signer, collection_name: String, token_name: String, token_uri: String, description: String) {
        
        let balance = 1;
        let maximum = 1;
        let minter_addr = signer::address_of(minter);
        token::create_token_script(minter, collection_name, token_name, description, balance,
        maximum,
        token_uri,
        minter_addr,
        0,
        0,
        vector<bool>[false, false, true, false, true],
        vector::empty<String>(),
        vector::empty<vector<u8>>(),
        vector::empty<String>(),);

        // change the property_version to be 1
        token::mutate_token_properties(minter, minter_addr, minter_addr, collection_name, token_name, 0, 1, vector::empty<String>(), vector::empty<vector<u8>>(), vector::empty<String>(),);

        let token_id = token::create_token_id_raw(minter_addr, collection_name, token_name, 1);
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


    #[test(user = @infamous, receiver = @0xBB)]
    public fun end_to_end(user: &signer, receiver: &signer) acquires CollectionInfo {

        use aptos_framework::account;

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        manager_cap::initialize(user);
        init_module(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        mint(receiver, 3);

        
        let manager_signer = manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = common::infamous_collection_name();

        let token_index_1_name = common::infamous_token_name(1);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_1_name)) == 1, 1);

        let token_index_2_name = common::infamous_token_name(2);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_2_name)) == 1, 1);

        let token_index_3_name = common::infamous_token_name(3);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_3_name)) == 1, 1);

    }


}
