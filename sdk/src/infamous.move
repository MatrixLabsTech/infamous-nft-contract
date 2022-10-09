module infamous::infamousNFT1_3 {

    use std::string::{Self, String};
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_framework::account;
    use aptos_token::token::{Self, TokenDataId};
    use aptos_std::table::{Self, Table};
    use aptos_std::table_with_length::{Self, TableWithLength};
    use aptos_framework::timestamp;

    const EMODULE_INITIALER_SHOULD_BE_MODULE_OWNER: u64 = 0;
    const EMINTER_INFO_NOT_PUBLISHED: u64 = 1;
    const EMINTER_INFO_ALREADY_PUBLISHED: u64 = 2;
    const ECOLLECTION_ALREADY_PUBLISHED: u64 = 3;
    const ECOLLECTION_NOT_PUBLISHED: u64 = 4;
    const EMINT_COUNT_OUT_OF_PER_MAX: u64 = 5;
    const EMINT_COUNT_OUT_OF_MAX: u64 = 6;
    const ETOKEN_PROPERTY_INFO_NOT_PUBLISHED: u64 = 7;
   
    const EEXP_NOT_ENOUGH_FOR_ONE_LEVEL: u64 = 9;
    const ETOKEN_ALREADY_STAKED: u64 = 10;
    const ETOKEN_LEVEL_FULL: u64 = 11;
    const ETOKEN_LEVEL_NEED_TO_MORE_THAN_THREE: u64 = 12;


    const COLLECTION_NAME: vector<u8> = b"InfamousNFT";
    

    struct PropertyInfo has key,drop,copy,store {
        level: u64,
        weapon: String,
    }

    struct MinterInfo has key {
        infamous_collection_name: String,
        counter: u64,
        maximum: u64,
        per_max: u64,
        per_minted_table: Table<address, u64>,
        token_property_table: Table<String, PropertyInfo>,
        seed: vector<u8>,
        signer_cap: account::SignerCapability,
    }


    struct StakingTime has store, drop {
        token_name: String,
        start: u64,
        used: u64,
    }

    struct TokenStakes has key {
        staking: vector<TokenDataId>,
        staking_time: TableWithLength<TokenDataId, StakingTime>,
    }


    /// initialize a resource account in current module address
    public entry fun initialize(source: &signer, seed: vector<u8>) {
        let source_addr = signer::address_of(source);
        let infamous_source_addr = @infamous;
        assert!(infamous_source_addr == source_addr, error::already_exists(EMODULE_INITIALER_SHOULD_BE_MODULE_OWNER));
        assert!(!exists<MinterInfo>(source_addr), error::already_exists(EMINTER_INFO_ALREADY_PUBLISHED));
        let (_, resource_signer_cap) = account::create_resource_account(source, seed);
        move_to(source, MinterInfo { 
            infamous_collection_name: string::utf8(b""),
            counter:0, 
            maximum:0,
            per_max:0, 
            seed: seed, 
            signer_cap: resource_signer_cap, 
            per_minted_table: table::new(),
            token_property_table: table::new()
        });
    }



    /// use resource account create infamous_collection_name
    public entry fun create_infamous_collection(per_max: u64, maximum: u64) acquires MinterInfo {
        
        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);
        assert!(string::is_empty(&minter_info.infamous_collection_name), error::already_exists(ECOLLECTION_ALREADY_PUBLISHED));

        let infamous_collection_nameName = string::utf8(b"InfamousNFT");
        token_create_infamous_collection_name(minter_info, maximum, infamous_collection_nameName);

        // record infamous_collection_nameName\maximum\per_max
        let infamous_collection_name_ref = &mut minter_info.infamous_collection_name;
        *infamous_collection_name_ref = infamous_collection_nameName;
        let maximum_ref = &mut minter_info.maximum;
        *maximum_ref = maximum;
        let per_max_ref = &mut minter_info.per_max;
        *per_max_ref = per_max;
    }



    public entry fun mint(receiver: &signer, count: u64) acquires MinterInfo {

        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);
        assert!(!string::is_empty(&minter_info.infamous_collection_name), error::not_found(ECOLLECTION_NOT_PUBLISHED));
        assert!(count <= minter_info.per_max, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));
        assert!(minter_info.counter + count <= minter_info.maximum, error::out_of_range(EMINT_COUNT_OUT_OF_MAX));

        let receiver_addr = signer::address_of(receiver);
        let used = minted_count(&minter_info.per_minted_table, receiver_addr);
        assert!(used + count <= minter_info.per_max, error::out_of_range(EMINT_COUNT_OUT_OF_PER_MAX));

        let minter = resolve_minter(minter_info);

        let infamous_collection_nameName = minter_info.infamous_collection_name;
        let prev_count = minter_info.counter;
        let i = 0;
        while (i < count) {
            i = i + 1;
            let cur = prev_count + i;
            let tokenName = create_token_and_transfer_to_receiver(&minter, receiver, cur, infamous_collection_nameName);
            table::add(&mut minter_info.token_property_table, tokenName, PropertyInfo{
                level: 0,
                weapon: string::utf8(b"")
            });
        };

        // change minterInfo status
        let counter_ref = &mut minter_info.counter;
        *counter_ref = prev_count + count;
        if (!table::contains(&minter_info.per_minted_table, receiver_addr)) {
            table::add(&mut minter_info.per_minted_table, receiver_addr, count);
        } else {
            let table_reciver_ref = table::borrow_mut(&mut minter_info.per_minted_table, receiver_addr);
            *table_reciver_ref = used + count;
        };

    }


    fun initialize_token_stakes(account: &signer) {
        move_to(
            account,
            TokenStakes {
                staking: vector::empty<TokenDataId>(),
                staking_time: table_with_length::new<TokenDataId, StakingTime>(),
            }
        )
    }


    public entry fun stake_script(
        sender: &signer,
        name: String,
        property_version: u64,
    ) acquires TokenStakes, MinterInfo {
       
        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);
        let minter = resolve_minter(minter_info);
        let minter_addr = signer::address_of(&minter);
        let collection = minter_info.infamous_collection_name;


        let token_id = token::create_token_id_raw(minter_addr, collection, name, property_version);
        token::direct_transfer(sender, &minter, token_id, 1);


        let token_data_id = token::create_token_data_id(minter_addr, collection, name);
        let sender_addr = signer::address_of(sender);
        if (!exists<TokenStakes>(sender_addr)) {
            initialize_token_stakes(sender);
        };
        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        assert!(!vector::contains(staking, &token_data_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        vector::push_back(staking, token_data_id);

        let staking_time = &mut stakes.staking_time;
        assert!(!table_with_length::contains(staking_time, token_data_id), error::already_exists(ETOKEN_ALREADY_STAKED));
        table_with_length::add(staking_time, token_data_id, StakingTime{
                 token_name: name,
                 start: timestamp::now_seconds(),
                 used: 0,
             });
    }

  

    public entry fun unstake_script(
        sender: &signer,
        name: String,
        property_version: u64,
    ) acquires TokenStakes, MinterInfo {
        
        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);
        let minter = resolve_minter(minter_info);
        let minter_addr = signer::address_of(&minter);
        let collection = minter_info.infamous_collection_name;


        let token_id = token::create_token_id_raw(minter_addr, collection, name, property_version);
        let token_data_id = token::create_token_data_id(minter_addr, collection, name);
        let sender_addr = signer::address_of(sender);
        assert!(exists<TokenStakes>(sender_addr), error::not_found(ETOKEN_NOT_STAKE));

        let stakes = borrow_global_mut<TokenStakes>(sender_addr);
        let staking = &mut stakes.staking;
        let (found, index) = vector::index_of(staking, &token_data_id);
        assert!(found, error::not_found(ETOKEN_NOT_STAKE));
        vector::remove(staking, index);

        let staking_time = &mut stakes.staking_time;
        assert!(table_with_length::contains(staking_time, token_data_id), error::not_found(ETOKEN_NOT_STAKE));
        let _stake_time = table_with_length::remove(staking_time, token_data_id);
        token::direct_transfer(&minter, sender, token_id, 1);
    }


    public entry fun upgrade_level(sender: &signer, token_name:String, token_property_version:u64) acquires MinterInfo, TokenStakes {
        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);

        let minter = resolve_minter(minter_info);
        let minter_addr = signer::address_of(&minter);


        let sender_addr = signer::address_of(sender);
        assert!(exists<TokenStakes>(sender_addr), error::not_found(ETOKEN_NOT_STAKE));
        let staking_time =
            &mut borrow_global_mut<TokenStakes>(sender_addr).staking_time;

        let token_data_id = token::create_token_data_id(minter_addr, minter_info.infamous_collection_name, token_name);
        assert!(table_with_length::contains(staking_time, token_data_id), error::not_found(ETOKEN_NOT_STAKE));


        let staking_time_mut = table_with_length::borrow_mut(staking_time, token_data_id);
        let start = staking_time_mut.start;
        let used = staking_time_mut.used;
        let now = timestamp::now_seconds();

        let exp = now - start - used;
        assert!(exp >= 300, error::not_found(EEXP_NOT_ENOUGH_FOR_ONE_LEVEL));

        let added_level = exp / 300;


        assert!(table::contains(&minter_info.token_property_table, token_name), error::not_found(ETOKEN_PROPERTY_INFO_NOT_PUBLISHED));
        let propertyValues = *table::borrow(&minter_info.token_property_table, token_name);
        assert!(propertyValues.level < 5, error::aborted(ETOKEN_LEVEL_FULL));
        let new_level = propertyValues.level + added_level;
         let new_keys = vector<String>[
            string::utf8(b"level")
        ];
        let new_types = vector<String>[
            string::utf8(b"integer")
        ];
        if(new_level >= 5) {
            new_level = 5;
            let new_vals = vector<vector<u8>>[
                *string::bytes(&num_str(new_level))
            ];
            unstake_script(sender, token_name, token_property_version);
            token::mutate_token_properties(&minter, minter_addr, minter_addr, minter_info.infamous_collection_name, token_name, token_property_version, 1, new_keys, new_vals, new_types);
        }else {
            let new_vals = vector<vector<u8>>[
                *string::bytes(&num_str(new_level))
            ];
            token::mutate_token_properties(&minter, minter_addr, minter_addr, minter_info.infamous_collection_name, token_name, token_property_version, 1, new_keys, new_vals, new_types);
            let property_value = table::borrow_mut(&mut minter_info.token_property_table, token_name);
            property_value.level = new_level;
            staking_time_mut.used = used + added_level * 300;
        }

       
    }

    public entry fun wear_weapon(sender: &signer, token_name:String, token_property_version:u64, weapon_name: String) acquires MinterInfo, TokenStakes {
        let infamous_source_addr = @infamous;
        assert!(exists<MinterInfo>(infamous_source_addr), error::not_found(EMINTER_INFO_NOT_PUBLISHED));
        let minter_info = borrow_global_mut<MinterInfo>(infamous_source_addr);

        let minter = resolve_minter(minter_info);
        let minter_addr = signer::address_of(&minter);


        let sender_addr = signer::address_of(sender);
        assert!(exists<TokenStakes>(sender_addr), error::not_found(ETOKEN_NOT_STAKE));
        let staking_time =
            &mut borrow_global_mut<TokenStakes>(sender_addr).staking_time;

        let token_data_id = token::create_token_data_id(minter_addr, minter_info.infamous_collection_name, token_name);
        assert!(table_with_length::contains(staking_time, token_data_id), error::not_found(ETOKEN_NOT_STAKE));


        assert!(table::contains(&minter_info.token_property_table, token_name), error::not_found(ETOKEN_PROPERTY_INFO_NOT_PUBLISHED));
        let propertyValues = *table::borrow(&minter_info.token_property_table, token_name);
        assert!(propertyValues.level >= 3, error::aborted(ETOKEN_LEVEL_NEED_TO_MORE_THAN_THREE));
     
        let new_keys = vector<String>[
            string::utf8(b"weapon")
        ];
        let new_vals = vector<vector<u8>>[
            *string::bytes(&weapon_name)
        ];
        let new_types = vector<String>[
            string::utf8(b"string")
        ];
        token::mutate_token_properties(&minter,
        minter_addr,
        minter_addr,
        minter_info.infamous_collection_name,
        token_name,
        token_property_version,
        1,
        new_keys,
        new_vals,
        new_types);
        let property_value = table::borrow_mut(&mut minter_info.token_property_table, token_name);
        property_value.weapon = weapon_name;
    }

    fun create_token_and_transfer_to_receiver(minter:&signer, receiver:&signer, cur: u64, infamous_collection_nameName: String): String {
        let name = resolve_token_name(cur);
        let description = string::utf8(b"Infamous nft...");
        let balance = 1;
        let maximum = 1;
        let uri = resolve_token_uri(cur);
        let minter_addr = signer::address_of(minter);
        let default_keys = vector<String>[string::utf8(b"level"), string::utf8(b"weapon")];
        let default_vals = vector<vector<u8>>[b"0", b""];
        let default_types = vector<String>[string::utf8(b"integer"), string::utf8(b"string")];
        token::create_token_script(minter, infamous_collection_nameName, name, description, balance,
        maximum,
        uri,
        minter_addr,
        0,
        0,
        vector<bool>[false, false, true, false, true],
        default_keys,
        default_vals,
        default_types);


        let token_id = token::create_token_id_raw(minter_addr, infamous_collection_nameName, name, 0);
        token::direct_transfer(minter, receiver, token_id, balance);
        name
    }

    fun minted_count(table_info: &Table<address, u64>, owner: address): u64 {
        if (table::contains(table_info, owner)) {
            *table::borrow(table_info, owner)
        } else {
            0
        }
    }

    fun token_create_infamous_collection_name(minter_info: &mut MinterInfo, maximum: u64, infamous_collection_nameName: String) {

        let signer_cap = &minter_info.signer_cap;
        let minter = account::create_signer_with_capability(signer_cap);

        let description = string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs");
        let uri = 
            string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png");

        token::create_collection_script(&minter, infamous_collection_nameName, description, uri, maximum, vector<bool>[false, true, false]);
    }


    fun resolve_token_uri(cur: u64): String {
        let uri = string::utf8(b"https://beta.api.infamousnft.xyz/infamousnft/token/");
        string::append(&mut uri, num_str(cur));
        uri
    }

    fun resolve_token_name(cur: u64): String {
        let name = string::utf8(b"Infamous #");
        string::append(&mut name, num_str(cur));
        name
    }

    fun resolve_minter(minter_info: &mut MinterInfo): signer{
        let signer_cap = &minter_info.signer_cap;
        account::create_signer_with_capability(signer_cap)
    }


    fun num_str(num: u64): String{
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }



    #[test(creator = @infamous)]
    public entry fun end_to_end(creator: signer) acquires MinterInfo {

        use aptos_std::debug;

        let creator_addr = signer::address_of(&creator);
        
        debug::print<address>(&creator_addr);
        let seed = x"01";
        initialize(&creator, seed);
        create_infamous_collection(10, 100);
        // mint(&owner0, 2);
        // mint(&owner1, 2);
    }



}
