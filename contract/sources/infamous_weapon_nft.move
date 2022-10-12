module infamous::infamous_weapon_nft {

    use std::bcs;
    use std::signer;
    use std::error;
    use std::string::{Self, String, utf8};

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use aptos_std::table::{Self, Table};

    use aptos_token::token::{Self, TokenId};

    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;

    const ECOLLECTION_NOT_PUBLISHED: u64 = 1;
    const ACCOUNT_MUSTBE_AUTHED: u64 = 2;
    const ACCOUNT_MUSTBE_MANAGER: u64 = 3;


    const MAXIMUM: u64 = 10000;


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
        let collection_name = infamous_common::infamous_weapon_collection_name();
        let collection_uri = infamous_common::infamous_weapon_collection_uri();
        let description = infamous_common::infamous_weapon_description();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        token::create_collection_script(&manager_signer, collection_name, description, collection_uri, MAXIMUM, vector<bool>[false, true, false]);

        move_to(source, CollectionInfo {
            counter: 0, 
            token_minted_events: account::new_event_handle<TokenMintedEvent>(&manager_signer),
        });

       
    }


    public entry fun airdrop(sender: &signer, receiver_addr: address, weapon: String, meterial: String, level: String,): String acquires CollectionInfo {
        
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        
        let source_addr = @infamous;
        let collection_info = borrow_global_mut<CollectionInfo>(source_addr);

        // token infos
        let collection_name = infamous_common::infamous_weapon_collection_name();
        let base_token_name = infamous_common::infamous_weapon_base_token_name();
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let prev_count = collection_info.counter;
        let cur = prev_count + 1;
        let name = infamous_common::append_num(base_token_name, cur);
        let base_uri = infamous_common::infamous_weapon_base_token_uri();
        let uri = copy base_uri;
        string::append(&mut uri, weapon);
        string::append(&mut uri, utf8(b".png"));

        create_token_and_transfer_to_receiver(&manager_signer, receiver_addr, collection_name, name, uri, weapon, meterial, level,);
        emit_minted_event(collection_info, receiver_addr, manager_addr, collection_name, name);

        // change CollectionInfo status
        let counter_ref = &mut collection_info.counter;
        *counter_ref = cur;
        name
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
    

    fun create_token_and_transfer_to_receiver(minter: &signer, receiver_addr: address, collection_name: String, token_name: String, token_uri: String, weapon: String, meterial: String, level: String,) {
        
        let balance = 1;
        let maximum = 1;
        let minter_addr = signer::address_of(minter);
        let description = infamous_common::infamous_weapon_description();
        token::create_token_script(minter, collection_name, token_name, description, balance,
        maximum,
        token_uri,
        minter_addr,
        0,
        0,
        vector<bool>[false, true, false, false, true],
        vector<String>[ utf8(b"weapon"), utf8(b"meterial"), utf8(b"level") ], 
        vector<vector<u8>>[bcs::to_bytes<String>(&weapon), bcs::to_bytes<String>(&meterial), bcs::to_bytes<String>(&level)], 
        vector<String>[ utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String")],);

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



        airdrop(minter, receiver_addr, utf8(b"knif"), utf8(b"normal knif"), utf8(b"3"));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_weapon_collection_name();

        let base_token_name = infamous_common::infamous_weapon_base_token_name();
        let token_index_1_name = infamous_common::append_num(base_token_name, 1);
        assert!(token::balance_of(receiver_addr, resolve_token_id(manager_addr, collection_name, token_index_1_name)) == 1, 1);

    }


}
