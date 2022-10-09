module infamous::infamous_nft {

    use std::signer;
    use std::error;
    use std::string::{Self, String};
    use aptos_std::table::{Self, Table};
    use aptos_token::token;
    use infamous::convertor;
    use infamous::manager_cap;

    const ECOLLECTION_NOT_PUBLISHED: u64 = 1;
    const EMINT_COUNT_OUT_OF_PER_MAX: u64 = 2;
    const EMINT_COUNT_OUT_OF_MAX: u64 = 3;

    struct CollectionInfo has key {
        collection_name: String,
        counter: u64,
        per_max: u64,
        maximum: u64,
        base_token_name: String,
        base_token_uri: String,
        per_minted_table: Table<address, u64>,
    }


    fun init_module(source: &signer) {
        let collection_name = string::utf8(b"InfamouseNFT");
        let base_token_name = string::utf8(b"Infamous #");
        let per_max = 10;
        let maximum = 100;
        let base_token_uri = string::utf8(b"https://beta.api.infamousnft.xyz/infamousnft/token/");
        let collection_uri = string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png");
        let description = string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs");
        let manager_signer = manager_cap::get_manager_signer();
        token::create_collection_script(&manager_signer, collection_name, description, collection_uri, maximum, vector<bool>[false, true, false]);

        move_to(source, CollectionInfo {
            collection_name: collection_name,
            counter: 0, 
            per_max: per_max, 
            maximum: maximum,
            base_token_name: base_token_name,
            base_token_uri: base_token_uri,
            per_minted_table: table::new(),
        });

       
    }

    
    public entry fun mint(receiver: &signer, count: u64) acquires CollectionInfo {
        let source_addr = @infamous;
        assert!(exists<CollectionInfo>(source_addr), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        let collection_info = borrow_global_mut<CollectionInfo>(source_addr);
        assert!(count <= collection_info.per_max, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));
        assert!(collection_info.counter + count <= collection_info.maximum, error::out_of_range(EMINT_COUNT_OUT_OF_MAX));

        let receiver_addr = signer::address_of(receiver);
        let used = minted_count(&collection_info.per_minted_table, receiver_addr);
        assert!(used + count <= collection_info.per_max, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));

        let collection_name = collection_info.collection_name;
        let base_token_name = collection_info.base_token_name;
        let base_token_uri = collection_info.base_token_uri;
        
        let default_keys = vector<String>[string::utf8(b"weapon"), string::utf8(b"level")];
        let default_vals = vector<vector<u8>>[b"", b"0"];
        let default_types = vector<String>[string::utf8(b"string"), string::utf8(b"integer")];
        let description = string::utf8(b"Infamous Token.");

        let manager_signer = manager_cap::get_manager_signer();
        let prev_count = collection_info.counter;
        let i = 0;
        while (i < count) {
            i = i + 1;
            let cur = prev_count + i;
            create_token_and_transfer_to_receiver(&manager_signer, receiver, cur, collection_name, base_token_name, base_token_uri, description, default_keys, default_vals, default_types);
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


    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }
    

    fun create_token_and_transfer_to_receiver(minter:&signer, receiver:&signer, cur: u64, collection_name: String, base_token_name: String, base_token_uri: String, description: String, default_property_keys: vector<String>, default_property_values: vector<vector<u8>>, default_property_types: vector<String>): String {
        let name = resolve_token_name(base_token_name, cur);
        let balance = 1;
        let maximum = 1;
        let uri = resolve_token_uri(base_token_uri, cur);
        let minter_addr = signer::address_of(minter);
        token::create_token_script(minter, collection_name, name, description, balance,
        maximum,
        uri,
        minter_addr,
        0,
        0,
        vector<bool>[false, false, true, false, true],
        default_property_keys,
        default_property_values,
        default_property_types);


        let token_id = token::create_token_id_raw(minter_addr, collection_name, name, 0);
        token::direct_transfer(minter, receiver, token_id, balance);
        name
    }

    
    fun resolve_token_name(base_token_name: String, cur: u64): String {
        let name = copy base_token_name;
        string::append(&mut name, convertor::num_str(cur));
        name
    }
    

    fun resolve_token_uri(base_token_uri: String, cur: u64): String {
        let uri = copy base_token_uri;
        string::append(&mut uri, convertor::num_str(cur));
        uri
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

    }


}
